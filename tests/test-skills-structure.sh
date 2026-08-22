#!/bin/bash
# test-skills-structure.sh — set 2: le skill sono prosa per Claude, non codice eseguibile,
# ma possono comunque essere verificate: frontmatter YAML valido (name/description),
# stile consistente con le skill esistenti (dev-critic/audit-commessa/verifica-visiva),
# e ogni percorso citato nel corpo esiste davvero (altrimenti è la stessa "citazione
# senza presidio" che ha causato il debito che questo giro chiude).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

check_skill_frontmatter() {
  local nome="$1" path="$2"
  [ -f "$path" ] && ok "$nome: SKILL.md esiste" || { ko "$nome: SKILL.md assente"; return; }
  [ "$(sed -n '1p' "$path")" = "---" ] && ok "$nome: apre con frontmatter YAML" \
    || ko "$nome: non apre con ---"
  grep -q "^name: $nome$" "$path" && ok "$nome: campo 'name' presente e corretto" \
    || ko "$nome: campo 'name' assente o diverso dalla directory"
  grep -q "^description: .\{100,\}" "$path" && ok "$nome: description sostanziosa (non un placeholder)" \
    || ko "$nome: description troppo corta o assente"
  local closing
  closing=$(awk 'NR>1 && /^---$/{print NR; exit}' "$path")
  [ -n "$closing" ] && ok "$nome: frontmatter chiuso correttamente" || ko "$nome: frontmatter senza chiusura ---"
}

check_referenced_paths() {
  local nome="$1" path="$2"
  # estrae percorsi citati in backtick che sembrano file del repo (contengono '/' o '.md')
  local refs missing=0
  refs=$(grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|py|js|toml)`' "$path" | tr -d '`' | sort -u)
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      *"<"*|*SKILL.md) continue ;;  # placeholder generici, non percorsi reali
    esac
    if [ ! -e "$HERE/$ref" ]; then
      echo "   riferimento non trovato: $ref"
      missing=$((missing+1))
    fi
  done <<< "$refs"
  [ "$missing" -eq 0 ] && ok "$nome: tutti i percorsi citati esistono davvero" \
    || ko "$nome: $missing percorso/i citato/i che non esiste/esistono"
}

check_skill_frontmatter "design-doc" "$HERE/.claude/skills/design-doc/SKILL.md"
check_referenced_paths  "design-doc" "$HERE/.claude/skills/design-doc/SKILL.md"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
