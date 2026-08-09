# portfolio-cloud-platform

[![CI](https://github.com/sauravrana646/portfolio-cloud-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/sauravrana646/portfolio-cloud-platform/actions/workflows/ci.yml)

> Platform deploy pack: run a **signed** app image from [`portfolio-secure-cicd`](https://github.com/sauravrana646/portfolio-secure-cicd) on Compose → Helm → Argo CD → optional EKS, with Kyverno admission and Infisical-backed cosign verify.

![Demo: Compose stack and local /healthz](docs/images/demo.jpg)

## Layout

```text
local/
  docker-compose.yml           # $0 API + Compose Prom/Grafana
  bootstrap/                   # Kind e2e: Kyverno, policies, prom-stack, demo-app
charts/
  bootstrap-layer/             # prerequisite charts (Kyverno, prom-stack, …)
  applications/                # workload charts (demo-app)
helm-values/                   # mirrors charts/ — values only
argocd/                        # root App + ApplicationSet (auto from charts/)
policy/kyverno/                # admission policies (referenced by bootstrap chart)
infra/terraform/               # local | eks
```

## Demo in 15 minutes

```bash
# Path A — Compose ($0, no cluster)
make up
curl -s http://127.0.0.1:8080/healthz   # {"status":"ok"}

# Path B — Kind full platform (Kyverno + policies + monitoring + app)
make bootstrap-up
make bootstrap-status
# Grafana http://127.0.0.1:30030  Prometheus http://127.0.0.1:30090
make bootstrap-down
```

Or: `./scripts/demo.sh`

## Local Kubernetes setup (OrbStack + Argo CD)

End-to-end guide when Argo CD is already installed on OrbStack: Infisical
**Universal Auth** machine identity, bootstrap root, env roots (`dev` / `uat` /
`prod`), Kyverno, monitoring, and `demo-app`.

→ **[`docs/LOCAL_K8S_ORBSTACK.md`](docs/LOCAL_K8S_ORBSTACK.md)**

## Division of responsibility

| Concern | Repo |
|---------|------|
| Build, Trivy, promotion, cosign **sign**, SBOM, GHCR release | [portfolio-secure-cicd](https://github.com/sauravrana646/portfolio-secure-cicd) |
| Digest pin, Infisical **verify**, Helm/Argo/EKS, Kyverno | **This repo** |

## Architecture

```mermaid
flowchart TB
  subgraph upstream [portfolio-secure-cicd]
    Rel[Signed GHCR release]
  end
  subgraph localpath [local/ — $0]
    Compose[Compose + Prom/Grafana]
  end
  subgraph boot [charts/bootstrap-layer]
    Kyverno[Kyverno]
    Prom[kube-prometheus-stack]
    InfOp[Infisical operator]
    Teleport[Teleport agent]
  end
  subgraph apps [charts/applications]
    Demo[demo-app]
  end
  Rel --> Compose
  Rel --> Demo
  InfOp --> Kyverno
  Kyverno --> Demo
  boot --> apps
```

## Stack

| Layer | Choice |
|-------|--------|
| Local Compose | `local/docker-compose.yml` |
| Local OrbStack + Argo | [`docs/LOCAL_K8S_ORBSTACK.md`](docs/LOCAL_K8S_ORBSTACK.md) |
| Local Kind e2e | `local/bootstrap/` (`make bootstrap-up`) |
| Bootstrap charts | Kyverno, kube-prometheus-stack, metrics-server, Infisical operator, Teleport |
| Apps | `charts/applications/demo-app` |
| Values | `helm-values/` (mirrors charts) |
| GitOps | Argo CD ApplicationSet over `charts/` |
| JIT | Teleport (`docs/JIT_TELEPORT.md`) |
| IaC | Terraform `local` \| `eks` |

See `argocd/README.md`, `helm-values/README.md`, `docs/architecture.md`.

## Hire me for…

**K8s Deploy Pack / platform path** — [sauravrana646@gmail.com](mailto:sauravrana646@gmail.com) · [github.com/sauravrana646](https://github.com/sauravrana646)
