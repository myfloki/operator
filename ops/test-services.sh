#!/bin/bash

ELECTRUM_HOST="localhost"
ELECTRUM_TCP_PORT="50001"
ELECTRUM_SSL_PORT="50002"
ELECTRUM_WSS_PORT="50004"

echo "🔍 Testing Electrum Services on $ELECTRUM_HOST..."

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
