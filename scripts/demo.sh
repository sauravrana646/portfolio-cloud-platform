#!/usr/bin/env bash
# 5–10 minute local demo: pull signed image, health check, optional helm note.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Compose up (digest-pinned GHCR image)"
docker compose up -d
echo "==> Waiting for /healthz"
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8080/healthz >/dev/null; then
    curl -s http://127.0.0.1:8080/healthz
    echo
    curl -s http://127.0.0.1:8080/
    echo
    break
  fi
  sleep 2
  if [[ "$i" -eq 30 ]]; then
    echo "API did not become healthy" >&2
    docker compose logs api >&2 || true
    exit 1
  fi
done

echo "==> Optional: make verify-image (requires Infisical + cosign)"
if command -v cosign >/dev/null 2>&1; then
  make verify-image || echo "verify-image skipped/failed (configure Infisical to enable)"
else
  echo "cosign not installed — skip verify"
fi

echo "==> Done. Grafana http://127.0.0.1:3000 (admin / \$GF_SECURITY_ADMIN_PASSWORD or admin)"
echo "    Cluster path: make cluster-deploy (current kubecontext)"
