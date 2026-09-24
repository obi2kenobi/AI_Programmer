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

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
