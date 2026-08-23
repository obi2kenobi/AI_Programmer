#!/bin/bash
# test-rollforward-cespiti.sh — 4° ciclo, SET 1 giro 8. Terzo caso risolto con la skill
# controllo-gestione: roll-forward cespiti, dominio di nuovo diverso (magazzino, controllo
# di gestione produzione, ora asset accounting) — letto RIGA PER RIGA sul codice reale di
# un modulo di quadratura/roll-forward (repo esterno REPO-E, gas-src/). Il segno del fondo
# (convenzionalmente negativo) è l'invariante critico che dev-critic §2ter avverte di
# verificare — qui provato con numeri sintetici derivati a mano PRIMA di eseguire il tool
# (regola CLAUDE.md "L'aspettativa si deriva").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

RISULTATO=$(cd "$HERE" && python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from rollforward_cespiti import calcola_roll_forward

fa = {
    "openCosto": 1000.0, "openRival": 50.0, "openSval": -30.0,
    "yearCosto": 200.0, "yearRival": 10.0, "yearSval": -5.0,
    "openFondo": -600.0, "yearFondo": -150.0,
}
cespiti = [
    # dismesso nell'anno: costo+rival+sval = 100+5-2 = 103; fondo = -80 -> -fondo = 80
    {"isDisposed": True, "yearCessioni": 1, "costo": 100.0, "rival": 5.0, "sval": -2.0, "fondo": -80.0},
    # non dismesso: non deve contribuire a clCess/fondoCess
    {"isDisposed": False, "yearCessioni": 0, "costo": 500.0, "rival": 0.0, "sval": 0.0, "fondo": -300.0},
]
r = calcola_roll_forward(fa, cespiti)

# a mano: clOpen = 1000+50-30 = 1020; clAcq=200; clRivalSval=10-5=5; clCess=103
# clClose = 1020+200+5-103 = 1122
# fondoOpen=-600; fondoAmm=-150; fondoCess=80; fondoClose=-600-150+80=-670
# vnOpen = 1020+(-600)=420; vnClose = 1122+(-670)=452
checks = []
checks.append(("clOpen = 1020.00", abs(r["clOpen"] - 1020.0) < 1e-9))
checks.append(("clCess = 103.00 (solo il cespite dismesso)", abs(r["clCess"] - 103.0) < 1e-9))
checks.append(("clClose = 1122.00", abs(r["clClose"] - 1122.0) < 1e-9))
checks.append(("fondoCess = 80.00 (segno invertito rispetto al fondo, -(-80)=80)", abs(r["fondoCess"] - 80.0) < 1e-9))
checks.append(("fondoClose = -670.00", abs(r["fondoClose"] - (-670.0)) < 1e-9))
checks.append(("vnOpen = 420.00 (costo storico + fondo negativo)", abs(r["vnOpen"] - 420.0) < 1e-9))
checks.append(("vnClose = 452.00", abs(r["vnClose"] - 452.0) < 1e-9))
# il cespite NON dismesso non deve contribuire alle cessioni
r_senza_non_dismesso = calcola_roll_forward(fa, [cespiti[0]])
checks.append(("il cespite non dismesso è escluso (stesso risultato senza di lui)", r_senza_non_dismesso == r))

for nome, esito in checks:
    print(f"{'OK' if esito else 'KO'}\t{nome}")
PY
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

grep -q "REPO-E" "$HERE/tools/rollforward_cespiti.py" \
  && ok "il tool cita la fonte reale della formula (per codice anonimo)" \
  || ko "il tool non cita più la fonte della formula"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
