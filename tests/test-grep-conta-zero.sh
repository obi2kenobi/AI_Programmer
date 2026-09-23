#!/bin/bash
# test-grep-conta-zero.sh — la lente del «doppio zero» (revisione 10 giri, 2026-09-23).
#
# `N=$(grep -c X file || echo 0)`: quando X non c'e', grep -c STAMPA 0 ed ESCE 1 — l'echo
# aggiunge un secondo 0 e N vale «0\n0». Non e' un intero: `[ "$N" -eq 0 ]` e' un errore di
# sintassi, cioe' FALSO. Misurato su night-shift/revisore.sh: un .night-verify di soli
# commenti sulla base non veniva visto come «verifiche-vuote» e la PR arrivava al merge.
# Stessa forma in altri sei siti (digest, ciclo-vivo, due test). La forma giusta:
#   N=$(grep -c X file 2>/dev/null || true); N=${N:-0}
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# la ragione della lente, eseguita: se un giorno grep smettesse di uscire 1 a zero, la
# lente sarebbe superflua e questo lo direbbe
X=$(printf 'a\n' | grep -c zzz || echo 0)
[ "$X" = $'0\n0' ] && ok "la forma produce davvero «0\\n0» (la lente ha ragione di esistere)" \
  || ko "grep -c || echo 0 da' '$X': rivedere la lente"

# righe di CODICE (non commenti) con grep -c… || echo 0 negli script dell'hub
FILES=$(ls "$HERE"/night-shift/*.sh "$HERE"/tools/*.sh "$HERE"/tests/*.sh "$HERE"/llm/*.sh 2>/dev/null | grep -v '/test-grep-conta-zero.sh$')
S=$(grep -nE 'grep +-[a-zA-Z]*c.*\|\| *echo +0' $FILES 2>/dev/null | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#' || true)
[ -z "$S" ] && ok "nessun grep -c … || echo 0 nel codice (forma: || true; N=\${N:-0})" \
  || ko "doppio zero possibile:"$'\n'"$S"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
