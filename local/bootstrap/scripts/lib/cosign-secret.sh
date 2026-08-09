#!/usr/bin/env bash
# Create platform-system/cosign-public-key for Kyverno verifyImages.
# shellcheck shell=bash

ensure_cosign_secret() {
  local ns="${COSIGN_SECRET_NAMESPACE:-platform-system}"
  local name="${COSIGN_SECRET_NAME:-cosign-public-key}"
  local key="${cosign_public_key:-${COSIGN_PUBLIC_KEY:-}}"

  kubectl get ns "${ns}" >/dev/null 2>&1 || kubectl create namespace "${ns}"

  if [[ -z "${key}" ]] && command -v infisical >/dev/null 2>&1; then
    echo "    trying Infisical export for cosign_public_key"
    # shellcheck disable=SC2046
    eval "$(
      infisical export \
        --env="${INFISICAL_ENV_SLUG:-prod}" \
        --path="${INFISICAL_SECRET_PATH:-/cosign}" \
        --projectId="${INFISICAL_PROJECT_SLUG:-devops-portfolio-x-k3-y}" \
        --format=dotenv 2>/dev/null | sed 's/^/export /' || true
    )"
    key="${cosign_public_key:-${COSIGN_PUBLIC_KEY:-}}"
  fi

  if [[ -z "${key}" ]]; then
    echo "    WARN: no cosign public key — creating placeholder Secret."
    echo "    demo-app-dev still works (signed-image policy targets uat/prod)."
    echo "    For full verifyImages: export COSIGN_PUBLIC_KEY=\"\$(cat cosign.pub)\" and re-run."
    kubectl -n "${ns}" create secret generic "${name}" \
      --from-literal=cosign.pub="-----BEGIN PUBLIC KEY-----
PLACEHOLDER_NOT_A_REAL_KEY
-----END PUBLIC KEY-----" \
      --dry-run=client -o yaml | kubectl apply -f -
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "${key}" >"${tmp}"
  kubectl -n "${ns}" create secret generic "${name}" \
    --from-file=cosign.pub="${tmp}" \
    --dry-run=client -o yaml | kubectl apply -f -
  rm -f "${tmp}"
  echo "    Secret ${ns}/${name} applied"
}
