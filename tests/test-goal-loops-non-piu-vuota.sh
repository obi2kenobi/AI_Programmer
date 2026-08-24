#!/bin/bash
# test-goal-loops-non-piu-vuota.sh — 5° ciclo, set 3 giro 6. METHOD.md e
# goal/SKILL.md dicevano ancora "loops/ è vuota" dopo che il Set 2 giro 3 di questo
# ciclo aveva eseguito il primo loop reale — la prosa non seguiva più i fatti.
# Verifica che loops/ contenga davvero più del solo README, e che nessuno dei due
# file affermi ancora il contrario.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

N_LOG=$(find "$HERE/loops" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
[ "$N_LOG" -gt 0 ] && ok "loops/ contiene $N_LOG log reale/i, non solo il README" \
  || ko "loops/ contiene ancora solo il README — nessun loop mai eseguito"

grep -q 'loops/.*è rimasta vuota\b' "$HERE/METHOD.md" 2>/dev/null \
  && ko "METHOD.md afferma ancora che loops/ è vuota" \
  || ok "METHOD.md non afferma più che loops/ è vuota"

# goal/SKILL.md può ancora raccontare che loops/ ERA vuota (storia vera, utile) — ma
# solo se lo qualifica al passato ("finché"), non come stato attuale.
if grep -q 'è rimasta vuota' "$HERE/.claude/skills/goal/SKILL.md"; then
  grep -q 'è rimasta vuota.\{0,40\}finché' "$HERE/.claude/skills/goal/SKILL.md" \
    && ok "goal/SKILL.md qualifica 'era vuota' al passato (finché...), non come stato attuale" \
    || ko "goal/SKILL.md afferma 'è rimasta vuota' senza qualificarlo al passato"
else
  ok "goal/SKILL.md non menziona più lo stato vuoto di loops/"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
