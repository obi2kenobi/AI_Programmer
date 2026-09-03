#!/bin/bash
# install-garante.sh — installa il garante-standard a livello UTENTE (~/.claude/settings.json):
# da questo momento, OGNI sessione su OGNI repo verifica e installa lo standard se manca.
set -uo pipefail
HUB="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# aggiunge il garante come SessionStart hook (se non già presente)
if ! jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | contains("garante"))' "$SETTINGS" >/dev/null 2>&1; then
  jq '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{
    "matcher": "startup|resume",
    "hooks": [{"type": "command", "command": "'"$HUB"'/tools/garante-standard.sh", "timeout": 15}]
  }])' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "✅ Garante installato: da ora ogni sessione verifica e installa lo standard"
  echo "   su qualunque repo, senza che nessuno debba ricordarselo."
  echo "   Per disattivarlo: rimuovi l'hook da $SETTINGS"
else
  echo "✅ Garante già installato"
fi
