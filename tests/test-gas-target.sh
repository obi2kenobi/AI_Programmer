#!/bin/bash
# test-gas-target.sh — il cancello dei target: il vivo mai, lo sconosciuto mai
# senza impronta, l'approvato si', e l'impronta resta (non sbaglia piu').
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DG="$HERE/tools/deploy-gas.sh"
export HOME="$PWD"
PASS=0; FAIL=0
# ok increments the success counter and prints a formatted OK message
ok(){ PASS=$((PASS+1)); echo "OK   $1"; }; ko(){ FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$DG" && ok "sintassi" || exit 1
T=$(mktemp -d); cd "$T"; git init -q -b main; git -c user.name=t -c user.email=t@t commit -qm i --allow-empty
VIVO="1yCrYK_vYWrE5FAKE"; mkdir -p "$HOME"; echo "$VIVO" > "$HOME/.gas-vivi"
printf '{"scriptId":"%s"}' "$VIVO" > .clasp.json
OUT=$(bash "$DG" . 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "lista dei VIVI" <<<"$OUT" && ok "il VIVO viene RIFIUTATO sempre (lista nera globale)" || ko "vivo rifiutato ($OUT)"
printf '{"scriptId":"1vYRy6IZnjE9TDE_FAKE"}' > .clasp.json
OUT=$(bash "$DG" . 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "SCONOSCIUTO" <<<"$OUT" && grep -q -- "--approva-target" <<<"$OUT" && ok "lo SCONOSCIUTO rifiuta e INSEGNA il gesto dell'impronta" || ko "sconosciuto ($OUT)"
[ -f .git/gas-targets ] && ko "nessuna impronta senza approvazione" || ok "nessuna impronta senza approvazione"
OUT=$(bash "$DG" . --approva-target 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "APPROVATO e memorizzato" <<<"$OUT" && ok "l'impronta si registra al gesto esplicito" || ko "impronta ($OUT)"
grep -qxF "1vYRy6IZnjE9TDE_FAKE" .git/gas-targets && ok "l'impronta e' nel registro della cartella (.git/gas-targets)" || ko "registro"
OUT=$(bash "$DG" . 2>&1); RC=$?
grep -q "TARGET: 1vYRy6IZnjE9TDE_FAKE (approvato" <<<"$OUT" && ok "la seconda volta il cancello SA qual e' il GAS giusto (memorizzato)" || ko "seconda volta ($OUT)"
[ -f .git/gas-targets.log ] && grep -q "push verso" .git/gas-targets.log && ok "ogni push lascia la traccia (registro .log: quando, dove, quale commit)" || ko "traccia"
VIVO_LETTO="$VIVO"   # E-002: cattura-prima, l'esito non e' dell'ultimo comando
grep -q FAKE <<<"$VIVO_LETTO" && ok "banco usa ID FINTI (mai ID veri nei test)" || true
echo ""; echo "$PASS OK, $FAIL FAIL"; [ "$FAIL" -eq 0 ]
