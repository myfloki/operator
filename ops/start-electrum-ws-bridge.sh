#!/bin/sh
set -e

SOCKET_FILE="/sockets/electrum.sock"

echo "Starting electrum-ws-bridge..."

# Cleanup stale socket
echo "Cleaning up $SOCKET_FILE..."
rm -f "$SOCKET_FILE"

# Install dependencies
# Note: In a production environment, these should be in the Dockerfile.
echo "Installing dependencies..."
apk add --no-cache websocat

# Permissions fix loop in background
(
    echo "Waiting for socket..."
    while [ ! -e "$SOCKET_FILE" ]; do
        sleep 0.1
    done
    echo "Setting permissions on $SOCKET_FILE..."
    chmod 666 "$SOCKET_FILE"
) &

# Start websocat
# -E: Exit on EOF
# -b: Binary mode
# l-ws-unix: Listen on Unix socket
echo "Launching websocat..."
exec websocat -v -E l-ws-unix:"$SOCKET_FILE" tcp:electrum:50001
