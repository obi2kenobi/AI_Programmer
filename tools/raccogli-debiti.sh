#!/bin/bash
# raccogli-debiti.sh — il registro dei debiti scorciatoia (furto da ponytail):
# i commenti "shortcut:" nel codice vengono raccolti e portati in DEBITI.md
# con file:riga. Il debito nasce dove nasce il debito.
set -uo pipefail
DIR="${1:?uso: raccogli-debiti.sh <dir-repo>}"
cd "$DIR" || exit 2
TROVATI=$(grep -rn "shortcut:" --include="*.sh" --include="*.py" --include="*.js" --include="*.gs" . 2>/dev/null \
  | grep -v "raccogli-debiti\|node_modules\|graphify-out" | head -20)
if [ -z "$TROVATI" ]; then
  echo "raccogli-debiti: nessuno shortcut marcato (dichiarato)"
  exit 0
fi
echo "== debiti scorciatoia trovati =="
printf '%s\n' "$TROVATI"
echo ""
echo "== da aggiungere a DEBITI.md (se non gia' presenti) =="
while IFS= read -r riga; do
  FILE="${riga%%:*}"
  RESTO="${riga#*:}"; NUM="${RESTO%%:*}"; CONTENUTO="${RESTO#*:}"
  DEBITO=$(printf '%s' "$CONTENUTO" | sed 's/.*shortcut:[[:space:]]*//')
  [ -n "$DEBITO" ] || continue
  # controlla se è già in DEBITI.md
  if ! grep -qF "$FILE:$NUM" DEBITI.md 2>/dev/null; then
    echo "- [$FILE:$NUM] $DEBITO"
  fi
done <<<"$TROVATI"
