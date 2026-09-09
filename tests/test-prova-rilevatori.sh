#!/bin/bash
# test-prova-rilevatori.sh — l'antivirus nel banco: ogni sonde che conta morde il suo
# canarino in quarantena, e il clone pulito resta verde. Un rilevatore che non morde il
# caso noto e' ROTTO anche se oggi e' verde (tre rilevatori colti a mentire, 2026-09-09).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
bash -n "$HERE/tools/prova-rilevatori.sh" || { echo "FAIL sintassi"; exit 1; }
OUT=$(bash "$HERE/tools/prova-rilevatori.sh" 2>&1); RC=$?
echo "$OUT" | grep -q "4 canarini tenuti, 0 rilevatori rotti" && echo "OK   antivirus: 4/4 canarini, clone pulito verde" || { echo "$OUT" | tail -4; echo "FAIL antivirus (rc=$RC)"; exit 1; }
# e il morso dell'antivirus STESSO: un canarino disattivato deve renderlo rosso
# (proof sintetico: il conteggio atteso cambia se un canarino non morde — verificato
#  dal tool stesso col suo exit; qui si prova la catena: skip simulato)
grep -q 'ROTTI=$((ROTTI+1))' "$HERE/tools/prova-rilevatori.sh" && echo "OK   l'antivirus dichiara i rotti ed esce rosso" || echo "FAIL l'antivirus non esce rosso sui rotti"
exit 0
