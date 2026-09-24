#!/bin/bash
# test-e002-banchi-curati.sh — il cricchetto dei banchi curati dalla famiglia E-002 (E-042).
#
# `echo "$X" | grep -q …` sotto `set -o pipefail` e' un rosso A CASO: grep -q esce alla prima riga
# che combacia, echo prende SIGPIPE (rc 141) e la pipeline intera e' falsa anche se il testo c'e'.
# A macchina scarica non si vede quasi mai; sotto carico si': catturato il 2026-09-23 su
# tests/test-errori.sh («E-032: mancanti: Guardia:», campo presente) — 2 rossi su 120 esecuzioni
# a quattro in parallelo, 0 dopo la cura `grep -q … <<<"$X"`.
# Il censimento dei banchi dice 250 siti in 68 file (DEBITI). Questa guardia non li cura tutti:
# tiene fermi quelli curati — un banco nella lista non puo' tornare alla forma che morde.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
FORMA='(echo|printf)[^|]*\| *grep -q'

# (Q31, 2026-09-23, notte dei giri): erano due banchi nominati; la voce di DEBITI aspettava «la
# caccia notturna, un banco per finestra» — ma tools/caccia-registro.sh non guardava tests/: i 253
# siti non sarebbero stati curati MAI. Curati tutti stanotte (lo stesso trasformatore di Q27, righe
# con continuazione comprese); il cricchetto ora vale per OGNI banco sotto pipefail. Fuori, dichiarati:
# i due banchi E-002, che citano la forma nei loro messaggi.
CURATI=$(cd "$HERE" && grep -lE pipefail tests/*.sh | grep -vE '^tests/test-e002-(banchi-curati|codice)\.sh$')
for f in $CURATI; do
  N=$(grep -vE '^[[:space:]]*#' "$HERE/$f" | grep -cE "$FORMA")   # i commenti che la citano non mordono
  [ "$N" -eq 0 ] && ok "$f: nessun «echo | grep -q» (curato, E-042)" || ko "$f: $N siti «echo | grep -q» sotto pipefail — la forma che dava il rosso a caso"
done

# la guardia della guardia: la forma che cerca e' proprio quella che mordeva
PROVA=$(mktemp); trap 'rm -f "$PROVA"' EXIT
printf 'echo "$BLOCCO" | grep -q "^- Guardia:" || MANCA=1\n' > "$PROVA"   # la fixture: resta la forma che morde
[ "$(grep -cE "$FORMA" "$PROVA")" -eq 1 ] && ok "la forma cercata riconosce la riga che ha dato il rosso" || ko "la forma cercata non riconosce il caso reale"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
