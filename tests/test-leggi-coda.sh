#!/bin/bash
# test-leggi-coda.sh — «0 issue» e «non so» non sono la stessa cosa (2026-09-24, quarto ventaglio, Q2 R5).
# Prima: `ISSUES=$(gh issue list …)` senza guardia. Con GitHub intermittente dopo l'auth, il conteggio
# restava vuoto, `[ "" -ge 50 ]` dava un errore su stderr, il log diceva «TURNO su X:  issue in coda» e
# il turno andava avanti come con la coda vuota: la notte senza commesse non lasciava traccia.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; mkdir -p "$T/bin"
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
type leggi_coda >/dev/null 2>&1 && ok "leggi_coda e' definita in night-shift/lib.sh" \
  || { ko "leggi_coda non esiste"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }
finto_gh() { printf '#!/bin/bash\n%s\n' "$1" > "$T/bin/gh"; chmod +x "$T/bin/gh"; }

finto_gh 'echo "error connecting to api.github.com" >&2; exit 1'
OUT=$(PATH="$T/bin:$PATH" leggi_coda o/r 2>"$T/err"); RC=$?
[ "$RC" -ne 0 ] && [ -z "$OUT" ] && grep -c 'api.github.com' "$T/err" >/dev/null \
  && ok "gh in errore: rc $RC e il motivo (non una coda vuota)" || ko "gh in errore: rc=$RC, out=«${OUT}», err=$(cat "$T/err")"
finto_gh 'echo "<html>502</html>"'
PATH="$T/bin:$PATH" leggi_coda o/r >/dev/null 2>&1; RC=$?
[ "$RC" -ne 0 ] && ok "risposta non JSON: rc $RC" || ko "risposta non JSON presa per buona"
finto_gh 'echo "[]"'
OUT=$(PATH="$T/bin:$PATH" leggi_coda o/r 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && [ "$(jq length <<<"$OUT")" = 0 ] && ok "coda davvero vuota: rc 0, lista vuota" || ko "coda vuota: rc=$RC «${OUT}»"
finto_gh 'echo "[{\"number\":7,\"title\":\"t\",\"body\":\"b\"}]"; echo "A new release of gh is available" >&2'
OUT=$(PATH="$T/bin:$PATH" leggi_coda o/r 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && [ "$(jq length <<<"$OUT")" = 1 ] && ok "un avviso di gh su stderr non sporca il JSON" || ko "avviso su stderr: rc=$RC «${OUT}»"

NS="$HERE/night-shift/night-shift.sh"
grep -c 'ISSUES=$(leggi_coda "$REPO"' "$NS" >/dev/null && grep -c 'coda ILLEGGIBILE' "$NS" >/dev/null \
  && ok "il turno legge la coda con leggi_coda e dice «coda ILLEGGIBILE»" || ko "il turno legge ancora la coda senza guardia"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
