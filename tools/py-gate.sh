#!/bin/bash
# py-gate.sh — il gate che compila ogni .py tracciato (nato da E-028, 2026-09-17).
#
# La dashboard era stata committata NON compilante e passava, perche' nessun gate
# ESEGUIVA la sintassi dei .py — le sonde li leggevano solo con regex, e una riga
# fusa passa tutte le regex. Poi (E-029) la prima versione di questo gate, scritta
# come riga composta dentro .night-verify, diventava un FALSO ROSSO ogni notte:
# il turno antepone `ai_timeout 120` a ogni riga, e `PYFAIL=0; for...` non e' un
# comando solo — l'assegnazione diventava argomento e la riga moriva di unary.
# Contratto di .night-verify: UN COMANDO per riga, eseguibile da timeout(1).
# Da qui un tool: testabile, citabile, con una porta.
#
# Uso: py-gate.sh [dir]   (default: la radice del repo che lo contiene)
# Esce: 0 = tutti i .py compilano · 1 = almeno uno non compila (nome stampato)
set -uo pipefail
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -d "$DIR" ] || { echo "⛔ py-gate: dir inesistente: $DIR" >&2; exit 1; }

ROTTI=0
while IFS= read -r f; do
  # compile() esegue la sintassi senza scrivere __pycache__ (py_compile lo scrive)
  if ! python3 -c "import sys; compile(open(sys.argv[1]).read(), sys.argv[1], 'exec')" "$f" 2>/dev/null; then
    echo "⛔ python non compila: $f"
    ROTTI=$((ROTTI+1))
  fi
done < <(cd "$DIR" && git ls-files '*.py' 2>/dev/null)

if [ "$ROTTI" -ne 0 ]; then
  echo "py-gate: $ROTTI file rotti"
  exit 1
fi
echo "Sintassi python: tutti i .py compilano ($(cd "$DIR" && git ls-files '*.py' | wc -l | tr -d ' ') file)"
