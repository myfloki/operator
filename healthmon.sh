#!/bin/bash

# Move to the script's directory (assumed to be where the Makefile is)
cd "$(dirname "$0")" || exit 1

CONTAINER_NAME="mainnet-electrum"

HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME")

if [ "$HEALTH_STATUS" == "unhealthy" ]; then
  echo "[$(date)] $CONTAINER_NAME is unhealthy. Restarting..."
  make restart_electrum
else
  echo "[$(date)] $CONTAINER_NAME is healthy."
fi