#!/bin/bash
# test-bootstrap-patterns-propagation.sh — set 3 giro 3: patterns/ (trucchi provati,
# ancorati al codice che li usa) non lasciava mai il hub — CLAUDE.md §7 dice "prima di
# scrivere infrastruttura, controlla patterns/" come regola universale, ma il posto dove
# guardare non arrivava a un progetto bootstrappato.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'cp -r "\$HERE/patterns/." patterns/' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh contiene la riga di copia di patterns/" \
  || ko "riga di copia patterns/ non trovata in bootstrap-app.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && mkdir -p patterns && cp -r "$HERE/patterns/." patterns/ )

N_HUB=$(find "$HERE/patterns" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
N_COPIATI=$(find "$TMP/patterns" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
[ "$N_COPIATI" -eq "$N_HUB" ] && [ "$N_COPIATI" -gt 0 ] \
  && ok "tutti i $N_HUB pattern del hub arrivano al progetto nuovo" \
  || ko "copiati $N_COPIATI pattern su $N_HUB nel hub"

[ -f "$TMP/patterns/README.md" ] && ok "patterns/README.md (indice) presente nella copia" \
  || ko "patterns/README.md assente dopo la copia"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
