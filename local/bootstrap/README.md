# Local Kind bootstrap (full platform)

End-to-end laptop path: **Kind + Kyverno + policies + kube-prometheus-stack + demo-app**.

Compose (`make up`) stays the $0 no-cluster demo. This folder is the cluster path.

## Layout

```text
local/bootstrap/
  kind.yaml                 # Kind cluster (+ Grafana/Prometheus NodePorts)
  components.yaml           # install order / waves (docs + script contract)
  values/                   # Kind overlays on top of helm-values/
    metrics-server.yaml
    kyverno.yaml
    kube-prometheus-stack.yaml
    demo-app.yaml
  manifests/
    namespaces.yaml
    cosign-public-key.sample.yaml
  scripts/
    up.sh                   # create cluster → deps → policies → app
    down.sh
    status.sh
    lib/cosign-secret.sh
```

## Quick start

```bash
# Tools: docker, kind, kubectl, helm
make bootstrap-up

# Optional: real cosign verifyImages key (uat/prod policies)
export COSIGN_PUBLIC_KEY="$(cat cosign.pub)"
make bootstrap-up

make bootstrap-status
make bootstrap-down
```

## What gets installed

| Wave | Component | Source |
|------|-----------|--------|
| 0 | metrics-server | `charts/bootstrap-layer/metrics-server` |
| 0 | Kyverno | `charts/bootstrap-layer/kyverno` |
| 0 | kube-prometheus-stack | `charts/bootstrap-layer/kube-prometheus-stack` |
| 1 | namespaces | `manifests/namespaces.yaml` |
| 2 | cosign Secret | env / Infisical → `platform-system/cosign-public-key` |
| 3 | ClusterPolicies | `charts/bootstrap-layer/kyverno-policies` → `policy/kyverno` |
| 10 | demo-app | `charts/applications/demo-app` → ns `demo-app-dev` |

Skipped by default (set `INSTALL_INFISICAL=1` to enable operator): Infisical operator, Teleport.

## Values

Same nesting as GitOps: base under `helm-values/…`, then `local/bootstrap/values/…` overlays for Kind (lighter resources, NodePorts).

## Access

| UI | URL |
|----|-----|
| Grafana | http://127.0.0.1:30030 (admin / admin) |
| Prometheus | http://127.0.0.1:30090 |
| demo-app | `kubectl -n demo-app-dev port-forward svc/demo-api 8080:80` |

## Relation to Argo

This script installs the **same charts and values tree** Argo would sync. On a durable cluster prefer `kubectl apply -f argocd/root.yaml` instead of `bootstrap-up`.
