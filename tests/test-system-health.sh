#!/bin/bash
# test-system-health.sh — regressione sul verdetto finale di system-health.sh.
# Bug reale trovato con dogfooding (nuovo ciclo 10 giri): la riga finale conteneva
# $⛔/RED invece di $RED — la variabile non si espandeva mai, il conteggio critici
# non compariva MAI nel verdetto, in nessun ambiente. Il test non fissa i numeri
# (dipendono dall'ambiente: curl/gh/launchctl assenti in sandbox), verifica solo che
# la riga di verdetto sia interamente espansa (nessun $ residuo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

VERDETTO=$(bash "$HERE/tools/system-health.sh" 2>/dev/null | grep "Verdetto:")

[ -n "$VERDETTO" ] && ok "riga di verdetto presente" || ko "nessuna riga di verdetto"
if ! grep -q '\$' <<<"$VERDETTO"; then
  ok "verdetto senza variabili non espanse: $VERDETTO"
else
  ko "verdetto con \$ residuo (variabile non espansa): $VERDETTO"
fi
grep -qE '[0-9]+ critici ==$' <<<"$VERDETTO" && ok "verdetto termina con un conteggio numerico di critici" \
  || ko "verdetto non termina con un numero: $VERDETTO"

# bug reale (revisione 14 lenti, 2026-08-28): `grep -c` su un repos.conf con solo
# commenti/righe vuote (coda vuota, stato NORMALE) stampava "0" ma usciva 1 — il
# fallback "|| echo 0" scattava comunque, N_REPO diventava la stringa a due righe "0\n0",
# e `[ "$N_REPO" -gt 0 ]` generava un errore di shell invece di leggere "coda vuota".
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/night-shift" "$TMP/tools"
cp "$HERE/tools/system-health.sh" "$TMP/tools/"
printf '# solo commenti\n\n' > "$TMP/night-shift/repos.conf"
OUT=$(bash "$TMP/tools/system-health.sh" 2>&1)
echo "$OUT" | grep -qi "integer expression" \
  && ko "coda con solo commenti: errore di shell — output: $OUT" \
  || ok "coda con solo commenti: nessun errore di shell"
echo "$OUT" | grep -q "repos.conf vuoto o assente" \
  && ok "coda con solo commenti: segnalata correttamente come vuota" \
  || ko "coda con solo commenti: non segnalata come vuota — output: $OUT"

# (Q30, 2026-09-23, notte dei giri): turno-vivo girava FUORI dai contatori — «⛔ TURNO INCASTRATO»
# stampato, ma il verdetto e l'exit code identici a un turno sano (il guasto delle tre notti del
# 2026-08-31 non spostava nulla, e quindi nemmeno status-page). Un log fermo alza i critici di 1.
TV=$(mktemp -d)
printf '[2026-01-01 00:00:00] === TURNO INIZIATO ===\n' > "$TV/fermo.log"
critici() { TURNO_VIVO_LOG="$1" bash "$HERE/tools/system-health.sh" 2>/dev/null | sed -n 's/.*attenzione · \([0-9]*\) critici.*/\1/p'; }
C_FERMO=$(critici "$TV/fermo.log"); C_NESSUNO=$(critici "$TV/nessuno.log")
[ -n "$C_FERMO" ] && [ "$C_FERMO" -eq $((C_NESSUNO+1)) ] && ok "turno incastrato: i critici salgono di 1 ($C_NESSUNO → $C_FERMO)" \
  || ko "turno incastrato non conta nel verdetto (critici: senza log $C_NESSUNO, log fermo ${C_FERMO:-?})"
rm -rf "$TV"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
