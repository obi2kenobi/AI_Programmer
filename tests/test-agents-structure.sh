#!/bin/bash
# test-agents-structure.sh — 5° ciclo, set 1 "agenti": .claude/agents/*.md sono prosa per
# Claude Code (subagent), non codice eseguibile, ma verificabili come le skill
# (test-skills-structure.sh): frontmatter YAML valido (name/description/tools), e ogni
# percorso citato nel corpo esiste davvero. Itera sul glob, non su nomi hardcoded — lezione
# già pagata una volta con .night-verify (4 test hardcoded, 23+ file nuovi mai eseguiti).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

check_agent_frontmatter() {
  local nome="$1" path="$2"
  [ "$(sed -n '1p' "$path")" = "---" ] && ok "$nome: apre con frontmatter YAML" \
    || ko "$nome: non apre con ---"
  grep -q "^name: $nome$" "$path" && ok "$nome: campo 'name' presente e corretto" \
    || ko "$nome: campo 'name' assente o diverso dal nome file"
  grep -q "^description: .\{80,\}" "$path" && ok "$nome: description sostanziosa (non un placeholder)" \
    || ko "$nome: description troppo corta o assente"
  grep -q "^tools: .\+" "$path" && ok "$nome: campo 'tools' dichiarato (accesso scoped)" \
    || ko "$nome: campo 'tools' assente — l'agente erediterebbe tutto"
  local closing
  closing=$(awk 'NR>1 && /^---$/{print NR; exit}' "$path")
  [ -n "$closing" ] && ok "$nome: frontmatter chiuso correttamente" || ko "$nome: frontmatter senza chiusura ---"
}

check_referenced_paths() {
  local nome="$1" path="$2"
  local refs missing=0
  refs=$(grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|py|js|toml)`' "$path" | tr -d '`' | sort -u)
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      *"<"*|*SKILL.md) continue ;;
    esac
    if [ ! -e "$HERE/$ref" ]; then
      echo "   riferimento non trovato: $ref"
      missing=$((missing+1))
    fi
  done <<< "$refs"
  [ "$missing" -eq 0 ] && ok "$nome: tutti i percorsi citati esistono davvero" \
    || ko "$nome: $missing percorso/i citato/i che non esiste/esistono"
}

shopt -s nullglob
AGENTS=("$HERE"/.claude/agents/*.md)
if [ ${#AGENTS[@]} -eq 0 ]; then
  ko "nessun agente trovato in .claude/agents/"
else
  for path in "${AGENTS[@]}"; do
    nome="$(basename "$path" .md)"
    check_agent_frontmatter "$nome" "$path"
    check_referenced_paths  "$nome" "$path"
  done
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
