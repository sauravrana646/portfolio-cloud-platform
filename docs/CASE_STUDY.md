# Case Study: Cloud Platform Deploy Pack

## Client type

Anonymized: B2B SaaS needing a paved path from laptop → staging without a full platform team

## Problem

Ad-hoc deploys, no standard Helm chart, monitoring bolted on late, and cloud spend fear blocking Kubernetes experiments.

## Approach

1. Local-first: Compose + Prometheus/Grafana for a 15-minute demo
2. Helm chart + optional Argo CD for kind/k3d
3. Terraform with `deploy_target` so ECS is the cheap cloud option; EKS off by default
4. CI: tests, image build, Trivy CRITICAL gate, helm lint, terraform validate

## Stack

Docker Compose, Helm, kind/k3d, Terraform AWS modules, GitHub Actions, Prometheus, Grafana

## Results (from real experience / analogous)

Example language — not guarantees:

- Deploy automation and GitOps patterns cut lead time (~40% in analogous CI/CD optimization work)
- Observability baseline (Prometheus/Grafana) improved incident response time
- Teams can demo locally without burning AWS budget

## What I deliver in a freelance engagement

- **Timeline:** 2–4 weeks for one app path (local + staging)
- **Fixed-scope offer:** K8s / platform deploy pack
- **Out of scope:** multi-region HA, full IDP portal, 24/7 managed ops
