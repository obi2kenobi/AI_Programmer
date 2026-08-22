#!/bin/bash
# test-night-shift-design-gate.sh — set 2 giro 5: due messaggi dedicati ("SENZA sezione
# ## Design"/"## Territorio") erano dead code — verificato con simulazione: quando una
# sezione manca del tutto, il controllo di QUALITÀ (lunghezza/pattern) intercettava sempre
# prima, perché la stringa estratta da una sezione assente è vuota (lunghezza 0 < 80,
# nessun pattern trovato). Replica qui la sequenza REALE (estratta da night-shift.sh
# tramite grep, non ridigitata a mano, per non disallinearsi in futuro).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

classify() {
  local BODY="$1"
  if ! printf '%s' "$BODY" | grep -q "^## Territorio"; then echo "SENZA-TERRITORIO"; return; fi
  if ! printf '%s' "$BODY" | grep -q "^## Design"; then echo "SENZA-DESIGN"; return; fi
  local DESIGN_BODY TERR_BODY
  DESIGN_BODY=$(printf '%s' "$BODY" | awk '/^## Design/{f=1;next} /^## /{f=0} f' | tr -d '[:space:]')
  [ "${#DESIGN_BODY}" -lt 80 ] && { echo "DESIGN-POVERO"; return; }
  TERR_BODY=$(printf '%s' "$BODY" | awk '/^## Territorio/{f=1;next} /^## /{f=0} f')
  printf '%s' "$TERR_BODY" | grep -qE '\.[a-z]{2,4}\b|file|riga|documento|md\b' || { echo "TERRITORIO-SENZA-FILE"; return; }
  echo "PASSA"
}

# verifica che l'ordine reale in night-shift.sh sia quello atteso: assenza PRIMA di qualità
ORDINE=$(grep -n '^      log "Issue #\$NUM: \(SENZA sezione ## Territorio\|SENZA sezione ## Design\|sezione ## Design troppo povera\|## Territorio senza file\)' \
  "$HERE/night-shift/night-shift.sh" | cut -d: -f1)
readarray -t RIGHE <<< "$ORDINE"
[ "${#RIGHE[@]}" -eq 4 ] && [ "${RIGHE[0]}" -lt "${RIGHE[2]}" ] && [ "${RIGHE[1]}" -lt "${RIGHE[3]}" ] \
  && ok "night-shift.sh: i controlli di ASSENZA precedono quelli di QUALITÀ (ordine corretto)" \
  || ko "night-shift.sh: ordine dei controlli non verificato: righe ${RIGHE[*]}"

RISULTATO=$(classify "## Commessa
fai qualcosa")
[ "$RISULTATO" = "SENZA-TERRITORIO" ] && ok "issue senza nessuna sezione: rilevata come SENZA Territorio (bug corretto)" \
  || ko "issue senza sezioni: classificata come $RISULTATO"

RISULTATO=$(classify "## Territorio
tools/foo.js righe 1-10")
[ "$RISULTATO" = "SENZA-DESIGN" ] && ok "issue con solo Territorio: rilevata come SENZA Design (bug corretto)" \
  || ko "issue senza Design: classificata come $RISULTATO"

DESIGN_LUNGO=$(printf 'x%.0s' {1..90})
RISULTATO=$(classify "## Design
$DESIGN_LUNGO

## Territorio
qualcosa senza estensione")
[ "$RISULTATO" = "TERRITORIO-SENZA-FILE" ] && ok "Design presente e valido, Territorio senza file: rilevato correttamente" \
  || ko "caso Territorio-senza-file: classificato come $RISULTATO"

RISULTATO=$(classify "## Design
$DESIGN_LUNGO

## Territorio
tools/foo.js righe 1-10")
[ "$RISULTATO" = "PASSA" ] && ok "issue completa e valida: passa il gate" \
  || ko "issue valida bloccata: $RISULTATO"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
