#!/bin/bash
# test-fondi.sh — il primo banco dell'auto-merge (tools/fondi.sh, 2026-11-10). Nato da un difetto: la condizione
# 3 («banco verde») eseguiva `bash .night-verify` intero, cioe' il rc dell'ULTIMA riga — un rosso in mezzo fondeva.
# gh e' FINTO (nessuna rete, nessuna PR vera): risponde alle tre domande di fondi e registra la fusione.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" <<'GH'
#!/bin/bash
case "$*" in
  *"pr merge"*) echo "fusa" >> "$GH_REGISTRO"; echo "merged" ;;
  *"pr ready"*) : ;;
  *mergeable*) echo "OPEN MERGEABLE false" ;;
  *comments*) printf 'LENTE SICUREZZA: PULITA\nPARERE: APPROVA\n' ;;
esac
GH
chmod +x "$TMP/bin/gh"; export PATH="$TMP/bin:$PATH" GH_REGISTRO="$TMP/fusioni"
R="$TMP/repo"; mkdir -p "$R"; git -C "$R" init -q -b main; git -C "$R" remote add origin https://github.com/finto/repo.git
fondi() { : > "$GH_REGISTRO"; OUT=$(bash "$HERE/tools/fondi.sh" "$R" 7 2>&1); RC=$?; }

printf 'true\n' > "$R/.night-verify"; fondi
[ "$RC" -eq 0 ] && grep -q "FONDI: SI" <<<"$OUT" && [ -s "$GH_REGISTRO" ] && ok "quattro condizioni verdi: fonde (gh pr merge chiamato)" || ko "verde (rc $RC): $OUT"

printf 'false\ntrue\n' > "$R/.night-verify"; fondi
[ "$RC" -eq 1 ] && grep -q "3. banco: ROSSO — ROSSA: false" <<<"$OUT" && [ ! -s "$GH_REGISTRO" ] \
  && ok "un rosso IN MEZZO al .night-verify ferma la fusione e dice quale riga" || ko "rosso in mezzo (rc $RC, fusioni: $(cat "$GH_REGISTRO")): $OUT"

rm -f "$R/.night-verify"; fondi
grep -q "3. banco: assente (dichiarato)" <<<"$OUT" && ok "banco assente: dichiarato" || ko "banco assente: $OUT"
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
