#!/bin/bash
# campo-triage.sh — il conto dei report dal campo e dei NON processati.
# Il contratto di "processato": il basename del report (senza estensione)
# compare CONTIGUO in SAL.md — è lì che le lezioni del campo finiscono. Un
# report che nessuno ha lavorato non svanisce: viene NOMINATO e il gate esce
# rosso, perché un report ignorato è il giro che non insegna niente.
# README.md non è un report (è la porta del formato): escluso dal conteggio.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOTAL=$(ls "$HERE"/docs/campo/*.md "$HERE"/docs/campo/*.html 2>/dev/null | grep -v "/README" | wc -l | tr -d ' ')
NON_PROC=0
for f in "$HERE"/docs/campo/*.md "$HERE"/docs/campo/*.html; do
  case "$f" in */README.md) continue;; esac
  [ -f "$f" ] || continue
  grep -q "$(basename "${f%.*}")" "$HERE/SAL.md" 2>/dev/null || { echo "  non processato: $(basename $f)"; NON_PROC=$((NON_PROC+1)); }
done
echo "docs/campo/: $TOTAL report, $NON_PROC non processati"
[ "$NON_PROC" -eq 0 ]
