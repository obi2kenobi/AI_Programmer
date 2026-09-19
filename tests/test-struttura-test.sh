#!/bin/bash
# test-struttura-test.sh — il cancello del verdetto sta ULTIMO (2026-09-19).
# Il teatro della notte: sezioni DEBITO aggiunte DOPO il riepilogo di
# test-caccia-miglioria — l'ultima riga era un `rm` e il suo rc 0 sovrascriveva
# il cancello: 10 FAIL stampati, uscita 0, 52 suite rosse di fila (il banco
# mutazioni urlava TEATRO a ogni ciclo). Regola: chi dichiara il cancello
# `[ $FAIL -eq 0 ]`, lo dichiara ULTIMO — aggiungere sezioni dopo il riepilogo
# e' l'errore facile, e il verdetto di un test e' la sua ultima parola.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TOT=0; SOSPETTI=0
for t in "$HERE"/tests/test-*.sh; do
  TOT=$((TOT+1))
  # solo i test che dichiarano il cancello classico
  NG=$(grep -c '^\[ \$FAIL -eq 0 \]$' "$t" || true)
  [ "$NG" -eq 0 ] && continue
  ULT=$(grep -v '^[[:space:]]*$\|^[[:space:]]*#' "$t" | tail -1)
  case "$ULT" in
    *'[ $FAIL -eq 0 ]'*) ;;
    *) SOSPETTI=$((SOSPETTI+1)); ko "$(basename "$t"): il cancello non e' l'ultima riga (ultima: ...$(printf '%s' "$ULT" | tail -c 30))" ;;
  esac
done
[ "$SOSPETTI" -eq 0 ] && ok "i $TOT test col cancello classico lo dichiarano tutti per ultimo" || ko "$SOSPETTI test col verdetto sovrascritto"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
