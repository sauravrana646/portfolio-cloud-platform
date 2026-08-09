# Security Policy

## Supported versions

This is a public portfolio demo. Use the latest `main` (or tagged config releases).

## Reporting a vulnerability

Email **sauravrana646@gmail.com** with repo name, commit SHA, and reproduction steps.

## Trust boundary

- **Application images** are built and cosign-signed in
  [portfolio-secure-cicd](https://github.com/sauravrana646/portfolio-secure-cicd).
- **This repo** pins digests and **verifies** signatures using
  `cosign-public-key` from Infisical (`devops-portfolio-x-k3-y`, path `/cosign`)
  via OIDC. Cosign **private** keys never live here.
- Kyverno admission policies enforce digest / signature expectations on cluster paths.
- Default path is local Compose or your kubecontext. Terraform `eks` is opt-in.
- Prefer GitHub OIDC → AWS for any Terraform plan/apply. No long-lived AWS keys in git.
- Do not `terraform apply` without a sandbox account and explicit approval.
