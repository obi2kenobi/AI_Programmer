#!/bin/bash
# test-roadmap-repo.sh — la roadmap per-repo (studio GSD Pi): il passo
# corrente vive in .git/roadmap, la caccia lo onora prima di vagare.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.git"
R="$HERE/tools/roadmap-repo.sh"

bash "$R" "$TMP/repo" get >/dev/null 2>&1 && ko "get senza roadmap dovrebbe uscire 3" \
  || ok "get senza roadmap: dichiara (nessuna), rc 3"

bash "$R" "$TMP/repo" set "saldare E-002 su tools/" >/dev/null 2>&1 \
  && ok "set: passo impostato" || ko "set fallito"

bash "$R" "$TMP/repo" get | grep -q "saldare" \
  && ok "get: il passo si legge" || ko "get non legge"

bash "$R" "$TMP/repo" advance >/dev/null 2>&1
grep -q "DONE" "$TMP/repo/.git/roadmap.done" 2>/dev/null \
  && ok "advance: il passo completato va nello storico" || ko "advance non storicizza"

bash "$R" "$TMP/repo" get | grep -q "prossimo" \
  && ok "dopo advance il passo corrente e' pronto per il prossimo" || ko "advance non resetta"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
