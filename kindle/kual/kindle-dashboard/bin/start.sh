#!/bin/sh

DASHBOARD="/mnt/us/extensions/kindle-dashboard/bin/dashboard.sh"
LOG="/mnt/us/documents/kindle-dashboard-kual-action.log"

echo "kindle-dashboard start wrapper $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG"
echo "dashboard=$DASHBOARD exists=$(test -f "$DASHBOARD" && echo yes || echo no) executable=$(test -x "$DASHBOARD" && echo yes || echo no)" >> "$LOG"
/bin/sh "$DASHBOARD" start >> "$LOG" 2>&1
echo "dashboard.sh start exit=$?" >> "$LOG"
