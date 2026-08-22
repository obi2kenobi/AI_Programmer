#!/bin/bash
# test-bootstrap-skills-propagation.sh — set 3 giro 1: le skill del hub (dev-critic,
# audit-commessa, verifica-visiva, design-doc, brainstorming, goal) non venivano mai
# copiate in un progetto bootstrappato — CLAUDE.md (le regole) viaggiava da sempre, gli
# strumenti che quelle regole presuppongono no. Isola solo la logica di copia (non l'intero
# script, che richiede gh autenticato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'cp -r "\$HERE/.claude/skills/." .claude/skills/' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh contiene la riga di copia di .claude/skills/" \
  || ko "riga di copia .claude/skills/ non trovata in bootstrap-app.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && mkdir -p .claude/skills && cp -r "$HERE/.claude/skills/." .claude/skills/ )

N_HUB=$(find "$HERE/.claude/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
N_COPIATE=$(find "$TMP/.claude/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$N_COPIATE" -eq "$N_HUB" ] && [ "$N_COPIATE" -gt 0 ] \
  && ok "tutte le $N_HUB skill del hub arrivano al progetto nuovo" \
  || ko "copiate $N_COPIATE skill su $N_HUB nel hub"

for skill in dev-critic audit-commessa verifica-visiva design-doc brainstorming goal; do
  [ -f "$TMP/.claude/skills/$skill/SKILL.md" ] && ok "skill '$skill' presente nel progetto copiato" \
    || ko "skill '$skill' assente dopo la copia"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
