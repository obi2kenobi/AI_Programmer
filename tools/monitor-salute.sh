#!/bin/bash
# monitor-salute.sh — il sistema è vivo? (cancella da crontab se resta giù)
URL="${1:-http://localhost:18789/}"
NOTIFY="${2:-}"  # email opzionale
if curl -sf --max-time 5 "$URL" >/dev/null 2>&1; then
  echo "✅ gateway vivo $(date '+%H:%M:%S')"
else
  echo "⚠ GATEWAY GIÙ $(date '+%H:%M:%S')"
  [ -n "$NOTIFY" ] && echo "Gateway OpenClaw giù da $(date)" | mail -s "⚠ OpenClaw DOWN" "$NOTIFY"
  # tenta rianimazione
  pkill -f "openclaw gateway" 2>/dev/null; sleep 2
  nohup openclaw gateway >/dev/null 2>&1 &
  echo "🔄 rianimato"
fi
