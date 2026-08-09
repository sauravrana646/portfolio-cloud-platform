# Bootstrap layer charts

Prerequisite platform components. Each subfolder is either:

- a **thin Helm wrapper** (`Chart.yaml` + upstream `dependencies`), or
- a **directory/Kustomize** bundle (`kustomization.yaml`)

Discovery: put `app.yaml` in the chart folder **and** add its path to the
`files:` list in `argocd/appsets/bootstrap/applicationset.yaml`. Apply
`argocd/root-bootstrap.yaml` (ApplicationSet `charts-bootstrap`).

| Chart | Type | Values |
|-------|------|--------|
| `kyverno` | Helm wrapper | `helm-values/bootstrap-layer/kyverno/` |
| `kube-prometheus-stack` | Helm wrapper | `helm-values/bootstrap-layer/kube-prometheus-stack/` |
| `metrics-server` | Helm wrapper | `helm-values/bootstrap-layer/metrics-server/` |
| `infisical-operator` | Helm wrapper | `helm-values/bootstrap-layer/infisical-operator/` |
| `teleport-kube-agent` | Helm wrapper | `helm-values/bootstrap-layer/teleport-kube-agent/` |
| `infisical-secrets` | Kustomize | (in-folder) |
| `kyverno-policies` | Kustomize → `policy/kyverno` | (in-folder) |

```bash
make helm-deps
```
