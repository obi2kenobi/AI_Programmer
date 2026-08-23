#!/bin/bash
# test-system-md-percorso-cloud-entrambi.sh — 4° ciclo, SET 3 giro 8. docs/system.md
# citava il limite "niente gh CLI in una sessione cloud" solo per l'onboarding
# (tools/onboard-repo.sh) — ma bootstrap-app.sh (giro 7) condivide esattamente lo stesso
# limite e ora lo stesso avviso in testa. Verifica che la mappa citi entrambi gli script
# gemelli, e che entrambi esistano e contengano davvero l'avviso citato.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SYS="$HERE/docs/system.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "tools/onboard-repo.sh" "$SYS" && grep -q "tools/bootstrap-app.sh" "$SYS" \
  && ok "docs/system.md cita entrambi gli script gemelli, non solo l'onboarding" \
  || ko "docs/system.md cita solo uno dei due script"

for s in tools/onboard-repo.sh tools/bootstrap-app.sh; do
  grep -q "PERCORSO CLOUD/IBRIDO" "$HERE/$s" \
    && ok "$s contiene davvero l'avviso citato dalla mappa" \
    || ko "$s non contiene l'avviso — citazione senza presidio"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
