# Platform dependency Helm values

Argo CD App-of-Apps installs these charts before workload apps:

| Wave | Application | Chart |
|------|-------------|-------|
| 0 | `platform-metrics-server` | `metrics-server` |
| 0 | `platform-kyverno` | `kyverno` |
| 1 | `platform-infisical-operator` | `secrets-operator` |
| 2 | `platform-infisical-secrets` | InfisicalSecret CR (git) |
| 3 | `platform-kyverno-policies` | Kustomize policies |
| 10 | `demo-*` | `charts/demo-app` |

Pin chart versions in `argocd/applications/platform-*.yaml` (`targetRevision`).
