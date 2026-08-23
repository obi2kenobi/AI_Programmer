#!/bin/bash
# test-project-md-controllo-gestione.sh — 4° ciclo, SET 3 giro 1: PROJECT.md è il primo
# file che una sessione di giorno legge per il contesto specifico di un progetto (regola
# CLAUDE.md §6: "leggilo all'inizio di ogni sessione"), ma la sezione Business Central
# non citava la skill controllo-gestione (Set 1, giro 1) — una sessione che lavora su un
# calcolo contabile sui dati BC non avrebbe saputo che il metodo esiste, e avrebbe
# rischiato di trattare l'estrazione dati come se fosse anche la verifica della formula.
# Verifica il rimando e la distinzione dal censimento campi (due cose diverse: cosa
# esiste vs come si calcola).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PM="$HERE/PROJECT.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "controllo-gestione" "$PM" \
  && ok "PROJECT.md cita la skill controllo-gestione nella sezione BC" \
  || ko "PROJECT.md non cita controllo-gestione"

[ -f "$HERE/.claude/skills/controllo-gestione/SKILL.md" ] \
  && ok "la skill citata esiste davvero" \
  || ko "PROJECT.md cita una skill che non esiste"

grep -qi "distinta dal censimento campi\|diverso dal censimento" "$PM" \
  && ok "PROJECT.md distingue esplicitamente censimento campi da calcolo (non li confonde)" \
  || ko "PROJECT.md non distingue le due discipline — rischio di confonderle"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
