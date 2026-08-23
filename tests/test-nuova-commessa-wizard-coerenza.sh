#!/bin/bash
# test-nuova-commessa-wizard-coerenza.sh — 4° ciclo, SET 2 giro 6. Il wizard
# .zcode-commands-nuova-commessa.md (mai testato prima) descriveva ancora /design-doc
# come "opzioni con trade-off già scelte" dopo che i giri 1-4 del Set 2 avevano cambiato
# il meccanismo reale (criteri espliciti + tabella opzioni×criteri) — stessa staleness
# già trovata e corretta in METHOD.md/docs/system.md al giro 5, mai propagata qui.
# Verifica anche che gli strumenti citati (graphify, il gate) esistano davvero.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
W="$HERE/.zcode-commands-nuova-commessa.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$W" ] && ok "il file del wizard esiste" || { ko "il wizard non esiste più"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

! grep -q "opzioni con trade-off già scelte" "$W" \
  && ok "non descrive più design-doc con la vecchia formula (trade-off narrativo)" \
  || ko "descrive ancora design-doc con la formula superata"

grep -q "criteri espliciti" "$W" \
  && ok "descrive design-doc col meccanismo reale (criteri espliciti)" \
  || ko "non descrive il meccanismo reale di design-doc"

grep -q "graphify" "$W" \
  && ok "il wizard cita graphify per il territorio" \
  || ko "il wizard non cita più graphify"

[ -d "$HERE/.opencode/skills/graphify" ] || [ -f "$HERE/AGENTS.md" ] \
  && ok "graphify citato ha davvero un posto dove vivere (skill o AGENTS.md)" \
  || ko "graphify citato ma nessuna fonte reale nel repo"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
