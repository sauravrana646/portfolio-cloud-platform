# Application charts

Workload charts (not platform prerequisites).

Discovery: add `apps/<env>.yaml` under the chart, then apply the matching root
(`argocd/root-dev.yaml` only picks up `apps/dev.yaml`, etc.). Creates
`<chart>-<env>` (namespace `<chart>-<env>`).

| Chart | Envs | Values |
|-------|------|--------|
| `demo-app` | `dev`, `uat`, `prod` | `helm-values/applications/demo-app/` |

Env overlays: `helm-values/applications/<chart>/environments/<env>/{values,images}.yaml`.
