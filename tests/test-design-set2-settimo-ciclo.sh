#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
grep -qi "VINCOLI DI SQUALIFICA" "$DD" && ok "squalifiche" || ko "squalifiche mancanti"
grep -qi "secondo ordine" "$DD" && ok "secondo ordine" || ko "secondo ordine"
grep -qi "spike" "$DD" && ok "spike" || ko "spike"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
