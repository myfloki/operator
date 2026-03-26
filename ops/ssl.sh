#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/.env"
  set +a
fi

SSL_DIR="${REPO_ROOT}/data/electrum/ssl"
LE_DIR="${REPO_ROOT}/data/electrum/letsencrypt"
LE_WORK_DIR="${REPO_ROOT}/data/electrum/letsencrypt-work"
CERT_FILE="${SSL_DIR}/server.crt"
KEY_FILE="${SSL_DIR}/server.key"
CERTBOT_IMAGE="${CERTBOT_IMAGE:-certbot/certbot:latest}"
DOMAIN="${ELECTRUM_SSL_DOMAIN:-}"
EMAIL="${ELECTRUM_SSL_EMAIL:-}"

usage() {
  cat <<EOF
usage: $0 [ensure|renew]

Environment:
  ELECTRUM_SSL_DOMAIN   Domain pointing to this host (required)
  ELECTRUM_SSL_EMAIL    Email for Let's Encrypt registration (required)
  CERTBOT_IMAGE         Override certbot image (default: ${CERTBOT_IMAGE})

Notes:
  - Ports 80 and 443 must be reachable for HTTP-01 challenge.
  - Certificates are stored under data/electrum/letsencrypt and copied to data/electrum/ssl.
EOF
}

require_env() {
  if [[ -z "${DOMAIN}" || -z "${EMAIL}" ]]; then
    echo "[ssl] Please set ELECTRUM_SSL_DOMAIN and ELECTRUM_SSL_EMAIL (env or .env)."
    usage
    exit 1
  fi
}

# Ensure ports 80/443 are free before running certbot standalone
preflight_check() {
  local blocked=0
  for port in 80 443; do
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
      echo "[ssl] ERROR: port ${port} is already in use — stop the service occupying it first"
      ss -tlnp 2>/dev/null | grep ":${port} "
      blocked=1
    fi
  done
  if (( blocked )); then
    echo "[ssl] hint: if docker-compose services are running, try 'make stop' first"
    exit 1
  fi
}

run_certbot() {
  preflight_check
  echo "[ssl] requesting certificate for ${DOMAIN} via Let's Encrypt"
  mkdir -p "${LE_WORK_DIR}" "${LE_DIR}/logs"
  docker run --rm \
    -p 80:80 -p 443:443 \
    -v "${LE_DIR}:/etc/letsencrypt" \
    -v "${LE_WORK_DIR}:/var/lib/letsencrypt" \
    -v "${LE_DIR}/logs:/var/log/letsencrypt" \
    "${CERTBOT_IMAGE}" certonly --standalone \
    --non-interactive --agree-tos \
    --preferred-challenges http \
    -d "${DOMAIN}" -m "${EMAIL}"
}

renew_certbot() {
  preflight_check
  echo "[ssl] renewing certificate for ${DOMAIN} via Let's Encrypt"
  mkdir -p "${LE_WORK_DIR}" "${LE_DIR}/logs"
  docker run --rm \
    -p 80:80 -p 443:443 \
    -v "${LE_DIR}:/etc/letsencrypt" \
    -v "${LE_WORK_DIR}:/var/lib/letsencrypt" \
    -v "${LE_DIR}/logs:/var/log/letsencrypt" \
    "${CERTBOT_IMAGE}" certonly --standalone \
    --non-interactive --agree-tos \
    --force-renewal \
    --preferred-challenges http \
    -d "${DOMAIN}" -m "${EMAIL}"
}

copy_live_certs() {
  local live_path="${LE_DIR}/live/${DOMAIN}"
  local src_cert="${live_path}/fullchain.pem"
  local src_key="${live_path}/privkey.pem"

  if [[ ! -f "${src_cert}" || ! -f "${src_key}" ]]; then
    echo "[ssl] could not find certbot outputs in ${live_path}"
    exit 1
  fi

  mkdir -p "${SSL_DIR}"
  cp "${src_cert}" "${CERT_FILE}"
  cp "${src_key}" "${KEY_FILE}"
  chmod 600 "${KEY_FILE}"
  echo "[ssl] copied certs to ${SSL_DIR}"
}

case "${1:-ensure}" in
  ensure)
    require_env
    if [[ ! -f "${LE_DIR}/live/${DOMAIN}/fullchain.pem" ]]; then
      run_certbot
    else
      echo "[ssl] existing Let's Encrypt material found; skipping issuance"
    fi
    copy_live_certs
    ;;
  renew)
    require_env
    renew_certbot
    copy_live_certs
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "[ssl] done"
