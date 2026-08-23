#!/bin/bash
# test-bootstrap-issue-template-propagation.sh — 4° ciclo, SET 1 giro 3: bootstrap-app.sh
# crea la label GitHub "night-shift" ma non copiava mai il template
# .github/ISSUE_TEMPLATE/night-shift.md che insegna la FORMA della commessa (## Design,
# ## Forma dei dati, ## Territorio — obbligatorie, altrimenti il turno salta l'issue in
# silenzio). Stesso pattern già corretto per .claude/skills/ e patterns/ (set 3 giro 1/3
# del ciclo precedente), mai applicato a questo file. Isola solo la logica di copia (non
# l'intero script, che richiede gh autenticato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'cp "\$HERE/.github/ISSUE_TEMPLATE/night-shift.md" .github/ISSUE_TEMPLATE/night-shift.md' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh contiene la riga di copia del template issue" \
  || ko "riga di copia .github/ISSUE_TEMPLATE/night-shift.md non trovata in bootstrap-app.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && mkdir -p .github/ISSUE_TEMPLATE && cp "$HERE/.github/ISSUE_TEMPLATE/night-shift.md" .github/ISSUE_TEMPLATE/night-shift.md )

[ -f "$TMP/.github/ISSUE_TEMPLATE/night-shift.md" ] \
  && ok "il template arriva al progetto bootstrappato" \
  || ko "template assente dopo la copia"

diff -q "$HERE/.github/ISSUE_TEMPLATE/night-shift.md" "$TMP/.github/ISSUE_TEMPLATE/night-shift.md" >/dev/null 2>&1 \
  && ok "il contenuto copiato è identico all'originale del hub" \
  || ko "il contenuto copiato differisce dall'originale"

grep -q '^## Design' "$TMP/.github/ISSUE_TEMPLATE/night-shift.md" \
  && ok "il template copiato insegna la sezione ## Design obbligatoria" \
  || ko "il template copiato non menziona ## Design"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
