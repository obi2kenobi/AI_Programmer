#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# (giro 26, 2026-09-20 — D39): `grep -qE ...` senza il file leggeva stdin (vuoto): zero
# ok/ko, «0 OK, 0 FAIL», verde da sempre. Ora ogni test deve avere una via di fallimento.
for t in "$HERE"/tests/test-*.sh; do
  # (audit-2): prima matchava lo scaffold stesso (153/154 passavano per
  # costruzione). Ora serve un ko IN CODICE: la chiamata ko( non commentata
  if grep -vE '^\s*#' "$t" | grep -Ec '\bko |\bko\(' >/dev/null ; then
    ok "$(basename "$t") ha una via di fallimento (ko in codice)"
  else
    ko "$(basename "$t") non puo' mai fallire (nessun ko eseguibile)"
  fi
done
echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
