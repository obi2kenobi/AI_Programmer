#!/bin/bash
# test-project-md-percorsi-citati.sh — 2026-08-24, report dal campo (F4): PROJECT.md
# citava CATALOGO_ENDPOINT_BC.md che non esiste da nessuna parte dell'hub — pattern
# citazione-non-presidio dentro il documento che OGNI progetto eredita. Ogni percorso
# citato in PROJECT.md deve esistere nell'hub OPPURE la riga che lo cita dichiara che
# vive altrove ("vive nel" / "repo del cliente" / "non vive in questo hub").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PM="$HERE/PROJECT.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

MANCANTI=0
while IFS= read -r riga_num_percorso; do
  riga="${riga_num_percorso%%:*}"
  percorso="${riga_num_percorso#*:}"
  [ -e "$HERE/$percorso" ] && continue
  riga_testo=$(sed -n "${riga}p" "$PM")
  echo "$riga_testo" | grep -qiE "vive nel|repo del cliente|non vive in questo hub|vive in .*repo" \
    || { echo "   citato ma assente e non dichiarato esterno: $percorso (riga $riga)"; MANCANTI=$((MANCANTI+1)); }
done < <(grep -noE '`[A-Za-z0-9_./-]+\.(md|sh|py|js|json|csv)`' "$PM" | sed 's/://;s/`//g' | awk -F: '{print $1":"$2}')

[ "$MANCANTI" -eq 0 ] \
  && ok "ogni percorso citato in PROJECT.md esiste o dichiara di vivere altrove" \
  || ko "$MANCANTI percorso/i citato/i senza presidio in PROJECT.md"

grep -q "CATALOGO_ENDPOINT_BC.md" "$PM" && grep -qi "vive nel REPO DEL CLIENTE" "$PM" \
  && ok "il catalogo endpoint dichiara dove vive (era il vicolo cieco del report)" \
  || ko "il riferimento al catalogo non dichiara la sua sede"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
