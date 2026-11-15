#!/bin/bash
# test-fondi.sh — banco dell'auto-merge (tools/fondi.sh, 2026-11-10). Nato da un difetto: la condizione
# 3 («banco verde») eseguiva `bash .night-verify` intero, cioe' il rc dell'ULTIMA riga — un rosso in mezzo fondeva.
# gh e' FINTO (nessuna rete, nessuna PR vera): risponde alle domande di fondi e registra la fusione.
# (AUDIT-KIMI Q10, 15/11): quattro regressioni anti-bypass — 1) spento di default; 2) banco
# assente = KO; 3) il merge porta --match-head-commit con lo SHA approvato; 4) il rifiuto
# di GitHub (SHA avanzato dopo il parere) = «FONDI: NO», mai «SI» annunciato a vuoto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
mkdir -p "$TMP/bin"
SHA_FISSO="abc123def456"
cat > "$TMP/bin/gh" <<'GH'
#!/bin/bash
case "$*" in
  *"pr merge"*) [ "${GH_MERGE_RIFIUTA:-0}" = 1 ] && { echo "head sha non coincide — il commit e' avanzato dopo il parere" >&2; exit 1; }
                echo "gh $*" >> "$GH_REGISTRO"; echo "merged" ;;
  *"pr ready"*) : ;;
  *headRefOid*) echo "$SHA_FISSO" ;;
  *mergeable*) echo "OPEN MERGEABLE false" ;;
  *comments*) cat "$GH_COMMENTI" ;;
esac
GH
chmod +x "$TMP/bin/gh"; export PATH="$TMP/bin:$PATH" GH_REGISTRO="$TMP/fusioni" SHA_FISSO
printf 'LENTE SICUREZZA: PULITA\nPARERE: APPROVA\n' > "$TMP/commenti"; export GH_COMMENTI="$TMP/commenti"
R="$TMP/repo"; mkdir -p "$R"; git -C "$R" init -q -b main; git -C "$R" remote add origin https://github.com/finto/repo.git
fondi() { : > "$GH_REGISTRO"; OUT=$(bash "$HERE/tools/fondi.sh" "$R" 7 2>&1); RC=$?; }

# ── Regressione 1 (Q10): l'auto-merge e' SPENTO di default (audit P0.3) ──────
printf 'true\n' > "$R/.night-verify"
unset FONDI_AUTO; fondi
[ "$RC" -eq 2 ] && grep -q "auto-merge spento" <<<"$OUT" && [ ! -s "$GH_REGISTRO" ] \
  && ok "spento di default: rc 2, nessuna chiamata a gh pr merge" || ko "spento di default (rc $RC): $OUT"
export FONDI_AUTO=1   # da qui in poi il banco prova le condizioni: il gate deve essere acceso

# ── Verde pieno: fonde E il merge e' legato allo SHA approvato (regressione 3) ──
fondi
[ "$RC" -eq 0 ] && grep -q "FONDI: SI" <<<"$OUT" && grep -q -- "--match-head-commit $SHA_FISSO" "$GH_REGISTRO" \
  && ok "quattro condizioni verdi: fonde con --match-head-commit $SHA_FISSO" || ko "verde (rc $RC): $OUT / $(cat "$GH_REGISTRO" 2>/dev/null)"

# ── Un rosso IN MEZZO al .night-verify ferma la fusione e dice quale riga ─────
printf 'false\ntrue\n' > "$R/.night-verify"; fondi
[ "$RC" -eq 1 ] && grep -q "3. banco: ROSSO — ROSSA: false" <<<"$OUT" && [ ! -s "$GH_REGISTRO" ] \
  && ok "un rosso IN MEZZO al .night-verify ferma la fusione e dice quale riga" || ko "rosso in mezzo (rc $RC, fusioni: $(cat "$GH_REGISTRO")): $OUT"

# ── Regressione 2 (Q10/Q5): banco assente = KO, non piu' «dichiarato» ─────────
rm -f "$R/.night-verify"; fondi
[ "$RC" -eq 1 ] && grep -q "3. banco: ASSENTE" <<<"$OUT" && [ ! -s "$GH_REGISTRO" ] \
  && ok "banco assente: KO — in un gate di scrittura l'assenza di prove blocca" || ko "banco assente (rc $RC): $OUT"
printf 'true\n' > "$R/.night-verify"

# ── Il veto NON APPROVABILE non fonde (bug del glob *APPROVA*, 15/11) ─────────
printf 'LENTE SICUREZZA: PULITA\nNON APPROVABILE\n' > "$GH_COMMENTI"
fondi
[ "$RC" -eq 1 ] && [ ! -s "$GH_REGISTRO" ] && grep -q "4. censore: NON APPROVABILE" <<<"$OUT" \
  && ok "il veto NON APPROVABILE non fonde (bug del glob *APPROVA*)" || ko "veto (rc $RC): $OUT"

printf 'LENTE SICUREZZA: PULITA\nDELIBERA: APPROVA\n' > "$GH_COMMENTI"; fondi
[ "$RC" -eq 0 ] && [ -s "$GH_REGISTRO" ] \
  && ok "la formula esatta DELIBERA: APPROVA fonde" || ko "delibera (rc $RC): $OUT"

# ── Regressione 4 (Q10): GitHub rifiuta il merge (SHA avanzato dopo il parere) ─
# Prima il rifiuto era invisibile: `gh … | tail -1` non controllato, «FONDI: SI» a vuoto.
export GH_MERGE_RIFIUTA=1; fondi
[ "$RC" -eq 1 ] && grep -q "FONDI: NO — GitHub ha rifiutato il merge" <<<"$OUT" && ! grep -q "FONDI: SI" <<<"$OUT" \
  && ok "GitHub rifiuta il merge (SHA avanzato): FONDI NO, rc 1 — mai SI a vuoto" || ko "rifiuto merge (rc $RC): $OUT"
unset GH_MERGE_RIFIUTA

# ── Satellite senza hub: i fallback interni (stessa cura di deploy-gas.sh) ────
H="$TMP/satellite"; mkdir -p "$H/tools"; cp "$HERE/tools/fondi.sh" "$H/tools/"
printf 'LENTE SICUREZZA: PULITA\nPARERE: APPROVA\n' > "$GH_COMMENTI"
OUT2=$(FONDI_AUTO=1 bash "$H/tools/fondi.sh" "$R" 7 2>&1); RC2=$?
[ "$RC2" -eq 0 ] && grep -q "FONDI: SI" <<<"$OUT2" \
  && ok "satellite senza hub: fonde coi fallback interni" || ko "satellite (rc $RC2): $OUT2"

printf 'false\n' > "$R/.night-verify"
OUT3=$(FONDI_AUTO=1 bash "$H/tools/fondi.sh" "$R" 7 2>&1); RC3=$?
[ "$RC3" -eq 1 ] && grep -q "3. banco: ROSSO" <<<"$OUT3" \
  && ok "satellite senza hub: il banco rosso ferma la fusione" || ko "satellite rosso (rc $RC3): $OUT3"
printf 'true\n' > "$R/.night-verify"
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
