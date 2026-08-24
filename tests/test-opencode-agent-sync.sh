#!/bin/bash
# test-opencode-agent-sync.sh — 6° ciclo, set 3 giro 3 (2026-08-24). Chiude il limite
# dichiarato in docs/system.md §"Limiti dichiarati" #6 nella parte OpenCode: ".opencode/
# agent/ assente, solo .opencode/skills/". Ora gli stessi 5 agenti vivono anche per il
# turno notturno (OpenCode). Il CORPO dei file deve restare identico fra .claude/agents/
# e .opencode/agent/ — cambiano solo frontmatter e nota di specchio: un agente che
# diverga fra giorno e notte è due agenti diversi che si credono lo stesso. Questo test
# blocca il drift su ogni coppia (glob, mai lista hardcoded).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

shopt -s nullglob
CLAUDE=("$HERE"/.claude/agents/*.md)
OPEN=("$HERE"/.opencode/agent/*.md)

[ "${#CLAUDE[@]}" -gt 0 ] && ok "agenti Claude presenti: ${#CLAUDE[@]}" || ko "nessun agente in .claude/agents/"
[ "${#OPEN[@]}" -eq "${#CLAUDE[@]}" ] \
  && ok "agenti OpenCode specchiati: ${#OPEN[@]} = ${#CLAUDE[@]}" \
  || ko "sfasamento: ${#OPEN[@]} OpenCode vs ${#CLAUDE[@]} Claude"

corpo() { # corpo = tutto ciò che segue la chiusura del frontmatter, senza la nota specchio
  sed '1,/^---$/d' "$1" | sed '1,/^---$/d' | grep -v '^<!--' | grep -v '^     ' | sed '/^-->$/d'
}

for c in "${CLAUDE[@]}"; do
  nome="$(basename "$c" .md)"
  o="$HERE/.opencode/agent/$nome.md"
  if [ ! -f "$o" ]; then ko "$nome: nessun specchio OpenCode"; continue; fi
  # frontmatter opencode: mode subagent e description non vuota
  grep -q "^mode: subagent" "$o" \
    && ok "$nome: frontmatter OpenCode con mode subagent" \
    || ko "$nome: frontmatter senza mode: subagent"
  if diff <(corpo "$c") <(corpo "$o") >/dev/null 2>&1; then
    ok "$nome: corpo identico fra Claude e OpenCode (no drift)"
  else
    ko "$nome: il corpo DIVERGE fra .claude/agents e .opencode/agent — due agenti diversi che si credono lo stesso"
  fi
done

# un agente OpenCode ORFANO (presente lì, non in Claude) è anch'esso drift
for o in "${OPEN[@]}"; do
  nome="$(basename "$o" .md)"
  [ -f "$HERE/.claude/agents/$nome.md" ] || ko "$nome: orfano OpenCode senza origine Claude"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
