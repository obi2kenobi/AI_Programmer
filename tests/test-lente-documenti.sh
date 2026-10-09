#!/bin/bash
# test-lente-documenti.sh — la lente PROSA dei documenti (Vale offline, regola
# ASCII di casa) + annota.sh (errorformat → annotazioni su riga, furto reviewdog).
# Nato dalla caccia per l'assistente diurno (Luca, 2026-10-09: «perfetto esegui»).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
LD="$HERE/tools/lente-documenti.sh"
AN="$HERE/tools/annota.sh"
PP="$HERE/tools/pre-push.sh"
GP="$HERE/tools/giorno.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$LD" && bash -n "$AN" && ok "sintassi (lente + annota)" || { ko "sintassi"; exit 1; }
command -v vale >/dev/null 2>&1 || { echo "SKIP: vale non installato — banco dichiarato saltato"; exit 0; }

SB=$(mktemp -d /tmp/test-lente-doc.XXXXXX)
trap 'rm -rf "$SB"' EXIT
nuova_repo() { git -C "$1" init -q -b main; git -C "$1" -c user.name=t -c user.email=t@t commit -qm init --allow-empty; }

# ── fixture ─────────────────────────────────────────────────────────────────────
R="$SB/repo"; mkdir -p "$R"; nuova_repo "$R"
printf "# Guida\n\nParagrafo vecchio, gia' pulito.\n" > "$R/guida.md"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm base -q

# ── riga accentata NUOVA: un rilievo, errorformat, riga giusta ──────────────────
printf "\nSezione nuova: perche' cosi' e' meglio così\n" >> "$R/guida.md"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm accentua -q
OUT=$(bash "$LD" "$R" HEAD~1 2>/dev/null); RC=$?
if [ "$RC" -eq 1 ] && grep -qE '^guida\.md:[0-9]+: documento\[' <<<"$OUT"; then
  ok "riga accentata NUOVA: rilievo in errorformat (file:riga: documento[...])"
else ko "riga accentata NUOVA: rilievo in errorformat (rc=$RC: $OUT)"; fi
[ "$(grep -c 'documento\[' <<<"$OUT")" -eq 1 ] && ok "una riga di rilievo per file:riga (i caratteri si dedupano)" || ko "dedup per file:riga ($(grep -c 'documento\[' <<<"$OUT") rilievi)"
RIGA_RIL=$(grep -oE '^[^:]+:[0-9]+' <<<"$OUT" | cut -d: -f2)
[ "$RIGA_RIL" -eq "$(grep -n 'così' "$R/guida.md" | cut -d: -f1)" ] && ok "il numero di riga punta alla riga accentata VERA" || ko "numero di riga sbagliato ($RIGA_RIL)"

# ── diff-aware: l'accento VECCHIO (gia' in base) non si giudica ─────────────────
printf '\nAggiunta pulita di oggi.\n' >> "$R/guida.md"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm pulito -q
OUT=$(bash "$LD" "$R" HEAD~1 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && [ -z "$OUT" ] && ok "diff-aware: la prosa gia' in base non si giudica (solo le righe aggiunte)" || ko "diff-aware: la prosa vecchia e' stata giudicata (rc=$RC: $OUT)"

# ── nessun .md nel diff: pulita ─────────────────────────────────────────────────
printf 'x = 1\n' > "$R/codice.py"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm codice -q
OUT=$(bash "$LD" "$R" HEAD~1 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "diff senza documenti: la lente non morde (dichiarato nel log)" || ko "diff senza documenti (rc=$RC)"

# ── Vale assente: SKIP dichiarato, mai morte ────────────────────────────────────
OUT=$(VALE_BIN=/non-esiste bash "$LD" "$R" HEAD~2 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -qi "SALTATA" <<<"$OUT" && ok "Vale assente: skip dichiarato, rc 0" || ko "Vale assente: skip dichiarato (rc=$RC: $OUT)"

# ── cablaggio pre-push: l'.md accentato nel push AVVERTE (non blocca) ──────────
PP_OUT=$(cd "$R" && bash "$PP" <<< "refs/heads/main $(git -C "$R" rev-parse HEAD) refs/heads/main $(git -C "$R" rev-parse HEAD~3)" 2>&1); PP_RC=$?
if [ "$PP_RC" -eq 0 ] && grep -q "lente documenti" <<<"$PP_OUT"; then
  ok "pre-push: l'.md accentato del push AVVERTE (qualità, non blocco)"
else ko "pre-push: avviso documenti (rc=$PP_RC: $PP_OUT)"; fi

# ── annota: errorformat → annotazioni SULLA RIGA (furto reviewdog) ──────────────
GHSTUB_DIR="$SB/bin"; mkdir -p "$GHSTUB_DIR"
cat > "$GHSTUB_DIR/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "${GHSTUB_REGISTRO:-/tmp/gh-annota.reg}"
case "$1 $2" in
  "pr view") case " $* " in *" --jq "*) echo "abc123def456" ;; *) echo '{"headRefOid": "abc123def456"}' ;; esac ;;
  *) echo '{"id": 1}' ;;
esac
EOF
chmod +x "$GHSTUB_DIR/gh"
export GHSTUB_REGISTRO="$SB/gh-annota.reg"
export PATH="$GHSTUB_DIR:$PATH"
AN_OUT=$(printf '%s\n' "guida.md:5: documento[casa.AsciiSolo]: carattere accentato — la casa scrive ASCII" "riga-senza-formato" | bash "$AN" obi2kenobi/FINTO 42 2>&1); AN_RC=$?
if [ "$AN_RC" -eq 0 ] && grep -q "1 annotazioni" <<<"$AN_OUT"; then
  ok "annota: una annotazione pubblicata, la riga senza formato saltata dichiarata"
else ko "annota: una pubblicata una saltata (rc=$AN_RC: $AN_OUT)"; fi
REG=$(cat "$GHSTUB_REGISTRO")
grep -q "repos/obi2kenobi/FINTO/pulls/42/comments" <<<"$REG" && ok "annota: POST sull'endpoint dei commenti-annotazione della PR" || ko "annota: endpoint commenti PR"
grep -q "path=guida.md" <<<"$REG" && grep -q "line=5" <<<"$REG" && grep -q "commit_id=abc123def456" <<<"$REG" && ok "annota: path, line e commit nel payload (sulla RIGA, non in coda)" || ko "annota: payload incompleto ($REG)"
grep -q "annota.sh" "$GP" && ok "giorno.sh annota: cablato (il giorno annota a comando)" || ko "giorno.sh annota: cablato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
