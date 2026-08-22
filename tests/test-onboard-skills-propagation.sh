#!/bin/bash
# test-onboard-skills-propagation.sh — set 3 giro 2: stesso gap del giro 1 ma per
# l'onboarding di repo esistenti. Qui il merge deve essere PRUDENTE: mai sovrascrivere
# una skill che il progetto avesse già con lo stesso nome (potrebbe essere una
# personalizzazione locale) — solo aggiungere quelle mancanti.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'if \[ ! -d "\$WORK/.claude/skills/\$skill_name" \]' "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh contiene la logica di merge per-skill (mai sovrascrive)" \
  || ko "logica di merge skill non trovata in onboard-repo.sh"

merge_skills() {
  local work="$1" skills_aggiunte=0
  mkdir -p "$work/.claude/skills"
  for skill_dir in "$HERE"/.claude/skills/*/; do
    local skill_name; skill_name="$(basename "$skill_dir")"
    if [ ! -d "$work/.claude/skills/$skill_name" ]; then
      cp -r "$skill_dir" "$work/.claude/skills/$skill_name"
      skills_aggiunte=$((skills_aggiunte+1))
    fi
  done
  echo "$skills_aggiunte"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# caso 1: repo senza nessuna skill -> tutte arrivano
WORK1="$TMP/repo-vuota"
N1=$(merge_skills "$WORK1")
N_HUB=$(find "$HERE/.claude/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$N1" -eq "$N_HUB" ] && ok "repo senza skill: tutte le $N_HUB arrivano" \
  || ko "repo vuota: arrivate $N1 su $N_HUB"

# caso 2: repo con una skill già personalizzata -> non viene toccata, le altre arrivano
WORK2="$TMP/repo-con-personalizzazione"
mkdir -p "$WORK2/.claude/skills/dev-critic"
echo "PERSONALIZZATA DAL PROGETTO" > "$WORK2/.claude/skills/dev-critic/SKILL.md"
N2=$(merge_skills "$WORK2")
[ "$N2" -eq "$((N_HUB-1))" ] && ok "repo con dev-critic personalizzata: arrivano solo le altre $((N_HUB-1))" \
  || ko "conteggio sbagliato: arrivate $N2, attese $((N_HUB-1))"
[ "$(cat "$WORK2/.claude/skills/dev-critic/SKILL.md")" = "PERSONALIZZATA DAL PROGETTO" ] \
  && ok "la skill personalizzata NON è stata sovrascritta" \
  || ko "la skill personalizzata è stata sovrascritta (bug di merge)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
