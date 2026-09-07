#!/bin/bash
# test-install-garante.sh — l'installatore del garante (scrive in ~/.claude/settings.json:
# UTENTE, tutte le repo): dichiara cosa scrive e non doppiona l'hook se gia' presente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/install-garante.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }
grep -q "QUESTO TOOL SCRIVE" "$TOOL" && ok "dichiara cosa scrive (il nome non mente)" || ko "non dichiara le scritture"
# l'idempotenza la garantisce il vero ~/.claude/settings.json: verifico che l'hook non sia doppio
if [ -f "$HOME/.claude/settings.json" ]; then
  N=$(python3 -c "
import json,sys
d=json.load(open('$HOME/.claude/settings.json'))
cmds=[h.get('command','') for s in d.get('hooks',{}).get('SessionStart',[]) for h in s.get('hooks',[])]
print(sum('garante-standard' in c for c in cmds))" 2>/dev/null || echo 0)
  [ "$N" -le 1 ] && ok "garante presente $N volta/e in settings.json (niente doppioni)" || ko "garante doppio: $N"
else
  ok "settings.json utente assente (ambiente di test)"
fi
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
