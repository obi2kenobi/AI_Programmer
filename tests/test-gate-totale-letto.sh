#!/bin/bash
# test-gate-totale-letto.sh — il gate dei banchi legge il suo stesso TOTALE (revisione della notte, 2026-11-03).
#
# lib.sh gate_banchi chiude con «TOTALE <ok> <ko> (di cui ambra-flaky: N)». night-shift.sh la leggeva con
# `read -r _ PASS_T FAIL_T`: l'ultima variabile prende TUTTO il resto della riga, cioe' FAIL_T="0 (di cui ambra-flaky: 0)",
# e `[ "$FAIL_T" -eq 0 ]` e' un errore di sintassi, cioe' FALSO: il gate non passava MAI e ogni auto-fix veniva
# bocciato («integer expression expected», 32 volte nel log del 2-3/11). Qui si esegue la riga VERA di night-shift.sh.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

LETTURA=$(grep -m1 'read -r _ PASS_T FAIL_T' "$HERE/night-shift/night-shift.sh" | sed 's/^[[:space:]]*//')
[ -n "$LETTURA" ] && ok "la riga che legge il TOTALE esiste in night-shift.sh" || { ko "riga di lettura del TOTALE non trovata"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

leggi() {  # $1 = il testo del banco; stampa «PASS_T|FAIL_T»
  local GATE_OUT="$1" PASS_T FAIL_T
  eval "$LETTURA"
  echo "$PASS_T|$FAIL_T"
}

R=$(leggi $'rosso x.sh\nTOTALE 11 0 (di cui ambra-flaky: 0)')
[ "$R" = "11|0" ] && ok "TOTALE con ambra-flaky: PASS_T=11 FAIL_T=0 (interi puliti)" || ko "TOTALE con ambra-flaky letto male: '$R'"

R=$(leggi 'TOTALE 9 2 (di cui ambra-flaky: 1)')
[ "$R" = "9|2" ] && ok "TOTALE con due falliti: PASS_T=9 FAIL_T=2" || ko "TOTALE con 2 falliti letto male: '$R'"

FAIL_T=$(leggi 'TOTALE 11 0 (di cui ambra-flaky: 0)'); FAIL_T=${FAIL_T#*|}
[ "$FAIL_T" -eq 0 ] 2>/dev/null && ok "il confronto numerico del gate ([ FAIL_T -eq 0 ]) e' vero a zero fallimenti" \
  || ko "il confronto numerico del gate e' un errore o falso con FAIL_T='$FAIL_T'"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
