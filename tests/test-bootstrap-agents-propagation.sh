#!/bin/bash
# test-bootstrap-agents-propagation.sh — 5° ciclo, set 1 giro 5: stesso gap già corretto
# per .claude/skills/ e patterns/ (set 3, 4° ciclo), mai applicato a .claude/agents/ (i
# subagent Claude Code, distinti dalle skill) — non venivano copiati in un progetto
# bootstrappato. Isola solo la logica di copia (non l'intero script, che richiede gh
# autenticato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'cp -r "\$HERE/.claude/agents/." .claude/agents/' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh contiene la riga di copia di .claude/agents/" \
  || ko "riga di copia .claude/agents/ non trovata in bootstrap-app.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && mkdir -p .claude/agents && cp -r "$HERE/.claude/agents/." .claude/agents/ )

N_HUB=$(find "$HERE/.claude/agents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
N_COPIATI=$(find "$TMP/.claude/agents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
[ "$N_COPIATI" -eq "$N_HUB" ] && [ "$N_COPIATI" -gt 0 ] \
  && ok "tutti i $N_HUB agenti del hub arrivano al progetto nuovo" \
  || ko "copiati $N_COPIATI agenti su $N_HUB nel hub"

for agente in contabilita-analitica costruttore-calcoli-gestionali revisore-calcoli-critici; do
  [ -f "$TMP/.claude/agents/$agente.md" ] && ok "agente '$agente' presente nel progetto copiato" \
    || ko "agente '$agente' assente dopo la copia"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
