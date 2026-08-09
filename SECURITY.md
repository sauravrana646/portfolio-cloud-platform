# Security Policy

## Supported versions

This is a public portfolio demo. Use the latest `main` (or tagged config releases).

## Reporting a vulnerability

Email **sauravrana646@gmail.com** with repo name, commit SHA, and reproduction steps.

## Trust boundary

- **Application images** are built and cosign-signed in
  [portfolio-secure-cicd](https://github.com/sauravrana646/portfolio-secure-cicd).
- **This repo** pins digests and **verifies** signatures using
  Infisical secret `cosign-public-key` (`devops-portfolio-x-k3-y`, path `/cosign`)
  via OIDC. Cosign **private** keys never live here.
- Kyverno admission policies enforce digest / signature expectations on cluster paths.
- Default path is local Compose or your kubecontext. Terraform `eks` is opt-in.
- Prefer GitHub OIDC → AWS for any Terraform plan/apply. No long-lived AWS keys in git.
- Human cluster JIT uses **Teleport** (`docs/JIT_TELEPORT.md`). AWS Identity Center / SSM are not the access path.
- CI runs `terraform plan -var='deploy_target=local'` only when `infra/terraform/**` (or the CI workflow) changes. Optional EKS plan when repo variable `AWS_ROLE_ARN` (and `AWS_REGION`) is set for OIDC. Other jobs are similarly path-filtered.
- Do not `terraform apply` without a sandbox account and explicit approval.
- Require the GitHub check **merge gates** (and optionally individual helm/terraform jobs) in branch protection before merge.
