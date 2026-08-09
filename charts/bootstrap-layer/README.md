# Bootstrap layer charts

Prerequisite platform components. Each subfolder is a **thin Helm wrapper**
around an upstream chart (declared in `Chart.yaml` `dependencies`).

| Chart | Upstream | Values |
|-------|----------|--------|
| `kyverno` | kyverno/kyverno | `helm-values/bootstrap-layer/kyverno/` |
| `kube-prometheus-stack` | prometheus-community | `helm-values/bootstrap-layer/kube-prometheus-stack/` |
| `metrics-server` | metrics-server | `helm-values/bootstrap-layer/metrics-server/` |
| `infisical-operator` | Infisical secrets-operator | `helm-values/bootstrap-layer/infisical-operator/` |
| `teleport-kube-agent` | Teleport | `helm-values/bootstrap-layer/teleport-kube-agent/` |
| `infisical-secrets` | Kustomize (InfisicalSecret CR) | manifests in-folder |

```bash
# Fetch upstream charts into charts/ subdir (CI / local)
for d in kyverno kube-prometheus-stack metrics-server infisical-operator teleport-kube-agent; do
  helm dependency update "charts/bootstrap-layer/$d"
done
```

Argo CD App-of-Apps syncs these before `charts/applications/*`.
