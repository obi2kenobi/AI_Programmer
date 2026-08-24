#!/bin/bash
# test-pipeline-diagrammi-mostrano-i-rami.sh — 5° ciclo, set 3 giro 2. I diagrammi in
# cima a METHOD.md e docs/system.md mostravano il flusso "brainstorming → design-doc →
# commessa → notte" come una linea retta — ma il metodo reale, dopo il ciclo precedente
# e il Set 2 di questo ciclo, ha due rami che il diagramma non mostrava: design-doc può
# tornare a brainstorming (nessuna opzione buona, giro 7) e può instradare a /goal invece
# che a commessa/notte per un territorio piccolo (4° ciclo, set 2 giro 10). Un diagramma
# che mostra solo la strada notturna fa sembrare quella l'unica strada.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

for f in METHOD.md docs/system.md; do
  BODY=$(cat "$HERE/$f")
  echo "$BODY" | grep -q "/goal" \
    && ok "$f: il diagramma cita il ramo /goal (territorio piccolo)" \
    || ko "$f: il diagramma non cita /goal — mostra solo la strada notturna"
  echo "$BODY" | grep -qi "torna a brainstorming\|brainstorming ⇄" \
    && ok "$f: il diagramma mostra il ritorno a /brainstorming se nessuna opzione è buona" \
    || ko "$f: il diagramma non mostra il loopback verso /brainstorming"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
