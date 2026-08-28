#!/bin/bash
# test-bootstrap-hooks-propagation.sh — banco di regressione nato dalla revisione "L'Hub
# Allo Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in bootstrap-app.sh,
# mancava "mkdir -p tools" prima dei cp degli hook — su un progetto bootstrappato da zero
# (nessuna cartella tools/ preesistente, il caso NORMALE per un progetto nuovo) il cp
# falliva silenziosamente (2>/dev/null || true) e gli hook non venivano mai installati,
# senza che lo script desse alcun avviso. Isola solo la logica di copia (non l'intero
# script, che richiede gh autenticato), come gli altri test di propagazione bootstrap.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q '^mkdir -p tools$' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh crea tools/ prima di copiare gli hook" \
  || ko "mkdir -p tools non trovato prima della copia degli hook in bootstrap-app.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# stesso scenario del bug: nessuna cartella tools/ preesistente nel progetto nuovo
( cd "$TMP" \
  && mkdir -p tools \
  && cp "$HERE/tools/metodo-reminder-hook.sh" tools/metodo-reminder-hook.sh 2>/dev/null \
  && cp "$HERE/tools/pattern-reminder-hook.sh" tools/pattern-reminder-hook.sh 2>/dev/null )

[ -f "$TMP/tools/metodo-reminder-hook.sh" ] \
  && ok "metodo-reminder-hook.sh installato in un progetto senza tools/ preesistente" \
  || ko "metodo-reminder-hook.sh NON installato — la cartella tools/ mancava"
[ -f "$TMP/tools/pattern-reminder-hook.sh" ] \
  && ok "pattern-reminder-hook.sh installato in un progetto senza tools/ preesistente" \
  || ko "pattern-reminder-hook.sh NON installato — la cartella tools/ mancava"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
