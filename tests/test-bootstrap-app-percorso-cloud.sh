#!/bin/bash
# test-bootstrap-app-percorso-cloud.sh — 4° ciclo, SET 3 giro 7. onboard-repo.sh ha il
# blocco "percorso cloud/ibrido" in testa (corretto al giro 6), ma bootstrap-app.sh —
# che chiama `gh` altrettanto direttamente (auth status, repo create, label create, api
# user) e scrive su repos.conf — non aveva nessun avviso: lo stesso gap, mai propagato
# al file gemello. Verifica che l'avviso esista, sia vicino alla testa, e nomini
# davvero le chiamate gh presenti nello script (non generico).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HERE/tools/bootstrap-app.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$SCRIPT" && ok "bootstrap-app.sh ha sintassi valida" \
  || ko "bootstrap-app.sh ha un errore di sintassi"

RIGA=$(grep -n "PERCORSO CLOUD/IBRIDO" "$SCRIPT" | head -1 | cut -d: -f1)
[ -n "$RIGA" ] && [ "$RIGA" -le 20 ] \
  && ok "l'avviso PERCORSO CLOUD/IBRIDO è vicino alla testa del file (riga $RIGA)" \
  || ko "nessun avviso vicino alla testa (riga ${RIGA:-assente})"

BLOCCO=$(sed -n "${RIGA:-1},$(( ${RIGA:-1} + 10 ))p" "$SCRIPT")
echo "$BLOCCO" | grep -q "repo create" \
  && ok "l'avviso nomina la chiamata gh repo create presente nello script" \
  || ko "l'avviso non nomina le chiamate gh reali"

echo "$BLOCCO" | grep -q "repos.conf" \
  && ok "l'avviso nomina repos.conf (l'altra scrittura locale-del-Mac)" \
  || ko "l'avviso non nomina repos.conf"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
