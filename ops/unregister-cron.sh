#!/bin/bash

HEALTH_SCRIPT="ops/health-check.sh"

# Remove from crontab
crontab -l 2>/dev/null | grep -v "$HEALTH_SCRIPT" | crontab -

echo "✅ Cron unregistered for $HEALTH_SCRIPT"
