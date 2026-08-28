#!/bin/bash
# test-backup-config.sh — 60 giri: backup-config non aveva test
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# il tool esiste, è eseguibile, e gestisce l'assenza di gh
[ -f "$HERE/tools/backup-config.sh" ] && ok "backup-config.sh esiste" || ko "assente"
[ -x "$HERE/tools/backup-config.sh" ] && ok "eseguibile" || ko "non eseguibile"
# senza gh deve fallire pulitamente (non crashare)
command -v gh >/dev/null 2>&1 && ok "gh disponibile: test completo saltato" || {
  out=$(bash "$HERE/tools/backup-config.sh" 2>&1); rc=$?
  [ $rc -ne 0 ] && echo "$out" | grep -qi "gh\|gist" && ok "senza gh: errore pulito" || ko "senza gh: crash poco chiaro"
}
echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
