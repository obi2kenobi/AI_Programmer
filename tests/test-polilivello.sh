#!/bin/bash
# test-polilivello.sh — lo scaffold polilivello sotto prova. Validato sul
# campo (demo rating in docs/campo/2026-08-29-polilivello-demo-rating.md):
# qui si verifica che i tre grep CHE IL CAMPO HA CORRETTO restino corretti —
# entrypoint con verbi italiani, ID in const, costanti magiche in espressioni.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/polilivello.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || ko "sintassi rotta"

# fixture: progetto GAS minimo con le tre cose che il primo grep mancava
SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
cat > "$SB/Codice.js" <<'JS'
// entrypoint col verbo di dominio italiano: il grep doGet/main lo mancava
function analizzaVenditeMensili() {
  const folderInputId = '1abcDEFghiJKLmnopQRSTuvwx';   // ID in const: anche questo
  const giorni = Math.floor((fine - inizio) / (1000 * 60 * 60 * 24));
  return 0.025;
}
JS

OUT=$(bash "$TOOL" "$SB" 2>&1)
echo "$OUT" | grep -q "analizzaVenditeMensili" && ok "entrypoint verbo italiano colto" || ko "entrypoint di dominio mancato"
echo "$OUT" | grep -q "folderInputId" && ok "ID in const colto" || ko "ID in const mancato"
echo "$OUT" | grep -q "1000 \* 60 \* 60 \* 24\|1000\*60" && ok "costante magica in espressione colta" || ko "costante magica mancata"
echo "$OUT" | grep -q "L1 Identità" && ok "il scaffold ricorda i livelli da compilare a mano" || ko "scaffold senza i livelli"
echo "$OUT" | grep -q "verbi di dominio" && ok "il perché del grep sta nel tool (chiarezza)" || ko "grep senza intent dichiarato"

# su directory inesistente: uso, non traceback
# output catturato PRIMA: il tool esce 1 per contratto e sotto pipefail
# la pipeline eredirebbe il suo status anche se grep matcha (E-002)
OUTERR=$(bash "$TOOL" /non/esiste 2>&1); RCERR=$?
[ "$RCERR" -eq 1 ] && grep -q "uso:" <<<"$OUTERR" \
  && ok "dir inesistente: uso + exit 1" || ko "dir inesistente: comportamento poco chiaro"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
