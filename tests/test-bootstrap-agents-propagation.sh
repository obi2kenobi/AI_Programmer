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
( cd "$TMP" && mkdir -p .claude/agents && cp -r "$HERE/.claude/agents/." .claude/agents/ \
  && mkdir -p .opencode/agent && cp -r "$HERE/.opencode/agent/." .opencode/agent/ )

N_HUB=$(find "$HERE/.claude/agents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
N_COPIATI=$(find "$TMP/.claude/agents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
[ "$N_COPIATI" -eq "$N_HUB" ] && [ "$N_COPIATI" -gt 0 ] \
  && ok "tutti i $N_HUB agenti del hub arrivano al progetto nuovo" \
  || ko "copiati $N_COPIATI agenti su $N_HUB nel hub"

# 5° ciclo, set 2 giro 9: qui sotto stava una lista di 3 nomi fissi — lo stesso identico
# bug appena trovato in test-bootstrap-skills-propagation.sh, scritto da me in questo
# stesso ciclo (giro 5) prima di aver imparato la lezione al giro 1/8. Un quarto agente
# futuro sarebbe passato inosservato qui esattamente come controllo-gestione lo è stato
# nell'altro file.
for agent_file in "$HERE"/.claude/agents/*.md; do
  agente="$(basename "$agent_file" .md)"
  [ -f "$TMP/.claude/agents/$agente.md" ] && ok "agente '$agente' presente nel progetto copiato" \
    || ko "agente '$agente' assente dopo la copia"
done

# 6° ciclo, set 3: anche lo specchio OpenCode arriva al progetto nuovo
grep -q 'cp -r "\$HERE/.opencode/agent/." .opencode/agent/' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh copia anche .opencode/agent/ (la notte usa OpenCode)" \
  || ko "bootstrap-app.sh non copia .opencode/agent/"
N_OP_HUB=$(find "$HERE/.opencode/agent" -maxdepth 1 -mindepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
N_OP_COPIATI=$(find "$TMP/.opencode/agent" -maxdepth 1 -mindepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
[ "$N_OP_COPIATI" -eq "$N_OP_HUB" ] && [ "$N_OP_COPIATI" -gt 0 ] \
  && ok "tutti i $N_OP_HUB agenti OpenCode arrivano al progetto nuovo" \
  || ko "copiati $N_OP_COPIATI agenti OpenCode su $N_OP_HUB nel hub"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
