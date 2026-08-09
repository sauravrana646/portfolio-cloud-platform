# Architecture

## Workload

Runtime image is the signed release from
[`portfolio-secure-cicd`](https://github.com/sauravrana646/portfolio-secure-cicd),
pinned by digest under `deploy/environments/*/images.yaml`.

## Local (default)

Docker Compose pulls the GHCR digest and runs API + Prometheus + Grafana.
No Redis/worker — upstream app is API-only (`/`, `/healthz`).

## Kubernetes (OrbStack / kind / k3d)

Helm chart `charts/demo-app` deploys the API against the current kubecontext
(`make cluster-deploy`). Values overlays live in `deploy/environments/`.

## GitOps

`argocd/root.yaml` App-of-Apps → Kyverno policies, then `demo-dev` / `demo-uat` /
`demo-prod`. Promotion = PR that bumps the digest in env `images.yaml`.

## Admission

Kyverno ClusterPolicies require digest, block `:latest`, require non-root, and
verify cosign signatures using an Infisical-synced public key Secret in
`platform-system`.

## Cloud (opt-in)

`deploy_target`:

- `local` — no AWS resources
- `eks` — VPC (no NAT by default) + EKS + node group + OIDC provider + add-ons

ECS is not supported.
