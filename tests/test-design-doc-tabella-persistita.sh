#!/bin/bash
# test-design-doc-tabella-persistita.sh — 4° ciclo, SET 2 giro 3. Il giro 1 ha aggiunto
# la tabella opzioni×criteri al METODO di /design-doc, ma §2 (dove va a vivere il
# documento) non diceva se quella tabella dovesse arrivare nel documento persistito
# (SAL.md/docs/design/) o restare solo nella conversazione — esattamente il rischio che
# la regola CLAUDE.md "Keep living documentation, not just commits" esiste per chiudere.
# Senza questa riga, chi legge la voce SAL fra sei mesi vedrebbe la scelta ma non il
# confronto che l'ha prodotta.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# la riga deve stare in ## 2 (dove va a vivere), non solo nel metodo del punto 3
SEZ2=$(awk '/^## 2\./{f=1} /^## 3\./{f=0} f' "$DD")
echo "$SEZ2" | grep -q "tabella opzioni×criteri" \
  && ok "§2 (persistenza) richiede esplicitamente la tabella opzioni×criteri" \
  || ko "§2 non menziona la tabella — potrebbe restare solo in chat"

echo "$SEZ2" | grep -qi "non solo la scelta finale in prosa\|non solo\b" \
  && ok "§2 esclude esplicitamente 'solo la scelta in prosa' come persistenza sufficiente" \
  || ko "§2 non esclude la persistenza minimale (solo prosa)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
