#!/bin/bash
# test-night-shift-template-controllo-gestione.sh — 4° ciclo, SET 1 giro 2. La skill
# controllo-gestione (giro 1) esiste ma il template `.github/ISSUE_TEMPLATE/night-shift.md`
# — l'unico posto che un operatore/agente legge PRIMA di scrivere una commessa — non la
# citava, esattamente come accadde a /design-doc e /brainstorming (mai citati, mai letti,
# stesso pattern "citazione senza presidio" al contrario: qui la skill esiste ma non è
# raggiungibile da chi scrive la commessa). Verifica che il template la citi, e che la
# skill citata esista davvero (coerenza, non solo prosa).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$HERE/.github/ISSUE_TEMPLATE/night-shift.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'controllo-gestione' "$TEMPLATE" \
  && ok "il template cita la skill controllo-gestione" \
  || ko "il template non cita ancora controllo-gestione"

grep -q 'mai indovinata\|mai indovinarla' "$TEMPLATE" \
  && ok "il template ricorda la regola 'mai indovinare la formula' vicino alla citazione" \
  || ko "il template cita la skill ma non la regola centrale"

[ -f "$HERE/.claude/skills/controllo-gestione/SKILL.md" ] \
  && ok "la skill citata dal template esiste davvero" \
  || ko "il template cita una skill che non esiste (citazione senza presidio)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
