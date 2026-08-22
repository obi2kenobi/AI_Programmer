#!/bin/bash
# test-night-verify-template-mentions-marker.sh — set 3 giri 6-7: il marcatore
# NON-VERIFICABILE (creato nel Set 2 giro 10) non era menzionato nei template
# .night-verify generati da bootstrap-app.sh/onboard-repo.sh — chi crea da zero un
# progetto senza modo di verificare in automatico non sapeva che l'opzione esistesse.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "NON-VERIFICABILE" "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh menziona il marcatore NON-VERIFICABILE nel template" \
  || ko "bootstrap-app.sh non menziona NON-VERIFICABILE"

grep -q "NON-VERIFICABILE" "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh menziona il marcatore NON-VERIFICABILE nel template" \
  || ko "onboard-repo.sh non menziona NON-VERIFICABILE"

# il marcatore nel template deve essere riconosciuto dalla stessa regex usata dal gate reale
REGEX_GATE=$(grep -oE "grep -iE '[^']*NON-VERIFICABILE[^']*'" "$HERE/night-shift/morning-gate.sh" | head -1)
[ -n "$REGEX_GATE" ] && ok "la regex del gate per NON-VERIFICABILE esiste davvero (non solo nei template)" \
  || ko "morning-gate.sh non ha (più?) la regex per NON-VERIFICABILE"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
