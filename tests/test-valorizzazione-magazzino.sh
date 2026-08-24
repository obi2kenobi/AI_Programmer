#!/bin/bash
# test-valorizzazione-magazzino.sh — 6° ciclo, Set 1 giro 3 (2026-08-24). Oracolo
# valorizzazione: catena override articolo>categoria>gruppo, "primo non-nullo per
# codice", senza-costo come anomalia (non zero), location escluse riportate,
# costi generali mai applicati. L'aspettativa è derivata A MANO riga per riga
# (regola METHOD.md #7), non copiata dall'output del tool:
#   ART-1: 10 × (100 −1€ cat) = 10 × 99.00        =  990.00
#   ART-2:  4 × (50 × 1.05 gruppo) = 4 × 52.50     =  210.00
#   ART-3:  2 × (20 +2€ articolo) = 2 × 22.00      =   44.00
#   ART-7:  costo "primo non-nullo"=10 (riga vuota prima) → (1+3) × 10 =   40.00
#   ART-6: −5 × 2 = −10.00 (negativa: valutata E flaggata) =  −10.00
#   TOTALE                                            = 1274.00
#   ART-4 senza costo → anomalia, NON nel totale · ART-5@SD → escluso riportato
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/config.json" <<'EOF'
{
  "override_gruppi":     {"LEGNO": {"type": "PERCENTUALE", "value": 5}},
  "override_categorie":  {"PANNELLI": {"type": "EURO", "value": -1.00}},
  "override_articoli":   {"ART-3": {"type": "EURO", "value": 2.00}},
  "costi_generali_percent": 10,
  "location_escluse":    ["SD"]
}
EOF
cat > "$TMP/righe.csv" <<'EOF'
codice,gruppo,categoria,location,qty,costo_medio
ART-1,LEGNO,PANNELLI,PRINCIPALE,10,100
ART-2,LEGNO,TRAVI,PRINCIPALE,4,50
ART-3,LEGNO,TRAVI,PRINCIPALE,2,20
ART-4,METALLO,VITERIA,PRINCIPALE,100,
ART-5,METALLO,VITERIA,SD,7,30
ART-6,METALLO,VITERIA,PRINCIPALE,-5,2
ART-7,METALLO,VITERIA,PRINCIPALE,1,
ART-7,METALLO,VITERIA,PRINCIPALE,3,10
EOF

OUT=$(python3 "$HERE/tools/valorizzazione_magazzino.py" "$TMP/config.json" < "$TMP/righe.csv")

# 1. il totale è esattamente quello derivato a mano
echo "$OUT" | grep -q "Valore totale (solo location considerate): 1274.00 EUR" \
  && ok "totale 1274.00 EUR come da aritmetica a mano" \
  || ko "totale errato: $(echo "$OUT" | grep 'Valore totale')"

# 2. catena override: articolo batte categoria che batte gruppo
echo "$OUT" | grep -q "ART-1: qty=+10 costo=99.0000 (override_categorie:PANNELLI)" \
  && ok "ART-1: override categoria (−1€) applicato sul base 100 → 99" \
  || ko "ART-1: $(echo "$OUT" | grep ART-1)"
echo "$OUT" | grep -q "ART-2: qty=+4 costo=52.5000 (override_gruppi:LEGNO)" \
  && ok "ART-2: override gruppo (+5%) applicato sul base 50 → 52.50" \
  || ko "ART-2: $(echo "$OUT" | grep ART-2)"
echo "$OUT" | grep -q "ART-3: qty=+2 costo=22.0000 (override_articoli:ART-3)" \
  && ok "ART-3: override articolo (+2€) vince su categoria e gruppo" \
  || ko "ART-3: $(echo "$OUT" | grep ART-3)"

# 3. "senza costo" è anomalia, NON valore zero: ART-4 non è nel totale
echo "$OUT" | grep -q "ANOMALIA senza costo.*ART-4" \
  && ok "ART-4 senza costo: anomalia dichiarata, non trattato a zero" \
  || ko "ART-4: anomalia senza costo mancante"
echo "$OUT" | grep -vq "ART-4: qty" \
  && ok "ART-4 non compare tra i valorizzati" \
  || ko "ART-4 valorizzato per errore"

# 4. location esclusa: scarto mai silenzioso
echo "$OUT" | grep -q "Location escluse.*ART-5@SD (valore non valorizzato: 210.00 EUR)" \
  && ok "ART-5@SD escluso ma riportato col suo valore (7×30=210)" \
  || ko "esclusione SD: $(echo "$OUT" | grep 'escluse')"

# 5. giacenza negativa: valutata e flaggata
echo "$OUT" | grep -q "ANOMALIA giacenza negativa: 1 righe, -5 pz" \
  && ok "ART-6 negativa: valutata (−10 nel totale) e flaggata" \
  || ko "anomalia negativa: $(echo "$OUT" | grep negativa)"

# 6. primo non-nullo per codice: ART-7 costa 10 su ENTRAMBE le righe (costo
# condiviso per codice, righe separate per location — come nello snapshot REPO-E)
N7=$(echo "$OUT" | grep -c "ART-7: qty=+[0-9]* costo=10.0000 (costo_base)")
[ "$N7" -eq 2 ] \
  && ok "ART-7: costo 'primo non-nullo per codice'=10 su entrambe le righe (1×10 + 3×10)" \
  || ko "ART-7: attese 2 righe a costo 10, trovate $N7 — $(echo "$OUT" | grep ART-7)"

# 7. costi generali: configurati ma NON applicati (formula non provata in REPO-E)
echo "$OUT" | grep -q "costi_generali_percent=10% configurato ma NON applicato" \
  && ok "costi generali 10% dichiarati non applicati (formula non provata)" \
  || ko "costi generali: mancata dichiarazione o applicati per errore"

# 8. rigressione rottura: override con tipo sconosciuto deve fallire, non tacere
cat > "$TMP/config_bad.json" <<'EOF'
{"override_gruppi": {"LEGNO": {"type": "MAGICO", "value": 5}}}
EOF
OUT_BAD=$(python3 "$HERE/tools/valorizzazione_magazzino.py" "$TMP/config_bad.json" < "$TMP/righe.csv" 2>&1)
RC_BAD=$?
[ "$RC_BAD" -ne 0 ] && echo "$OUT_BAD" | grep -qi "sconosciuto" \
  && ok "override di tipo ignoto: errore esplicito, non silenzioso" \
  || ko "override ignoto accettato in silenzio: rc=$RC_BAD"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
