#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# (giro 26, 2026-09-20 — D39): `grep -qE ...` senza il file leggeva stdin (vuoto): zero
# ok/ko, «0 OK, 0 FAIL», verde da sempre. Ora ogni test deve avere una via di fallimento.
for t in "$HERE"/tests/test-*.sh; do
  grep -qE "FAIL|exit 1|ko " "$t" && ok "$(basename "$t") ha una via di fallimento" || ko "$(basename "$t") non puo' mai fallire (niente FAIL/exit 1/ko)"
done
echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
