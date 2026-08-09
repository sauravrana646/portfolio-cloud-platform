# Application charts

Workload charts (not platform prerequisites).

Discovery: add `apps/<env>.yaml` under the chart, then apply the matching root
(`argocd/root-dev.yaml` only picks up `apps/dev.yaml`, etc.). Creates
`<chart>-<env>` (namespace `<chart>-<env>`).

| Chart | Envs | Values |
|-------|------|--------|
| `demo-app` | `dev`, `uat`, `prod` | `helm-values/applications/demo-app/` |

Env overlays: `helm-values/applications/<chart>/environments/<env>/{values,images}.yaml`.

### demo-app notes

- Pin a **multi-arch** signed digest (`v0.2.0+`) so OrbStack arm64 can pull.
- Chart sets `readOnlyRootFilesystem: true` and mounts `emptyDir` at `/tmp`
  (`TMPDIR=/tmp`) for gunicorn.
- Service name: `demo-app-api` (port 80 → container 8080).
- Kyverno digest + cosign Enforce applies in `demo-app-dev` / `uat` / `prod`.
