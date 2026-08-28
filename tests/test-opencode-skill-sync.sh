#!/bin/bash
# test-opencode-skill-sync.sh — dall'audit indipendente 2026-08-28: le skill
# .opencode/skills/ erano dichiarate "copiate con guardia anti-drift" in SAL.md
# ma la guardia NON esisteva, e gas-sviluppo era GIÀ divergente. Gli agenti
# avevano il loro test di sync da giorni: le skill no. Stesso principio.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

shopt -s nullglob
CLAUDE_SKILLS=("$HERE"/.claude/skills/*/SKILL.md)
OC_SKILLS=()
for d in "$HERE"/.opencode/skills/*/; do
  n=$(basename "$d")
  [ "$n" = "graphify" ] && continue  # OpenCode-specific, non uno specchio
  OC_SKILLS+=("$d/SKILL.md")
done

[ "${#CLAUDE_SKILLS[@]}" -gt 0 ] && ok "skill Claude presenti: ${#CLAUDE_SKILLS[@]}" || ko "nessuna skill"
[ "${#OC_SKILLS[@]}" -eq "${#CLAUDE_SKILLS[@]}" ] \
  && ok "skill OpenCode specchiate: ${#OC_SKILLS[@]} = ${#CLAUDE_SKILLS[@]}" \
  || ko "sfasamento: ${#OC_SKILLS[@]} vs ${#CLAUDE_SKILLS[@]}"

for cs in "${CLAUDE_SKILLS[@]}"; do
  nome="$(basename "$(dirname "$cs")")"
  os="$HERE/.opencode/skills/$nome/SKILL.md"
  if [ ! -f "$os" ]; then ko "$nome: nessuno specchio OpenCode"; continue; fi
  if diff -q "$cs" "$os" >/dev/null 2>&1; then
    ok "$nome: identiche (no drift)"
  else
    # il frontmatter può differire (mode/tools), il CORPO no
    corpo_c=$(sed '1,/^---$/d' "$cs" | sed '1,/^---$/d')
    corpo_o=$(sed '1,/^---$/d' "$os" | sed '1,/^---$/d')
    if [ "$corpo_c" = "$corpo_o" ]; then
      ok "$nome: corpo identico (frontmatter diverso ok)"
    else
      ko "$nome: corpo DIVERGE fra .claude e .opencode"
    fi
  fi
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
