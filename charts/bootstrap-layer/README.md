# Bootstrap layer charts

Prerequisite platform components. Each subfolder is either:

- a **thin Helm wrapper** (`Chart.yaml` + upstream `dependencies`), or
- a **directory/Kustomize** bundle (`kustomization.yaml`)

Discovery: put `app.yaml` in the chart folder. The ApplicationSet in
`argocd/appsets/charts.yaml` creates `bootstrap-<chart>` automatically.

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
