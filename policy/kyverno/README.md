# Kyverno policies

Admission policies for the platform pack. Cosign **public** key is synced from
Infisical (`/cosign` → `cosign-public-key`) into Secret
`cosign-public-key` in namespace `platform-system` (see
`policy/kyverno/cosign-key-secret.sample.yaml`).

GitOps path: `charts/bootstrap-layer/kyverno-policies` (Kustomize wrapper)
discovered by the charts ApplicationSet. Wave order: Kyverno Helm → Infisical
operator → InfisicalSecret → these policies → Policy Reporter UI → workload apps.
See `argocd/README.md`.

## Policy Reporter UI

Argo app `bootstrap-policy-reporter` (sync wave 4):

```bash
kubectl -n policy-reporter get pods
kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8082:8080
# http://127.0.0.1:8082
```

## Policies

| Policy | Mode | Namespaces |
|--------|------|------------|
| `require-image-digest` | Enforce | `demo`, `demo-app-dev`, `demo-app-uat`, `demo-app-prod` |
| `disallow-latest-tag` | Enforce | same + matches non-root set |
| `require-signed-upstream-image` | Enforce | `demo`, `demo-app-dev`, `demo-app-uat`, `demo-app-prod` |
| `require-run-as-non-root` | Enforce | `demo`, `demo-app-dev`, `demo-app-uat`, `demo-app-prod` |
| `require-sbom-attestation` | Audit | `demo-app-uat`, `demo-app-prod` (`mutateDigest: false` required for Audit) |

## How to prove verifyImages ran

`verifyImages` with `background: false` does not leave a lasting “pass” in
PolicyReports. Use:

1. **Deny** a tag-only / bogus-digest Pod in `demo-app-dev` (webhook error names the policy).
2. **Allow** path: `kubectl -n demo-app-dev rollout restart deploy/demo-app-api`, then
   inspect Pod annotation `kyverno.io/verify-images` for `"verified": true`.

Details: [`docs/RUNBOOK.md`](../docs/RUNBOOK.md).
