#!/bin/bash
# test-cita-verifica.sh — il dente delle citazioni file:riga (REPO-V 7/9: tre citazioni
# sbagliate scritte senza verificarle). Morso provato nei tre versi: rotta, buona, esclusa.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/cita-verifica.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

D=$(mktemp -d /tmp/cita-t.XXXXXX); trap 'rm -rf "$D"' EXIT
# 1. riga oltre la fine del file: ROSSA
printf 'vede `tools/cita-verifica.sh:9999`\n' > "$D/rotta.md"
bash "$TOOL" "$D/rotta.md" >/dev/null 2>&1 && ko "citazione oltre la fine passa" || ok "citazione oltre la fine: ROSSA"
# 2. riga che esiste: VERDE
printf 'vede `tools/cita-verifica.sh:1`\n' > "$D/buona.md"
bash "$TOOL" "$D/buona.md" >/dev/null 2>&1 && ok "citazione esistente: VERDE" || ko "citazione buona bocciata"
# 3. orario HH:MM non e' una citazione: non scatta mai
printf 'alle `14:30` e `SAL.md:12:00` non conta\n' > "$D/orario.md"
bash "$TOOL" "$D/orario.md" >/dev/null 2>&1 && ok "orario HH:MM ignorato (nessun falso positivo)" || ko "orario scambiato per citazione"
# 4. il dente e' nel pre-commit (la frontiera giusta)
grep -q "cita-verifica" "$HERE/tools/pre-commit.sh" && ok "il dente gira nel pre-commit" || ko "cita-verifica non e' nel pre-commit"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
