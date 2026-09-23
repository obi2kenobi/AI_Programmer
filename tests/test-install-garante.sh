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
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
