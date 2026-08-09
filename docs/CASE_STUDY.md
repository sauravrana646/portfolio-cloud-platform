# Case Study: Cloud Platform Deploy Pack

## Client type

Anonymized: B2B SaaS needing a paved path from laptop → staging Kubernetes
without a full platform team, while consuming images already built and signed
elsewhere.

## Problem

Ad-hoc deploys, incomplete Helm charts, no admission policy for signed images,
and cloud spend fear blocking EKS experiments.

## Approach

1. **Separate supply chain from runtime** — signed images come from
   `portfolio-secure-cicd`; this pack only pins digests and verifies with
   Infisical-backed cosign public keys.
2. Local-first: Compose + Prometheus/Grafana for a 15-minute demo.
3. Helm + Argo CD env overlays for GitOps promotion.
4. Kyverno policies (digest, non-root, signature / SBOM attestation).
5. Terraform `deploy_target=eks` (cost-gated, no NAT by default); ECS removed.
6. **Teleport** for JIT kubectl (`tsh`) — not AWS Identity Center / SSM.
7. Platform CI: path-filtered helm/terraform gates + optional Infisical cosign verify.

## Stack

Docker Compose, Helm, Argo CD, Kyverno, Infisical (verify), Terraform AWS EKS,
GitHub Actions, Prometheus, Grafana, GHCR (consume).

## Results (from real experience / analogous)

Example language — not guarantees:

- Deploy automation and GitOps patterns cut lead time (~40% in analogous work)
- Admission policy blocks unsigned / `:latest` images before they run
- Teams demo locally without burning AWS budget

## What I deliver in a freelance engagement

- **Scope:** one app path (local + staging GitOps + optional EKS sandbox)
- **Fixed-scope offer:** K8s / platform deploy pack
- **Out of scope:** multi-region HA, full IDP portal, 24/7 managed ops,
  rebuilding the app release train (see secure-cicd case study)
