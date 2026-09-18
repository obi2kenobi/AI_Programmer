#!/bin/bash
# suite.sh — il runner della suite di test dell'hub (un comando per riga, E-029).
#
# Storia: questa riga viveva composta dentro .night-verify (`N=0; TOT=$(...);
# for t in ...`) e sopravviveva PER CASO: il turno antepone `ai_timeout 120` a
# ogni riga, l'assegnazione iniziale diventava argomento del comando, e solo il
# fatto che l'ULTIMO comando fosse un echo la teneva verde. Scoperto da E-029
# (2026-09-18): il contratto di .night-verify e' UN COMANDO per riga. La riga
# diventa tool: testabile, citabile, con una porta.
#
# Porta con se' le due lezioni del report del gate (4° ciclo, 2026-08-23):
# 1. l'elenco per nome lasciava fuori i test nuovi — il loop li prende tutti;
# 2. il report mostra solo il tail: serve un riepilogo esplicito N/TOT sempre
#    visibile, e sul fallimento QUALE file e il suo output.
#
# Uso: suite.sh [dir-repo]   (default: la radice del repo che lo contiene)
# Esce: 0 = tutti i test superati · 1 = almeno un test fallito (o zero test)
set -uo pipefail
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$DIR"

N=0
TOT=$(ls tests/test-*.sh 2>/dev/null | wc -l | tr -d ' ')
[ "$TOT" -eq 0 ] && { echo "⛔ suite: nessun tests/test-*.sh trovato"; exit 1; }
for t in tests/test-*.sh; do
  N=$((N+1))
  OUT=$(bash "$t" 2>&1) || {
    echo "FALLITO ($N/$TOT): $t"
    echo "$OUT" | tail -10
    exit 1
  }
done
echo "Suite test hub: $N/$TOT file superati"
