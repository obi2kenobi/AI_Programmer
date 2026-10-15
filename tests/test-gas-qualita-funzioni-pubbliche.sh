#!/bin/bash
# test-gas-qualita-funzioni-pubbliche.sh — la terza proposta dei report di campo del 2026-09-30 e 2026-10-01 (riordino-legno): in una web app Apps Script OGNI funzione globale
# senza «_» finale e' un endpoint (google.script.run). `getAccessToken()` restituiva al browser un token valido di Business Central: la famiglia dell'underscore finale
# esisteva (famiglie-difetti.md:182) ma nessun controllo meccanico la applicava. Qui: una funzione pubblica che restituisce un token o che legge/usa un segreto e' un sito.
# Le funzioni che USANO un token per fare altro (e restituiscono dati) non sono un sito; doGet/doPost e i gestori `onXxx` sono pubblici per costruzione.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# siti <id> <sorgente>: quanti siti ha la famiglia «funzioni pubbliche …» per quel file (l'id nomina la cartella: una sostituzione di comando non puo' aggiornare un contatore del chiamante)
siti() { local d="$TMP/c$1"; mkdir -p "$d"; printf '%s\n' "$2" > "$d/Codice.gs"; python3 "$HERE/tools/gas_qualita.py" "$d" 2>&1 | grep -E "^## funzioni pubbliche" | grep -oE '[0-9]+$'; }
sito_testo() { python3 "$HERE/tools/gas_qualita.py" "$TMP/c$1" 2>&1 | grep -A3 "^## funzioni pubbliche"; }

POS=(
"function getAccessToken() {
  var p = { client_secret: SEGRETO };
  var r = UrlFetchApp.fetch(URL, { method: 'post', payload: p });
  return JSON.parse(r.getContentText()).access_token;
}"
"function leggiProprieta() { return PropertiesService.getScriptProperties().getProperty('BC_CLIENT_SECRET'); }"
"function dammiIlToken() { var token = calcola_(); return token; }"
"function passa() { return getAccessToken_(); }"
)
i=0
for caso in "${POS[@]}"; do
  i=$((i+1))
  [ "$(siti "p$i" "$caso")" = "1" ] && ok "pubblica con segreto o token restituito: rilevata (${caso:0:42}…)" || ko "NON rilevata: ${caso:0:60}"
done
sito_testo p4 | grep -qE "Codice.gs:[0-9]+ passa\(\) \[restituisce un token\]" && ok "il sito dice file:riga" || ko "sito senza file:riga"

NEG=(
"function getAccessToken_() { var p = { client_secret: SEGRETO }; return JSON.parse(UrlFetchApp.fetch(URL, { payload: p })).access_token; }"
"function doGet() { return HtmlService.createHtmlOutput(getProperty_('client_secret')); }"
"function onOpen() { var s = PropertiesService.getScriptProperties().getProperty('API_KEY'); SpreadsheetApp.getUi().createMenu(s).addToUi(); }"
"function elencoOrdini() { var token = getAccessToken_(); return leggiOrdini_(token); }"
"function elencoOrdini2() { return leggiOrdini_(getAccessToken_()); }"
"function sommaTotali() { return [1, 2, 3].reduce(function(a, b) { return a + b; }, 0); }"
)
i=0
for caso in "${NEG[@]}"; do
  i=$((i+1))
  [ "$(siti "n$i" "$caso")" = "0" ] && ok "NON e' un sito: ${caso:0:60}" || ko "falso positivo su: ${caso:0:60}"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
