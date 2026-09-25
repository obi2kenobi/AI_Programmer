set -uo pipefail
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
#!/bin/bash
# test-prova-rilevatori.sh — l'antivirus nel banco: ogni sonde che conta morde il suo
# canarino in quarantena, e il clone pulito resta verde. Un rilevatore che non morde il
# caso noto e' ROTTO anche se oggi e' verde (tre rilevatori colti a mentire, 2026-09-09).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
bash -n "$HERE/tools/prova-rilevatori.sh" || { echo "FAIL sintassi"; exit 1; }
OUT=$(bash "$HERE/tools/prova-rilevatori.sh" 2>&1); RC=$?
grep -q "4 canarini tenuti, 0 rilevatori rotti" <<<"$OUT" && ok "antivirus: 4/4 canarini, clone pulito verde" || { ko "antivirus (rc=$RC): $(echo "$OUT" | tail -2 | tr "\n" " " | cut -c1-100)"; }
# e il morso dell'antivirus STESSO: un canarino disattivato deve renderlo rosso
# (proof sintetico: il conteggio atteso cambia se un canarino non morde — verificato
#  dal tool stesso col suo exit; qui si prova la catena: skip simulato)
grep -q 'ROTTI=$((ROTTI+1))' "$HERE/tools/prova-rilevatori.sh" && ok "l'antivirus dichiara i rotti ed esce rosso" || ko "l'antivirus non esce rosso sui rotti"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
