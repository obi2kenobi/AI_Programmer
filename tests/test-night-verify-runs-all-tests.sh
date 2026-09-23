#!/bin/bash
# test-night-verify-runs-all-tests.sh — 4° ciclo, SET 1 giro 4: bug reale trovato
# leggendo la storia di .night-verify (git log -p). La riga delle verifiche dichiarate
# del HUB elencava 4 test per nome (test-lib, test-gate-tools, test-ask-wrappers,
# test-privacy), ferma dall'"autogiro 5/10" — i 23+ file tests/test-*.sh accumulati nei
# cicli successivi (Set 2, Set 3, questo) non erano mai stati aggiunti: il gate che
# impone a ogni altra repo "dichiara le tue verifiche" non applicava a se stesso la
# propria regola ("verifiche-vuote" per omissione, non per il file intero ma per singoli
# test dimenticati). Sostituito con un loop: verifica che non regredisca a un elenco fisso.
# (E-029, 2026-09-18): il loop e' migrato in tools/suite.sh (.night-verify e' un
# comando per riga) — il guardiano segue il codice dove vive.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
NV="$HERE/.night-verify"
RUNNER="$HERE/tools/suite.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -Eq "^(@[0-9]+ )?bash tools/suite\.sh$" "$NV" \
  && ok ".night-verify invoca il runner della suite (un comando per riga)" \
  || ko ".night-verify non invoca piu' il runner — verifiche-vuote per omissione?"

grep -Eq '^for t in tests/test-\*\.sh' "$RUNNER" \
  && ok "il runner usa un loop su tests/test-*.sh (non un elenco fisso)" \
  || ko "il runner non contiene piu' il loop — regredito a un elenco per nome?"

# non deve restare nessuna riga che invoca UN test per nome fisso (regressione all'elenco)
NOMINATI=$(grep -oE 'bash tests/test-[a-z0-9-]+\.sh' "$NV" || true)
[ -z "$NOMINATI" ] && ok "nessun test è più invocato per nome fisso in .night-verify (solo via runner)" \
  || ko "test ancora invocati per nome fisso, fuori dal runner: $NOMINATI"

# il glob del runner deve davvero includere OGNI file tests/test-*.sh presente oggi
# (revisione 10 giri, 2026-09-23): N_MATCH era lo STESSO comando di N_REALI — una tautologia
# che non poteva fallire. Ora il glob si legge dal runner vero (tools/suite.sh, il suo `for`).
N_REALI=$(cd "$HERE" && ls tests/test-*.sh | wc -l | tr -d ' ')
GLOB_RUNNER=$(grep -oE '^for t in [^;]+' "$HERE/tools/suite.sh" | head -1 | awk '{print $4}')
N_MATCH=$(cd "$HERE" && ls $GLOB_RUNNER 2>/dev/null | wc -l | tr -d ' ')
[ "$N_MATCH" -eq "$N_REALI" ] && [ "$N_REALI" -gt 20 ] \
  && ok "il glob del runner copre tutti i $N_REALI file di test presenti oggi" \
  || ko "il glob copre $N_MATCH file su $N_REALI presenti — non tutti raggiunti"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
