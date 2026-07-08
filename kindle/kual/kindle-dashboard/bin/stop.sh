#!/bin/sh

DASHBOARD="/mnt/us/extensions/kindle-dashboard/bin/dashboard.sh"
LOG="/mnt/us/documents/kindle-dashboard-kual-action.log"

echo "kindle-dashboard stop wrapper $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG"
/bin/sh "$DASHBOARD" stop >> "$LOG" 2>&1
echo "dashboard.sh stop exit=$?" >> "$LOG"
