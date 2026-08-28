#!/bin/bash
# test-opencode-skills-sync.sh — nato dalla revisione "L'Hub Allo Specchio" (14 lenti
# indipendenti, 2026-08-28): per gli AGENTI esiste l'intera catena anti-drift
# (test-opencode-agent-sync.sh, propagazione in onboard/bootstrap/sync-repo) — per le
# SKILL nessuno di questi pezzi esisteva. DEBITI.md dichiarava "le 9 skill non viaggiano
# in OpenCode" e SAL.md ne dichiarava la chiusura "con guardia" lo stesso giorno — ma la
# guardia non è mai stata scritta, e 3 file (gas-sviluppo/references/{consegna,
# famiglie-difetti,metodo}.md) sono divergenti ore dopo la copia (trovato da 3 lenti
# indipendenti: divergenza diretta, coerenza DEBITI.md, campionamento SAL.md). Questo
# test è la guardia mancante — blocca il drift su ogni skill, mai una lista hardcoda.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

shopt -s nullglob
CLAUDE_SKILLS=("$HERE"/.claude/skills/*/)
[ "${#CLAUDE_SKILLS[@]}" -gt 0 ] && ok "skill Claude presenti: ${#CLAUDE_SKILLS[@]}" \
  || ko "nessuna skill in .claude/skills/"

for dir in "${CLAUDE_SKILLS[@]}"; do
  nome="$(basename "$dir")"
  specchio="$HERE/.opencode/skills/$nome"
  if [ ! -d "$specchio" ]; then
    ko "$nome: nessuno specchio in .opencode/skills/"
    continue
  fi
  if diff -rq "$dir" "$specchio" >/dev/null 2>&1; then
    ok "$nome: identica fra .claude/skills e .opencode/skills (no drift)"
  else
    ko "$nome: DIVERGE fra .claude/skills e .opencode/skills — $(diff -rq "$dir" "$specchio" | tr '\n' ' ')"
  fi
done

# skill OpenCode orfana (presente lì, non in Claude): drift anch'essa, TRANNE graphify
# — plugin/hook opencode-only dichiarato tale (nessuna controparte prevista in .claude,
# non un'omissione: AGENTS.md la cita come reminder specifico di quel framework).
for o in "$HERE"/.opencode/skills/*/; do
  nome="$(basename "$o")"
  [ "$nome" = "graphify" ] && continue
  [ -d "$HERE/.claude/skills/$nome" ] || ko "$nome: orfana in .opencode/skills senza origine Claude"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
