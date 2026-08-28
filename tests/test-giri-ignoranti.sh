#!/bin/bash
# test-giri-ignoranti.sh — la batteria delle sonde scortesi sotto prova (il
# banco 7 lo pretendeva: modificata l'esclusione S1, nessun test la citava).
# Contratto: su repo pulito esce 0 finding con tutte le sonde dichiarate;
# il caso negativo della S1 (glifo piantato a runtime) viene PRESO.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BAT="$HERE/tools/giri-ignoranti.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$BAT" && ok "sintassi" || ko "sintassi rotta"

OUT=$(bash "$BAT" 2>&1); RC=$?
echo "$OUT" | grep -q "VERDETTO: 0 finding" && ok "su repo integro: 0 finding" || ko "finding su repo integro: $(echo "$OUT" | grep -c '^FIND')"
for s in S1 S2 S3 S4 S5 S6 S7 S8 S9; do
  echo "$OUT" | grep -q "OK   $s " && ok "sonda $s presente e verde" || ko "sonda $s assente o rossa"
done

# caso negativo S1: glifo costruito a runtime (il nome letterale qui dentro
# auto-segnalerebbe il test stesso — E-007 del registro)
GLIFO=$(python3 -c "print(chr(0x9633)+chr(0x53f0))")
printf 'parola con %s dentro\n' "$GLIFO" >> "$HERE/DEBITI.md"
OUT2=$(bash "$BAT" 2>&1); RC2=$?
[ $RC2 -ne 0 ] && echo "$OUT2" | grep -q "FIND S1" \
  && ok "glifo piantato: S1 lo prende e la batteria esce rossa" \
  || ko "glifo piantato NON visto (rc=$RC2)"
git -C "$HERE" checkout -- DEBITI.md

# l'esclusione del registro è DICHIARATA nel commento della sonda
grep -q "REGISTRO.md" "$BAT" && ok "l'esclusione del registro è dichiarata, non silenziosa" || ko "esclusione non dichiarata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
