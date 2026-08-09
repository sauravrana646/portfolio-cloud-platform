# Argo CD — generic App-of-Apps

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

Local Compose Prometheus/Grafana stays under `local/` (not Argo).

## Before first sync

1. Install Argo CD (ApplicationSet controller enabled).
2. Patch Infisical identity in `charts/bootstrap-layer/infisical-secrets/`.
3. Teleport: set `proxyAddr` + join-token (`docs/JIT_TELEPORT.md`), then sync.
4. Wrapper charts: Argo runs `helm dependency build` (or `make helm-deps`).
