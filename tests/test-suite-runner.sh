#!/bin/bash
# test-suite-runner.sh — tools/suite.sh sotto prova (E-029: era una riga composta
# in .night-verify sopravvissuta per caso). Prova il runner su una suite finta:
# tutti verdi → rc 0 e riepilogo N/TOT; uno rosso → rc 1, nome e output del file.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$HERE/tools/suite.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$RUNNER" && ok "sintassi" || { ko "sintassi"; exit 1; }

SB=$(mktemp -d /tmp/test-suite.XXXXXX); trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/tests"
printf '#!/bin/bash\necho "vero"\n' > "$SB/tests/test-uno.sh"
printf '#!/bin/bash\necho "anchesso"\n' > "$SB/tests/tests-due.sh" 2>/dev/null || true
printf '#!/bin/bash\necho "vero due"\n' > "$SB/tests/test-due.sh"

# 1. tutti verdi: rc 0, riepilogo 2/2
OUT=$(bash "$RUNNER" "$SB" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "tutti verdi: rc 0" || ko "rc $RC con suite tutta verde"
echo "$OUT" | grep -q "2/2 file superati" && ok "riepilogo N/TOT presente" || ko "riepilogo mancante: $OUT"

# 2. uno rosso: rc 1, NOME del file e suo output (la lezione del giro 7)
printf '#!/bin/bash\necho "dettaglio importante del fallimento"\nexit 7\n' > "$SB/tests/test-tre.sh"
OUT=$(bash "$RUNNER" "$SB" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "uno rosso: rc 1" || ko "rc $RC con un test rosso"
echo "$OUT" | grep -q "test-tre.sh" && ok "il file fallito viene nominato" || ko "non nomina il file fallito"
echo "$OUT" | grep -q "dettaglio importante" && ok "l'output del fallito si vede" || ko "output del fallito perso"

# 3. zero test: rosso dichiarato (verifiche-vuote non passano inosservate)
SB2=$(mktemp -d /tmp/test-suite2.XXXXXX)
mkdir -p "$SB2/tests"
OUT=$(bash "$RUNNER" "$SB2" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "zero test: rc 1 (verifiche-vuote subite)" || ko "rc $RC con zero test"
rm -rf "$SB2"

# 4. il runner e' dichiarato in .night-verify come UN COMANDO per riga
grep -q "^bash tools/suite.sh$" "$HERE/.night-verify" && ok "dichiarato in .night-verify" \
  || ko ".night-verify non invoca suite.sh"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
