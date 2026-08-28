#!/bin/bash
# test-gas-qualita-secret-pattern.sh — banco di regressione nato dalla revisione "L'Hub
# Allo Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in tools/gas_qualita.py,
# il pattern securityCode(Prefix) in SECRET_PATTERNS era scritto come stringa NORMALE
# ('r"...') invece che raw-string (r'...') — i due caratteri iniziali r" finivano nel
# VALORE runtime del pattern come testo letterale, cosa che il codice reale non contiene
# mai. Il rilevatore era di fatto morto dalla sua prima introduzione (il commit che
# dichiarava "fix esteso: securityCodePrefix riconosciuto" non lo riconosceva). Nessun
# test esisteva per questo caso specifico (confermato anche da un report dal campo che
# dichiarava erroneamente il fix già avvenuto — vedi docs/campo/2026-08-27-test-repo-e-
# ciclo2.md).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/Codice.gs" <<'EOF'
function autentica() {
  var securityCodePrefix = "ABC1234XYZ";
  return securityCodePrefix;
}
EOF

OUT=$(python3 "$HERE/tools/gas_qualita.py" "$TMP" 2>&1)
echo "$OUT" | grep -q "segreti hardcoded (valore MAI riportato) — 1" \
  && ok "securityCodePrefix hardcoded: rilevato (1 sito)" \
  || ko "securityCodePrefix hardcoded NON rilevato — output: $OUT"
echo "$OUT" | grep -q "ABC1234XYZ" \
  && ko "il valore del segreto è finito nell'output (violazione 'mai il valore')" \
  || ok "il valore del segreto NON è riportato nell'output (per design)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
