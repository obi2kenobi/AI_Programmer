#!/bin/bash
# test-accuratezza-fatture-acquisto.sh — 6° ciclo, Set 1 giro 5 (2026-08-24).
# Oracolo accuratezza: solo OVER-invoicing è discrepanza (fattura sotto ordine =
# fatturazione parziale, NON errore — falsi positivi corretti nel codice REPO-E),
# whitelist fornitori legittima il senza-ordine, accuratezza (T−E)/T.
# Aritmetica a mano (10 fatture):
#   validi:      F01 (0%), F03 (−40% parziale), F04 (+2%), F09 (+4.5%), F10 (0%) = 5
#   discrepanze: F02 (+10%), F05 (+20%) = 2
#   anomale:     F06 (senza ordine, fornitore non in whitelist) = 1
#   legittime:   F07 (whitelist) = 1
#   inesistenti: F08 (ordine O9 assente) = 1
#   erroriReali = 1+1+2 = 4 → accuratezza (10−4)/10 = 60.0% · margine 40.0%
#   obiettivo 0.1% → NON raggiunto
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/config.json" <<'EOF'
{"soglia_discrepanza_pct": 5, "obiettivo_margine_errore_pct": 0.1, "whitelist_fornitori": ["FORN-C"]}
EOF
cat > "$TMP/fatture.csv" <<'EOF'
nr,fornitore,ordine_nr,importo
F01,FORN-A,O1,1000
F02,FORN-A,O1,1100
F03,FORN-A,O1,600
F04,FORN-A,O2,510
F05,FORN-A,O2,600
F06,FORN-B,,300
F07,FORN-C,,100
F08,FORN-A,O9,150
F09,FORN-A,O3,209
F10,FORN-A,O3,200
EOF
cat > "$TMP/ordini.csv" <<'EOF'
nr,importo
O1,1000
O2,500
O3,200
EOF

OUT=$(python3 "$HERE/tools/accuratezza_fatture_acquisto.py" "$TMP/config.json" "$TMP/fatture.csv" "$TMP/ordini.csv")

# 1. accuratezza e margine come da aritmetica a mano
echo "$OUT" | grep -q "Accuratezza: 60.0% · Margine di errore: 40.0%" \
  && ok "accuratezza 60.0%, margine 40.0% ((10−4)/10)" \
  || ko "accuratezza: $(echo "$OUT" | grep 'Accuratezza')"
echo "$OUT" | grep -q "Errori reali: 4" && ok "errori reali = 1 anomala + 1 inesistente + 2 discrepanze" \
  || ko "errori reali: $(echo "$OUT" | grep 'Errori reali')"

# 2. LA REGOLA: fattura sotto ordine NON è discrepanza (fatturazione parziale)
echo "$OUT" | grep -q "Matching validi (incl. fatturazione parziale): 5" \
  && ok "F03 (−40%): parziale, valida — il falso positivo storico resta chiuso" \
  || ko "validi: $(echo "$OUT" | grep 'validi')"

# 3. soglia al 5%: F04 +2% e F09 +4.5% passano, F02 +10% e F05 +20% no
echo "$OUT" | grep -q "F02→O1: fattura oltre ordine di +100.00 EUR (+10.0%)" \
  && ok "F02 +10%: discrepanza" || ko "F02: $(echo "$OUT" | grep F02)"
echo "$OUT" | grep -q "F05→O2: fattura oltre ordine di +100.00 EUR (+20.0%)" \
  && ok "F05 +20%: discrepanza" || ko "F05: $(echo "$OUT" | grep F05)"
echo "$OUT" | grep -vq "F09→O3" && ok "F09 +4.5%: sotto soglia 5%, valida" \
  || ko "F09 segnalata per errore: $(echo "$OUT" | grep F09)"

# 4. whitelist: F07 legittima, F06 anomala
echo "$OUT" | grep -q "Senza ordine — legittime (whitelist): 1 — F07" \
  && ok "F07 fornitore whitelist: legittima, non errore" || ko "F07: $(echo "$OUT" | grep legittime)"
echo "$OUT" | grep -q "Senza ordine — anomale: 1 — F06" \
  && ok "F06 senza ordine né whitelist: anomala" || ko "F06: $(echo "$OUT" | grep anomale)"

# 5. ordine inesistente
echo "$OUT" | grep -q "Ordine inesistente: 1 — F08→O9" \
  && ok "F08 con ordine O9 assente: errore dichiarato" || ko "F08: $(echo "$OUT" | grep inesistente)"

# 6. obiettivo
echo "$OUT" | grep -q "Obiettivo (margine < 0.1%): NON raggiunto" \
  && ok "obiettivo 0.1% correttamente NON raggiunto con margine 40%" \
  || ko "obiettivo: $(echo "$OUT" | grep Obiettivo)"

# 7. caso felice piccolo: tutto conforme → accuratezza 100%, obiettivo raggiunto
cat > "$TMP/f2.csv" <<'EOF'
nr,fornitore,ordine_nr,importo
G1,FORN-A,O1,1000
EOF
OUT2=$(python3 "$HERE/tools/accuratezza_fatture_acquisto.py" "$TMP/config.json" "$TMP/f2.csv" "$TMP/ordini.csv")
echo "$OUT2" | grep -q "Accuratezza: 100.0%" && echo "$OUT2" | grep -q "Obiettivo (margine < 0.1%): RAGGIUNTO" \
  && ok "caso conforme: 100.0% e obiettivo RAGGIUNTO (il verde dev'essere raggiungibile)" \
  || ko "caso conforme: $OUT2"

# 8. bug reale (revisione 14 lenti, 2026-08-28): ordine con importo <= 0 non deve passare
# "valida" a prescindere dall'importo fatturato — va segnalato come categoria a sé.
cat > "$TMP/f3.csv" <<'EOF'
nr,fornitore,ordine_nr,importo
H1,FORN-A,OZERO,5000
EOF
cat > "$TMP/o3.csv" <<'EOF'
nr,importo
OZERO,0
EOF
OUT3=$(python3 "$HERE/tools/accuratezza_fatture_acquisto.py" "$TMP/config.json" "$TMP/f3.csv" "$TMP/o3.csv")
echo "$OUT3" | grep -q "Ordine con importo <= 0 (dato anomalo, percentuale non definita): 1 — H1→OZERO" \
  && ok "ordine a 0€ con fattura 5000€: segnalato come dato anomalo, non 'valida'" \
  || ko "ordine a 0€ non segnalato: $OUT3"
echo "$OUT3" | grep -q "Errori reali: 1" \
  && ok "ordine a 0€: contato negli errori reali" \
  || ko "errori reali attesi 1: $OUT3"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
