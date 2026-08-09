# Local demo

Two paths:

| Path | Command | What you get |
|------|---------|----------------|
| **Compose ($0)** | `make up` | Signed API image + Compose Prometheus/Grafana |
| **Kind (full platform)** | `make bootstrap-up` | Kyverno, policies, kube-prometheus-stack, demo-app |

## Compose

| File | Purpose |
|------|---------|
| `docker-compose.yml` | API (digest-pinned GHCR) + Prometheus + Grafana |
| `monitoring/prometheus.yml` | Compose Prometheus scrape config |

```bash
make up
curl -s localhost:8080/healthz
# Grafana http://127.0.0.1:3000  (admin / admin)
```

## Kind bootstrap

Everything lives under `local/bootstrap/` — Kind config, dependency values, manifests, and scripts.

```bash
make bootstrap-up      # Kind + metrics-server + Kyverno + prom-stack + policies + demo-app-dev
make bootstrap-status
make bootstrap-down
```

See [`bootstrap/README.md`](bootstrap/README.md).

## OrbStack + Argo CD (recommended if Argo is already installed)

Do not use `make bootstrap-up` (it fights Argo). Follow the full guide:

→ [`docs/LOCAL_K8S_ORBSTACK.md`](../docs/LOCAL_K8S_ORBSTACK.md)
