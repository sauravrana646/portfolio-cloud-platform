# Helm values

Mirrors `charts/` layout. The `charts` ApplicationSet mounts these via
multi-source `$values/helm-values/...`.

```text
helm-values/
  bootstrap-layer/<chart>/values.yaml
  applications/<chart>/
    values.yaml
    environments/<env>/
      values.yaml
      images.yaml          # digest pins (when app sets imagePin: "true")
```

## Convention

| Chart kind | Value files applied (in order) |
|------------|--------------------------------|
| Bootstrap Helm | `values.yaml` |
| Workload env | `values.yaml` → `environments/<env>/values.yaml` → `environments/<env>/images.yaml` |

Wrapper charts under `charts/bootstrap-layer/*` expect values **nested** under
the upstream dependency name (e.g. top-level key `kyverno:`).

Application discovery lives next to charts (`app.yaml` / `apps/<env>.yaml`),
not here — see `argocd/README.md`.
