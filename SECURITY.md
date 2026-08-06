# Security Policy

## Supported versions

This is a public portfolio demo. Use the latest `main` (or tagged releases such as `v1.0.0`).

## Reporting a vulnerability

Email **sauravrana646@gmail.com** with repo name, commit SHA, and reproduction steps.

## Demo notes

- Default path is local Compose or your existing kubecontext (e.g. OrbStack). Cloud Terraform (`ecs` / `eks`) is opt-in.
- Do not `terraform apply` without a sandbox account and explicit approval.
- Prefer OIDC over long-lived AWS keys for any staging deploy job.
