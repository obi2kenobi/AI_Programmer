#!/bin/bash
# test-turno-vivo.sh — il detector del turno incastrato (E-017: tre notti perse
# per un processo mai tornato che il silenzio nascondeva). Contratti: sintassi;
# sistema senza processi notturni → rc 0 col messaggio; la soglia è dichiarata
# e sovrascrivibile; l'aggancio a system-health resta al suo posto (la visibilità
# che non è cablata non è visibilità).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/turno-vivo.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || ko "sintassi rotta"
OUT=$(bash "$TOOL" 2>&1); RC=$?
if echo "$OUT" | grep -q "nessun processo notturno"; then
  ok "sistema pulito: rc 0 e lo dice"
elif echo "$OUT" | grep -q "TURNO INCASTRATO"; then
  ok "il detector vede un processo REALE oltre soglia (il sistema non è a riposo: il test non finge)"
else
  ko "output inatteso a riposo (rc=$RC): $OUT"
fi
grep -q "TURNO_VIVO_SOGLIA" "$TOOL" && ok "la soglia è dichiarata e sovrascrivibile" || ko "soglia cablata muta"
grep -q "turno-vivo.sh" "$HERE/tools/system-health.sh" \
  && ok "cablato nel polso quotidiano (system-health)" || ko "detector non cablato: invisibile"
grep -q "pkill -f" "$TOOL" && ok "la pulizia consolidata è scritta nell'avviso" || ko "avviso senza la via d'uscita"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
