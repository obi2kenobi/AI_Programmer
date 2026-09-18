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
# auto-segnalerebbe il test stesso — E-007 del registro).
# (2026-09-18, il fantasma delle 17:21, trovato nel test di un'ora): il glifo
# si piantava nel DEBITI.md del repo VERO — visibile a ogni batteria ignoranti
# sovrapposta (il banco del turno, il banco dentro la suite): FIND S1 fantasma
# e banco rosso a intermittenza per un pomeriggio intero. Il canarico vive in
# un CLONE DI QUARANTENA (come prova-rilevatori dal primo giorno): il repo
# vivo non lo vede MAI, e non c'e' ripristino che possa mancare.
QT=$(mktemp -d /tmp/test-ignoranti.XXXXXX)
if git clone -q --local "$HERE" "$QT/hub" 2>/dev/null; then
  # il clone non porta i gitignored: si portano a mano (lezione di prova-rilevatori)
  cp "$HERE/night-shift/repos.conf" "$QT/hub/night-shift/repos.conf" 2>/dev/null || true
  cp "$HERE/night-shift/repos.key" "$QT/hub/night-shift/repos.key" 2>/dev/null || true
  GLIFO=$(python3 -c "print(chr(0x9633)+chr(0x53f0))")
  printf 'parola con %s dentro\n' "$GLIFO" >> "$QT/hub/DEBITI.md"
  OUT2=$(bash "$QT/hub/tools/giri-ignoranti.sh" 2>&1); RC2=$?
  [ $RC2 -ne 0 ] && echo "$OUT2" | grep -q "FIND S1" \
    && ok "glifo in quarantena: S1 lo prende e la batteria esce rossa" \
    || ko "glifo piantato NON visto (rc=$RC2)"
  rm -rf "$QT"
else
  ko "clone di quarantena fallito: il canarico NON si pianta nel repo vivo"
  rm -rf "$QT"
fi

# l'esclusione del registro è DICHIARATA nel commento della sonda
grep -q "REGISTRO.md" "$BAT" && ok "l'esclusione del registro è dichiarata, non silenziosa" || ko "esclusione non dichiarata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
