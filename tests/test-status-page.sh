#!/bin/bash
# test-status-page.sh — la pagina di stato sotto test (richiesta dal banco 7):
# NOOPEN=1 genera senza aprire il browser; la pagina porta i QUATTRO blocchi
# delle quattro domande del mattino e dichiara «mai eseguito» quando manca il
# dato (l'assenza di dato è un dato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$HERE/tools/status-page.sh" && ok "sintassi" || ko "sintassi rotta"
grep -q 'NOOPEN' "$HERE/tools/status-page.sh" && ok "esiste la via senza browser" || ko "il test aprirebbe il browser"

OUT=$(NOOPEN=1 bash "$HERE/tools/status-page.sh" 2>&1)
echo "$OUT" | grep -q "no browser" && ok "NOOPEN genera senza aprire" || ko "NOOPEN ignorato"
PAGINA="$HOME/ai-programmer-status.html"
[ -f "$PAGINA" ] && ok "la pagina viene generata" || ko "pagina assente"
grep -q "Salute" "$PAGINA" && grep -q "Metriche" "$PAGINA" \
  && ok "i blocchi salute e metriche ci sono" || ko "blocchi mancanti"
grep -qE "mai eseguito|TURNO FINITO|Gate completato" "$PAGINA" \
  && ok "i turni sono dichiarati (o 'mai eseguito': l'assenza è un dato)" || ko "stato turni assente"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
