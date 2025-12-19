#!/bin/bash

HEALTH_SCRIPT="./ops/health-check.sh"
HEALTH_LOG="/var/log/healthmon.log"
CRON_SCHEDULE="*/1 * * * *"

# Ensure script is executable
chmod +x "$HEALTH_SCRIPT"

# Get absolute path of current directory
PWD=$(pwd)
CRON_CMD="cd $PWD && $HEALTH_SCRIPT >> $HEALTH_LOG 2>&1"
CRON_ENTRY="$CRON_SCHEDULE $CRON_CMD"

# Add to crontab if not exists
(crontab -l 2>/dev/null | grep -F "$CRON_CMD") && echo "✅ Cron already registered." && exit 0

(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
echo "✅ Cron registered: $CRON_ENTRY"
