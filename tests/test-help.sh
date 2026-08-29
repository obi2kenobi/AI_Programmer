#!/bin/bash
# test-help.sh — il menu dei verbi sotto prova: le sezioni essenziali ci sono,
# e OGNI comando citato nel menu esiste davvero (un menu che punta a comandi
# scomparsi è la porta d'ingresso che porta nel vuoto — la stessa regola di S6
# per il README, applicata al menu operativo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

OUT=$(bash "$HERE/tools/help.sh")
echo "$OUT" | grep -q "ALLA CHIUSURA" && echo "$OUT" | grep -q "LO STUDIO" && echo "$OUT" | grep -q "LE BATTERIE" \
  && ok "le sezioni per momento d'uso ci sono" || ko "sezioni mancanti"
echo "$OUT" | grep -q "banco-passaggio.sh" && ok "il banco di fine passaggio è in menu" || ko "banco assente dal menu"

# ogni tools/<nome>.sh citato nel menu deve esistere
ROTTI=""
while IFS= read -r nome; do
  [ -n "$nome" ] || continue
  [ -e "$HERE/tools/$nome" ] || ROTTI="$ROTTI $nome"
done < <(echo "$OUT" | grep -oE '^[[:space:]]+[a-z_-]+\.(sh|py)' | tr -d ' ')
[ -z "$ROTTI" ] && ok "ogni comando del menu esiste" || ko "comandi fantasma nel menu:$ROTTI"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
