#!/bin/bash
# test-eval-review.sh — l'audit post-merge (tools/eval-review.sh, da main 2026-09-24, furti superpowers+gsd):
# la PR fusa porta la sua prova? Arrivato su main senza banco (tests/test-banco-passaggio.sh lo segnava
# SCOPERTO). `gh` qui e' finto: il banco giudica le scelte dello script, non GitHub.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/repo/tests"
printf '#!/bin/bash\ncat "%s/diff" 2>/dev/null\n' "$T" > "$T/bin/gh"; chmod +x "$T/bin/gh"
ER="$HERE/tools/eval-review.sh"
esegui() { PATH="$T/bin:$PATH" bash "$ER" "$T/repo" 7 >"$T/out" 2>&1; echo $?; }

# uso sbagliato: 2, come dice l'intestazione (prima `${1:?}` usciva 1, che qui vuol dire «prove mancanti»)
bash "$ER" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 2 ] && ok "senza argomenti: rc 2 (uso)" || ko "senza argomenti: rc $RC, atteso 2"
# PR illeggibile: 2
rm -f "$T/diff"; RC=$(esegui)
[ "$RC" -eq 2 ] && ok "PR illeggibile: rc 2" || ko "PR illeggibile: rc $RC"
# il test della PR c'e' nel main, il verify passa: 0
printf '+++ b/tests/test-x.sh\n+echo x\n' > "$T/diff"; touch "$T/repo/tests/test-x.sh"; echo 'true' > "$T/repo/.night-verify"
RC=$(esegui)
[ "$RC" -eq 0 ] && grep -c '1 prove vere, nessuna mancante' "$T/out" >/dev/null && ok "test presente e verify verde: rc 0" || ko "caso verde: rc $RC — $(cat "$T/out")"
# il test dichiarato non c'e': 1
rm "$T/repo/tests/test-x.sh"; RC=$(esegui)
[ "$RC" -eq 1 ] && grep -c 'test-assente:tests/test-x.sh' "$T/out" >/dev/null && ok "test assente nel main: rc 1, detto per nome" || ko "test assente: rc $RC — $(cat "$T/out")"
# il verify e' rosso: 1
touch "$T/repo/tests/test-x.sh"; echo 'false' > "$T/repo/.night-verify"; RC=$(esegui)
[ "$RC" -eq 1 ] && grep -c 'verify-rossa:false' "$T/out" >/dev/null && ok "verify rosso: rc 1" || ko "verify rosso: rc $RC — $(cat "$T/out")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
