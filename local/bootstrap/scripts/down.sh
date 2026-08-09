#!/usr/bin/env bash
# Tear down local Kind bootstrap cluster (or helm releases only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

CLUSTER_NAME="${CLUSTER_NAME:-portfolio-cloud-platform}"
DELETE_CLUSTER="${DELETE_CLUSTER:-1}"

if [[ "${DELETE_CLUSTER}" == "1" ]]; then
  if command -v kind >/dev/null 2>&1 && kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
    echo "==> Deleting Kind cluster '${CLUSTER_NAME}'"
    kind delete cluster --name "${CLUSTER_NAME}"
    echo "Done."
    exit 0
  fi
  echo "Kind cluster '${CLUSTER_NAME}' not found; nothing to delete."
  exit 0
fi

echo "==> Uninstalling helm releases (cluster kept)"
helm uninstall demo-app -n demo-app-dev 2>/dev/null || true
helm uninstall kube-prometheus-stack -n monitoring 2>/dev/null || true
helm uninstall kyverno -n kyverno 2>/dev/null || true
helm uninstall metrics-server -n kube-system 2>/dev/null || true
helm uninstall infisical-secrets-operator -n infisical-system 2>/dev/null || true
kubectl delete -k charts/bootstrap-layer/kyverno-policies --ignore-not-found 2>/dev/null || true
kubectl delete -f local/bootstrap/manifests/namespaces.yaml --ignore-not-found 2>/dev/null || true
echo "Done."
