#!/bin/bash
# test-design-doc-criteri-punteggio.sh — 4° ciclo, SET 2 "progettare" giro 1. /design-doc
# produceva opzioni con trade-off narrativi liberi — confrontabili solo a occhio, e
# vulnerabili a criteri diversi scelti a posteriori per far vincere l'opzione preferita
# (il difetto che questo giro chiude). Verifica che il metodo dichiari i criteri PRIMA
# delle opzioni, li applichi con una tabella opzioni×criteri, e non trasformi il
# punteggio in una raccomandazione implicita — la scelta resta sempre di chi possiede
# il progetto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "Dichiara i criteri di confronto PRIMA delle opzioni" "$DD" \
  && ok "i criteri si dichiarano prima delle opzioni, non dopo" \
  || ko "nessun passo impone di dichiarare i criteri prima"

grep -qE "costo.*rischio.*reversibilità|rischio.*reversibilità.*costo" "$DD" \
  && ok "i tre criteri di base (costo, rischio, reversibilità) sono nominati" \
  || ko "i criteri di base non sono più nominati"

grep -q "tabella opzioni×criteri\|tabella\b.*opzioni" "$DD" \
  && ok "il formato richiede una tabella opzioni×criteri, non prosa libera" \
  || ko "nessun riferimento alla tabella di confronto"

grep -qE "non lo decide|non trasformare la tabella in|resta all'utente|resta di chi possiede" "$DD" \
  && ok "il punteggio struttura ma non decide — la scelta resta dell'utente" \
  || ko "manca la clausola che il punteggio non sostituisce la decisione umana"

grep -q "criteri diversi.*posteriori\|criteri diversi per ogni opzione" "$DD" \
  && ok "vieta criteri diversi a posteriori (confronto truccato)" \
  || ko "non vieta più il confronto truccato con criteri a posteriori"

# l'esempio in §1bis deve essere una tabella markdown reale (non solo prosa che ne parla)
grep -c '^|.*|.*|.*|.*|$' "$DD" | grep -q '^[1-9]' \
  && ok "esiste almeno una tabella markdown reale nell'esempio (non solo descritta)" \
  || ko "nessuna tabella markdown trovata — l'esempio resta solo prosa"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
