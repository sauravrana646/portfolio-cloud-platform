# Argo CD — App-of-Apps

Bootstrap:

```bash
kubectl apply -f argocd/root.yaml
```

`platform-root` syncs everything under `argocd/applications/`.

## Sync order

| Wave | App | Type |
|------|-----|------|
| 0 | `platform-metrics-server` | Helm (`metrics-server`) |
| 0 | `platform-kyverno` | Helm (`kyverno`) |
| 1 | `platform-infisical-operator` | Helm (`secrets-operator`) |
| 2 | `platform-infisical-secrets` | Kustomize (`InfisicalSecret` CR) |
| 3 | `platform-kyverno-policies` | Kustomize (ClusterPolicies) |
| 10 | `demo-dev` / `demo-uat` / `demo-prod` | Helm (`charts/demo-app`) |

Not using ApplicationSets — plain Applications under App-of-Apps.

## Before first sync

1. Install Argo CD on the cluster.
2. Patch `platform/infisical/infisical-secret-cosign.yaml` with a real Infisical machine `identityId` (Kubernetes auth).
3. Prefer syncing platform apps before demos (waves handle this automatically).
