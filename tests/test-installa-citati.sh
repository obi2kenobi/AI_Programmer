#!/bin/bash
# test-installa-citati.sh — la lista unica di cio' che lo standard cita (tools/installa-citati.sh), al secondo giro
# (2026-09-24, sesto ventaglio, S2 R6). Senza --solo-mancanti il secondo giro stampava «17 file scritti» con l'albero
# pulito: contava le copie, non i cambiamenti, e sync-repo ne faceva la misura della PR («24 gruppi aggiornati» per
# un diff di un file). Un file identico non si riscrive e non si conta.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
git init -q "$T/sat"
N1=$(bash "$HERE/tools/installa-citati.sh" "$T/sat" 2>/dev/null | grep -c .)
[ "$N1" -gt 0 ] && ok "primo giro: $N1 percorsi scritti" || ko "primo giro: niente scritto"
OUT2=$(bash "$HERE/tools/installa-citati.sh" "$T/sat" 2>&1 >/dev/null); N2=$(bash "$HERE/tools/installa-citati.sh" "$T/sat" 2>/dev/null | grep -c .)
[ "$N2" -eq 0 ] && grep -c 'installa-citati: 0 file scritti' <<<"$OUT2" >/dev/null && ok "secondo giro: 0 file scritti, e lo dice" || ko "secondo giro: $N2 percorsi «scritti» su file identici — $OUT2"
echo "cambiato" >> "$T/sat/tools/cita-verifica.sh"
N3=$(bash "$HERE/tools/installa-citati.sh" "$T/sat" 2>/dev/null | grep -cx 'tools/cita-verifica.sh')
[ "$N3" -eq 1 ] && ok "un file diverso dall'hub si riscrive e si conta" || ko "il file cambiato non e' stato riscritto"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
