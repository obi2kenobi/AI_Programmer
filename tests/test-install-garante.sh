#!/bin/bash
# test-install-garante.sh — l'installatore del garante (scrive in ~/.claude/settings.json:
# UTENTE, tutte le repo): dichiara cosa scrive e non doppiona l'hook se gia' presente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/install-garante.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }
grep -q "QUESTO TOOL SCRIVE" "$TOOL" && ok "dichiara cosa scrive (il nome non mente)" || ko "non dichiara le scritture"
# (revisione 10 giri, 2026-09-23): l'installatore non veniva MAI eseguito — si guardava il vero
# ~/.claude/settings.json della macchina (e «assente» valeva ok): un tool sostituito da uno
# stub che esce 1 passava 3/3. Ora gira DAVVERO, due volte, in una HOME temporanea che porta
# gia' un hook di qualcun altro: una sola voce del garante, l'hook altrui intatto.
H=$(mktemp -d); trap 'rm -rf "$H"' EXIT
mkdir -p "$H/.claude"
printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"/x/altro-hook.sh"}]}]}}' > "$H/.claude/settings.json"
HOME="$H" bash "$TOOL" >/dev/null 2>&1; RC1=$?
HOME="$H" bash "$TOOL" >/dev/null 2>&1; RC2=$?
N=$(jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains("garante-standard"))] | length' "$H/.claude/settings.json" 2>/dev/null)
[ "$RC1" -eq 0 ] && [ "$RC2" -eq 0 ] && [ "$N" = "1" ] && ok "due installazioni: il garante c'e' UNA volta (idempotente)" || ko "idempotenza: rc=$RC1/$RC2, garante $N volte"
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command == "/x/altro-hook.sh")' "$H/.claude/settings.json" >/dev/null 2>&1 \
  && ok "l'hook gia' presente di qualcun altro resta intatto" || ko "l'installatore ha cancellato un hook altrui"
rm -f "$H/.claude/settings.json"
HOME="$H" bash "$TOOL" >/dev/null 2>&1
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | contains("garante-standard"))' "$H/.claude/settings.json" >/dev/null 2>&1 \
  && ok "settings.json assente: creato col garante" || ko "settings.json assente: garante non installato"
# (2026-09-24, notte dei giri, T6#7): con settings.json ROTTO, o senza jq, l'installatore stampava
# «✅ Garante installato» ed usciva 0 senza aver installato niente — un verde senza verdetto.
printf '{"hooks": rotto' > "$H/.claude/settings.json"; PRIMA=$(cat "$H/.claude/settings.json")
OUT=$(HOME="$H" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -c "✅" <<<"$OUT" >/dev/null && [ "$(cat "$H/.claude/settings.json")" = "$PRIMA" ] \
  && ok "settings.json rotto: rc $RC, nessun ✅, il file resta com'era" || ko "settings.json rotto: rc $RC — «$(head -1 <<<"$OUT")»"
SENZAJQ="$H/bin"; mkdir -p "$SENZAJQ"; for c in bash dirname mkdir mv cat rm; do ln -sf "$(command -v $c)" "$SENZAJQ/$c"; done
OUT=$(HOME="$H" PATH="$SENZAJQ" "$SENZAJQ/bash" "$TOOL" 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -c "✅" <<<"$OUT" >/dev/null && grep -c "jq" <<<"$OUT" >/dev/null \
  && ok "senza jq: rc $RC, nessun ✅, lo dice" || ko "senza jq: rc $RC — «$(head -1 <<<"$OUT")»"

# (2026-09-24, sesto ventaglio, S3 R2): il comando del gancio era il percorso NUDO — da un hub con uno spazio la
# shell dei ganci lo spezzava (rc 127) e il garante non girava mai, dopo «✅ Garante installato». Qui l'hub e' in
# una cartella con lo spazio, e il comando scritto si ESEGUE.
H2=$(mktemp -d); mkdir -p "$H2/hub con spazio/tools" "$H2/casa/.claude"
cp "$HERE/tools/install-garante.sh" "$H2/hub con spazio/tools/"
printf '#!/bin/bash\necho GARANTE-PARTITO\n' > "$H2/hub con spazio/tools/garante-standard.sh"; chmod +x "$H2/hub con spazio/tools/garante-standard.sh"
HOME="$H2/casa" bash "$H2/hub con spazio/tools/install-garante.sh" >/dev/null 2>&1
CMD=$(jq -r '.hooks.SessionStart[]?.hooks[]? | select(.command | contains("garante")) | .command' "$H2/casa/.claude/settings.json" 2>/dev/null)
OUTG=$(bash -c "$CMD" 2>&1); RCG=$?
[ "$RCG" -eq 0 ] && grep -c GARANTE-PARTITO <<<"$OUTG" >/dev/null && ok "S3 R2: da un hub con lo spazio nel percorso il gancio del garante parte" || ko "S3 R2: il comando del gancio non parte (rc $RCG): $CMD — $OUTG"
rm -rf "$H2"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
