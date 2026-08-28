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
const m = require('$HERE/tools/verifica-visiva.js');
const sane = m.estraiTesto('<html><head><script>var u = undefined;</script></head><body><p>Testo sufficientemente lungo per superare la soglia minima dei caratteri.</p></body></html>');
const broken = m.estraiTesto('<html><body><p>Errore durante lelaborazione della richiesta.</p></body></html>');
console.log(sane.includes('undefined') ? 'KO script-contaminato' : 'OK sane-pulita');
console.log(broken.includes('Errore') ? 'OK errore-rilevato' : 'KO errore-perso');
")

while IFS= read -r line; do
  case "$line" in
    OK*) PASS=$((PASS+1)); echo "OK   ${line#OK }";;
    KO*) FAIL=$((FAIL+1)); echo "FAIL ${line#KO }";;
  esac
done <<< "$OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
