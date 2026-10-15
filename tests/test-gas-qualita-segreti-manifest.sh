#!/bin/bash
# test-gas-qualita-segreti-manifest.sh — due falsi negativi di tools/gas_qualita.py, MISURATI sul campo (docs/campo/2026-09-30-riordino-legno-adozione-cloud.md,
# 2026-10-01-riordino-legno-analisi-quattro-letture.md; riprovati il 2026-10-14 sul repo vero: 0 e 0):
#  1. un segreto assegnato a una variabile di nome sensibile (`var BC_CLIENT_SECRET = '<valore lungo>'`) non era riconosciuto: i pattern erano solo chiavi con prefisso
#     noto (sk_live_, AKIA, ...) e `securityCode`;
#  2. un manifest con `access: ANYONE` (qualunque account Google) non era riconosciuto: la lente cercava solo ANYONE_ANONYMOUS.
# I valori sono FINTI. Il valore di un segreto non deve mai finire nell'output (regola del mandato, tools/gas_qualita.py:14).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FINTO='Fz9Q~AbCdEfGhIjKlMnOpQrStUvWxYz012345'

# esito <nome-prova> <sorgente.gs>: l'output di gas_qualita.py su una cartella con quel solo file
esito() { local d="$TMP/$1"; mkdir -p "$d"; printf '%s\n' "$2" > "$d/Codice.gs"; python3 "$HERE/tools/gas_qualita.py" "$d" 2>&1; }
righe_segreti() { grep -E "^## segreti hardcoded" <<<"$1" | grep -oE '[0-9]+$'; }

OUT=$(esito a "var BC_CLIENT_SECRET = '$FINTO';")
[ "$(righe_segreti "$OUT")" = "1" ] && ok "un segreto assegnato a BC_CLIENT_SECRET: rilevato (1 sito)" || ko "BC_CLIENT_SECRET con valore NON rilevato: $(grep -E '^## segreti' <<<"$OUT")"
grep -q "$FINTO" <<<"$OUT" && ko "il valore del segreto e' finito nell'output" || ok "il valore del segreto NON e' nell'output"
grep -q "Codice.gs:1" <<<"$OUT" && ok "il sito e' file:riga (Codice.gs:1)" || ko "il sito non dice file:riga: $OUT"

for caso in "const password = \"$FINTO\";" "var API_KEY = '$FINTO';" "var accessToken = \"$FINTO\";" "var PRIVATE_KEY: '$FINTO'"; do
  OUT=$(esito b "$caso")
  [ "$(righe_segreti "$OUT")" = "1" ] && ok "rilevato: ${caso%%$FINTO*}…" || ko "NON rilevato: ${caso%%$FINTO*}…"
done

# i casi che NON sono un segreto nel sorgente
declare -a NO=(
  "var BC_CLIENT_SECRET = PropertiesService.getScriptProperties().getProperty('BC_CLIENT_SECRET');"
  "var TOKEN_URL = 'https://login.microsoftonline.com/tenant/oauth2/v2.0/token';"
  "var CLIENT_SECRET = '';"
  "var CLIENT_SECRET = 'YOUR_CLIENT_SECRET_HERE';"
  "var password = 'una frase con spazi non e un segreto';"
  "var SECRET_NAME = 'corto';"
  "var tokenCache = cache.get('token-cache-key-che-non-e-un-valore');"
  "var CACHE_TOKEN_KEY = 'acq_bc_token_cache_key_name';"
  "var TOKEN_CHIAVE = 'riordino_oauth_token_cache';"
)
for caso in "${NO[@]}"; do
  OUT=$(esito c "$caso")
  [ "$(righe_segreti "$OUT")" = "0" ] && ok "NON e' un segreto: ${caso:0:60}" || ko "falso positivo su: ${caso:0:60}"
done

# il manifest
manifest() { local d="$TMP/m-$1"; mkdir -p "$d"; printf 'function f() {}\n' > "$d/Codice.gs"; printf '{"webapp": {"access": "%s", "executeAs": "USER_DEPLOYING"}}\n' "$1" > "$d/appsscript.json"; python3 "$HERE/tools/gas_qualita.py" "$d" 2>&1; }
righe_manifest() { grep -E "^## webapp anonima" <<<"$1" | grep -oE '[0-9]+$'; }
for acc in ANYONE ANYONE_ANONYMOUS; do
  OUT=$(manifest $acc)
  [ "$(righe_manifest "$OUT")" = "1" ] && ok "manifest access: $acc rilevato" || ko "manifest access: $acc NON rilevato: $(grep -E '^## webapp' <<<"$OUT")"
done
for acc in DOMAIN MYSELF; do
  OUT=$(manifest $acc)
  [ "$(righe_manifest "$OUT")" = "0" ] && ok "manifest access: $acc non e' aperto" || ko "falso positivo su access: $acc"
done
OUT=$(manifest ANYONE)
grep -q "ANYONE" <<<"$OUT" && grep -q "deployment" <<<"$OUT" && ok "il sito dice quale valore (ANYONE) e ricorda il deployment vivo" || ko "sito di ANYONE senza valore o senza il caveat del deployment"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
