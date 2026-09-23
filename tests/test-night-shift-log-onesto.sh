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

# --- Q12 (2026-09-23, giro A5 della notte): tre promesse del turno che non si mantenevano.
# (a) `exec "$0"` a fine ciclo: lanciato come `bash night-shift.sh` da dentro night-shift/, $0 e'
#     relativo e dopo il `cd` alla radice non esiste piu' — il turno moriva al primo giro. E vuole +x.
grep -q 'exec "\$0"' "$NS" && ko "Q12a: il ciclo riparte con exec \"\$0\" (relativo dopo il cd, e vuole +x)" \
  || ok "Q12a: il ciclo non riparte piu' da \$0"
grep -q 'exec bash "\$HERE/night-shift.sh" "\$@"' "$NS" && ok "Q12a: il ciclo riparte da un percorso assoluto, via bash" \
  || ko "Q12a: manca il riavvio assoluto exec bash \"\$HERE/night-shift.sh\""
# (b) il server sordo dopo 30 minuti faceva `exit 1` promettendo «il prossimo ciclo riprovera'» e
#     «KeepAlive mi riporta»: il plist non ha KeepAlive, parte alle 23:00 — nessuno lo riportava.
PLIST="$HERE/night-shift/plist/com.luca.nightshift.plist"
grep -q KeepAlive "$PLIST" && echo "· Q12b: il plist ora ha KeepAlive — rivedere questo caso"
USCITE=$(grep -A1 -E 'log "ERRORE: server (Ollama )?sordo dopo' "$NS" | grep -c '^[[:space:]]*exit 1')
[ "$USCITE" = "0" ] && ok "Q12b: server sordo dopo la pazienza → il turno riparte da capo, non esce per sempre" \
  || ko "Q12b: $USCITE uscite per server sordo: senza KeepAlive nessuno riporta il turno prima delle 23:00"
grep -q 'KeepAlive mi riporta' "$NS" && ko "Q12b: il log promette un KeepAlive che il plist non ha" || ok "Q12b: nessuna promessa di KeepAlive nel log"
grep -q 'launchd lo riparte da solo' "$HERE/tools/turno-vivo.sh" && ko "Q12b: turno-vivo promette che launchd riparte il turno ucciso" \
  || ok "Q12b: turno-vivo non promette un riavvio che non c'e'"
# (c) l'auto-fix CRLF riscriveva il file con `mv` di un temporaneo: perdeva +x, e la PR di
#     auto-fix portava anche un cambio di modo 755→644. Si esegue la riga vera su un file 755.
RIGA_CRLF=$(grep -F "tr -d '\r' < \"\$CF\"" "$NS" | head -1)
if [ -n "$RIGA_CRLF" ]; then
  CFT=$(mktemp -d); CF="$CFT/x.sh"; printf '#!/bin/bash\r\necho ok\r\n' > "$CF"; chmod 755 "$CF"
  ( cd "$CFT" && CF="$CF" eval "$RIGA_CRLF" )
  { [ -x "$CF" ] && ! grep -q $'\r' "$CF"; } && ok "Q12c: l'auto-fix CRLF toglie i \\r e tiene +x" \
    || ko "Q12c: l'auto-fix CRLF perde +x (o lascia i \\r): $(ls -l "$CF" | cut -c1-10)"
  rm -rf "$CFT"
else
  ko "Q12c: la riga dell'auto-fix CRLF non si trova"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
