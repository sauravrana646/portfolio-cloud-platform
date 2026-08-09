# Architecture

## Workload

Runtime image is the signed release from
[`portfolio-secure-cicd`](https://github.com/sauravrana646/portfolio-secure-cicd),
pinned by digest under
`helm-values/applications/demo-app/environments/*/images.yaml`.

## Local (`local/`)

Docker Compose pulls the GHCR digest and runs API + Prometheus + Grafana.
Optional Kind cluster: `kind create cluster --config local/bootstrap.yaml`.

## Charts

| Tree | Role |
|------|------|
| `charts/bootstrap-layer/` | Prerequisites (wrapper Helm charts + InfisicalSecret Kustomize) |
| `charts/applications/` | Workloads (`demo-app`) |
| `helm-values/` | Values only — same folder shape as `charts/` |

## GitOps (App-of-Apps)

`argocd/root.yaml` syncs `argocd/applications/` with sync-waves:

1. Bootstrap Helm: metrics-server, Kyverno, kube-prometheus-stack
2. Infisical operator → InfisicalSecret (cosign public key)
3. Teleport kube-agent (JIT)
4. Kyverno ClusterPolicies
5. `demo-dev` / `uat` / `prod` from `charts/applications/demo-app`

Promotion = PR that bumps digests under `helm-values/applications/demo-app/environments/`.

## Cloud (opt-in)

`deploy_target`: `local` \| `eks` (no ECS).
