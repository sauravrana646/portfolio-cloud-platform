# Argo CD — generic App-of-Apps

## OrbStack (Argo CD already installed)

Do **not** run `make bootstrap-up` — that Helm-installs the same charts and will
fight Argo. Point kubectl at OrbStack and apply the root app:

```bash
kubectl config use-context orbstack
kubectl -n argocd get pods

git checkout main && git pull

# Repo must be reachable by Argo (public GH or configured credentials)
kubectl apply -f argocd/root.yaml

# ApplicationSet discovers charts/**/app.yaml and apps/*.yaml
kubectl -n argocd get applicationset
kubectl -n argocd get applications
```

Then follow **Before first sync** below (cosign Secret / Infisical, skip Teleport
until configured). Sync waves pull Kyverno, kube-prometheus-stack, policies, and
`demo-app-dev` automatically. `demo-app-prod` and Teleport stay manual
(`autoSync: false`).

```bash
# Useful checks
kubectl -n argocd get app platform-root
kubectl -n kyverno get pods
kubectl -n monitoring get pods
kubectl -n demo-app-dev get deploy,svc
kubectl get clusterpolicy

# App
kubectl -n demo-app-dev port-forward svc/demo-api 8080:80
# Grafana (if NodePort / port-forward the monitoring services)
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Tear down GitOps apps (keeps OrbStack + Argo CD):

```bash
kubectl -n argocd delete application platform-root
# ApplicationSet prune removes child apps if prune=true; otherwise:
kubectl -n argocd delete applicationset charts
```

---

```bash
kubectl apply -f argocd/root.yaml
```

`platform-root` syncs `argocd/appsets/`, which installs the **`charts` ApplicationSet**.
That ApplicationSet loops over discovery files under `charts/` and creates one
Application per match — no hand-written Application manifests per chart.

## Onboard a chart (automatic Application)

| Layer | Add | Discovery file | Values |
|-------|-----|----------------|--------|
| Bootstrap | `charts/bootstrap-layer/<chart>/` | `app.yaml` | `helm-values/bootstrap-layer/<chart>/values.yaml` (Helm only) |
| Workload | `charts/applications/<chart>/` | `apps/<env>.yaml` per env | `helm-values/applications/<chart>/` + `environments/<env>/` |

### Naming

| Kind | Application name | Namespace |
|------|------------------|-----------|
| Bootstrap | `bootstrap-<chart>` | from `app.yaml` (component default) |
| Workload env | `<chart>-<env>` | `<chart>-<env>` (e.g. `demo-app-dev`) |

### `app.yaml` / `apps/<env>.yaml` fields

| Field | Required | Notes |
|-------|----------|-------|
| `name` | yes | Application CR name |
| `layer` | yes | `bootstrap-layer` \| `applications` |
| `chart` | yes | Folder name under the layer |
| `chartPath` | yes | Git path to chart / kustomize dir |
| `valuesPath` | Helm | Path under `helm-values/` (no prefix) |
| `namespace` | yes | Destination namespace |
| `syncWave` | yes | String wave (`"0"` … `"10"`) |
| `sourceType` | no | `helm` (default) \| `directory` |
| `releaseName` | no | Defaults to `chart` |
| `env` | workloads | Enables `environments/<env>/values.yaml` |
| `imagePin` | workloads | `"true"` also mounts `environments/<env>/images.yaml` |
| `autoSync` / `selfHeal` / `prune` | no | Strings `"true"` / `"false"` (default on except where set) |
| `serverSideApply` | no | `"true"` for large CRD charts |
| `finalizer` | no | `"false"` to omit app finalizer |

### Values layout (mirrors charts)

```text
helm-values/
  bootstrap-layer/<chart>/values.yaml
  applications/<chart>/
    values.yaml
    environments/<env>/
      values.yaml
      images.yaml          # when imagePin: "true"
```

Workload valueFiles order: base → env values → env images.

## Sync waves

| Wave | Apps |
|------|------|
| 0 | metrics-server, kyverno, kube-prometheus-stack |
| 1 | infisical-operator |
| 2 | infisical-secrets, teleport-kube-agent |
| 3 | kyverno-policies |
| 10 | `*-dev` / `*-uat` / `*-prod` workload apps |

Local paths (not Argo): Compose under `local/docker-compose.yml`; full Kind
bootstrap (same charts/policies/monitoring) under `local/bootstrap/` —
`make bootstrap-up`.

## Before first sync

1. Install Argo CD (ApplicationSet controller enabled).
2. Patch Infisical identity in `charts/bootstrap-layer/infisical-secrets/`.
3. Teleport: set `proxyAddr` + join-token (`docs/JIT_TELEPORT.md`), then sync.
4. Wrapper charts: Argo runs `helm dependency build` (or `make helm-deps`).
