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
  *comments*) cat "$GH_COMMENTI" ;;
esac
GH
chmod +x "$TMP/bin/gh"; export PATH="$TMP/bin:$PATH" GH_REGISTRO="$TMP/fusioni"
printf 'LENTE SICUREZZA: PULITA\nPARERE: APPROVA\n' > "$TMP/commenti"; export GH_COMMENTI="$TMP/commenti"
R="$TMP/repo"; mkdir -p "$R"; git -C "$R" init -q -b main; git -C "$R" remote add origin https://github.com/finto/repo.git
fondi() { : > "$GH_REGISTRO"; OUT=$(bash "$HERE/tools/fondi.sh" "$R" 7 2>&1); RC=$?; }

printf 'true\n' > "$R/.night-verify"; fondi
[ "$RC" -eq 0 ] && grep -q "FONDI: SI" <<<"$OUT" && [ -s "$GH_REGISTRO" ] && ok "quattro condizioni verdi: fonde (gh pr merge chiamato)" || ko "verde (rc $RC): $OUT"

printf 'false\ntrue\n' > "$R/.night-verify"; fondi
[ "$RC" -eq 1 ] && grep -q "3. banco: ROSSO — ROSSA: false" <<<"$OUT" && [ ! -s "$GH_REGISTRO" ] \
  && ok "un rosso IN MEZZO al .night-verify ferma la fusione e dice quale riga" || ko "rosso in mezzo (rc $RC, fusioni: $(cat "$GH_REGISTRO")): $OUT"

rm -f "$R/.night-verify"; fondi
grep -q "3. banco: assente (dichiarato)" <<<"$OUT" && ok "banco assente: dichiarato" || ko "banco assente: $OUT"

# (15/11, rassegna frontiera sulle PR #45/#303/#57): il glob *APPROVA* contava
# «NON APPROVABILE» come approvazione. Le formule si confrontano ESATTE.
printf 'LENTE SICUREZZA: PULITA\nNON APPROVABILE\n' > "$GH_COMMENTI"
printf 'true\n' > "$R/.night-verify"; fondi
[ "$RC" -eq 1 ] && [ ! -s "$GH_REGISTRO" ] && grep -q "4. censore: NON APPROVABILE" <<<"$OUT" \
  && ok "il veto NON APPROVABILE non fonde (bug del glob *APPROVA*)" || ko "veto (rc $RC): $OUT"

printf 'LENTE SICUREZZA: PULITA\nDELIBERA: APPROVA\n' > "$GH_COMMENTI"; fondi
[ "$RC" -eq 0 ] && [ -s "$GH_REGISTRO" ] \
  && ok "la formula esatta DELIBERA: APPROVA fonde" || ko "delibera (rc $RC): $OUT"

# (15/11, stessa cura di deploy-gas.sh): nei satelliti night-shift/ NON c'e'.
# Lo script copiato fuori dall'hub deve funzionare coi fallback interni.
H="$TMP/satellite"; mkdir -p "$H/tools"; cp "$HERE/tools/fondi.sh" "$H/tools/"
printf 'LENTE SICUREZZA: PULITA\nPARERE: APPROVA\n' > "$GH_COMMENTI"
OUT2=$(bash "$H/tools/fondi.sh" "$R" 7 2>&1); RC2=$?
[ "$RC2" -eq 0 ] && grep -q "FONDI: SI" <<<"$OUT2" \
  && ok "satellite senza hub: fonde coi fallback interni" || ko "satellite (rc $RC2): $OUT2"

printf 'false\n' > "$R/.night-verify"
OUT3=$(bash "$H/tools/fondi.sh" "$R" 7 2>&1); RC3=$?
[ "$RC3" -eq 1 ] && grep -q "3. banco: ROSSO" <<<"$OUT3" \
  && ok "satellite senza hub: il banco rosso ferma la fusione" || ko "satellite rosso (rc $RC3): $OUT3"
printf 'true\n' > "$R/.night-verify"
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
