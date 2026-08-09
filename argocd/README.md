# Argo CD — App-of-Apps

```bash
kubectl apply -f argocd/root.yaml
```

`platform-root` syncs `argocd/applications/`.

## Layout

| Layer | Charts | Values |
|-------|--------|--------|
| Bootstrap | `charts/bootstrap-layer/*` | `helm-values/bootstrap-layer/*` |
| Apps | `charts/applications/*` | `helm-values/applications/*` |

## Sync order

| Wave | App | Source |
|------|-----|--------|
| 0 | `platform-metrics-server` | `charts/bootstrap-layer/metrics-server` |
| 0 | `platform-kyverno` | `charts/bootstrap-layer/kyverno` |
| 0 | `platform-kube-prometheus-stack` | `charts/bootstrap-layer/kube-prometheus-stack` |
| 1 | `platform-infisical-operator` | `charts/bootstrap-layer/infisical-operator` |
| 2 | `platform-infisical-secrets` | Kustomize `charts/bootstrap-layer/infisical-secrets` |
| 2 | `platform-teleport-agent` | `charts/bootstrap-layer/teleport-kube-agent` |
| 3 | `platform-kyverno-policies` | `policy/kyverno` |
| 10 | `demo-*` | `charts/applications/demo-app` |

Local $0 demo (Compose Prometheus/Grafana) lives under `local/` — not Argo.

## Before first sync

1. Install Argo CD.
2. Patch Infisical identity in `charts/bootstrap-layer/infisical-secrets/infisical-secret-cosign.yaml`.
3. Teleport: set `proxyAddr` in helm-values + join-token Secret (`docs/JIT_TELEPORT.md`).
4. Wrapper charts: Argo runs `helm dependency build` on sync (or `make helm-deps` locally).
