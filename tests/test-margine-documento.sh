#!/bin/bash
# test-margine-documento.sh — 6° ciclo, Set 1 giro 4 (2026-08-24). Oracolo margine
# per documento: accoppiamento per riferimento normalizzato, % sui RICAVI (non sul
# costo), unmatched = errore (non margine zero), nota di credito = annullato,
# BU diversa flaggata ma calcolata, margine negativo ammesso.
# Aritmetica a mano:
#   RF-001: 1000 − 600 = +400 (40.0% sui ricavi)
#   RF-002:  500 − 400 = +100 (20.0%) con ⚠️ BU DIVERSA
#   RF-005: 1000 − 1200 = −200 (−20.0%) margine negativo, ammesso
#   RF-003: senza acquisto → ERRORE, fuori dai totali
#   RF-004: nota di credito → annullato, fuori dai totali
#   Ricavi accoppiati = 1000+500+1000 = 2500 · Margine = 400+100−200 = +300 (12.0%)
# (nota: la prima stesura di questo test aveva "−100/+400" — aritmetica a mano
# sbagliata colta dalla run rossa: 1000−1200 fa −200. Il tool era giusto.)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/vendite.csv" <<'EOF'
rif,data,bu,ubicazione,importo
RF-001,2026-05-10,BIOC,SD,1000
RF-002,2026-05-11,EDIL,SD,500
RF-003,2026-05-12,BIOC,SD,300
RF-004,2026-05-13,BIOC,SD,200
RF-005,2026-05-14,BIOC,SD,1000
EOF
cat > "$TMP/acquisti.csv" <<'EOF'
rif,data,bu,fornitore,importo
rf-001,2026-04-01,BIOC,FORN-A,600
RF-002,2026-04-02,BIOC,FORN-B,400
RF-005,2026-04-03,BIOC,FORN-C,1200
EOF
cat > "$TMP/note.csv" <<'EOF'
rif
RF-004
EOF

OUT=$(python3 "$HERE/tools/margine_documento.py" "$TMP/vendite.csv" "$TMP/acquisti.csv" "$TMP/note.csv")

# 1. totale e percentuale come da aritmetica a mano
echo "$OUT" | grep -q "Totale ricavi accoppiati: 2500.00 EUR" \
  && ok "ricavi accoppiati 2500.00 EUR" || ko "ricavi: $(echo "$OUT" | grep 'ricavi accoppiati')"
echo "$OUT" | grep -q "Totale margine: +300.00 EUR (+12.0% sui ricavi)" \
  && ok "margine totale +300.00 EUR = 12.0% sui ricavi" || ko "margine: $(echo "$OUT" | grep 'Totale margine')"

# 2. normalizzazione riferimento: "rf-001" (minuscolo) accoppia "RF-001" per il
# toUpperCase del codice REPO-E. NOTA: gli SPAZI vengono rimossi ma il trattino no —
# "rf 001" (→RF001) NON accoppia "RF-001" nemmeno nel codice originale: aspettativa
# corretta dopo la prima run rossa, non un difetto del tool
echo "$OUT" | grep -q "RF-001: vendita=1000.00 acquisto=600.00 margine=+400.00 (+40.0% sui ricavi)" \
  && ok "normalizzazione rif: 'rf-001' minuscolo accoppia 'RF-001'" || ko "RF-001: $(echo "$OUT" | grep 'RF-001:')"

# 3. % sui RICAVI, non sul costo: 400/1000=40% (su costo sarebbe 400/600=66.7%)
echo "$OUT" | grep -q "RF-001.*+40.0%" && ! echo "$OUT" | grep -q "RF-001.*+66.7%" \
  && ok "percentuale calcolata sui ricavi (40.0%, non 66.7% sul costo)" \
  || ko "percentuale: base sbagliata? $(echo "$OUT" | grep 'RF-001:')"

# 4. BU diversa: flaggata ma margine calcolato
echo "$OUT" | grep -q "RF-002.*BU DIVERSA" && echo "$OUT" | grep -q "RF-002.*margine=+100.00" \
  && ok "RF-002: BU DIVERSA flaggata, margine +100 calcolato lo stesso" \
  || ko "RF-002: $(echo "$OUT" | grep 'RF-002:')"

# 5. margine negativo ammesso (nessun clamp)
echo "$OUT" | grep -q "RF-005: vendita=1000.00 acquisto=1200.00 margine=-200.00 (-20.0% sui ricavi)" \
  && ok "RF-005: margine negativo −200 ammesso e visibile" || ko "RF-005: $(echo "$OUT" | grep 'RF-005:')"

# 6. vendita senza acquisto = ERRORE, non margine zero
echo "$OUT" | grep -q "ERRORI accoppiamento (NON sono margine zero): 1 — RF-003" \
  && ok "RF-003 senza acquisto: errore dichiarato, escluso dai totali" \
  || ko "RF-003: $(echo "$OUT" | grep 'ERRORI')"

# 7. nota di credito: annullato, escluso, riportato
echo "$OUT" | grep -q "Annullati da nota di credito: 1 — RF-004 (200.00 EUR esclusi)" \
  && ok "RF-004 in nota di credito: annullato e riportato (scarto mai silenzioso)" \
  || ko "RF-004: $(echo "$OUT" | grep 'Annullati')"

# 8. guardia di regressione: RF-003/RF-004 NON nei totali
TOT=$(echo "$OUT" | grep "Totale ricavi accoppiati")
echo "$TOT" | grep -qv "2800\|3000" \
  && ok "i documenti non accoppiati/annullati non gonfiano i totali ($TOT)" \
  || ko "totali gonfiati: $TOT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
