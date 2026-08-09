# Local demo ($0)

Laptop path — no cluster required.

| File | Purpose |
|------|---------|
| `docker-compose.yml` | API (signed GHCR image) + Prometheus + Grafana |
| `monitoring/prometheus.yml` | Scrape config for Compose Prometheus |
| `bootstrap.yaml` | Kind cluster config for optional local Kubernetes |

```bash
# From repo root:
make up                 # uses local/docker-compose.yml
curl -s localhost:8080/healthz

# Optional local cluster (Kind):
kind create cluster --config local/bootstrap.yaml
```

Cluster monitoring on OrbStack/EKS uses `charts/bootstrap-layer/kube-prometheus-stack`
(not this Compose stack).
