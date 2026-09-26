#!/bin/bash
# test-turno-vivo.sh — il detector del turno incastrato (E-017: tre notti perse
# per un processo mai tornato che il silenzio nascondeva). Dal 2026-09-18
# (era continua): il contratto non e' piu' sull'eta' del processo (vecchio =
# by design, 24/7) ma sul FRESCO DEL LOG — un ciclo non supera i ~15 minuti.
# Contratti: log fresco -> rc 0; log fermo oltre soglia -> rc 1 TURNO INCASTRATO
# e indica dove guardare; senza log -> rc 0 dichiarato; timestamp rotto -> rc 2 (non so, dal 2026-09-24)
# (mai un rosso su input illeggibile); soglia sovrascrivibile; cablato in
# system-health; la pulizia scritta nell'avviso.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/turno-vivo.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || { ko "sintassi rotta"; exit 1; }

TMP=$(mktemp -d /tmp/test-turnovivo.XXXXXX); trap 'rm -rf "$TMP"' EXIT
ADESSO=$(date '+%Y-%m-%d %H:%M:%S')
# (D22): `date -v` e' BSD — su Linux VECCHIO restava vuoto e tre attese cadevano per il
# calendario, non per il tool. python3 conta i minuti uguale ovunque.
VECCHIO=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(minutes=90)).strftime('%Y-%m-%d %H:%M:%S'))")

printf '[%s] === TURNO INIZIATO (1 repo in coda) ===\n' "$ADESSO" > "$TMP/fresco.log"
OUT=$(TURNO_VIVO_LOG="$TMP/fresco.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "cicla" <<<"$OUT" && ok "log fresco: rc 0, il turno cicla" || ko "log fresco: rc=$RC, $OUT"

printf '[%s] === TURNO INIZIATO (1 repo in coda) ===\n[un passo qualsiasi]\n' "$VECCHIO" > "$TMP/fermo.log"
OUT=$(TURNO_VIVO_LOG="$TMP/fermo.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 1 ] && grep -q "TURNO INCASTRATO" <<<"$OUT" && ok "log fermo 90min: rc 1 INCASTRATO" || ko "log fermo: rc=$RC, $OUT"
grep -q "ultima riga" <<<"$OUT" && ok "dice DOVE guardare (ultima riga del log)" || ko "non dice dove guardare"

OUT=$(TURNO_VIVO_LOG="$TMP/inesistente.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "niente da giudicare" <<<"$OUT" && ok "senza log: rc 0 dichiarato" || ko "senza log: rc=$RC, $OUT"

printf '[data-fantasma] === TURNO INIZIATO ===\n' > "$TMP/rotto.log"
OUT=$(TURNO_VIVO_LOG="$TMP/rotto.log" bash "$TOOL" 2>&1); RC=$?
# (2026-09-24, Q3 R6): era rc 0 «non urla al lupo» — ma 0 vuol dire «cicla», e il polso lo contava ✅. Ora 2,
# «non so»: il polso lo segna ⚠️, che non e' un allarme e non e' un verde
[ "$RC" -eq 2 ] && grep -c "NON SO" <<<"$OUT" >/dev/null && ok "timestamp illeggibile: rc 2 (non so), non un verde" || ko "timestamp rotto: rc=$RC, $OUT"

OUT=$(TURNO_VIVO_LOG="$TMP/fermo.log" TURNO_VIVO_SOGLIA=120 bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "soglia sovrascrivibile (120min: il fermo da 90min e' sano)" || ko "soglia non rispettata: rc=$RC"

grep -q "turno-vivo.sh" "$HERE/tools/system-health.sh" \
  && ok "cablato nel polso quotidiano (system-health)" || ko "detector non cablato: invisibile"
OUT=$(TURNO_VIVO_LOG="$TMP/fermo.log" bash "$TOOL" 2>&1)
grep -q "pkill -f" <<<"$OUT" && ok "la pulizia consolidata e' scritta nell'avviso" || ko "avviso senza la via d'uscita"

# (2026-09-24, quarto ventaglio, Q3 R6): un timestamp illeggibile usciva 0, cioe' «il turno cicla», e il polso
# (system-health) lo contava ✅. «Non so giudicare» e' un terzo esito (2), che il polso segna ⚠️.
printf '[24/09/2026 03:00:00] === TURNO INIZIATO ===\n' > "$TMP/illeggibile.log"
OUT=$(TURNO_VIVO_LOG="$TMP/illeggibile.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "timestamp illeggibile: esce 2 (non so), non 0 (cicla)" || ko "timestamp illeggibile: rc=$RC"
grep -c 'turno-vivo.sh.*2)' "$HERE/tools/system-health.sh" >/dev/null && ok "system-health mappa il 2 di turno-vivo su un avviso" || ko "system-health non distingue il 2"


# (2026-09-25, settimo ventaglio, V3 R4): l'eta' si calcolava fra due ore locali «ingenue». Al cambio dell'ora di
# primavera 15 minuti veri diventavano 75 (e un pkill da incollare contro un turno sano); in autunno l'eta' veniva
# negativa e il messaggio diceva «illeggibile». L'ora «adesso» si finge con un sitecustomize (time.time), nel fuso di Roma.
mkdir -p "$TMP/py"; printf 'import os, time\nf = os.environ.get("FAKE_NOW")\nif f:\n    time.time = lambda: float(f)\n' > "$TMP/py/sitecustomize.py"
ORA=$(TZ=Europe/Rome python3 -c 'import time; print(time.mktime(time.strptime("2027-03-28 03:05:00", "%Y-%m-%d %H:%M:%S")))')
echo "[2027-03-28 01:50:00] === TURNO INIZIATO" > "$TMP/primavera.log"
OUT=$(TZ=Europe/Rome FAKE_NOW="$ORA" PYTHONPATH="$TMP/py" TURNO_VIVO_LOG="$TMP/primavera.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ! grep -c 'INCASTRATO' <<<"$OUT" >/dev/null && ok "V3 R4: al cambio dell'ora di primavera 15 minuti veri restano 15 (niente ⛔)" \
  || ko "V3 R4: primavera: rc=$RC, $(head -1 <<<"$OUT")"
ORA=$(TZ=Europe/Rome python3 -c 'import time; print(time.mktime(time.strptime("2026-10-25 02:50:00", "%Y-%m-%d %H:%M:%S")) + 1200)')
echo "[2026-10-25 02:50:00] === TURNO INIZIATO" > "$TMP/autunno.log"
OUT=$(TZ=Europe/Rome FAKE_NOW="$ORA" PYTHONPATH="$TMP/py" TURNO_VIVO_LOG="$TMP/autunno.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "V3 R4: nell'ora ripetuta d'autunno l'eta' non e' negativa (niente «illeggibile»)" || ko "V3 R4: autunno: rc=$RC, $(head -1 <<<"$OUT")"
# (2026-09-25, D39): la console ruota (copia e tronca) all'inizio del ciclo — per qualche minuto il file nuovo non ha
# ancora il suo TURNO INIZIATO, che sta nel .1. L'ultimo ciclo si cerca in tutti e due.
printf '[%s] === TURNO INIZIATO (1 repo in coda) ===\n' "$ADESSO" > "$TMP/ruotato.log.1"
printf '[%s] REPO r/x: un passo\n' "$ADESSO" > "$TMP/ruotato.log"
OUT=$(TURNO_VIVO_LOG="$TMP/ruotato.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "cicla" <<<"$OUT" && ok "D39: console appena ruotata: l'ultimo ciclo si trova nel .1" || ko "D39: console ruotata: rc=$RC, $(head -1 <<<"$OUT")"

# (2026-09-25, D30, risposta delegata): un'issue ha un watchdog di 240 minuti — con un'issue in lavoro da 45 minuti il ⛔
# (con il pkill da incollare) arrivava contro un turno sano. Se il ciclo corrente ha cominciato un'issue, la soglia e' il
# watchdog piu' 15 minuti di margine.
MIN45=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(minutes=45)).strftime('%Y-%m-%d %H:%M:%S'))")
MIN300=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(minutes=300)).strftime('%Y-%m-%d %H:%M:%S'))")
printf '[%s] === TURNO INIZIATO (1 repo in coda) ===\n[%s] --- Issue #12: una commessa lunga\n' "$MIN45" "$MIN45" > "$TMP/issue.log"
OUT=$(TURNO_VIVO_LOG="$TMP/issue.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "issue in corso" <<<"$OUT" && ok "D30: issue in lavoro da 45 minuti: nessun ⛔, e lo dice" || ko "D30: issue da 45 min: rc=$RC, $(head -1 <<<"$OUT")"
printf '[%s] === TURNO INIZIATO (1 repo in coda) ===\n[%s] --- Issue #12: una commessa lunga\n' "$MIN300" "$MIN300" > "$TMP/issue.log"
OUT=$(TURNO_VIVO_LOG="$TMP/issue.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "D30: issue ferma da 300 minuti (oltre il watchdog): ⛔" || ko "D30: issue da 300 min: rc=$RC"
printf '[%s] === TURNO INIZIATO (1 repo in coda) ===\n' "$MIN45" > "$TMP/senza.log"
OUT=$(TURNO_VIVO_LOG="$TMP/senza.log" bash "$TOOL" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "D30: senza issue in corso la soglia resta 30 minuti" || ko "D30: senza issue, 45 min: rc=$RC"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
