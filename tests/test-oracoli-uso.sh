#!/bin/bash
# test-oracoli-uso.sh — gli oracoli davanti a un input sbagliato (giro 21 dell'analisi
# profonda, 2026-09-20). Il canone degli oracoli lo dice in due docstring (indici_crisi,
# rollforward_cespiti: «Input non-parsabile: uso, non traceback») e scadenzario_aging lo fa
# dal 2026-08-28 (colonne mancanti → riga «uso:» con cosa manca). I fratelli no: file
# inesistente, colonna mancante, argomento non numerico, JSON che non e' un oggetto —
# traceback nudo in otto oracoli su undici. E uno, rollforward_cespiti, leggeva stdin DUE
# volte (json.load nel try e poi di nuovo fuori): traceback anche sull'input VALIDO — il suo
# test importava la funzione e non ha mai lanciato la riga di comando.
#
# Regola del banco: input sbagliato → exit != 0, NESSUN «Traceback» sull'output, una riga
# «uso:» o «ERRORE» che dice cosa manca. Input valido → exit 0.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T="$HERE/tools"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf 'a,b\n1,2\n' > "$TMP/ab.csv"
echo '{}' > "$TMP/vuoto.json"; echo '[]' > "$TMP/lista.json"
: > "$TMP/niente"

# dichiara: nome, comando (stdin gia' redirezionato dal chiamante) → rc!=0, niente Traceback, una riga uso/ERRORE
dichiara() {
  local NOME="$1"; shift
  local OUT RC
  OUT=$("$@" 2>&1); RC=$?
  if [ "$RC" -ne 0 ] && ! grep -q "Traceback" <<<"$OUT" && grep -qiE "^(uso:|ERRORE)" <<<"$OUT"; then
    ok "$NOME: rc $RC, dichiarato ($(grep -iE '^(uso:|ERRORE)' <<<"$OUT" | head -1 | cut -c1-70)...)"
  else
    ko "$NOME: rc $RC, traceback=$(grep -c Traceback <<<"$OUT") — $(tail -1 <<<"$OUT" | cut -c1-90)"
  fi
}

# --- D31: rollforward sull'input VALIDO ---------------------------------------------
echo '{"categoria":{"openCosto":100,"openRival":0,"openSval":0,"yearCosto":10,"yearRival":0,"yearSval":0,"openFondo":-20,"yearFondo":-5},"cespiti":[]}' > "$TMP/cespiti.json"
OUT=$(python3 "$T/rollforward_cespiti.py" < "$TMP/cespiti.json" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "^clClose: 110.00" <<<"$OUT" && grep -q "^vnClose: 85.00" <<<"$OUT" \
  && ok "rollforward: input valido → rc 0, clClose 110 e vnClose 85 (100+10-20-5)" \
  || ko "rollforward (D31): input valido → rc $RC — $(tail -1 <<<"$OUT" | cut -c1-90)"

# --- D32: input sbagliato, per oracolo ------------------------------------------------
dichiara "rollforward: JSON senza campi"        python3 "$T/rollforward_cespiti.py" < "$TMP/vuoto.json"
dichiara "leasing: file inesistente"            python3 "$T/leasing_amministrativo.py" "$TMP/nonesiste.json"
dichiara "leasing: JSON non oggetto"            python3 "$T/leasing_amministrativo.py" "$TMP/lista.json"
dichiara "leasing: JSON senza campi"            python3 "$T/leasing_amministrativo.py" "$TMP/vuoto.json"
dichiara "valorizzazione: config inesistente"   python3 "$T/valorizzazione_magazzino.py" "$TMP/nonesiste.json" < "$TMP/ab.csv"
dichiara "valorizzazione: colonne sbagliate"    python3 "$T/valorizzazione_magazzino.py" "$TMP/vuoto.json" < "$TMP/ab.csv"
dichiara "scostamento: costo non numerico"      python3 "$T/scostamento_standard_effettivo.py" --help < "$TMP/ab.csv"
dichiara "scostamento: colonne sbagliate"       python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/ab.csv"
dichiara "scostamento: stdin vuoto"             python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/niente"
dichiara "margine: file inesistenti"            python3 "$T/margine_documento.py" "$TMP/no1.csv" "$TMP/no2.csv"
dichiara "margine: colonne sbagliate"           python3 "$T/margine_documento.py" "$TMP/ab.csv" "$TMP/ab.csv"
dichiara "accuratezza: file inesistenti"        python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/no.json" "$TMP/no.csv" "$TMP/no.csv"
dichiara "accuratezza: colonne sbagliate"       python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/ab.csv" "$TMP/ab.csv"
# (2026-09-25, settimo ventaglio, V4 R4): un export Windows-1252 (Excel) era un UnicodeDecodeError nudo, cioe' il traceback
# che D32 aveva curato; la codifica non era nel banco
# (D31, 2026-09-25): un file cp1252 ora si legge; il rifiuto si prova con un byte che nemmeno cp1252 definisce (0x81)
printf 'a,b\nSedia citt\340 \201 promo,2\n' > "$TMP/cp1252.csv"
dichiara "margine: CSV non UTF-8"               python3 "$T/margine_documento.py" "$TMP/cp1252.csv" "$TMP/ab.csv"
dichiara "accuratezza: CSV non UTF-8"           python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/cp1252.csv" "$TMP/ab.csv"
dichiara "rating: colonne sbagliate"            python3 "$T/rating_dso_clienti.py" < "$TMP/ab.csv"
dichiara "rating: stdin vuoto"                  python3 "$T/rating_dso_clienti.py" < "$TMP/niente"
dichiara "riconciliazione: colonne sbagliate"   python3 "$T/riconciliazione_magazzino.py" < "$TMP/ab.csv"
printf 'codice,qty_bc,costo_finale,qty_fisica\nA1,nan,2,3\n' > "$TMP/nan.csv"
dichiara "riconciliazione: nan (era return 1 dentro categorizza → TypeError)" python3 "$T/riconciliazione_magazzino.py" < "$TMP/nan.csv"
dichiara "riconciliazione: stdin vuoto"         python3 "$T/riconciliazione_magazzino.py" < "$TMP/niente"
dichiara "bilancio_bu: colonna amount assente"  python3 "$T/bilancio_bu.py" < "$TMP/ab.csv"
dichiara "bilancio_bu: stdin vuoto"             python3 "$T/bilancio_bu.py" < "$TMP/niente"

# --- Q22a (2026-09-23, giro A4 della notte): la cura D32 provava il file VUOTO (senza intestazione).
#     Con l'intestazione giusta e ZERO righe valide nove oracoli su nove uscivano rc 0 con un verdetto
#     sullo zero — accuratezza stampava «RAGGIUNTO» con 0 fatture, bilancio_bu «QUADRATURA» con tutte
#     le righe scartate. Un estratto vuoto e' un'estrazione fallita finche' non si dimostra il
#     contrario: nessuna riga valida = nessun verdetto (ERRORE, rc != 0).
printf 'nr,importo\n' > "$TMP/solo-nr-importo.csv"
dichiara "accuratezza: solo intestazione"       python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/solo-nr-importo.csv" "$TMP/solo-nr-importo.csv"
dichiara "margine: solo intestazione"           python3 "$T/margine_documento.py" "$TMP/solo-nr-importo.csv" "$TMP/solo-nr-importo.csv"
printf 'bu,amount\n' > "$TMP/h.csv";                          dichiara "bilancio_bu: solo intestazione"       python3 "$T/bilancio_bu.py" < "$TMP/h.csv"
printf 'bu,amount\nARRG,abc\n' > "$TMP/h.csv";                dichiara "bilancio_bu: tutte le righe scartate" python3 "$T/bilancio_bu.py" < "$TMP/h.csv"
printf 'codice,qty_bc,costo_finale\n' > "$TMP/h.csv";          dichiara "riconciliazione: solo intestazione"   python3 "$T/riconciliazione_magazzino.py" < "$TMP/h.csv"
printf 'giorni,tipo,importo\n' > "$TMP/h.csv";                 dichiara "aging: solo intestazione"             python3 "$T/scadenzario_aging.py" < "$TMP/h.csv"
printf 'codice,qty\n' > "$TMP/h.csv";                          dichiara "valorizzazione: solo intestazione"    python3 "$T/valorizzazione_magazzino.py" "$TMP/vuoto.json" < "$TMP/h.csv"
printf 'tipo,data_documento,importo\n' > "$TMP/h.csv";         dichiara "rating: solo intestazione"            python3 "$T/rating_dso_clienti.py" < "$TMP/h.csv"
printf 'costo_eff_unitario,qta_prodotta\n' > "$TMP/h.csv";     dichiara "scostamento: solo intestazione"       python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/h.csv"

# --- Q22b (2026-09-23, giro A4 della notte): la cura nan/inf (D5/D6/D20) era arrivata in 3
#     oracoli su 11. Valorizzazione e leasing davano «nan EUR» con rc 0; in valorizzazione una qty
#     vuota, un tipo di override sconosciuto finivano in traceback, e un override SENZA value
#     valeva 0 in silenzio (la riga risultava «valorizzata con override»).
V="codice,gruppo,categoria,location,qty,costo_medio"
printf '%s\nA,,,,10,nan\nB,,,,5,2\n' "$V" > "$TMP/v.csv"
OUT=$(python3 "$T/valorizzazione_magazzino.py" "$TMP/vuoto.json" < "$TMP/v.csv" 2>&1)
grep -qi 'nan' <<<"$(grep -v '^ATTENZIONE' <<<"$OUT")" && ko "valorizzazione: costo_medio nan finisce nei valori: $(grep -i nan <<<"$OUT" | head -1)" \
  || ok "valorizzazione: costo_medio nan trattato come non numerico (senza costo, dichiarato), non «nan EUR»"
printf '%s\nA,,,,,2\n' "$V" > "$TMP/v.csv";    dichiara "valorizzazione: qty vuota"   python3 "$T/valorizzazione_magazzino.py" "$TMP/vuoto.json" < "$TMP/v.csv"
printf '%s\nA,,,,nan,2\n' "$V" > "$TMP/v.csv"; dichiara "valorizzazione: qty nan"     python3 "$T/valorizzazione_magazzino.py" "$TMP/vuoto.json" < "$TMP/v.csv"
printf '%s\nA,,,,10,2\n' "$V" > "$TMP/v.csv"
echo '{"override_articoli":{"A":{"type":"SCONTO","value":5}}}' > "$TMP/ovr.json"
dichiara "valorizzazione: tipo override sconosciuto" python3 "$T/valorizzazione_magazzino.py" "$TMP/ovr.json" < "$TMP/v.csv"
echo '{"override_articoli":{"A":{"type":"EURO"}}}' > "$TMP/ovr.json"
dichiara "valorizzazione: override senza value (valeva 0 in silenzio)" python3 "$T/valorizzazione_magazzino.py" "$TMP/ovr.json" < "$TMP/v.csv"
L='"canone_base":1000,"data_inizio":"2025-01-01","data_fine":"2029-12-31","spread":1.5,"euribor_stipula":3.5,"data_riferimento":"2026-09-01"'
echo "{$L,\"euribor_corrente\":\"nan\"}" > "$TMP/l.json";  dichiara "leasing: euribor_corrente nan" python3 "$T/leasing_amministrativo.py" "$TMP/l.json"
echo "{${L/1000/\"nan\"}}" > "$TMP/l.json";                   dichiara "leasing: canone nan (passava canone <= 0)" python3 "$T/leasing_amministrativo.py" "$TMP/l.json"
echo "{${L/1000/\"abc\"}}" > "$TMP/l.json";                   dichiara "leasing: canone non numerico"  python3 "$T/leasing_amministrativo.py" "$TMP/l.json"
echo "{${L/2025-01-01/2025-13-01}}" > "$TMP/l.json";           dichiara "leasing: data non valida"      python3 "$T/leasing_amministrativo.py" "$TMP/l.json"
echo "{$L}" > "$TMP/l.json"
OUT=$(python3 "$T/leasing_amministrativo.py" "$TMP/l.json" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "leasing: contratto valido senza euribor corrente → rc 0" || ko "leasing: contratto valido rc=$RC — $(tail -1 <<<"$OUT")"

# --- Q22c (2026-09-23, giro A4 della notte): il resto MECCANICO dei rilievi del giro — traceback,
#     righe che spariscono senza conteggio, «+0.0%» su un denominatore nullo, e una normalizzazione
#     diversa da quella del sorgente che il docstring cita. Nessuna formula di dominio toccata: le
#     domande di fedelta' al sistema studiato stanno in docs/giri/2026-09-23-notte/DOMANDE.md.
S="costo_eff_unitario,qta_prodotta"
printf '%s\n12,0\n13,0\n' "$S" > "$TMP/s.csv";                 dichiara "scostamento: quantita' prodotta nulla (dava -100% ALERT ALTO)" python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/s.csv"
printf '%s\nnan,5\n12,5\n30,5\n30,5\n' "$S" > "$TMP/s.csv";  dichiara "scostamento: costo nan"         python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/s.csv"
printf '%s\nabc,5\n' "$S" > "$TMP/s.csv";                       dichiara "scostamento: costo non numerico" python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/s.csv"
printf '%s\n0,5\n0,5\n11,5\n12,5\n' "$S" > "$TMP/s.csv"
OUT=$(python3 "$T/scostamento_standard_effettivo.py" 10 < "$TMP/s.csv" 2>&1); RC=$?
! grep -q Traceback <<<"$OUT" && grep -q "Trend: DATI_INSUFFICIENTI" <<<"$OUT" \
  && ok "scostamento: prima meta' a costo 0 → trend DATI_INSUFFICIENTI, non ZeroDivisionError" \
  || ko "scostamento: media1 = 0 → rc $RC, $(tail -1 <<<"$OUT" | cut -c1-80)"
echo '{"categoria":{"openCosto":100,"openRival":0,"openSval":0,"yearCosto":0,"yearRival":0,"yearSval":0,"openFondo":-20,"yearFondo":-5},"cespiti":[{"isDisposed":true,"yearCessioni":1,"costo":10,"rival":0,"sval":0}]}' > "$TMP/rf.json"
dichiara "rollforward: cespite dismesso senza fondo (KeyError)" python3 "$T/rollforward_cespiti.py" < "$TMP/rf.json"
echo '{"categoria":{"openCosto":null,"openRival":0,"openSval":0,"yearCosto":0,"yearRival":0,"yearSval":0,"openFondo":-20,"yearFondo":-5},"cespiti":[]}' > "$TMP/rf.json"
dichiara "rollforward: null in un campo della categoria (TypeError)" python3 "$T/rollforward_cespiti.py" < "$TMP/rf.json"
H='tipo,data_documento,data_registrazione,nr_doc,cliente,descrizione,importo'
printf '%s\nfattura,2026-01-01,,1,Rossi,,100\ncessione,2026-01-05,,2,Rossi,cess 25OV-000123 310226,100\n' "$H" > "$TMP/r.csv"
dichiara "rating: data di cessione impossibile (310226)" python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv"
printf '%s\nfattura,2026-01-01,,1,Rossi,,100\nnota credito,2026-01-02,,2,Rossi,,-100\n' "$H" > "$TMP/r.csv"
OUT=$(python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv" 2>&1)
grep -qiE "ignorat.*1|1 .*ignorat" <<<"$OUT" && ok "rating: la riga di tipo ignoto e' contata e detta, non sparisce" \
  || ko "rating: riga «nota credito» sparita senza conteggio: $(head -1 <<<"$OUT")"
printf 'tipo,importo,giorni\nFornitore FATTURA,1000,10\nFornitore Payment,300,10\nFornitore Fattura,200,10\n' > "$TMP/a.csv"
OUT=$(python3 "$T/scadenzario_aging.py" < "$TMP/a.csv" 2>&1)
# (2026-09-26, domanda 1): «FATTURA» ora e' riconosciuta (maiuscole indifferenti); «Payment» resta sconosciuto, e si dice
grep -q "ATTENZIONE" <<<"$OUT" && ! grep -q "FATTURA" <<<"$(grep ATTENZIONE <<<"$OUT")" && grep -q "Payment" <<<"$OUT" \
  && ok "aging: i tipi documento fornitore non riconosciuti sono DETTI (prima: entrate in silenzio)" \
  || ko "aging: tipi fornitore ignoti presi come entrate senza avviso: $(head -2 <<<"$OUT" | tr '\n' ' ')"
# (2026-09-24, quinto ventaglio, R3 R2): la cura nan/inf non era arrivata a sei oracoli — due davano un verdetto
# VERDE su dati marci: indici «🟢 Nessuna presunzione di crisi» con pn NaN, accuratezza «100% RAGGIUNTO» con
# importi nan. Un numero non finito si dichiara, rc 1.
echo '{"pn": NaN, "ricavi": 100, "oneriFin": 1, "passivoTot": 100, "debPrev": 0, "debTrib": 0, "cashFlow": 5, "attivo": 100, "attCorrenti": 200, "passCorrenti": 100}' > "$TMP/ic.json"
dichiara "indici: pn NaN (era «nessuna presunzione di crisi», rc 0)" python3 "$T/indici_crisi.py" < "$TMP/ic.json"
printf 'nr,importo,ordine_nr,fornitore\nF1,nan,O1,A\n' > "$TMP/fn.csv"; printf 'nr,importo\nO1,100\n' > "$TMP/on.csv"
dichiara "accuratezza: importo fattura nan (era «100% RAGGIUNTO»)" python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/fn.csv" "$TMP/on.csv"
printf 'nr,importo,ordine_nr,fornitore\nF1,100,O1,A\n' > "$TMP/fn.csv"; printf 'nr,importo\nO1,nan\n' > "$TMP/on.csv"
dichiara "accuratezza: importo ordine nan" python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/fn.csv" "$TMP/on.csv"
printf 'costo_eff_unitario,qta_prodotta\n10,5\n12,5\n' > "$TMP/sc.csv"
dichiara "scostamento: costo standard nan dall'argomento" python3 "$T/scostamento_standard_effettivo.py" nan < "$TMP/sc.csv"
dichiara "scostamento: costo standard inf dall'argomento" python3 "$T/scostamento_standard_effettivo.py" inf < "$TMP/sc.csv"
printf 'rif,importo\nRF1,nan\n' > "$TMP/mv.csv"; printf 'rif,importo\nRF1,100\n' > "$TMP/ma.csv"
dichiara "margine: importo vendita nan (era «Totale margine: +nan»)" python3 "$T/margine_documento.py" "$TMP/mv.csv" "$TMP/ma.csv"
printf 'rif,importo\nRF1,100\n' > "$TMP/mv.csv"; printf 'rif,importo\nRF1,inf\n' > "$TMP/ma.csv"
dichiara "margine: importo acquisto inf" python3 "$T/margine_documento.py" "$TMP/mv.csv" "$TMP/ma.csv"
echo '{"categoria":{"openCosto":NaN,"openRival":0,"openSval":0,"yearCosto":10,"yearRival":0,"yearSval":0,"openFondo":-20,"yearFondo":-5},"cespiti":[]}' > "$TMP/rf.json"
dichiara "rollforward: openCosto NaN (era «clClose: nan», rc 0)" python3 "$T/rollforward_cespiti.py" < "$TMP/rf.json"
printf '%s\nfattura,2026-01-01,,1,Rossi,,nan\npagamento,2026-01-05,,2,Rossi,,nan\n' "$H" > "$TMP/r.csv"
dichiara "rating: importo nan" python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv"
# (2026-09-24, quinto ventaglio, R3 R3): il contratto D32 si provava sulle colonne, non sulle celle. Una cella
# vuota, in formato italiano o non intera era un traceback in aging, rating, margine e accuratezza. Ora si
# rifiuta col numero di riga; se «1.234,56» vada invece LETTO e' una domanda (DEBITI, D-R3-2).
printf 'giorni,tipo,importo\n10,Cliente,\n' > "$TMP/a.csv";            dichiara "aging: importo vuoto"          python3 "$T/scadenzario_aging.py" < "$TMP/a.csv"
printf 'giorni,tipo,importo\n10,Cliente,"1.234,56"\n' > "$TMP/a.csv";  dichiara "aging: importo 1.234,56"       python3 "$T/scadenzario_aging.py" < "$TMP/a.csv"
printf 'giorni,tipo,importo\n1.5,Cliente,100\n' > "$TMP/a.csv";        dichiara "aging: giorni 1.5"             python3 "$T/scadenzario_aging.py" < "$TMP/a.csv"
printf '%s\nfattura,,,1,Rossi,,100\n' "$H" > "$TMP/r.csv";                dichiara "rating: data vuota"            python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv"
printf '%s\nfattura,24/09/2026,,1,Rossi,,100\n' "$H" > "$TMP/r.csv";      dichiara "rating: data 24/09/2026"       python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv"
printf '%s\nfattura,2026-01-01,,1,Rossi,,"1.234,56"\n' "$H" > "$TMP/r.csv"; dichiara "rating: importo 1.234,56"   python3 "$T/rating_dso_clienti.py" < "$TMP/r.csv"
printf 'rif,importo\nRF1,"1.200,00"\n' > "$TMP/mv.csv"; printf 'rif,importo\nRF1,100\n' > "$TMP/ma.csv"
dichiara "margine: importo vendita 1.200,00" python3 "$T/margine_documento.py" "$TMP/mv.csv" "$TMP/ma.csv"
printf 'rif,importo\nRF1,100\n' > "$TMP/mv.csv"; printf 'rif,importo\nRF1,\n' > "$TMP/ma.csv"
dichiara "margine: importo acquisto vuoto" python3 "$T/margine_documento.py" "$TMP/mv.csv" "$TMP/ma.csv"
printf 'nr,importo,ordine_nr,fornitore\nF1,100,O1,A\n' > "$TMP/fn.csv"; printf 'nr,importo\nO1,\n' > "$TMP/on.csv"
dichiara "accuratezza: importo ordine vuoto" python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/fn.csv" "$TMP/on.csv"
printf 'nr,importo,ordine_nr,fornitore\nF1,,O1,A\n' > "$TMP/fn.csv"; printf 'nr,importo\nO1,100\n' > "$TMP/on.csv"
dichiara "accuratezza: importo fattura vuoto" python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/vuoto.json" "$TMP/fn.csv" "$TMP/on.csv"
# (2026-09-24, quinto ventaglio, R3 R4): le guardie provavano che le chiavi ci fossero, non il loro tipo. Un
# JSON con la forma sbagliata (lista, stringa, null, data scritta come numero) era un traceback in cinque oracoli.
echo "{${L/\"2026-09-01\"/20260901}}" > "$TMP/l.json";  dichiara "leasing: data_riferimento scritta come numero" python3 "$T/leasing_amministrativo.py" "$TMP/l.json"
echo "{${L/\"2029-12-31\"/null}}" > "$TMP/l.json";       dichiara "leasing: data_fine null"                       python3 "$T/leasing_amministrativo.py" "$TMP/l.json"
printf 'nr,importo,ordine_nr,fornitore\nF1,100,O1,A\n' > "$TMP/fn.csv"; printf 'nr,importo\nO1,100\n' > "$TMP/on.csv"
dichiara "accuratezza: config lista"              python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/lista.json" "$TMP/fn.csv" "$TMP/on.csv"
echo '{"soglia_discrepanza_pct":"cinque"}' > "$TMP/c.json"
dichiara "accuratezza: soglia non numerica"       python3 "$T/accuratezza_fatture_acquisto.py" "$TMP/c.json" "$TMP/fn.csv" "$TMP/on.csv"
printf '%s\nA,,,,1,2\n' "$V" > "$TMP/v.csv"
dichiara "valorizzazione: config lista"           python3 "$T/valorizzazione_magazzino.py" "$TMP/lista.json" < "$TMP/v.csv"
echo '{"override_articoli":["A"]}' > "$TMP/c.json"
dichiara "valorizzazione: override_articoli lista" python3 "$T/valorizzazione_magazzino.py" "$TMP/c.json" < "$TMP/v.csv"
echo '{"override_articoli":{"A":"EURO+2"}}' > "$TMP/c.json"
dichiara "valorizzazione: override stringa"       python3 "$T/valorizzazione_magazzino.py" "$TMP/c.json" < "$TMP/v.csv"
echo '{"categoria":{"openCosto":100,"openRival":0,"openSval":0,"yearCosto":10,"yearRival":0,"yearSval":0,"openFondo":-20,"yearFondo":-5},"cespiti":[5]}' > "$TMP/rf.json"
dichiara "rollforward: un cespite non oggetto"    python3 "$T/rollforward_cespiti.py" < "$TMP/rf.json"
# indici: «"pn": "100"» e null erano un TypeError; li copre gia' la guardia di R3 R2 (numero finito, non bool)
sed 's/"pn": NaN/"pn": "100"/' "$TMP/ic.json" > "$TMP/ic2.json"; dichiara "indici: pn stringa (gia' coperto da R3 R2)" python3 "$T/indici_crisi.py" < "$TMP/ic2.json"
echo 5 > "$TMP/ic2.json"; dichiara "indici: JSON numero (non oggetto)" python3 "$T/indici_crisi.py" < "$TMP/ic2.json"
echo '["pn"]' > "$TMP/ic2.json"; dichiara "indici: JSON lista con un nome di campo" python3 "$T/indici_crisi.py" < "$TMP/ic2.json"
# (2026-09-24, quinto ventaglio, R3 R6): i sei oracoli che leggono stdin ignoravano un file passato come
# argomento — «aging.py scadenzario.csv» calcolava su quello che c'era in stdin, rc 0. Stdin qui e' VALIDO:
# il rifiuto viene dall'argomento, non dall'input.
printf 'giorni,tipo,importo\n10,Cliente,999\n' > "$TMP/sa.csv"
dichiara "aging: file come argomento"           python3 "$T/scadenzario_aging.py" "$TMP/sa.csv" < "$TMP/sa.csv"
printf 'codice,qty_bc,costo_finale,qty_fisica,stato\nX,10,5,5,Contato\n' > "$TMP/sr.csv"
dichiara "riconciliazione: file come argomento" python3 "$T/riconciliazione_magazzino.py" "$TMP/sr.csv" < "$TMP/sr.csv"
printf '%s\nfattura,2026-01-01,,1,Rossi,,100\n' "$H" > "$TMP/r.csv"
dichiara "rating: file come argomento"          python3 "$T/rating_dso_clienti.py" "$TMP/r.csv" < "$TMP/r.csv"
printf 'bu,amount\nARRG,100\n' > "$TMP/sb.csv"
dichiara "bilancio_bu: file come argomento"     python3 "$T/bilancio_bu.py" "$TMP/sb.csv" < "$TMP/sb.csv"
echo '{"pn":10,"ricavi":100,"oneriFin":1,"passivoTot":100,"debPrev":0,"debTrib":0,"cashFlow":5,"attivo":100,"attCorrenti":200,"passCorrenti":100}' > "$TMP/ic3.json"
dichiara "indici: file come argomento"          python3 "$T/indici_crisi.py" "$TMP/ic3.json" < "$TMP/ic3.json"
dichiara "rollforward: file come argomento"     python3 "$T/rollforward_cespiti.py" "$TMP/cespiti.json" < "$TMP/cespiti.json"
# (2026-09-24, quinto ventaglio, R3 R1): il ramo «fornitore» in minuscolo (o con uno spazio davanti) non
# assegnava l'importo — la riga prendeva quello della riga PRIMA (Entrate +2000 invece di +1500), o, se era la
# prima, un traceback. Il segno resta quello che l'ATTENZIONE dichiara (+abs, convenzione provvisoria: la
# domanda 1 di docs/giri/2026-09-23-notte/DOMANDE.md): qui si pretende solo che l'importo sia il SUO.
printf 'giorni,tipo,importo\n10,Cliente Fattura,1000\n10,fornitore Fattura,500\n' > "$TMP/a2.csv"
OUT=$(python3 "$T/scadenzario_aging.py" < "$TMP/a2.csv" 2>&1)
# (2026-09-26, domanda 1): «fornitore Fattura» e' ora un'uscita (maiuscole indifferenti): -500, col SUO importo
grep -c '^Uscite: -500.00' <<<"$OUT" >/dev/null && grep -c '^Entrate: +1000.00' <<<"$OUT" >/dev/null && ok "aging: la riga «fornitore» minuscola porta il SUO importo (-500 in uscita)" || ko "aging: riga fornitore minuscola: $(grep -E 'Entrate|Uscite' <<<"$OUT" | tr '\n' ' ')"
printf 'giorni,tipo,importo\n10, Fornitore Fattura,500\n' > "$TMP/a3.csv"
OUT=$(python3 "$T/scadenzario_aging.py" < "$TMP/a3.csv" 2>&1); RC=$?
! grep -c Traceback <<<"$OUT" >/dev/null && [ "$RC" -eq 0 ] && ok "aging: la riga «fornitore» come PRIMA riga non e' un traceback" || ko "aging: prima riga fornitore: rc=$RC $(tail -1 <<<"$OUT")"
printf 'rif,data,bu,ubicazione,importo\nFT\xc2\xa0001,2026-01-01,ARRG,X,150\nFT002,2026-01-01,ARRG,X,0\n' > "$TMP/v.csv"
printf 'rif,data,bu,fornitore,importo\nFT001,2026-01-01,ARRG,F,100\nFT002,2026-01-01,ARRG,F,100\n' > "$TMP/ac.csv"
OUT=$(python3 "$T/margine_documento.py" "$TMP/v.csv" "$TMP/ac.csv" 2>&1)
grep -q "FT001: vendita=150.00" <<<"$OUT" && ok "margine: il rif con NBSP si accoppia (\\s+ come il sorgente citato nel docstring)" \
  || ko "margine: rif con NBSP non accoppiato: $(grep -i errori <<<"$OUT")"
printf 'rif,data,bu,ubicazione,importo\nFT002,2026-01-01,ARRG,X,0\n' > "$TMP/v.csv"
OUT=$(python3 "$T/margine_documento.py" "$TMP/v.csv" "$TMP/ac.csv" 2>&1)
grep -q "Totale margine: -100.00 EUR (+0.0%" <<<"$OUT" && ko "margine: totale a ricavi nulli detto «+0.0%» su un margine di -100" \
  || ok "margine: totale a ricavi nulli → percentuale n.d., non +0.0%"
printf 'rif,data,bu,ubicazione,importo\n,2026-01-01,ARRG,X,150\n' > "$TMP/v.csv"; printf 'rif\n \n' > "$TMP/nc.csv"
OUT=$(python3 "$T/margine_documento.py" "$TMP/v.csv" "$TMP/ac.csv" "$TMP/nc.csv" 2>&1)
grep -q "Annullati da nota di credito: 1" <<<"$OUT" && ko "margine: una nota di credito col rif vuoto annulla le vendite senza rif" \
  || ok "margine: il rif vuoto di una nota di credito non annulla nulla (la vendita senza rif resta ERRORE)"
grep -q "Errori reali: .*(anomale + inesistenti + discrepanze)\")" "$T/accuratezza_fatture_acquisto.py" \
  && ko "accuratezza: l'etichetta degli errori reali tace un addendo (ordini a importo <= 0)" \
  || ok "accuratezza: l'etichetta degli errori reali elenca tutti gli addendi"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
