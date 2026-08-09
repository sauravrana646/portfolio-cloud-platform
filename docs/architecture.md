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

## GitOps (App-of-Apps)

`argocd/root.yaml` syncs `argocd/applications/`. Order via sync-waves:

1. Helm: `metrics-server`, `kyverno`, Infisical `secrets-operator`
2. InfisicalSecret CR → `platform-system/cosign-public-key`
3. Helm: Teleport `teleport-kube-agent` (JIT kubectl — see `docs/JIT_TELEPORT.md`)
4. Kyverno ClusterPolicies (Kustomize)
5. Helm: `charts/demo-app` per env (`demo-dev` / `uat` / `prod`)

Promotion = PR that bumps the digest in env `images.yaml`. Not using ApplicationSets.  
Human JIT is **Teleport**; AWS IAM Identity Center / SSM are not used for access.

## Admission

Kyverno ClusterPolicies require digest, block `:latest`, require non-root, and
verify cosign signatures using an Infisical-synced public key Secret in
`platform-system`.

## Cloud (opt-in)

`deploy_target`:

- `local` — no AWS resources
- `eks` — VPC (no NAT by default) + EKS + node group + OIDC provider + add-ons

ECS is not supported.
