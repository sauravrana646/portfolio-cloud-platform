#!/usr/bin/env bash
# End-to-end local Kind bootstrap: metrics-server, Kyverno, kube-prometheus-stack,
# cosign Secret, ClusterPolicies, demo-app-dev.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

CLUSTER_NAME="${CLUSTER_NAME:-portfolio-cloud-platform}"
KIND_CONFIG="${KIND_CONFIG:-local/bootstrap/kind.yaml}"
SKIP_CLUSTER_CREATE="${SKIP_CLUSTER_CREATE:-0}"
INSTALL_INFISICAL="${INSTALL_INFISICAL:-0}"
TIMEOUT="${TIMEOUT:-300s}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required tool: $1" >&2
    exit 1
  }
}

need kind
need kubectl
need helm
need docker

echo "==> Ensuring Kind cluster '${CLUSTER_NAME}'"
if [[ "${SKIP_CLUSTER_CREATE}" != "1" ]]; then
  if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
    echo "    cluster already exists — reusing (set SKIP_CLUSTER_CREATE=1 to silence)"
  else
    kind create cluster --config "${KIND_CONFIG}"
  fi
fi
kubectl cluster-info >/dev/null

echo "==> Fetching Helm chart dependencies"
make helm-deps

helm_install() {
  local release="$1" chart="$2" ns="$3"
  shift 3
  local -a args=()
  local create_ns=0
  local wait=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --create-namespace) create_ns=1; shift ;;
      --wait) wait=1; shift ;;
      -f) args+=(-f "$2"); shift 2 ;;
      *) echo "unknown helm_install arg: $1" >&2; exit 1 ;;
    esac
  done
  [[ "${create_ns}" == "1" ]] && args+=(--create-namespace)
  [[ "${wait}" == "1" ]] && args+=(--wait --timeout "${TIMEOUT}")
  echo "    helm upgrade --install ${release} (${ns})"
  helm upgrade --install "${release}" "${chart}" \
    --namespace "${ns}" \
    "${args[@]}"
}

echo "==> [wave 0] metrics-server"
helm_install metrics-server charts/bootstrap-layer/metrics-server kube-system \
  -f helm-values/bootstrap-layer/metrics-server/values.yaml \
  -f local/bootstrap/values/metrics-server.yaml \
  --wait

echo "==> [wave 0] kyverno"
helm_install kyverno charts/bootstrap-layer/kyverno kyverno \
  -f helm-values/bootstrap-layer/kyverno/values.yaml \
  -f local/bootstrap/values/kyverno.yaml \
  --create-namespace --wait

echo "==> [wave 0] kube-prometheus-stack (cluster monitoring)"
helm_install kube-prometheus-stack charts/bootstrap-layer/kube-prometheus-stack monitoring \
  -f helm-values/bootstrap-layer/kube-prometheus-stack/values.yaml \
  -f local/bootstrap/values/kube-prometheus-stack.yaml \
  --create-namespace --wait

echo "==> [wave 1] platform namespaces"
kubectl apply -f local/bootstrap/manifests/namespaces.yaml

if [[ "${INSTALL_INFISICAL}" == "1" ]]; then
  echo "==> [wave 1] infisical-operator (optional)"
  helm_install infisical-secrets-operator charts/bootstrap-layer/infisical-operator infisical-system \
    -f helm-values/bootstrap-layer/infisical-operator/values.yaml \
    --create-namespace --wait
  echo "    Apply InfisicalSecret after patching IDENTITY_ID:"
  echo "    kubectl apply -k charts/bootstrap-layer/infisical-secrets"
else
  echo "==> [wave 2] cosign public key Secret (local; skip Infisical)"
  # shellcheck disable=SC1091
  source "${ROOT}/local/bootstrap/scripts/lib/cosign-secret.sh"
  ensure_cosign_secret
fi

echo "==> [wave 3] Kyverno policies"
if command -v kustomize >/dev/null 2>&1; then
  kustomize build charts/bootstrap-layer/kyverno-policies | kubectl apply -f -
elif kubectl kustomize --help >/dev/null 2>&1; then
  kubectl kustomize charts/bootstrap-layer/kyverno-policies | kubectl apply -f -
else
  echo "kustomize/kubectl kustomize required to apply policies" >&2
  exit 1
fi

echo "    waiting for ClusterPolicies"
kubectl wait --for=condition=Ready clusterpolicy --all --timeout=120s 2>/dev/null \
  || kubectl get clusterpolicy

echo "==> [wave 10] demo-app (demo-app-dev)"
helm_install demo-app charts/applications/demo-app demo-app-dev \
  -f helm-values/applications/demo-app/values.yaml \
  -f helm-values/applications/demo-app/environments/dev/values.yaml \
  -f helm-values/applications/demo-app/environments/dev/images.yaml \
  -f local/bootstrap/values/demo-app.yaml \
  --create-namespace --wait

echo
echo "==> Bootstrap complete"
"${ROOT}/local/bootstrap/scripts/status.sh"
