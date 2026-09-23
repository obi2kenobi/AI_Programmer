#!/bin/bash
# test-oracoli-integrati.sh — due oracoli contabili eseguiti insieme su dati minimi.
#
# (Revisione 10 giri, 2026-09-23): questo test NON POTEVA FALLIRE. `python3 -c "abs($V - 1274.0)
# < 0.01"` valuta l'espressione e la butta: esce 0 sempre, anche con V vuoto. E le attese erano
# SBAGLIATE: gli oracoli danno 1300.00 e un margine totale di 200.00, non 1274 e -600 (il grep
# del «-» sul TOTALE non trovava niente, B era vuoto, e il confronto passava lo stesso).
# Le attese si derivano a mano dalle formule citate negli oracoli (regola 7 di METHOD.md):
#  - valorizzazione (tools/valorizzazione_magazzino.py: PERCENTUALE = costo*(1+v/100)):
#    A1 10*100*1.05 = 1050 · A2 4*50*1.05 = 210 · A3 2*20 = 40 (nessun override) → 1300.00
#  - bilancio per BU (convenzione G/L dell'oracolo: amount<0 = ricavo, >=0 = costo):
#    ricavi 1000+500 = 1500 · costi 600+700 = 1300 → margine diretto totale 200.00
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
uguale() { # uguale <valore> <atteso>: vero solo se il valore e' un numero e coincide (±0.01)
  python3 -c "import sys; v=sys.argv[1]; sys.exit(0 if v and abs(float(v)-float(sys.argv[2]))<0.01 else 1)" "$1" "$2" 2>/dev/null
}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

printf 'codice,gruppo,categoria,location,qty,costo_medio\nA1,LEGNO,PANNELLI,PRINCIPALE,10,100\nA2,LEGNO,TRAVI,PRINCIPALE,4,50\nA3,METALLO,VITERIA,PRINCIPALE,2,20\n' > "$TMP/righe.csv"
printf '{"override_gruppi":{"LEGNO":{"type":"PERCENTUALE","value":5}},"location_escluse":["SD"],"costi_generali_percent":0}' > "$TMP/config.json"
V=$(python3 "$HERE/tools/valorizzazione_magazzino.py" "$TMP/config.json" < "$TMP/righe.csv" 2>/dev/null | grep "Valore totale" | grep -oE '[0-9]+\.[0-9]+' | head -1)
uguale "$V" 1300.0 && ok "valorizzazione: 1300.00 (derivata a mano)" || ko "valorizzazione: '$V' (attesa 1300.00)"

printf 'conto,posting_date,bu,amount\n510000,2026-01-01,LEGNO,-1000\n610000,2026-01-01,LEGNO,600\n510000,2026-01-01,METALLO,-500\n610000,2026-01-01,METALLO,700\n' > "$TMP/gl.csv"
B=$(python3 "$HERE/tools/bilancio_bu.py" < "$TMP/gl.csv" 2>/dev/null | grep "^TOTALE" | awk '{print $NF}')
uguale "$B" 200.0 && ok "bilancio per BU: margine diretto totale 200.00 (derivato a mano)" || ko "bilancio: '$B' (atteso 200.00)"

# la guardia della guardia: un valore VUOTO non e' uguale a niente
uguale "" 0 && ko "uguale() accetta il vuoto: il test tornerebbe a non poter fallire" || ok "uguale() rifiuta il vuoto"

echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
