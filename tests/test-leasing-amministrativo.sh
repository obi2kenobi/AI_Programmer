#!/bin/bash
# test-leasing-amministrativo.sh — oracolo leasing (REPO-E, adeguamento Euribor
# trimestrale ARRETRATO). Aritmetica a mano (2026-08-28, ogni passo dalla formula
# documentata nel tool):
#   durata = 23 mesi (gen-2026→dic-2027, mesi calendario, giorno ignorato)
#   trascorsi = 9 (gen→ott) · rimanenti = 14 · iniziale stimato = 1000×23 = 23000
#   residuo = 23000 × 14/23 = 14000.00 (esatto)
#   quota interessi mensile = 14000 × 2,5% / 12 = 29.1667 → 29.17
#   tassoBase = 0,5+1,0 = 1,5 · tassoCorrente = 1,5+1,0 = 2,5 · delta = 1,0 punto
#   adeguamento mensile = 29,1667 × 1,0/100 = 0,2917 → 0.29
#   trimestrale ARRETRATO = 0,875 → 0.88 · importo previsto = 1000.88
# Secondo caso: Euribor corrente ASSENTE → nessun adeguamento, importo = canone,
# e il dato assente DICHIARA se stesso (non zero in silenzio).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/leasing_amministrativo.py"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/caso.json" <<'EOF'
{"canone_base": 1000, "data_inizio": "2026-01-01", "data_fine": "2027-12-31",
 "data_riferimento": "2026-10-01", "spread": 1.0, "euribor_stipula": 0.5, "euribor_corrente": 1.5}
EOF
OUT=$(python3 "$TOOL" "$TMP/caso.json" 2>&1)

echo "$OUT" | grep -q "Durata 23 mesi" && ok "durata 23 mesi (calendario, giorno ignorato)" || ko "durata: attesa 23 mesi"
echo "$OUT" | grep -q "rimanenti 14" && ok "rimanenti 14" || ko "rimanenti: attesi 14"
echo "$OUT" | grep -q "Capitale residuo stimato: 14000.00" && ok "residuo 14000.00 (23000 × 14/23)" || ko "residuo: atteso 14000.00"
echo "$OUT" | grep -q "Quota interessi mensile: 29.17" && ok "quota interessi 29.17 (14000×2,5%/12)" || ko "quota interessi: attesa 29.17"
echo "$OUT" | grep -q "delta +1.000 punti" && ok "delta tasso +1.000" || ko "delta tasso: atteso +1.000"
echo "$OUT" | grep -q "trimestrale ARRETRATO: +0.88" && ok "adeguamento trimestrale 0.88" || ko "adeguamento: atteso +0.88"
echo "$OUT" | grep -q "Importo previsto: 1000.88" && ok "importo previsto 1000.88 (1000 + 0.875)" || ko "importo: atteso 1000.88"
echo "$OUT" | grep -q "STIMATO" && ok "la stima 2,5% è DICHIARATA nell'output" || ko "la stima non è dichiarata"
echo "$OUT" | grep -qi "arretrato" && ok "la regola arretrato è dichiarata" || ko "regola arretrato assente"

python3 - "$TMP" <<'EOF'
import json, sys
c = json.load(open(sys.argv[1] + "/caso.json")); del c["euribor_corrente"]
json.dump(c, open(sys.argv[1] + "/no-euribor.json", "w"))
EOF
OUT2=$(python3 "$TOOL" "$TMP/no-euribor.json" 2>&1)
echo "$OUT2" | grep -q "Importo previsto: 1000.00" && ok "Euribor assente: importo = canone" || ko "Euribor assente: importo atteso 1000.00"
echo "$OUT2" | grep -q "Euribor corrente mancante" && ok "dato assente dichiarato, non zero in silenzio" || ko "il dato assente non dichiara se stesso"

python3 "$TOOL" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok "senza argomenti esce 1" || ko "senza argomenti: atteso exit 1, avuto $RC"
python3 "$TOOL" /inesistente.json >/dev/null 2>&1; RC=$?
[ "$RC" -ne 0 ] && ok "file inesistente: errore, non silenzio" || ko "file inesistente: exit 0 inaspettato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
