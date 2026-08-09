# Architecture

## Workload

Runtime image is the signed release from
[`portfolio-secure-cicd`](https://github.com/sauravrana646/portfolio-secure-cicd),
pinned by digest under
`helm-values/applications/demo-app/environments/*/images.yaml`.

## Local (`local/`)

| Path | Entry |
|------|--------|
| Compose ($0) | `make up` — API + Compose Prometheus/Grafana |
| Kind e2e | `make bootstrap-up` — `local/bootstrap/` installs metrics-server, Kyverno, kube-prometheus-stack, policies, `demo-app-dev` |

Kind config: `local/bootstrap/kind.yaml`. Overlays: `local/bootstrap/values/`.

## Charts

| Tree | Role |
|------|------|
| `charts/bootstrap-layer/` | Prerequisites (wrapper Helm charts + InfisicalSecret Kustomize) |
| `charts/applications/` | Workloads (`demo-app`) |
| `helm-values/` | Values only — same folder shape as `charts/` |

## GitOps (per-env roots)

| Apply | Deploys |
|-------|---------|
| `argocd/root-bootstrap.yaml` | Platform charts (`charts/bootstrap-layer/*/app.yaml`) |
| `argocd/root-dev.yaml` | Only `charts/applications/*/apps/dev.yaml` |
| `argocd/root-uat.yaml` | Only `…/apps/uat.yaml` |
| `argocd/root-prod.yaml` | Only `…/apps/prod.yaml` |

Env choice = **which root you apply**, not a single toggle. See `argocd/README.md`.

Promotion = PR that bumps digests under `helm-values/applications/demo-app/environments/`.

## Cloud (opt-in)

`deploy_target`: `local` \| `eks` (no ECS).
