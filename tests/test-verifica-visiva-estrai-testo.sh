#!/bin/bash
# test-verifica-visiva-estrai-testo.sh — banco di regressione dalla revisione "Hub
# allo Specchio": la rimozione dei tag HTML lasciava intatto <script>/<style>
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

command -v node >/dev/null 2>&1 || { echo "node non disponibile, salto"; exit 0; }

OUT=$(node -e "
const m = require(process.argv[1]);
const sane = m.estraiTesto('<html><head><script>var u = undefined;</script></head><body><p>Testo sufficientemente lungo per superare la soglia minima dei caratteri.</p></body></html>');
const broken = m.estraiTesto('<html><body><p>Errore durante lelaborazione della richiesta.</p></body></html>');
console.log(sane.includes('undefined') ? 'KO script-contaminato' : 'OK sane-pulita');
console.log(broken.includes('Errore') ? 'OK errore-rilevato' : 'KO errore-perso');
// (2026-09-24, terzo ventaglio, V2 S26): l'intestazione nomina <script>/<style>, ma si provava solo <script>
const stile = m.estraiTesto('<html><head><style>.x:after{content:\\'undefined\\'}</style></head><body><p>Testo sufficientemente lungo per superare la soglia.</p></body></html>');
console.log(stile.includes('undefined') ? 'KO style-contaminato' : 'OK style-pulito');
" "$HERE/tools/verifica-visiva.js")

while IFS= read -r line; do
  case "$line" in
    OK*) PASS=$((PASS+1)); echo "OK   ${line#OK }";;
    KO*) FAIL=$((FAIL+1)); echo "FAIL ${line#KO }";;
  esac
done <<< "$OUT"

# (2026-09-24, sesto ventaglio, rinviati di S3 R6): un node che non parte non stampa nulla, e il banco
# diceva «0 OK, 0 FAIL» con rc 0. Tre esiti attesi: se ne mancano, e' rosso.
[ $((PASS+FAIL)) -eq 3 ] || ko "attesi 3 esiti da node, arrivati $((PASS+FAIL)): $(head -3 <<<"$OUT")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
