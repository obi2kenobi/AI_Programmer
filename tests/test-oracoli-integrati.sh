#!/bin/bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf 'codice,gruppo,categoria,location,qty,costo_medio\nA1,LEGNO,PANNELLI,PRINCIPALE,10,100\nA2,LEGNO,TRAVI,PRINCIPALE,4,50\nA3,METALLO,VITERIA,PRINCIPALE,2,20\n' > "$TMP/righe.csv"
printf '{"override_gruppi":{"LEGNO":{"type":"PERCENTUALE","value":5}},"location_escluse":["SD"],"costi_generali_percent":0}' > "$TMP/config.json"
V=$(python3 "$HERE/tools/valorizzazione_magazzino.py" "$TMP/config.json" < "$TMP/righe.csv" 2>/dev/null | grep "Valore totale" | grep -oE '[0-9]+\.[0-9]+')
python3 -c "abs($V - 1274.0) < 0.01" && ok "valorizzazione 1274" || ko "valore: $V"
printf 'conto,posting_date,bu,amount\n510000,2026-01-01,LEGNO,-1000\n610000,2026-01-01,LEGNO,600\n510000,2026-01-01,METALLO,-500\n610000,2026-01-01,METALLO,700\n' > "$TMP/gl.csv"
B=$(python3 "$HERE/tools/bilancio_bu.py" < "$TMP/gl.csv" 2>/dev/null | grep "TOTALE" | grep -oE '\-[0-9]+\.[0-9]+' | head -1)
python3 -c "abs($B - (-600.0)) < 0.01" && ok "bilancio -600" || ko "bilancio: $B"
echo ""; echo "$PASS OK, $FAIL FAIL"; [ $FAIL -eq 0 ]
