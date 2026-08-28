#!/bin/bash
# test-banco-passaggio.sh — il banco di fine passaggio sotto prova (esso stesso
# è «codice appena scritto»: il banco 7 lo aveva SCOPERTO, questo test è la
# risposta). Si usa --solo-copertura: il banco intero in suite costerebbe
# minuti a ogni .night-verify — qui si prova il contratto del banco 7, che è
# la parte nuova: vede i file NUOVI non tracciati, li segnala, e le esclusioni
# giustificate chiudono.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BANCO="$HERE/tools/banco-passaggio.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$BANCO" ] && ok "il banco è eseguibile" || ko "banco non eseguibile"
bash -n "$BANCO" && ok "sintassi del banco" || ko "sintassi rotta"
grep -q -- "--solo-copertura" "$BANCO" && ok "esiste la via rapida --solo-copertura" || ko "manca --solo-copertura"

# il banco 7 VEDRE un tool nuovo che nessun test cita (git diff non li vedeva:
# i non tracciati sono il caso tipico del codice appena scritto — provato a mano)
# il nome del probe è unico a RUNTIME ($$): il nome letterale dentro QUESTO file
# renderebbe il probe «coperto» dal test stesso (scoperto così: il banco diceva
# presidiato perché questo test cita il nome — auto-copertura circolare)
PROBE="tools/_scoperto_$$_prova.py"
printf '#!/usr/bin/env python3\nprint("prova")\n' > "$HERE/$PROBE"
OUT=$(bash "$BANCO" --solo-copertura 2>&1); RC=$?
[ $RC -ne 0 ] && echo "$OUT" | grep -qF "$PROBE" \
  && ok "tool nuovo non coperto: visto e dichiarato, il banco non chiude" \
  || ko "tool nuovo non coperto NON visto (rc=$RC)"
rm -f "$HERE/$PROBE"

# esclusione giustificata: il banco chiude (dichiarato, non dimenticato)
printf '%s # esiste solo dentro questo test, giustificato qui\n' "$PROBE" >> "$HERE/tools/banco-passaggio.esclusioni"
printf '#!/usr/bin/env python3\nprint("prova")\n' > "$HERE/$PROBE"
OUT=$(bash "$BANCO" --solo-copertura 2>&1); RC=$?
[ $RC -eq 0 ] && ok "esclusione giustificata: il banco chiude" \
  || { echo "$OUT" | tail -2 | sed 's/^/    /'; ko "esclusione ignorata"; }
rm -f "$HERE/$PROBE"
git -C "$HERE" checkout -- tools/banco-passaggio.esclusioni 2>/dev/null || true

# dopo la pulizia il banco torna verde (il repo vero non ha scoperti)
OUT=$(bash "$BANCO" --solo-copertura 2>&1); RC=$?
[ $RC -eq 0 ] && ok "pulito: copertura OK ($(echo "$OUT" | head -1))" || { echo "$OUT" | sed 's/^/    /'; ko "copertura rossa su repo pulito"; }

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
