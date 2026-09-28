#!/bin/bash
# test-numero.sh — domanda 12 di Luca (2026-09-26): «numeri CSV in formato italiano (1.234,56),
# una funzione di lettura sola li converte per tutti gli oracoli». Il banco prova la funzione
# (tools/numero.py) e che ciascun oracolo che legge numeri da un CSV la usi davvero: prima «1.234,56»
# era un ERRORE in aging, rating, margine, accuratezza, scostamento e riconciliazione, una riga
# scartata in silenzio nel bilancio per BU, e un costo «ignorato» nella valorizzazione.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$HERE/tools"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. La funzione: testo -> numero, o ValueError.
leggi() { PYTHONPATH="$T" python3 -c 'import sys; from numero import leggi_numero; print(leggi_numero(sys.argv[1]))' "$1" 2>&1; }
while IFS='|' read -r IN ATTESO; do
  GOT=$(leggi "$IN" | tail -1)
  [ "$GOT" = "$ATTESO" ] && ok "leggi_numero «${IN}» -> $ATTESO" || ko "leggi_numero «${IN}»: atteso $ATTESO, uscito $GOT"
done <<'CASI'
1.234,56|1234.56
-1.234,56|-1234.56
1234,5|1234.5
 12,00 |12.0
1.234.567,89|1234567.89
1.234|1234.0
1234.56|1234.56
-0.5|-0.5
100|100.0
0.500|0.5
CASI
for IN in "" "abc" "1,234,56" "1.23,4" "12.34.56"; do
  grep -q "ValueError" <<<"$(leggi "$IN")" && ok "leggi_numero «${IN}» rifiutato (ValueError)" || ko "leggi_numero «${IN}» accettato: $(leggi "$IN" | tail -1)"
done

# 2. Ogni oracolo la usa: la stessa cifra all'italiana e col punto danno lo stesso risultato.
printf 'giorni,tipo,importo\n10,Cliente,"1.234,56"\n' > "$TMP/a.csv"
grep -qF "Entrate: +1234.56" <<<"$(python3 "$T/scadenzario_aging.py" < "$TMP/a.csv" 2>&1)" \
  && ok "aging legge 1.234,56" || ko "aging: $(python3 "$T/scadenzario_aging.py" < "$TMP/a.csv" 2>&1 | tail -1)"

H='tipo,data_documento,data_registrazione,nr_doc,cliente,descrizione,importo'
printf '%s\nfattura,2026-01-01,,1,Rossi,,"1.234,56"\npagamento,2026-01-05,,2,Rossi,,"1.234,56"\n' "$H" > "$TMP/r.csv"
OUT=$(python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ! grep -q "NON MATCHATO" <<<"$OUT" && grep -q "^rossi .* 4 gg" <<<"$OUT" && ok "rating legge 1.234,56 e abbina il pagamento (importi uguali)" || ko "rating: rc $RC $(tail -1 <<<"$OUT")"

printf 'rif,importo\nRF1,"1.200,00"\n' > "$TMP/mv.csv"; printf 'rif,importo\nRF1,"1.000,00"\n' > "$TMP/ma.csv"
grep -qF "margine=+200.00" <<<"$(python3 "$T/margine_documento.py" "$TMP/mv.csv" "$TMP/ma.csv" 2>&1)" \
  && ok "margine legge 1.200,00 e 1.000,00 (margine 200)" || ko "margine: $(python3 "$T/margine_documento.py" "$TMP/mv.csv" "$TMP/ma.csv" 2>&1 | tail -1)"

echo '{}' > "$TMP/cfg.json"
printf 'nr,importo,ordine_nr,fornitore\nF1,"1.000,00",O1,A\n' > "$TMP/fn.csv"; printf 'nr,importo\nO1,"1.000,00"\n' > "$TMP/on.csv"
OUT=$(python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/cfg.json" "$TMP/fn.csv" "$TMP/on.csv" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ! grep -q "ERRORE" <<<"$OUT" && ok "accuratezza legge 1.000,00" || ko "accuratezza: rc $RC $(tail -1 <<<"$OUT")"

OUT=$(printf 'conto,posting_date,bu,amount\n1,2026-01-01,ARRG,"-1.234,56"\n' | python3 "$T/bilancio_bu.py" 2>&1)
grep -qF "TOTALE          1234.56" <<<"$OUT" && ! grep -qi "scartat" <<<"$OUT" && ok "bilancio per BU legge -1.234,56 (non la scarta)" || ko "bilancio: $(tr '\n' ' ' <<<"$OUT" | cut -c1-160)"

printf 'codice,gruppo,categoria,location,qty,costo_medio\nA,G,C,PRINCIPALE,"1.000","2,50"\n' > "$TMP/v.csv"
OUT=$(python3 "$T/valorizzazione_magazzino.py" "$TMP/cfg.json" < "$TMP/v.csv" 2>&1)
grep -qF "Valore totale (solo location considerate): 2500.00 EUR" <<<"$OUT" && ok "valorizzazione legge qty 1.000 e costo 2,50" || ko "valorizzazione: $(tr '\n' ' ' <<<"$OUT" | cut -c1-160)"

OUT=$(printf 'costo_eff_unitario,qta_prodotta\n"10,50","1.000"\n' | python3 "$T/scostamento_standard_effettivo.py" 10 2>&1)
grep -qF "Scostamento: +5.0%" <<<"$OUT" && ok "scostamento legge 10,50 e 1.000" || ko "scostamento: $(tr '\n' ' ' <<<"$OUT" | cut -c1-160)"

OUT=$(printf 'codice,qty_bc,costo_finale,qty_fisica,stato\nA,"1.000","2,50","1.002",\n' | python3 "$T/riconciliazione_magazzino.py" 2>&1)
grep -qF "A: delta=+2 deltaValore=+5.00" <<<"$OUT" && ok "riconciliazione legge 1.000, 2,50 e 1.002" || ko "riconciliazione: $(tr '\n' ' ' <<<"$OUT" | cut -c1-160)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
