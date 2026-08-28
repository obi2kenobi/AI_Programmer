#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SAL="$HERE/SAL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# bash 3.2: loop while-read invece di array
N_TROVATE=0
N_OK=0
while IFS= read -r START; do
  N_TROVATE=$((N_TROVATE+1))
  TITOLO=$(sed -n "${START}p" "$SAL")
  END=$(awk -v s="$START" 'NR>s && /^## /{print NR; exit}' "$SAL")
  [ -z "$END" ] && END=$(wc -l < "$SAL")
  BODY=$(sed -n "$((START+1)),${END}p" "$SAL")
  echo "$BODY" | grep -qi 'criteri dichiarat' && N_OK=$((N_OK+1)) || ko "\"$TITOLO\": nessun criterio"
  echo "$BODY" | grep -qE '^\| ?Opzione' && N_OK=$((N_OK+1)) || ko "\"$TITOLO\": NESSUNA tabella"
done < <(grep -n '^### .*— design:' "$SAL" | cut -d: -f1)

if [ "$N_TROVATE" -eq 0 ]; then
  ok "nessuna voce design nel SAL attivo (archiviate in SAL-ARCHIVIO.md)"
else
  ok "trovate $N_TROVATE voci di design nel SAL attivo"
fi
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
