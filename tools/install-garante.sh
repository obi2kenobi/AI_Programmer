#!/bin/bash
# ⚠ QUESTO TOOL SCRIVE: aggiunge l'hook SessionStart a ~/.claude/settings.json (UTENTE, tutte le repo)
# install-garante.sh — installa il garante-standard a livello UTENTE (~/.claude/settings.json):
# da questo momento, OGNI sessione su OGNI repo verifica e installa lo standard se manca.
set -uo pipefail
HUB="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$HOME/.claude/settings.json"

# (2026-09-24, notte dei giri, T6#7): con settings.json ROTTO, o senza jq, qui si stampava «✅ Garante
# installato» e si usciva 0 senza aver installato niente. Ora: jq e un JSON leggibile sono condizioni
# dichiarate, e il ✅ si stampa solo se l'hook c'e' davvero dopo la scrittura.
command -v jq >/dev/null 2>&1 || { echo "⛔ install-garante: jq assente — non posso leggere ne' scrivere $SETTINGS, niente installato" >&2; exit 1; }
mkdir -p "$HOME/.claude"
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi
jq -e . "$SETTINGS" >/dev/null 2>&1 || { echo "⛔ install-garante: $SETTINGS non e' JSON leggibile — non lo tocco, niente installato (correggilo e rilancia)" >&2; exit 1; }

# aggiunge il garante come SessionStart hook (se non già presente)
# (2026-09-24, sesto ventaglio, S3 R2): il percorso finiva NUDO nel comando (e incollato nel programma jq): da un hub
# con uno spazio la shell dei ganci lo spezzava, rc 127, e il garante non girava mai. Ora il percorso e' quotato per
# la shell (printf %q) e passa a jq come dato (--arg), come i ganci di progetto con "$CLAUDE_PROJECT_DIR".
CMD_GARANTE="$(printf '%q' "$HUB")/tools/garante-standard.sh"
if ! jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | contains("garante"))' "$SETTINGS" >/dev/null 2>&1; then
  jq --arg c "$CMD_GARANTE" '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{
    "matcher": "startup|resume",
    "hooks": [{"type": "command", "command": $c, "timeout": 15}]
  }])' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS" \
    || { rm -f "$SETTINGS.tmp"; echo "⛔ install-garante: scrittura di $SETTINGS fallita, niente installato" >&2; exit 1; }
  jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | contains("garante"))' "$SETTINGS" >/dev/null 2>&1 \
    || { echo "⛔ install-garante: dopo la scrittura l'hook non c'e' in $SETTINGS" >&2; exit 1; }
  echo "✅ Garante installato: da ora ogni sessione verifica e installa lo standard"
  echo "   su qualunque repo, senza che nessuno debba ricordarselo."
  echo "   Per disattivarlo: rimuovi l'hook da $SETTINGS"
else
  echo "✅ Garante già installato"
fi
