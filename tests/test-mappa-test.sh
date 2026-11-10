#!/bin/bash
# test-mappa-test.sh — tools/mappa-test.sh scrive la mappa «sorgente → banco» in .git/test-mappa (primo banco,
# 2026-11-10: il tool non ne aveva; shellcheck vi trovava un `> file` senza comando e un 2>/dev/null doppio).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
R="$TMP/r"; mkdir -p "$R/tests" "$R/tools"; git -C "$R" init -q
printf '#!/bin/bash\nbash "$HERE/tools/alfa.sh" x\n' > "$R/tests/test-alfa.sh"
printf '#!/bin/bash\necho niente\n' > "$R/tests/test-muto.sh"
OUT=$(bash "$HERE/tools/mappa-test.sh" "$R" 2>&1)
grep -q "1 banchi mappati, 1 saltati" <<<"$OUT" && ok "un banco mappato, il muto saltato e dichiarato" || ko "conteggio: $OUT"
grep -q "tools/alfa.sh tests/test-alfa.sh" "$R/.git/test-mappa" && ok "la mappa lega tools/alfa.sh al suo banco" || ko "mappa: $(cat "$R/.git/test-mappa")"
bash "$HERE/tools/mappa-test.sh" "$R" >/dev/null 2>&1
[ "$(grep -c . "$R/.git/test-mappa")" -eq 1 ] && ok "rigirato: la mappa si riscrive, non si accoda" || ko "mappa accodata: $(cat "$R/.git/test-mappa")"
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
