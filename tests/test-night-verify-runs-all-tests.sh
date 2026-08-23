#!/bin/bash
# test-night-verify-runs-all-tests.sh — 4° ciclo, SET 1 giro 4: bug reale trovato
# leggendo la storia di .night-verify (git log -p). La riga delle verifiche dichiarate
# del HUB elencava 4 test per nome (test-lib, test-gate-tools, test-ask-wrappers,
# test-privacy), ferma dall'"autogiro 5/10" — i 23+ file tests/test-*.sh accumulati nei
# cicli successivi (Set 2, Set 3, questo) non erano mai stati aggiunti: il gate che
# impone a ogni altra repo "dichiara le tue verifiche" non applicava a se stesso la
# propria regola ("verifiche-vuote" per omissione, non per il file intero ma per singoli
# test dimenticati). Sostituito con un loop: verifica che non regredisca a un elenco fisso.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
NV="$HERE/.night-verify"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -qE 'for .* in tests/test-\*\.sh' "$NV" \
  && ok ".night-verify usa un loop su tests/test-*.sh (non un elenco fisso)" \
  || ko ".night-verify non contiene più il loop — regredito a un elenco per nome?"

# non deve restare nessuna riga che invoca UN test per nome fisso (regressione all'elenco)
NOMINATI=$(grep -oE 'bash tests/test-[a-z0-9-]+\.sh' "$NV" || true)
[ -z "$NOMINATI" ] && ok "nessun test è più invocato per nome fisso (solo via loop)" \
  || ko "test ancora invocati per nome fisso, fuori dal loop: $NOMINATI"

# il loop deve davvero includere OGNI file tests/test-*.sh presente oggi nel repo —
# lo verifichiamo estraendo il pattern glob dal file ed eseguendolo per davvero
N_REALI=$(cd "$HERE" && ls tests/test-*.sh | wc -l | tr -d ' ')
N_MATCH=$(cd "$HERE" && GLOB=$(grep -oE 'tests/test-\*\.sh' "$NV" | head -1) && ls $GLOB | wc -l | tr -d ' ')
[ "$N_MATCH" -eq "$N_REALI" ] && [ "$N_REALI" -gt 20 ] \
  && ok "il glob del loop copre tutti i $N_REALI file di test presenti oggi" \
  || ko "il glob copre $N_MATCH file su $N_REALI presenti — non tutti raggiunti"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
