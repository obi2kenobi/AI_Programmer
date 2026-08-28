#!/bin/bash
# test-verifica-visiva-estrai-testo.sh — banco di regressione nato dalla revisione "L'Hub
# Allo Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in tools/verifica-visiva.js,
# la rimozione dei tag HTML lasciava intatto il contenuto di <script>/<style> — il codice
# JS di una pagina normale contiene quasi sempre "undefined" (es. typeof x === "undefined"),
# facendo scattare un falso "segnale d'errore" su pagine perfettamente sane. Difetto
# simmetrico (falso rosso) di quello che lo strumento dichiara di prevenire.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

command -v node >/dev/null 2>&1 || { echo "node non disponibile, salto"; exit 0; }

RISULTATO=$(node - "$HERE/tools/verifica-visiva.js" <<'JS'
const { estraiTesto, SEGNALI_ERRORE, SOGLIA_TESTO_VUOTO } = require(process.argv[2]);
const checks = [];

// caso 1 — bug reale: pagina sana con "undefined" solo dentro <script>
const domSano = '<html><head><script>function check(x){ return typeof x === "undefined"; }</script></head>' +
  '<body><p>Pagina normale con abbastanza testo visibile per superare la soglia dei quaranta caratteri.</p></body></html>';
const testoSano = estraiTesto(domSano);
const trovatoSano = SEGNALI_ERRORE.find((s) => testoSano.toLowerCase().includes(s.toLowerCase()));
checks.push(["pagina sana con 'undefined' solo nello <script>: nessun falso positivo", !trovatoSano]);

// caso 2 — <style> non deve inquinare il testo estratto
const domStile = '<html><head><style>.err::before{content:"exception"}</style></head>' +
  '<body><p>Contenuto valido, sufficientemente lungo da superare la soglia minima di caratteri.</p></body></html>';
const testoStile = estraiTesto(domStile);
const trovatoStile = SEGNALI_ERRORE.find((s) => testoStile.toLowerCase().includes(s.toLowerCase()));
checks.push(["contenuto CSS con 'exception': nessun falso positivo", !trovatoStile]);

// caso 3 — un vero segnale d'errore nel BODY (non nello script) deve restare rilevato
const domRotto = '<html><body><p>Spiacenti, si è verificato un errore inatteso nella pagina.</p></body></html>';
const testoRotto = estraiTesto(domRotto);
const trovatoRotto = SEGNALI_ERRORE.find((s) => testoRotto.toLowerCase().includes(s.toLowerCase()));
checks.push(["errore vero nel body: ancora rilevato (nessuna regressione)", !!trovatoRotto]);

// caso 4 — pagina quasi vuota (dopo la rimozione di script/style) resta rilevata come tale
const domVuoto = '<html><head><script>var x = 1; var undefined_marker = "undefined";</script></head><body></body></html>';
const testoVuoto = estraiTesto(domVuoto);
checks.push(["pagina vuota nel body: testo sotto soglia anche con script rumoroso", testoVuoto.length < SOGLIA_TESTO_VUOTO]);

for (const [nome, esito] of checks) {
  console.log((esito ? "OK" : "KO") + "\t" + nome);
}
JS
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
