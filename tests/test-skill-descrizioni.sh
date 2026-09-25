#!/bin/bash
# test-skill-descrizioni.sh — ogni skill ha name e description, e la description sta nei 1024 caratteri
# della specifica Agent Skills (2026-09-24, notte dei giri, T6#8). Sei skill la superavano (fino a
# 1436): Claude Code le carica comunque, ma lo specchio .opencode/skills/ lo legge il turno di notte, e
# un caricatore che applica la specifica le scarterebbe (non provato da qui: DEBITI, ⏳ Mac). La storia
# che le allungava ora sta nel corpo, in «Provenienza».
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
FUORI=$(cd "$HERE" && python3 - .claude/skills/*/SKILL.md .opencode/skills/*/SKILL.md <<'PY'
import re, sys
for p in sys.argv[1:]:
    t = open(p, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
    fm = m.group(1) if m else ""
    nome = re.search(r"^name:\s*(\S+)", fm, re.M)
    d = re.search(r"^description:\s*(.*?)(?=^[\w-]+:|\Z)", fm, re.S | re.M)
    n = len(d.group(1).strip()) if d else 0
    if not nome or n == 0 or n > 1024:
        print(f"{p} ({'senza name' if not nome else ''}{' description ' + str(n) + ' caratteri' if nome else ''})")
PY
)
N=$(ls "$HERE"/.claude/skills/*/SKILL.md "$HERE"/.opencode/skills/*/SKILL.md | wc -l | tr -d ' ')
[ -z "$FUORI" ] && ok "tutte le $N skill (due specchi) hanno name e una description entro 1024 caratteri" || ko "fuori specifica: $(tr '\n' ' ' <<<"$FUORI")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
