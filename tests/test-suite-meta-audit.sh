#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
for t in "$HERE"/tests/test-*.sh; do
  grep -qE "FAIL|exit 1|ko "
done
echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
