#!/bin/bash
# test-onboard-opencode-skills-propagation.sh — banco di regressione nato dalla revisione
# "L'Hub Allo Specchio" (14 lenti indipendenti, 2026-08-28): .opencode/skills/ non era mai
# propagato dall'onboarding — root cause della divergenza fra .claude/skills e
# .opencode/skills trovata da 3 lenti indipendenti. Stesso merge prudente per-skill già
# usato per .claude/skills/.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'mkdir -p "\$WORK/.opencode/skills"' "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh contiene la logica di merge per .opencode/skills (mai sovrascrive)" \
  || ko "logica di merge .opencode/skills non trovata in onboard-repo.sh"

merge_opencode_skills() {
  local work="$1" aggiunte=0
  mkdir -p "$work/.opencode/skills"
  for skill_dir in "$HERE"/.opencode/skills/*/; do
    local skill_name; skill_name="$(basename "$skill_dir")"
    if [ ! -d "$work/.opencode/skills/$skill_name" ]; then
      cp -r "$skill_dir" "$work/.opencode/skills/$skill_name"
      aggiunte=$((aggiunte+1))
    fi
  done
  echo "$aggiunte"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
N_HUB=$(find "$HERE/.opencode/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')

WORK1="$TMP/repo-vuota"
N1=$(merge_opencode_skills "$WORK1")
[ "$N1" -eq "$N_HUB" ] && ok "repo senza skill OpenCode: tutte le $N_HUB arrivano" \
  || ko "repo vuota: arrivate $N1 su $N_HUB"

WORK2="$TMP/repo-con-personalizzazione"
mkdir -p "$WORK2/.opencode/skills/graphify"
echo "PERSONALIZZATO DAL PROGETTO" > "$WORK2/.opencode/skills/graphify/SKILL.md"
N2=$(merge_opencode_skills "$WORK2")
if [ -d "$HERE/.opencode/skills/graphify" ]; then EXPECTED=$((N_HUB-1)); else EXPECTED=$N_HUB; fi
[ "$N2" -eq "$EXPECTED" ] && ok "repo con graphify personalizzata: arrivano solo le altre $((N_HUB-1))" \
  || ko "conteggio sbagliato: arrivate $N2, attese $((N_HUB-1))"
[ "$(cat "$WORK2/.opencode/skills/graphify/SKILL.md")" = "PERSONALIZZATO DAL PROGETTO" ] \
  && ok "la skill OpenCode personalizzata NON è stata sovrascritta" \
  || ko "la skill OpenCode personalizzata è stata sovrascritta (bug di merge)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
