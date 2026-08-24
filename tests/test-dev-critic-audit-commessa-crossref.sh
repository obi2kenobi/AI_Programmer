#!/bin/bash
# test-dev-critic-audit-commessa-crossref.sh — 5° ciclo, set 3 giro 8. Sweep sistematico
# di tutte le citazioni fra skill/agenti (grep su ogni file, non uno alla volta a
# occhio): audit-commessa dichiara già "non sostituisce dev-critic", ma dev-critic non
# diceva mai nulla su audit-commessa — la relazione era dichiarata da una sola parte,
# rischio di confondere le due skill senza un aiuto reciproco a distinguerle.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DC="$HERE/.claude/skills/dev-critic/SKILL.md"
AC="$HERE/.claude/skills/audit-commessa/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "dev-critic" "$AC" \
  && ok "audit-commessa cita dev-critic (direzione 1, preesistente)" \
  || ko "audit-commessa non cita più dev-critic"

grep -q "audit-commessa" "$DC" \
  && ok "dev-critic ora cita audit-commessa (direzione 2, chiusa in questo giro)" \
  || ko "dev-critic non cita audit-commessa — relazione ancora mono-direzionale"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
