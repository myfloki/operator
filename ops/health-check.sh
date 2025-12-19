#!/bin/bash

# Configuration
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
ELECTRUM_HOST="localhost"
ELECTRUM_TCP_PORT="50001"
ELECTRUM_SSL_PORT="50002"
ELECTRUM_WSS_PORT="50004"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

notify_discord() {
    local message="$1"
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        curl -H "Content-Type: application/json" \
             -d "{\"content\": \"$message\"}" \
             "$DISCORD_WEBHOOK_URL"
    else
        log "WARNING: Discord Webhook URL not set. Notification skipped: $message"
    fi
}

check_tcp() {
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/$ELECTRUM_HOST/$ELECTRUM_TCP_PORT" 2>/dev/null
    return $?
}

check_ssl() {
    echo | openssl s_client -connect "$ELECTRUM_HOST:$ELECTRUM_SSL_PORT" -quiet 2>/dev/null >/dev/null
    return $?
}

check_wss() {
    curl -k -i -N \
        -H "Connection: Upgrade" \
        -H "Upgrade: websocket" \
        -H "Host: $ELECTRUM_HOST:$ELECTRUM_WSS_PORT" \
        -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
        -H "Sec-WebSocket-Version: 13" \
        "https://$ELECTRUM_HOST:$ELECTRUM_WSS_PORT/" 2>/dev/null | grep -q "101 Switching Protocols\|400 Bad Request"
    # Note: 400 Bad Request with "Only WebSocket connections are welcome here" from Nginx bridge implies backend is up but we didn't do full handshake. 
    # Proper WSS handshake return is 101. 
    # Let's try to be robust. If we get a response from nginx on that port, it's a good sign.
    # A better check for WSS is to actually see the upgrade header in response.
    return $?
}

# Main Check Loop
FAILED_SERVICES=()

if ! check_tcp; then
    FAILED_SERVICES+=("Electrum TCP ($ELECTRUM_TCP_PORT)")
fi

if ! check_ssl; then
    FAILED_SERVICES+=("Electrum SSL ($ELECTRUM_SSL_PORT)")
fi

# We use a slightly different check for WSS to be sure
HTTP_CODE=$(curl -k -o /dev/null -s -w "%{http_code}" \
    -H "Connection: Upgrade" \
    -H "Upgrade: websocket" \
    -H "Host: $ELECTRUM_HOST:$ELECTRUM_WSS_PORT" \
    -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
    -H "Sec-WebSocket-Version: 13" \
    "https://$ELECTRUM_HOST:$ELECTRUM_WSS_PORT/")

if [[ "$HTTP_CODE" != "101" && "$HTTP_CODE" != "400" ]]; then
     FAILED_SERVICES+=("Electrum WSS ($ELECTRUM_WSS_PORT) - Status: $HTTP_CODE")
fi

# Reporting
if [ ${#FAILED_SERVICES[@]} -ne 0 ]; then
    MESSAGE="🚨 **Critical Alert**: The following Electrum services are DOWN on $(hostname): ${FAILED_SERVICES[*]}"
    log "$MESSAGE"
    notify_discord "$MESSAGE"
    exit 1
else
    log "✅ All Electrum services are OPERATIONAL."
    exit 0
fi
