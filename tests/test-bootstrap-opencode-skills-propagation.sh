#!/bin/bash
# test-bootstrap-opencode-skills-propagation.sh — banco di regressione nato dalla
# revisione "L'Hub Allo Specchio" (14 lenti indipendenti, 2026-08-28): .opencode/skills/
# non veniva mai copiato per un progetto bootstrappato da zero — root cause della
# divergenza fra .claude/skills e .opencode/skills. Isola solo la logica di copia (non
# l'intero script, che richiede gh autenticato), come gli altri test di propagazione.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'cp -r "\$HERE/.opencode/skills/." .opencode/skills/' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh contiene la riga di copia di .opencode/skills/" \
  || ko "riga di copia .opencode/skills/ non trovata in bootstrap-app.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && mkdir -p .opencode/skills && cp -r "$HERE/.opencode/skills/." .opencode/skills/ )

N_HUB=$(find "$HERE/.opencode/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
N_COPIATE=$(find "$TMP/.opencode/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$N_COPIATE" -eq "$N_HUB" ] && [ "$N_COPIATE" -gt 0 ] \
  && ok "tutte le $N_HUB skill OpenCode del hub arrivano al progetto nuovo" \
  || ko "copiate $N_COPIATE skill OpenCode su $N_HUB nel hub"

for skill_dir in "$HERE"/.opencode/skills/*/; do
  skill="$(basename "$skill_dir")"
  [ -d "$TMP/.opencode/skills/$skill" ] && ok "skill OpenCode '$skill' presente nel progetto copiato" \
    || ko "skill OpenCode '$skill' assente dopo la copia"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
