#!/bin/bash
# banco-selettivo.sh — gira SOLO i test che toccano il diff (furto da TIA:
# Martin Fowler). Se la mappa manca: gira tutto (degrado dichiarato).
# Uso: banco-selettivo.sh <dir-repo> [base=origin/main]
set -uo pipefail
DIR="${1:?uso: banco-selettivo.sh <dir> [base]}"; BASE="${2:-origin/main}"
cd "$DIR" || exit 2
MAPPA="$(git rev-parse --absolute-git-dir 2>/dev/null || echo .git)/test-mappa"
if [ ! -s "$MAPPA" ]; then
  echo "banco-selettivo: mappa assente — giro TUTTO (degrado dichiarato: mappa-test.sh prima)"
  [ -f .night-verify ] && exec bash .night-verify
  exit 0
fi
# i file cambiati
CAMBIATI=$(git diff --name-only "$BASE"...HEAD 2>/dev/null | head -100)
[ -n "$CAMBIATI" ] || { echo "banco-selettivo: diff vuoto — niente da selezionare"; exit 0; }
# per ogni file cambiato, trova i test che lo toccano
TESTI=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  T=$(grep "^$f " "$MAPPA" 2>/dev/null | awk '{print $2}' | sort -u)
  TESTI="$TESTI
$T"
done <<<"$CAMBIATI"
TESTI=$(sort -u <<<"$TESTI" | grep -v '^$' | head -50)
if [ -z "$TESTI" ]; then
  echo "banco-selettivo: NESSUN test tocca il diff (dichiarato) — niente da girare"
  exit 0
fi
N=$(grep -c . <<<"$TESTI")
echo "banco-selettivo: $N test pertinenti al diff ($CAMBIATI | wc -l file cambiati)"
RC=0
while IFS= read -r t; do
  [ -f "$t" ] || continue
  echo "--- $t"
  bash "$t" >/dev/null 2>&1 || { echo "⛔ $t ROSSO"; RC=1; }
done <<<"$TESTI"
[ "$RC" -eq 0 ] && echo "banco-selettivo: VERDE ($N test)" || echo "banco-selettivo: ROSSO"
exit "$RC"
