#!/bin/sh

DASHBOARD="/mnt/us/extensions/kindle-dashboard/bin/dashboard.sh"
LOG="/mnt/us/documents/kindle-dashboard-proof.log"
PGM="/mnt/us/documents/kindle-dashboard-last-render.pgm"

{
  echo "kindle-dashboard proof $(date '+%Y-%m-%d %H:%M:%S')"
  echo "dashboard=$DASHBOARD exists=$(test -f "$DASHBOARD" && echo yes || echo no) executable=$(test -x "$DASHBOARD" && echo yes || echo no)"
  echo "pgm=$PGM"
} >> "$LOG"

rm -f "$PGM"
SAVE_PGM="$PGM" /bin/sh "$DASHBOARD" once >> "$LOG" 2>&1
status="$?"
echo "dashboard.sh once exit=$status" >> "$LOG"
if [ -s "$PGM" ]; then
  echo "saved_pgm_bytes=$(wc -c < "$PGM" 2>/dev/null)" >> "$LOG"
else
  echo "missing_pgm=$PGM" >> "$LOG"
fi
if [ "$status" -eq 0 ]; then
  eips 2 2 "Dashboard proof OK" >/dev/null 2>&1 || true
else
  eips 2 2 "Dashboard proof failed" >/dev/null 2>&1 || true
fi
exit 0
