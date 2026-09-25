#!/bin/bash
# test-commit-altrui.sh — il «lease» del turno non sovrascrive il lavoro del giorno (2026-09-24, quinto
# ventaglio, R5 R2-R3). Prima: il turno rifaceva il fetch di origin/night/issue-N e usava come valore atteso
# del --force-with-lease lo sha APPENA letto — il lease non proteggeva niente: due correzioni a mano sul
# ramo sparivano, e il log diceva «fix committato e pushato». Ora: se il ramo remoto ha commit di un autore
# diverso dal turno, niente forzatura (il push viene rifiutato e il ramo resta com'e'), e lo si dice.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
type commit_altrui >/dev/null 2>&1 && ok "commit_altrui e' definita in night-shift/lib.sh" \
  || { ko "commit_altrui non esiste"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false
git init -q -b main "$T/r"; git -C "$T/r" config user.name "Night Shift"; git -C "$T/r" config user.email night-shift@localhost
echo a > "$T/r/a"; git -C "$T/r" add a; git -C "$T/r" commit -qm init
git -C "$T/r" checkout -q -b night/issue-7; echo b > "$T/r/b"; git -C "$T/r" add b; git -C "$T/r" commit -qm "fix: night #7"
N=$(commit_altrui "$T/r" main night/issue-7); [ "$N" = 0 ] && ok "solo commit del turno: 0 altrui" || ko "commit del turno contati come altrui: $N"
echo c > "$T/r/c"; git -C "$T/r" add c; git -C "$T/r" -c user.name=Luca -c user.email=luca@esempio.invalid commit -qm "giorno: correzione"
N=$(commit_altrui "$T/r" main night/issue-7); [ "$N" = 1 ] && ok "una correzione del giorno sul ramo: 1 altrui" || ko "correzione del giorno non vista: $N"

NS="$HERE/night-shift/night-shift.sh"
grep -c 'commit_altrui "$DIR"' "$NS" >/dev/null && grep -c 'non lo sovrascrivo' "$NS" >/dev/null \
  && ok "il turno non forza il push su un ramo con commit altrui, e lo dice" || ko "il turno forza il push anche sui commit del giorno"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
