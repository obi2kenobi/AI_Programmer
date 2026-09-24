#!/bin/bash
# test-giri-avversari-classifica.sh — il giudice degli input ostili non premia un traceback (2026-09-24, quinto
# ventaglio, R3 R5). `classifica` in tools/giri-avversari.sh contava come «tiene» ogni output con «traceback»:
# il contratto D32 di tests/test-oracoli-uso.sh dice il contrario (input sbagliato → rifiuto dichiarato, MAI
# traceback). E la sonda D9 mandava campi che indici_crisi non legge: non arrivava mai al calcolo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
GA="$HERE/tools/giri-avversari.sh"
# classifica estratta dallo script, con verdetti finti che scrivono solo la parola
eval "$(sed -n '/^classifica() {/,/^}/p' "$GA")"
tiene() { echo TIENE; }; aggirato() { echo AGGIRA; }
[ "$(classifica $'Traceback (most recent call last):\nValueError: x' 1 d)" = AGGIRA ] \
  && ok "un traceback con rc 1 e' AGGIRA, non «si dichiara»" || ko "classifica premia il traceback"
[ "$(classifica 'ERRORE: riga 2: importo non numerico' 1 d)" = TIENE ] && ok "un rifiuto dichiarato resta TIENE" || ko "il rifiuto dichiarato non tiene piu'"
[ "$(classifica 'Totale: +nan' 0 d)" = AGGIRA ] && ok "la spazzatura silenziosa resta AGGIRA" || ko "nan silenzioso non piu' AGGIRA"
D9=$(grep -A2 'D9 mandava' "$GA" | grep -o "echo '{[^']*}'" | head -1)
[ -n "$D9" ] && ! grep -c 'patrimonio\|perdite_precedenti' <<<"$D9" >/dev/null && grep -c 'passCorrenti' <<<"$D9" >/dev/null \
  && ok "D9 manda i dieci campi veri di indici_crisi" || ko "D9 manda campi che il tool non legge: ${D9:-(non trovata)}"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
