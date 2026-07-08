#!/bin/sh

DASHBOARD="/mnt/us/extensions/kindle-dashboard/bin/dashboard.sh"
LOG="/mnt/us/documents/kindle-dashboard-kual-action.log"

echo "kindle-dashboard once wrapper $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG"
/bin/sh "$DASHBOARD" once >> "$LOG" 2>&1
echo "dashboard.sh once exit=$?" >> "$LOG"
