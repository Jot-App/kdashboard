#!/bin/sh

LOG="${LOG:-/mnt/us/documents/kindle-dashboard-menu-ping.log}"

{
  echo "kindle-dashboard menu ping $(date '+%Y-%m-%d %H:%M:%S')"
  echo "shell=$SHELL"
  echo "script=$0"
  echo "pwd=$(pwd 2>/dev/null)"
  echo "uname=$(uname -a 2>/dev/null)"
} >> "$LOG"

if [ "${RUN_VISUAL_ON_PING:-1}" = "1" ]; then
  /bin/sh /mnt/us/extensions/kindle-dashboard/bin/once.sh >> /mnt/us/documents/kindle-dashboard-kual-action.log 2>&1
fi

exit 0
