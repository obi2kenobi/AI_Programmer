#!/bin/bash
# test-fixture-provenienza.sh — il dente delle fixture con la provenienza (REPO-V 7/9:
# tre fixture bugiarde in un giorno). Morso provato in entrambi i versi + l'esclusione dichiarata.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/fixture-provenienza.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

SB=$(mktemp -d /tmp/fixprov-t.XXXXXX); trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/tests/fixtures"
printf '{"a":1}' > "$SB/tests/fixtures/nuda.json"
bash "$TOOL" "$SB" >/dev/null 2>&1 && ko "fixture senza provenienza passa (il dente non morde)" \
  || ok "fixture senza provenienza: ROSSO"
printf '# prodotto da: node estrai.js --campione reale\n{"a":1}\n' > "$SB/tests/fixtures/nuda.json"
bash "$TOOL" "$SB" >/dev/null 2>&1 && ok "fixture con provenienza: VERDE" || ko "fixture dichiarata bocciata"
# l'esclusione si dichiara, col file fratello o l'elenco
printf '{"b":2}' > "$SB/tests/fixtures/a-mano-per-motivi.json"
printf 'a-mano-per-motivi.json\n' > "$SB/.fixture-esclusioni"
bash "$TOOL" "$SB" >/dev/null 2>&1 && ok "esclusione dichiarata: VERDE (il motivo sta nell'elenco)" || ko "esclusione ignorata"
# (2026-09-24, terzo ventaglio, V2 S6a-c): tre scelte della convenzione senza un caso — via il ramo del
# fratello, -qxF scritto -qF, -ic scritto -c: verde lo stesso.
rm -f "$SB/.fixture-esclusioni" "$SB/tests/fixtures/a-mano-per-motivi.json"
printf '{"c":3}' > "$SB/tests/fixtures/col-fratello.json"
printf 'prodotto da: python3 estrai.py --mese 09\n' > "$SB/tests/fixtures/col-fratello.json.provenienza"
bash "$TOOL" "$SB" >/dev/null 2>&1 && ok "provenienza nel file fratello .provenienza: VERDE" || ko "il fratello .provenienza non e' letto"
rm -f "$SB/tests/fixtures/col-fratello.json"*
printf '{"d":4}' > "$SB/tests/fixtures/motivi.json"
printf 'a-mano-per-motivi.json\n' > "$SB/.fixture-esclusioni"
bash "$TOOL" "$SB" >/dev/null 2>&1 && ko "motivi.json escluso perche' il suo nome e' dentro un'altra riga dell'elenco" \
  || ok "l'esclusione vale per il nome ESATTO: motivi.json non dichiarata resta ROSSA"
rm -f "$SB/tests/fixtures/motivi.json" "$SB/.fixture-esclusioni"
printf '# Prodotto da: node estrai.js\n{"e":5}\n' > "$SB/tests/fixtures/maiuscola.json"
bash "$TOOL" "$SB" >/dev/null 2>&1 && ok "«Prodotto da:» con la maiuscola vale (la riga e' letta senza badare al caso)" || ko "«Prodotto da:» maiuscolo bocciato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
