# Argo CD — per-environment roots

Each root Application syncs **one** ApplicationSet folder. Workload envs are
isolated: `root-dev` only discovers `charts/applications/*/apps/dev.yaml`.

| Root file | Creates | Discovers |
|-----------|---------|-----------|
| `root-bootstrap.yaml` | `platform-root-bootstrap` → ApplicationSet `charts-bootstrap` | `charts/bootstrap-layer/*/app.yaml` |
| `root-dev.yaml` | `platform-root-dev` → `charts-dev` | `charts/applications/*/apps/dev.yaml` |
| `root-uat.yaml` | `platform-root-uat` → `charts-uat` | `…/apps/uat.yaml` |
| `root-prod.yaml` | `platform-root-prod` → `charts-prod` | `…/apps/prod.yaml` |

## OrbStack (Argo CD already installed)

**Full end-to-end (Infisical Universal Auth, roots, verify):**  
[`docs/LOCAL_K8S_ORBSTACK.md`](../docs/LOCAL_K8S_ORBSTACK.md)

```bash
kubectl config use-context orbstack
kubectl -n argocd get pods
git checkout main && git pull

# 1) Platform once per cluster (Kyverno, monitoring, policies, …)
kubectl apply -f argocd/root-bootstrap.yaml

# 2) Only the env you want on this cluster
kubectl apply -f argocd/root-dev.yaml
# kubectl apply -f argocd/root-uat.yaml
# kubectl apply -f argocd/root-prod.yaml
```

Do **not** use `make bootstrap-up` alongside Argo (Helm would fight GitOps).

```bash
kubectl -n argocd get applicationset
kubectl -n argocd get applications -l platform.env=dev

kubectl -n kyverno get pods
kubectl -n monitoring get pods
kubectl -n demo-app-dev get deploy,svc
kubectl get clusterpolicy

kubectl -n demo-app-dev port-forward svc/demo-api 8080:80
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Tear down one env (keeps Argo + other roots):

```bash
kubectl -n argocd delete application platform-root-dev
kubectl -n argocd delete applicationset charts-dev
```

## How env selection works

There is no runtime “mode” switch. **Which root you apply** decides the env:

- Apply only `root-dev.yaml` → only Applications from `apps/dev.yaml` (e.g. `demo-app-dev`).
- Apply `root-uat.yaml` → only `apps/uat.yaml` workloads.
- Bootstrap is separate so Kyverno/monitoring are not reinstalled per env.

Promotion = PR changing digests under `helm-values/applications/<chart>/environments/<env>/`.

## Onboard a chart

| Layer | Add | Discovery file | Also register path in | Values |
|-------|-----|----------------|----------------------|--------|
| Bootstrap | `charts/bootstrap-layer/<chart>/` | `app.yaml` | `argocd/appsets/bootstrap/applicationset.yaml` `files:` list | `helm-values/bootstrap-layer/<chart>/values.yaml` |
| Workload | `charts/applications/<chart>/` | `apps/<env>.yaml` | matching `argocd/appsets/<env>/applicationset.yaml` | `helm-values/applications/<chart>/environments/<env>/` |

Paths are listed **explicitly** (no `*` globs). Argo’s default git file globbing is
greedy and can emit duplicate Application names.

### Naming

| Kind | Application name | Namespace |
|------|------------------|-----------|
| Bootstrap | `bootstrap-<chart>` | from `app.yaml` |
| Workload env | `<chart>-<env>` | `<chart>-<env>` |

### Sync waves (bootstrap)

| Wave | Apps |
|------|------|
| 0 | metrics-server, kyverno, kube-prometheus-stack |
| 1 | infisical-operator |
| 2 | infisical-secrets, teleport-kube-agent (manual until configured) |
| 3 | kyverno-policies |
| 4 | policy-reporter (UI + Kyverno plugin) |
| 10 | workload apps from the env root you applied |

## Before first sync

1. Argo CD with ApplicationSet controller (already on OrbStack).
2. Patch Infisical identity in `charts/bootstrap-layer/infisical-secrets/` (or create cosign Secret manually).
3. Teleport: set `proxyAddr` + join-token before syncing that app.
4. If you previously applied the old monolithic `root.yaml` / ApplicationSet `charts`, delete them first:

```bash
kubectl -n argocd delete application platform-root --ignore-not-found
kubectl -n argocd delete applicationset charts --ignore-not-found
```
