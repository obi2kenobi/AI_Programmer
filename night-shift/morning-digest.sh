#!/bin/bash
# morning-digest.sh — il gate arriva nella mailbox, non nel filesystem (giro 3/10).
# Luca non deve ANDARE a leggere ~/morning-gate-report.md: il sistema viene da lui.
# Destinatario: ScriptProperty DIGEST_EMAIL (vuoto = no-op educato, come il digest notturno).
set -euo pipefail

EMAIL=$(python3 -c "
import subprocess
try:
    r = subprocess.check_output(['osascript', '-e', 'tell application \"System Events\" to get the name of every user'], timeout=3)
    print('')
except: print('')" 2>/dev/null || echo "")
# il destinatario vive in night-shift/repos.key (locale, gitignored): DIGEST_EMAIL=...
KEY="$(cd "$(dirname "$0")" && pwd)/repos.key"
DEST=""
if [ -f "$KEY" ]; then
  DEST=$(grep -E '^DIGEST_EMAIL=' "$KEY" | cut -d= -f2- | xargs)
fi
if [ -z "$DEST" ]; then
  echo "morning-digest: DIGEST_EMAIL non configurata in repos.key — digest saltato (aggiungi DIGEST_EMAIL=tu@esempio.it)"
  exit 0
fi

REPORT="$HOME/morning-gate-report.md"
[ -f "$REPORT" ] || { echo "nessun report del gate: esegui morning-gate prima"; exit 1; }

# subject: la riga del totale dal report
SUBJ=$(grep "Totale:" "$REPORT" | head -1 | sed 's/[*\`]//g' | head -c 120)
[ -z "$SUBJ" ] && SUBJ="Gate del mattino — $(date '+%Y-%m-%d')"

# corpo: il report + il summary numerico
BODY="$REPORT

---
$(bash "$(dirname "$0")/gate-summary.sh" 0 2>/dev/null || echo '(summary non disponibile)')"

osascript -e "
tell application \"Mail\"
  set newMsg to make new outgoing message with properties {subject:\"[Gate] $SUBJ\", content:\"$BODY\", visible:false}
  tell newMsg
    make new to recipient at end of to recipients with properties {address:\"$DEST\"}
  end tell
  send newMsg
end tell" 2>/dev/null && echo "Digest inviato a $DEST" || {
  # fallback: mail CLI
  echo "$BODY" | mail -s "[Gate] $SUBJ" "$DEST" 2>/dev/null && echo "Digest inviato a $DEST (via mail)" || echo "ERRORE invio"
}
