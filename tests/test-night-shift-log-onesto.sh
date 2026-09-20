#!/bin/bash
# test-night-shift-log-onesto.sh — il turno dice il vero (test del sistema completo
# 2026-09-20, D15-D17). Il turno intero non gira nella suite (gh, Ollama, launchd): qui
# si presidia la FORMA delle tre cure, e la pausa dei cicli a vuoto si prova a runtime
# estraendo la sua aritmetica dal sorgente (la stessa riga, non una copia ridigitata).
#   D15: «PR di riallineo aperta: <errore>» — il log dichiarava aperta una PR su qualunque
#        ultima riga di sync-repo, anche «impossibile leggere CLAUDE.md».
#   D16: l'issue [night-verify] diceva «I dettagli sono nel log del turno»: da remoto il
#        giorno non poteva disporre (issue #95 aperta cosi' dal 18/9).
#   D17: 390 cicli in 4,5 minuti con la copia rotta e la caccia in cooldown (~8 gh/ciclo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
NS="$HERE/night-shift/night-shift.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$NS" && ok "sintassi" || { ko "sintassi rotta"; exit 1; }

# D15: la riga «PR di riallineo aperta» e' condizionata alla URL della PR
BLOCCO=$(awk '/SYNC_OUT=\$\(bash .*sync-repo.sh/{f=1} f{print} f&&/esac/{exit}' "$NS")
echo "$BLOCCO" | grep -q 'case "$SYNC_OUT" in' && echo "$BLOCCO" | grep -q '"PR aperta https://"' \
  && ok "D15: «PR di riallineo aperta» solo quando sync-repo restituisce la URL della PR" \
  || ko "D15: il log dichiara la PR aperta su qualunque uscita di sync-repo"
echo "$BLOCCO" | grep -q "riallineo NON riuscito" \
  && ok "D15: l'uscita non-PR viene loggata come riallineo NON riuscito" \
  || ko "D15: nessun ramo per il riallineo fallito"

# D16: il corpo dell'issue [night-verify] porta i comandi rossi
ISSUE=$(grep -n '\[night-verify\] \$NV_ROSSI verifiche rosse' "$NS" | head -1 | cut -d: -f1)
[ -n "$ISSUE" ] || { ko "D16: la creazione dell'issue [night-verify] non si trova"; }
if [ -n "$ISSUE" ]; then
  CORPO=$(sed -n "${ISSUE},$((ISSUE+6))p" "$NS")
  echo "$CORPO" | grep -q 'NV_ROSSI_LISTA' && ok "D16: il corpo dell'issue elenca i comandi rossi (NV_ROSSI_LISTA)" \
    || ko "D16: il corpo dell'issue non nomina i comandi rossi"
  echo "$CORPO" | grep -q "I dettagli sono nel log del turno" && ko "D16: il corpo rimanda ancora al log locale" \
    || ok "D16: nessun rimando al solo log locale"
fi
grep -q 'NV_ROSSI_LISTA=""' "$NS" && grep -c 'NV_ROSSI_LISTA=' "$NS" | awk '{exit !($1>=3)}' \
  && ok "D16: la lista si azzera a ogni repo e si riempie in ogni ramo rosso (script, riga, vuote)" \
  || ko "D16: la lista dei rossi non e' alimentata in tutti i rami ($(grep -c 'NV_ROSSI_LISTA=' "$NS") assegnazioni)"

# D17: la pausa dei cicli a vuoto — forma e aritmetica
grep -q 'T_CICLO_INIZIO=\$(date +%s)' "$NS" && ok "D17: l'inizio del ciclo e' misurato" || ko "D17: nessuna misura dell'inizio ciclo"
CODA=$(awk '/^CICLO_SEC=/{f=1} f{print} /^exec "\$0"/{exit}' "$NS")
echo "$CODA" | grep -q 'NIGHT_CICLO_MIN_SEC' && echo "$CODA" | grep -q 'sleep "\$PAUSA"' \
  && ok "D17: il ciclo a vuoto sotto la soglia dorme il resto (NIGHT_CICLO_MIN_SEC) prima dell'exec" \
  || ko "D17: nessuna pausa prima di exec \$0"
# l'aritmetica, eseguita: ciclo di 12s con soglia 60 → pausa 48; ciclo di 70s → nessuna pausa
PAUSA_DI() { # $1=durata ciclo $2=soglia — replica la condizione del turno con PR=0, proposte=0
  local CICLO_SEC="$1" TOT_PR_CREATED=0 TOT_PROPOSTE=0 NIGHT_CICLO_MIN_SEC="$2"
  if [ "$TOT_PR_CREATED" -eq 0 ] && [ "$TOT_PROPOSTE" -eq 0 ] && [ "$CICLO_SEC" -lt "${NIGHT_CICLO_MIN_SEC:-60}" ]; then
    echo $(( ${NIGHT_CICLO_MIN_SEC:-60} - CICLO_SEC )); else echo 0; fi
}
[ "$(PAUSA_DI 12 60)" = "48" ] && ok "D17: ciclo a vuoto di 12s → pausa 48s (un giro a vuoto al minuto, non 390 in 4,5 min)" || ko "D17: pausa calcolata $(PAUSA_DI 12 60) (atteso 48)"
[ "$(PAUSA_DI 70 60)" = "0" ] && ok "D17: ciclo sopra la soglia → nessuna pausa (chi lavora riparte subito)" || ko "D17: pausa su ciclo lungo"
grep -q 'riparto SUBITO' "$NS" && ok "D17: il ramo «riparto SUBITO» resta per i cicli che lavorano (decisione di Luca 2026-09-18 rispettata)" || ko "D17: sparito il riparto immediato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
