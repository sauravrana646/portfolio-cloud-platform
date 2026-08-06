# Architecture

## Local (default)

Docker Compose runs API, worker, Redis, Prometheus, and Grafana.

## Kubernetes (OrbStack / existing kubecontext)

Helm chart `charts/demo-app` deploys the API against the **current** `kubectl` context (e.g. OrbStack). Use `make cluster-deploy` / `make cluster-down`. Optional Argo CD Application in `argocd/`.
## Cloud (opt-in)

`deploy_target`:

- `local` — no AWS resources
- `ecs` — VPC + ECS cluster skeleton
- `eks` — placeholder only; prefer local kind unless budget approved
