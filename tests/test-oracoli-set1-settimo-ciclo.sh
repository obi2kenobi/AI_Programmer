#!/bin/bash
# test-oracoli-set1-settimo-ciclo.sh — 7° ciclo, set 1 (2026-08-24): i tre oracoli
# dei domini residui della mappa (leasing, rating DSO, bilancio BU). Aritmetica
# derivata a mano riga per riga; ogni oracolo porta DENTRO di sé le stime dichiarate
# del codice REPO-E (2,5%, 30%, ammortamento uniforme, DSO 0≠"paga subito").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ============ LEASING ============
# Derivazione a mano (mesi = DIFFERENZA calendario senza aggiustare il giorno,
# come calcolaMesiTra del codice REPO-E — la prima stesura di questo test derivava
# 36 mesi inclusivi e aveva torto lei, non il tool): 2024-01→2026-12 = 35 mesi;
# riferimento 2025-07: trascorsi 18, rimanenti 17 (48.6%); iniziale 1000x35=35000;
# residuo 35000x17/35 = 17000; interessi 17000x2,5%/12 = 35,42; delta = (2,0+1,5)-(1,0+1,5)
# = +1,0 pt; adeguamento mensile 35,42x0,01 = 0,354; trimestrale 1,0625; previsto = 1001,06.
cat > "$TMP/leasing.json" <<'EOF'
{"canone_base": 1000, "spread": 1.5, "euribor_stipula": 1.0, "euribor_corrente": 2.0,
 "data_inizio": "2024-01-01", "data_fine": "2026-12-31", "data_riferimento": "2025-07-01"}
EOF
OUT=$(python3 "$HERE/tools/leasing_amministrativo.py" "$TMP/leasing.json")
echo "$OUT" | grep -q "Durata 35 mesi · trascorsi 18 · rimanenti 17 (48.6%)" \
  && ok "leasing: durata 35 mesi (differenza, non inclusiva), 17 rimanenti" || ko "leasing durata: $(echo "$OUT" | grep Durata)"
echo "$OUT" | grep -q "Capitale residuo stimato: 17000.00 EUR" \
  && ok "leasing: residuo 35000x17/35 = 17000 (ammortamento uniforme dichiarato)" \
  || ko "leasing residuo: $(echo "$OUT" | grep residuo)"
echo "$OUT" | grep -q "Quota interessi mensile: 35.42 EUR" \
  && ok "leasing: interessi 17000x2,5%/12 = 35,42 (stima dichiarata)" \
  || ko "leasing interessi: $(echo "$OUT" | grep interessi)"
echo "$OUT" | grep -q "Adeguamento mensile: +0.35 EUR · trimestrale ARRETRATO: +1.06 EUR" \
  && ok "leasing: adeguamento 0,354 mensile, 1,0625 trimestrale" \
  || ko "leasing adeguamento: $(echo "$OUT" | grep Adeguamento)"
echo "$OUT" | grep -q "Importo previsto: 1001.06 EUR" \
  && ok "leasing: previsto 1000 + 1,06 = 1001,06" || ko "leasing previsto: $(echo "$OUT" | grep previsto)"
# Euribor assente: NESSUN adeguamento dichiarato (assente ≠ zero in silenzio)
python3 - <<PY
import json
c = json.load(open("$TMP/leasing.json")); c["euribor_corrente"] = None
json.dump(c, open("$TMP/leasing_noeuribor.json", "w"))
PY
OUT2=$(python3 "$HERE/tools/leasing_amministrativo.py" "$TMP/leasing_noeuribor.json")
echo "$OUT2" | grep -q "NESSUNO — Euribor corrente mancante" \
  && ok "leasing: Euribor assente = NESSUN adeguamento dichiarato (non zero in silenzio)" \
  || ko "leasing assenza: $OUT2"

# ============ RATING DSO ============
# Derivazione a mano:
#   Alfa: fattura F1 2026-05-01 1000 → pagamento 2026-05-31 (codice 25OV-1, +30gg)
#         fattura F2 2026-06-01 2000 → MAI pagata → DSO 30, non pagate 1
#   Beta: fattura 2026-05-01 500 → cessione FACTOR 2026-05-11 (10gg) → DSO 10
#   Gamma: pagamento senza fattura → non matchato elencato
#   Delta: SOLO fattura non pagata → DSO n.d. (nel codice REPO-E usciva 0!)
cat > "$TMP/mov.csv" <<'EOF'
tipo,data_documento,nr_doc,cliente,descrizione,importo
fattura,2026-05-01,F1,alfa,fattura 25OV-1,1000
pagamento,2026-05-31,P1,alfa,pagamento 25OV-1,1000
fattura,2026-06-01,F2,alfa,fattura 25OV-2,2000
fattura,2026-05-01,F3,beta,fattura 25FVI-9,500
cessione,2026-05-11,C1,beta,CessioneFACTORProsoluto 25FVI-9 11052026,500
pagamento,2026-05-20,P2,gamma,pagamento sconosciuto,300
fattura,2026-05-05,F4,delta,fattura 25CORR-7,700
EOF
OUT=$(python3 "$HERE/tools/rating_dso_clienti.py" < "$TMP/mov.csv")
echo "$OUT" | grep -q "alfa.*30 gg.*1" \
  && ok "rating: alfa DSO 30 gg, 1 non pagata" || ko "rating alfa: $(echo "$OUT" | grep alfa)"
echo "$OUT" | grep -q "beta .*1 *10 gg" \
  && ok "rating: beta cessione FACTOR al 11/05 = DSO 10 gg" || ko "rating beta: $(echo "$OUT" | grep beta)"
echo "$OUT" | grep -q "delta.*0 *n\.d\. *1" \
  && ok "rating: delta solo non pagate → DSO 'n.d.' (il confine 0≠'paga subito' è dichiarato)" \
  || ko "rating delta: $(echo "$OUT" | grep delta)"
echo "$OUT" | grep -q "NOTA confine: 1 cliente/i con DSO 'n.d.'" \
  && ok "rating: la nota confine elenca chi non è misurabile" \
  || ko "rating: nota confine mancante"
echo "$OUT" | grep -q "NON MATCHATO: 2026-05-20 300.00" \
  && ok "rating: pagamento senza fattura elencato (scarto mai silenzioso)" \
  || ko "rating: non matchati non elencati"
# guardia falsi matching: pagamento 400 giorni dopo la fattura → scartato, non DSO 400
cat > "$TMP/mov2.csv" <<'EOF'
tipo,data_documento,nr_doc,cliente,descrizione,importo
fattura,2025-01-01,F1,alfa,fattura,100
pagamento,2026-02-05,P1,alfa,pagamento,100
EOF
OUT2=$(python3 "$HERE/tools/rating_dso_clienti.py" < "$TMP/mov2.csv")
echo "$OUT2" | grep -q "alfa.*0 *n\.d\." \
  && ok "rating: pagamento >365gg scartato dalla guardia (DSO resta n.d., non 400)" \
  || ko "rating: guardia 365 non applicata: $OUT2"

# ============ BILANCIO BU ============
# Derivazione a mano: amount<0 = ricavo (−amount), >=0 = costo.
#   BIOC: −1000 → ricavo 1000; +600 → costo 600 → margine +400
#   EDIL: −500 → ricavo 500; +700 → costo 700 → margine −200
#   (bu vuota) NOBU: −200 → ricavo 200; +100 → costo 100 → margine +100
#   TOTALE: ricavi 1700, costi 1400, risultato +300; quadratura 400−200+100=300 ✓
cat > "$TMP/gl.csv" <<'EOF'
conto,posting_date,bu,amount
510000,2026-03-10,BIOC,-1000
610000,2026-03-11,BIOC,600
510000,2026-03-12,EDIL,-500
610000,2026-03-13,EDIL,700
510000,2026-03-14,, -200
610000,2026-03-15,,100
EOF
OUT=$(python3 "$HERE/tools/bilancio_bu.py" < "$TMP/gl.csv")
echo "$OUT" | grep -q "CONVENZIONE G/L: amount < 0 = ricavo" \
  && ok "bilancio: convenzione dei segni dichiarata in testa" || ko "bilancio: convenzione mancante"
echo "$OUT" | grep -q "BIOC *1000.00 *600.00 *400.00" \
  && ok "bilancio BIOC: −1000→ricavo 1000, margine +400" || ko "bilancio BIOC: $(echo "$OUT" | grep BIOC)"
echo "$OUT" | grep -q "EDIL *500.00 *700.00 *-200.00" \
  && ok "bilancio EDIL: margine negativo −200 visibile (segno non invertito)" \
  || ko "bilancio EDIL: $(echo "$OUT" | grep EDIL)"
echo "$OUT" | grep -q "NOBU (movimenti non attribuiti a BU): ricavi 200.00 · costi 100.00" \
  && ok "bilancio: NOBU visibile (non attribuito ≠ perso)" || ko "bilancio NOBU: $(echo "$OUT" | grep NOBU)"
echo "$OUT" | grep -q "QUADRATURA: somma margini BU (300.00) = risultato totale" \
  && ok "bilancio: quadratura 400−200+100 = 300 verificata" || ko "bilancio quadratura: $(echo "$OUT" | grep QUADRATURA)"
echo "$OUT" | grep -q "APERTO: il ribaltamento dei costi indiretti" \
  && ok "bilancio: ribaltamento REPARTO dichiarato APERTO (formula non provata, non indovinata)" \
  || ko "bilancio: manca la dichiarazione del ribaltamento aperto"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
