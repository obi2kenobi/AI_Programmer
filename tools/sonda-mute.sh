#!/bin/bash
# sonda-mute.sh — conta le finestre mute di Ollama per notte e le confronta col carico
# (la misura che mancava: 4 finestre sono il singhiozzo o l'inizio del peggio?)
set -uo pipefail
L="${1:-$HOME/night-shift.log}"
echo "SONDA MUTE (ultime 3 notti)"
for i in 1 2 3; do
  D=$(date -v-${i}d +%F)
  MUTE=$(grep "^\[$D" "$L" 2>/dev/null | grep -ci "non ha risposto" || true)
  CICLI=$(grep "^\[$D" "$L" 2>/dev/null | grep -c "bilancino:" || true)
  printf "%s: %s finestre mute, %s righe bilancino\n" "$D" "${MUTE:-0}" "${CICLI:-0}"
done
MUTE_TOT=$(date -v-1d +%F | xargs -I{} grep "^\[{}" "$L" 2>/dev/null | grep -ci "non ha risposto" || true)
[ "${MUTE_TOT:-0}" -ge 6 ] && echo "⚠ DRIFT: $MUTE_TOT finestre ieri — sopra la soglia (6), guarda il carico"
