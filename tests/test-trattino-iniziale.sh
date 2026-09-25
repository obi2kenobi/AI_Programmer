#!/bin/bash
# test-trattino-iniziale.sh — (2026-09-24, sesto ventaglio, rinviati di S3 R6): una cartella relativa che
# comincia col trattino («-sat») veniva letta come opzione. `cd "$DIR"` diceva «dir inesistente» (e gas-gate
# proseguiva nella cartella del chiamante), `mkdir` moriva, `basename` usciva vuoto e lo strumento andava
# avanti. Ogni strumento qui sotto riceve «-sat» e non deve mai dire «invalid option» o «missing operand».
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
cd "$T" || exit 1
mkdir -p -- -sat/tests -sat2
printf '#!/bin/bash\necho "1 OK, 0 FAIL"\n' > -sat/tests/test-ok.sh
printf '# DEBITI\n' > -sat/DEBITI.md
git -C ./-sat init -q
printf 'function f() { return 1; }\n' > -sat/Codice.gs; git -C ./-sat add Codice.gs

prova() { # prova <descrizione> <rc atteso o -> <comando...>
  local desc="$1" atteso="$2"; shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  if grep -cE 'invalid option|missing operand|inesistente' <<<"$out" >/dev/null; then
    ko "$desc: il trattino letto come opzione: $(grep -m1 -E 'invalid option|missing operand|inesistente' <<<"$out")"
  elif [ "$atteso" != "-" ] && [ "$rc" -ne "$atteso" ]; then
    ko "$desc: rc=$rc (atteso $atteso): $(tail -1 <<<"$out")"
  else
    ok "$desc"
  fi
  ULTIMA="$out"
}

prova "suite.sh -sat esegue i banchi di -sat" 0 bash "$HERE/tools/suite.sh" -sat
prova "gas-gate.sh -sat giudica -sat, non la cartella del chiamante" 0 bash "$HERE/tools/gas-gate.sh" -sat
prova "debiti-riapertura.sh -sat legge il DEBITI.md di -sat" 0 bash "$HERE/tools/debiti-riapertura.sh" -sat
prova "copia-hook.sh -sat copia i ganci" 0 bash "$HERE/tools/copia-hook.sh" -sat
prova "polilivello.sh -sat" - bash "$HERE/tools/polilivello.sh" -sat
grep -cF 'Scaffold polilivello — -sat' <<<"$ULTIMA" >/dev/null && ok "polilivello: il titolo nomina -sat" \
  || ko "polilivello: il titolo non nomina -sat: $(grep -m1 'Scaffold' <<<"$ULTIMA")"
prova "fork-stato.sh -sat -sat2" - bash "$HERE/tools/fork-stato.sh" -sat -sat2

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
