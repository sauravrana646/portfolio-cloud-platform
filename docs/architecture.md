# Architecture

## Workload

Runtime image is the signed **multi-arch** release from
[`portfolio-secure-cicd`](https://github.com/sauravrana646/portfolio-secure-cicd),
pinned by digest under
`helm-values/applications/demo-app/environments/*/images.yaml`
(currently `v0.2.0` — `linux/amd64` + `linux/arm64` for OrbStack Apple Silicon).

The demo-app Deployment uses a hardened security context
(`readOnlyRootFilesystem: true`) and mounts `emptyDir` at `/tmp` so gunicorn
can create worker temp files.

## Local (`local/`)

| Path | Entry |
|------|--------|
| Compose ($0) | `make up` — API + Compose Prometheus/Grafana |
| Kind e2e | `make bootstrap-up` — `local/bootstrap/` installs metrics-server, Kyverno, kube-prometheus-stack, policies, `demo-app-dev` |
| OrbStack + Argo | Prefer GitOps roots — [`LOCAL_K8S_ORBSTACK.md`](LOCAL_K8S_ORBSTACK.md) (do not mix with `bootstrap-up`) |

Kind config: `local/bootstrap/kind.yaml`. Overlays: `local/bootstrap/values/`.

## Charts

| Tree | Role |
|------|------|
| `charts/bootstrap-layer/` | Prerequisites (wrapper Helm charts + InfisicalSecret / policies Kustomize) |
| `charts/applications/` | Workloads (`demo-app`) |
| `helm-values/` | Values only — same folder shape as `charts/` |

Bootstrap includes Kyverno, kube-prometheus-stack, metrics-server, Infisical
operator, Teleport agent (manual), Kyverno policies, and **Policy Reporter UI**.

## GitOps (per-env roots)

| Apply | Deploys |
|-------|---------|
| `argocd/root-bootstrap.yaml` | Platform charts (`charts/bootstrap-layer/*/app.yaml`) |
| `argocd/root-dev.yaml` | Only `charts/applications/*/apps/dev.yaml` |
| `argocd/root-uat.yaml` | Only `…/apps/uat.yaml` |
| `argocd/root-prod.yaml` | Only `…/apps/prod.yaml` |

Env choice = **which root you apply**, not a single toggle. See `argocd/README.md`.

ApplicationSets list discovery files **explicitly** (no globs). `templatePatch`
only emits `metadata` when setting finalizers so empty patches cannot wipe
`metadata.name`.

Promotion = PR that bumps digests under `helm-values/applications/demo-app/environments/`.

## Admission & visibility

| Piece | Role |
|-------|------|
| Infisical → `platform-system/cosign-public-key` | Cosign public PEM for verify |
| ClusterPolicies | Digest + cosign Enforce on `demo-app-{dev,uat,prod}`; SBOM Audit on uat/prod |
| Policy Reporter | UI over PolicyReports — `bootstrap-policy-reporter` |

## Cloud (opt-in)

`deploy_target`: `local` \| `eks` (no ECS).
