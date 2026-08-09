# Kyverno policies

Admission policies for the platform pack. Cosign **public** key is synced from
Infisical (`/cosign` → `cosign-public-key`) into Secret
`cosign-public-key` in namespace `platform-system` (see
`policy/kyverno/cosign-key-secret.sample.yaml`).

GitOps path: `charts/bootstrap-layer/kyverno-policies` (Kustomize wrapper)
discovered by the charts ApplicationSet. Wave order: Kyverno Helm → Infisical
operator → InfisicalSecret → these policies → workload apps. See `argocd/README.md`.

| Policy | Mode (suggested) |
|--------|------------------|
| require-digest | Enforce uat/prod |
| disallow-latest-tag | Enforce uat/prod |
| require-signed-images | Enforce uat/prod (needs key Secret) |
| require-non-root | Enforce |
| require-sbom-attestation | Audit → Enforce when stable |
