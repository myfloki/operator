#!/bin/bash

ELECTRUM_HOST="localhost"
ELECTRUM_TCP_PORT="50001"
ELECTRUM_SSL_PORT="50002"
ELECTRUM_WSS_PORT="50004"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env for ELECTRUM_SSL_DOMAIN
if [[ -f "${REPO_ROOT}/.env" ]]; then
    set -a
    source "${REPO_ROOT}/.env"
    set +a
fi

DOMAIN="${ELECTRUM_SSL_DOMAIN:-}"
CERT_FILE="${REPO_ROOT}/data/electrum/ssl/server.crt"
WARN_DAYS=7

echo "🔍 Testing Electrum Services on $ELECTRUM_HOST..."
echo ""

# ---------- Service checks ----------
echo "── Service Connectivity ──"

# TCP Check
echo -n "👉 TCP ($ELECTRUM_TCP_PORT): "
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$ELECTRUM_HOST/$ELECTRUM_TCP_PORT" 2>/dev/null; then
    echo "✅ UP"
else
    echo "❌ DOWN"
fi

# SSL Check
echo -n "👉 SSL ($ELECTRUM_SSL_PORT): "
if echo | openssl s_client -connect "$ELECTRUM_HOST:$ELECTRUM_SSL_PORT" -quiet 2>/dev/null >/dev/null; then
    echo "✅ UP"
else
    echo "❌ DOWN"
fi

# WSS Check
echo -n "👉 WSS ($ELECTRUM_WSS_PORT): "
HTTP_CODE=$(curl -k -o /dev/null -s -w "%{http_code}" \
    -H "Connection: Upgrade" \
    -H "Upgrade: websocket" \
    -H "Host: $ELECTRUM_HOST:$ELECTRUM_WSS_PORT" \
    -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
    -H "Sec-WebSocket-Version: 13" \
    "https://$ELECTRUM_HOST:$ELECTRUM_WSS_PORT/")

if [[ "$HTTP_CODE" == "101" || "$HTTP_CODE" == "400" ]]; then
    echo "✅ UP (HTTP Code: $HTTP_CODE)"
else
    echo "❌ DOWN (HTTP Code: $HTTP_CODE)"
fi

# ---------- SSL Certificate Validity ----------
echo ""
echo "── SSL Certificate ──"

check_cert() {
    local label="$1"
    local cert_pem="$2"

    if [[ -z "$cert_pem" ]]; then
        echo "  ❌ $label: could not read certificate"
        return 1
    fi

    # Extract fields
    local not_after subject issuer
    not_after=$(echo "$cert_pem" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2-)
    subject=$(echo "$cert_pem"   | openssl x509 -noout -subject 2>/dev/null | sed 's/subject= *//')
    issuer=$(echo "$cert_pem"    | openssl x509 -noout -issuer  2>/dev/null | sed 's/issuer= *//')

    if [[ -z "$not_after" ]]; then
        echo "  ❌ $label: unable to parse certificate"
        return 1
    fi

    # Days remaining (portable: use date -d)
    local exp_epoch now_epoch days_left
    exp_epoch=$(date -d "$not_after" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_left=$(( (exp_epoch - now_epoch) / 86400 ))

    echo "  📜 Subject : $subject"
    echo "  🏢 Issuer  : $issuer"
    echo "  📅 Expires : $not_after  ($days_left days remaining)"

    if (( days_left < 0 )); then
        echo "  ❌ $label: EXPIRED $(( -days_left )) days ago!"
        return 1
    elif (( days_left <= WARN_DAYS )); then
        echo "  ⚠️  $label: expires in $days_left days — RENEW NOW (make renew)"
        return 1
    else
        echo "  ✅ $label: valid"
        return 0
    fi
}

# --- Check 1: live certificate from SSL port ---
echo "👉 Live cert on port $ELECTRUM_SSL_PORT:"
LIVE_PEM=$(echo | openssl s_client -connect "$ELECTRUM_HOST:$ELECTRUM_SSL_PORT" -servername "${DOMAIN:-$ELECTRUM_HOST}" 2>/dev/null \
    | openssl x509 2>/dev/null)
check_cert "Live" "$LIVE_PEM"
live_ok=$?

# --- Check 2: certificate file on disk ---
echo ""
echo "👉 Cert file ($CERT_FILE):"
if [[ -f "$CERT_FILE" ]]; then
    DISK_PEM=$(cat "$CERT_FILE")
    check_cert "Disk" "$DISK_PEM"
    disk_ok=$?
else
    echo "  ❌ Certificate file not found"
    disk_ok=1
fi

# --- Summary ---
echo ""
if (( live_ok == 0 && disk_ok == 0 )); then
    echo "🟢 SSL certificate is valid and healthy."
elif (( live_ok != 0 && disk_ok != 0 )); then
    echo "🔴 SSL certificate has issues — run: make renew"
else
    echo "🟡 SSL certificate status is mixed — review above."
fi
