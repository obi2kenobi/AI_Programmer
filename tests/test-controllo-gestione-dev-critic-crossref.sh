#!/bin/bash
# test-controllo-gestione-dev-critic-crossref.sh — 4° ciclo, SET 1 giro 7. dev-critic
# ha già una lente §2ter matematico-finanziaria (REVISIONA calcoli esistenti) e la nuova
# skill controllo-gestione (giro 1) COSTRUISCE calcoli nuovi — stesso dominio, stessa
# disciplina (oracolo/invariante), ma nessuna delle due citava l'altra: chi trova una
# delle due non scoprirebbe l'altra. Verifica il rimando in entrambe le direzioni e che
# i percorsi citati esistano davvero.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CG="$HERE/.claude/skills/controllo-gestione/SKILL.md"
DC="$HERE/.claude/skills/dev-critic/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'dev-critic' "$CG" \
  && ok "controllo-gestione rimanda a dev-critic (per la revisione dopo il merge)" \
  || ko "controllo-gestione non cita dev-critic"

grep -q 'controllo-gestione' "$DC" \
  && ok "dev-critic rimanda a controllo-gestione (per la costruzione prima del codice)" \
  || ko "dev-critic non cita controllo-gestione"

grep -q 'banco-sintetico-per-calcoli-critici' "$CG" \
  && ok "controllo-gestione cita il pattern del banco sintetico" \
  || ko "controllo-gestione non cita il pattern condiviso"

[ -f "$HERE/patterns/banco-sintetico-per-calcoli-critici.md" ] \
  && ok "il pattern citato esiste davvero" \
  || ko "il pattern citato non esiste"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
