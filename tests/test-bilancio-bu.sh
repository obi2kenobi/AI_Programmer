#!/bin/bash
# test-bilancio-bu.sh — banco di regressione nato dalla revisione "L'Hub Allo Specchio"
# (14 lenti indipendenti, 2026-08-28): due bug reali in tools/bilancio_bu.py, nessun test
# esisteva per questo tool.
#   1. amount vuoto/non numerico diventava un costo zero silenzioso.
#   2. il controllo QUADRATURA confrontava due somme derivate ENTRAMBE dallo stesso
#      bu_tot popolato dallo stesso loop — matematicamente sempre uguali, un vero doppio
#      conteggio in aggregazione sarebbe passato "quadrato" comunque (falso positivo
#      strutturale). Il fix introduce un secondo calcolo indipendente, mai passato da
#      bu_tot, direttamente sulle righe grezze.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# Caso 1 — normale: quadratura pulita, nessuna riga scartata.
OUT1=$(printf 'conto,posting_date,bu,amount\n1,2026-01-01,ARRG,-100\n1,2026-01-01,ARRG,50\n' | python3 "$HERE/tools/bilancio_bu.py")
grep -q "^QUADRATURA: " <<<"$OUT1" \
  && ok "caso normale: quadratura pulita (nessun ROTTA)" \
  || ko "caso normale: quadratura inattesa — output: $OUT1"
grep -qE "TOTALE.*50\.00\s*$" <<<"$OUT1" \
  && ok "caso normale: margine totale = 50.00 (ricavo 100 - costo 50)" \
  || ko "margine totale atteso non trovato — output: $OUT1"

# Caso 2 — bug reale: amount vuoto non deve diventare un costo zero silenzioso, deve
# essere scartato e CONTATO.
OUT2=$(printf 'conto,posting_date,bu,amount\n1,2026-01-01,ARRG,\n1,2026-01-01,ARRG,-100\n' | python3 "$HERE/tools/bilancio_bu.py")
grep -q "ATTENZIONE: 1 riga/e scartata/e per amount vuoto" <<<"$OUT2" \
  && ok "amount vuoto: scartato e segnalato (non zero silenzioso)" \
  || ko "amount vuoto non segnalato — output: $OUT2"

# Caso 3 — watchdog-guardato: la quadratura deve saper fallire quando c'è un vero doppio
# conteggio, non solo quando i due lati derivano dallo stesso calcolo. Verifica iniettando
# un doppio conteggio in una copia del file e confrontando con il codice reale.
BUGGED=$(mktemp /tmp/bilancio_bu_bugged.XXXX.py)
python3 - "$HERE/tools/bilancio_bu.py" "$BUGGED" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
s = s.replace(
    '        t["ricavi"] += ricavo\n        t["costi"] += costo\n',
    '        t["ricavi"] += ricavo\n        t["costi"] += costo\n        t["ricavi"] += ricavo  # BUG INIETTATO\n        t["costi"] += costo  # BUG INIETTATO\n'
)
open(dst, "w").write(s)
PY
OUT_BUG=$(printf 'conto,posting_date,bu,amount\n1,2026-01-01,ARRG,-100\n1,2026-01-01,ARRG,50\n' | python3 "$BUGGED")
rm -f "$BUGGED"
grep -q "^QUADRATURA ROTTA: " <<<"$OUT_BUG" \
  && ok "watchdog-guardato: un doppio conteggio iniettato fa scattare QUADRATURA ROTTA" \
  || ko "watchdog-guardato: la quadratura non ha rilevato il doppio conteggio iniettato — output: $OUT_BUG"

# (2026-09-26, risposta di Luca alla domanda 8): l'elenco delle BU e' chiuso — ARRG, BIOC, EDIL, IMB. Il docstring prometteva
# «fuori elenco → NOBU» ma l'elenco non c'era: un refuso («ARGG») diventava una BU col suo margine. Ora va in NOBU, detto.
OUT8=$(printf 'conto,posting_date,bu,amount\n1,2026-01-01,ARRG,-100\n1,2026-01-01,ARGG,-40\n' | python3 "$HERE/tools/bilancio_bu.py" 2>&1)
! grep -qE '^ARGG ' <<<"$OUT8" && grep -q 'NOBU (movimenti non attribuiti a BU): ricavi 40.00' <<<"$OUT8" && grep -q 'ARGG' <<<"$(grep -i attenzione <<<"$OUT8")" \
  && ok "D8: una BU fuori elenco (ARGG) va in NOBU, e l'ATTENZIONE la nomina" || ko "D8: $(grep -E 'ARGG|NOBU|ATTENZIONE' <<<"$OUT8" | tr '\n' ' ')"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
