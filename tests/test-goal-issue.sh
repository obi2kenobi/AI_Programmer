#!/bin/bash
# test-goal-issue.sh — il goal durable delle issue (studio deepseek-harness
# packages/goal): sopravvive ai cicli, si aggiorna, si chiude con esito.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.git"
G="$HERE/tools/goal-issue.sh"

bash "$G" "$TMP/repo" create 42 "Correggere il calcolo IVA" >/dev/null 2>&1 \
  && ok "create: goal aperto per issue #42" || ko "create fallito"

bash "$G" "$TMP/repo" create 42 "doppio" >/dev/null 2>&1 && ko "create duplicato accettato" \
  || ok "create duplicato rifiutato (rc 3)"

bash "$G" "$TMP/repo" update 42 "solver rc=1 al primo giro" >/dev/null 2>&1
bash "$G" "$TMP/repo" update 42 "PR bozza aperta: fix applicato" >/dev/null 2>&1
bash "$G" "$TMP/repo" show 42 | grep -q "PR bozza" \
  && ok "update+show: i progressi si accumulano e si leggono" || ko "show non mostra i progressi"

bash "$G" "$TMP/repo" list | grep -q "#42" \
  && ok "list: il goal aperto si vede" || ko "list vuota"

bash "$G" "$TMP/repo" close 42 ok >/dev/null 2>&1
bash "$G" "$TMP/repo" list | grep -q "#42" && ko "close non ha chiuso" || ok "close: il goal sparisce dagli aperti"
grep -q "esito: ok" "$TMP/repo/.git/goals/done-42" \
  && ok "l'esito e' registrato nello storico" || ko "done senza esito"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
