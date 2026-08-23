#!/bin/bash
# test-dev-critic-routing-idee.sh — 4° ciclo, SET 2 giro 9. dev-critic propone "nuove
# funzionalità non considerate" ma non diceva mai qual è il passo successivo naturale
# (/brainstorming se l'idea è vaga, /design-doc se sono già visibili 2+ approcci) —
# stesso gap di flusso già chiuso altrove in questo ciclo (audit-commessa↔controllo-gestione,
# dev-critic↔controllo-gestione), qui applicato al proprio output più generico. Senza
# questo rimando, un'idea proposta da dev-critic resta un'affermazione isolata, non
# l'inizio di un percorso.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DC="$HERE/.claude/skills/dev-critic/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# la riga deve stare nella categoria "Nuove funzionalità non considerate", non altrove
SEZ=$(awk '/Nuove funzionalità non considerate/{f=1} /^$/{if(f)exit} f' "$DC")

echo "$SEZ" | grep -q "brainstorming" \
  && ok "il rimando a /brainstorming è nella sezione giusta (idea ancora vaga)" \
  || ko "nessun rimando a /brainstorming nella sezione nuove funzionalità"

echo "$SEZ" | grep -q "design-doc" \
  && ok "il rimando a /design-doc è nella sezione giusta (2+ approcci già visibili)" \
  || ko "nessun rimando a /design-doc nella sezione nuove funzionalità"

[ -f "$HERE/.claude/skills/brainstorming/SKILL.md" ] && [ -f "$HERE/.claude/skills/design-doc/SKILL.md" ] \
  && ok "entrambe le skill citate esistono davvero" \
  || ko "una delle skill citate non esiste — citazione senza presidio"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
