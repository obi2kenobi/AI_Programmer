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

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
