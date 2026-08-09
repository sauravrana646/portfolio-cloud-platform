#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

echo "context: $(kubectl config current-context 2>/dev/null || echo none)"
echo
echo "-- workloads --"
kubectl get deploy,svc -n demo-app-dev 2>/dev/null || echo "(no demo-app-dev)"
echo
echo "-- kyverno --"
kubectl get pods -n kyverno 2>/dev/null || true
kubectl get clusterpolicy 2>/dev/null || true
echo
echo "-- monitoring --"
kubectl get pods,svc -n monitoring 2>/dev/null || true
echo
echo "-- cosign secret --"
kubectl -n platform-system get secret cosign-public-key 2>/dev/null || echo "(missing)"
echo
cat <<'EOF'
Access (Kind NodePorts from local/bootstrap/kind.yaml):
  Grafana:     http://127.0.0.1:30030  (admin / admin)
  Prometheus:  http://127.0.0.1:30090
  App:         kubectl -n demo-app-dev port-forward svc/demo-api 8080:80
               then curl http://127.0.0.1:8080/healthz

Compose-only path (no cluster): make up
EOF
