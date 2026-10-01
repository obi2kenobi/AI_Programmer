#!/bin/bash
# test-verify-standalone.sh — il verify che non collide col turno (2026-10-01, giro 3):
# gira in un worktree staccato di origin/main, e a fine corsa il worktree SPARISCE.
# Banco: repo mini con verify verde/rosso, e il worktree sempre ripulito.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/verify-standalone.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

T=$(mktemp -d /tmp/test-vfy-stand.XXXXXX)
trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
git init -q -b main "$T/mini"
( cd "$T/mini" && printf 'true\n' > .night-verify && mkdir -p tools && cp "$HERE/llm/_timeout.sh" ../timeout-copia 2>/dev/null; git add -A && git commit -qm base )
git -C "$T/mini" remote add origin "$T/mini"   # origin = se stesso: il fetch e' muto ma innocuo

OUT=$(bash "$TOOL" "$T/mini" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "VERDE" <<<"$OUT" && ok "verify verde su repo mini (rc 0)" || ko "rc=$RC: $(tail -2 <<<"$OUT" | tr '\n' ' ')"
N_WT=$(git -C "$T/mini" worktree list | wc -l | tr -d ' ')
[ "$N_WT" -eq 1 ] && ok "il worktree di servizio e' SPARITO (1 = solo il principale)" || ko "worktree residui: $N_WT"

# verify rosso: si dichiara e non finge
( cd "$T/mini" && printf 'false\n' > .night-verify && git add -A && git commit -qm rosso )
git -C "$T/mini" branch -f main HEAD 2>/dev/null
OUT=$(bash "$TOOL" "$T/mini" 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "ROSSO" <<<"$OUT" && ok "verify rosso dichiarato (rc $RC)" || ko "rosso non visto: rc=$RC $OUT"
N_WT=$(git -C "$T/mini" worktree list | wc -l | tr -d ' ')
[ "$N_WT" -eq 1 ] && ok "worktree ripulito anche col rosso" || ko "residui: $N_WT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
