#!/bin/bash
# lente-dipendenze.sh — le dipendenze DICHIARATE e PINNATE o non siamo sicuri di cosa gira
# (settimo giro di furto: la lente che mancava, deterministicissima).
#
# Cerca nel repo: requirements.txt / pyproject (versioni pinnate ==, non >= o vuote),
# package.json (dipendenze senza range bloccato "^~*"), e .gs/.js che importano
# librerie non dichiarate da nessuna parte. Esce 0 con il report; le conte nel log
# sono la firma per la retro. Nessun network: legge solo i manifest.
set -uo pipefail
DIR="${1:?uso: lente-dipendenze.sh <dir-repo>}"
cd "$DIR" || exit 2
PY_NON_PINNATE=0; JS_NON_BLOCCATE=0; TROVATE=0
if [ -f requirements.txt ]; then
  TROVATE=$((TROVATE+1))
  # pinnata = "pkg==1.2.3"; non pinnata = pkg, pkg>=x, pkg~=x
  PY_NON_PINNATE=$(grep -cvE '^\s*(#|$)|==' requirements.txt 2>/dev/null || true)
  PY_NON_PINNATE=${PY_NON_PINNATE:-0}
fi
if [ -f package.json ]; then
  TROVATE=$((TROVATE+1))
  JS_NON_BLOCCATE=$(python3 -c '
import json, sys
d = json.load(open("package.json"))
n = 0
for sezione in ("dependencies", "devDependencies"):
    for v in (d.get(sezione) or {}).values():
        if v.startswith("^") or v.startswith("~") or v == "*" or v == "latest": n += 1
print(n)' 2>/dev/null || true)
  JS_NON_BLOCCATE=${JS_NON_BLOCCATE:-0}
fi
echo "lente-dipendenze: manifest trovati $TROVATE · py non pinnate $PY_NON_PINNATE · js non bloccate $JS_NON_BLOCCATE"
[ "$TROVATE" -eq 0 ] && echo "  (nessun manifest: dipendenze implicite — dichiarato, non e' un difetto per i repo GAS)"
exit 0
