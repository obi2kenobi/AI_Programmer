#!/bin/bash
# test-ciclo-vivo.sh — il ciclo vivo sotto prova (100 giri di chiarezza: il
# banco 7 lo pretendeva, perché l'header era stato riscritto). Verifica:
# sintassi; un giro REALE esce e dice i finding; il CUORE e le salite di
# livello scrivono la memoria in FILE PIATTI leggibili (il contratto
# dichiarato nell'header — nessuno stato.json è mai esistito, e chi legge
# l'header deve trovare quello che l'header promette).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$HERE/tools/ciclo-vivo.sh" && ok "sintassi" || ko "sintassi rotta"
grep -q "stato.json" "$HERE/tools/ciclo-vivo.sh" && grep -q "MAI ESISTIT" "$HERE/tools/ciclo-vivo.sh" \
  && ok "l'header dichiara la storia (stato.json citato SOLO come mai esistito)" \
  || { grep -q "Memoria: .ciclo/stato.json" "$HERE/tools/ciclo-vivo.sh" && ko "l'header promette ancora stato.json che non esiste" || ok "nessun riferimento fuorviante a stato.json"; }

# un giro reale: la memoria è disposable (.ciclo gitignored), il giro è sicuro
OUT=$(bash "$HERE/tools/ciclo-vivo.sh" 2>&1); RC=$?
echo "$OUT" | grep -q "^=== CICLO VIVO" && ok "un giro parte e si presenta" || ko "il giro non parte"
echo "$OUT" | grep -q "^Finding questo giro: " && ok "il verdetto è sempre visibile" || ko "verdetto assente"
[ -f "$HERE/.ciclo/giro" ] && [ -f "$HERE/.ciclo/livello" ] \
  && ok "memoria in file piatti leggibili (giro, livello)" \
  || ko "memoria assente: i file piatti promessi dall'header non ci sono"
L=$(cat "$HERE/.ciclo/livello" 2>/dev/null)
{ [ "$L" -ge 1 ] && [ "$L" -le 5 ]; } && ok "livello nell'intervallo 1-5 ($L)" || ko "livello fuori intervallo: $L"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
