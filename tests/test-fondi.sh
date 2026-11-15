#!/bin/bash
# test-fondi.sh — il wrapper di merge esiste solo sopra una REVIEW FRESCA del
# revisore sul commit della PR. Niente commenti storici, banco sul working tree
# o merge laterale. Tutti gli attori esterni sono finti; il wrapper e' reale.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d /tmp/test-fondi.XXXXXX); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
H="$TMP/hub"; mkdir -p "$H/tools" "$H/night-shift"
cp "$HERE/tools/fondi.sh" "$H/tools/fondi.sh"
cat > "$H/night-shift/revisore.sh" <<'REV'
#!/bin/bash
printf '%s\n' "$*" >> "$REV_REGISTRO"
printf '%s\n' "${REV_OUTPUT:-PARERE: APPROVA}" >&2
exit "${REV_RC:-4}"
REV
chmod +x "$H/night-shift/revisore.sh"
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" <<'GH'
#!/bin/bash
printf '%s\n' "$*" >> "$GH_REGISTRO"
case "$1 $2" in
  "pr view") cat "$GH_PR_JSON" ;;
  "pr ready") [ "${GH_READY_RIFIUTA:-0}" = 1 ] && { echo 'ready rifiutato' >&2; exit 1; }; echo ready ;;
  "pr merge") [ "${GH_MERGE_RIFIUTA:-0}" = 1 ] && { echo 'head cambiato' >&2; exit 1; }; echo merged ;;
esac
GH
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH" GH_REGISTRO="$TMP/gh.log" REV_REGISTRO="$TMP/rev.log"
R="$TMP/repo"; mkdir -p "$R"; git -C "$R" init -q -b main; git -C "$R" remote add origin https://github.com/finto/repo.git
SHA_FISSO=abc123def456
cat > "$TMP/pr.json" <<EOF
{"headRefOid":"$SHA_FISSO","headRefName":"giorno/prova","mergeable":"MERGEABLE","state":"OPEN","isDraft":false}
EOF
export GH_PR_JSON="$TMP/pr.json"
fondi() {
  : > "$GH_REGISTRO"; : > "$REV_REGISTRO"
  OUT=$(FONDI_AUTO=1 bash "$H/tools/fondi.sh" "$R" 7 2>&1); RC=$?
}

# 1. Default spento: nessuna chiamata esterna, nessuna review auto-assolta.
OUT=$(bash "$H/tools/fondi.sh" "$R" 7 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q 'auto-merge spento' <<<"$OUT" && [ ! -e "$GH_REGISTRO" ] \
  && ok "spento di default: nessuna chiamata gh/review/merge" || ko "default spento: rc=$RC, $OUT"

# 2. Verde: la review fresca approva e il merge e' vincolato allo stesso SHA.
fondi
[ "$RC" -eq 0 ] && grep -q 'FONDI: SI' <<<"$OUT" && grep -q -- "--match-head-commit $SHA_FISSO" "$GH_REGISTRO" \
  && grep -q "$R 7" "$REV_REGISTRO" && ok "review fresca approva: merge solo sullo SHA revisto" || ko "verde: rc=$RC, $OUT"

# 3. Non si leggono commenti come prova: la sola via e' il revisore eseguito ora.
! grep -q 'comments' "$GH_REGISTRO" && ok "nessun commento storico usato come attestato" || ko "il wrapper legge ancora i commenti"

# 4. Due richieste = due review fresche, anche sullo stesso SHA.
fondi
cp "$REV_REGISTRO" "$TMP/rev-prima"
fondi
N_REV=$(cat "$TMP/rev-prima" "$REV_REGISTRO" | grep -c .)
[ "$N_REV" -eq 2 ] && ok "stesso SHA, nuova richiesta: review ripetuta davvero" || ko "review non fresca: $N_REV chiamate"

# 5. PR non fondibile: il revisore non viene nemmeno chiamato.
python3 - "$TMP/pr.json" "$SHA_FISSO" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['mergeable']='CONFLICTING'; json.dump(d,open(p,'w'))
PY
fondi
[ "$RC" -ne 0 ] && [ ! -s "$REV_REGISTRO" ] && ! grep -q 'pr merge' "$GH_REGISTRO" \
  && ok "PR in conflitto: NO prima della review, nessun merge" || ko "conflitto: rc=$RC, $OUT / $(cat "$GH_REGISTRO")"

# 6. Il wrapper non diventa un merge generico fuori dalle corsie consentite.
python3 - "$TMP/pr.json" "$SHA_FISSO" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d.update(mergeable='MERGEABLE',headRefName='claude/non-fondi'); json.dump(d,open(p,'w'))
PY
fondi
[ "$RC" -ne 0 ] && [ ! -s "$REV_REGISTRO" ] && ! grep -q 'pr merge' "$GH_REGISTRO" \
  && ok "branch fuori dalle corsie di fondi: NO, resta al cancelliere" || ko "branch fuori scope: rc=$RC, $OUT"

# 7. Review rinviata o veto esplicito: mai merge.
python3 - "$TMP/pr.json" "$SHA_FISSO" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['headRefName']='giorno/prova'; json.dump(d,open(p,'w'))
PY
REV_RC=2 REV_OUTPUT='prove rosse' fondi
[ "$RC" -ne 0 ] && ! grep -q 'pr merge' "$GH_REGISTRO" && ok "review rinviata = FONDI NO" || ko "rinvio: rc=$RC, $OUT"
REV_RC=4 REV_OUTPUT='PARERE: NON APPROVABILE' fondi
[ "$RC" -ne 0 ] && ! grep -q 'pr merge' "$GH_REGISTRO" && ok "veto della review = FONDI NO" || ko "veto: rc=$RC, $OUT"

# 8. Su bozza, ready avviene SOLO dopo approvazione; ready fallito ferma.
python3 - "$TMP/pr.json" "$SHA_FISSO" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['isDraft']=True; json.dump(d,open(p,'w'))
PY
GH_READY_RIFIUTA=1 fondi
[ "$RC" -ne 0 ] && grep -q 'pr ready' "$GH_REGISTRO" && ! grep -q 'pr merge' "$GH_REGISTRO" \
  && ok "bozza: ready dopo la review; rifiuto ready = nessun merge" || ko "ready fallito: rc=$RC, $OUT"

# 9. Rifiuto GitHub allo SHA atteso: NO, mai successo a vuoto.
GH_MERGE_RIFIUTA=1 fondi
[ "$RC" -eq 1 ] && grep -q 'FONDI: NO' <<<"$OUT" && ! grep -q 'FONDI: SI' <<<"$OUT" \
  && ok "GitHub rifiuta il merge sullo SHA: FONDI NO" || ko "rifiuto merge: rc=$RC, $OUT"

# 10. Senza revisore il percorso attivo e' fail-closed, anche nei satelliti.
mv "$H/night-shift/revisore.sh" "$TMP/revisore.tolto"
fondi
[ "$RC" -eq 2 ] && grep -q 'revisore.*assente' <<<"$OUT" && ! grep -q 'pr merge' "$GH_REGISTRO" \
  && ok "revisore assente = NO; nessun fallback debole nei satelliti" || ko "revisore assente: rc=$RC, $OUT"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
