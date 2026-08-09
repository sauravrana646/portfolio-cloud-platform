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

## GitOps (App-of-Apps)

`argocd/root.yaml` → `argocd/appsets/charts.yaml` (ApplicationSet).
Discovery files under `charts/**/app.yaml` and `charts/**/apps/*.yaml` create
Applications automatically (see `argocd/README.md`).

Sync-waves (from those files):

1. Bootstrap Helm: metrics-server, Kyverno, kube-prometheus-stack
2. Infisical operator → InfisicalSecret (cosign public key)
3. Teleport kube-agent (JIT)
4. Kyverno ClusterPolicies (`charts/bootstrap-layer/kyverno-policies`)
5. `demo-app-{dev,uat,prod}`

Promotion = PR that bumps digests under `helm-values/applications/demo-app/environments/`.

## Cloud (opt-in)

`deploy_target`: `local` \| `eks` (no ECS).
