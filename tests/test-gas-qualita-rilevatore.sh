#!/bin/bash
# test-gas-qualita-rilevatore.sh — 7° ciclo, set 1 (2026-08-24): il rilevatore
# meccanico delle famiglie misurate (tools/gas_qualita.py) su un progetto
# SINTETICO deterministico: ogni famiglia presente una volta, ogni assente
# dichiarato. Verifica anche le regole del tool stesso: accetta .js E .gs,
# stampa la cartella letta, non è un verdetto, e i falsi positivi attesi non
# accusano (il fuso 'Europe/Rome' NON è un rilievo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/progetto"

# test finto (no throw/assert) + test VERO (con throw: non deve contare)
cat > "$TMP/progetto/Tests.js" <<'EOF'
function testParser() {
  Logger.log("il parser funziona");
}
function testConEsito() {
  if (calcola(2) !== 5) throw new Error("attesa fallita");
}
EOF

# nome in ombra DIVERGENTE fra due file + catch vuoto + clear-poi-scrivi
cat > "$TMP/progetto/Main.js" <<'EOF'
function aggregaDati(a) {
  return a + 1;
}
function sincronizza() {
  const sh = SpreadsheetApp.getActiveSheet();
  sh.clearContents();
  sh.getRange(1, 1, 2, 2).setValues([["a"],["b"]]);
  try { fetchBCPaged(); } catch (e) {}
}
EOF
cat > "$TMP/progetto/Vecchio.gs" <<'EOF'
function aggregaDati(a, b) {
  return a + b;
}
EOF

# paginazione indizio + fuso CORRETTO (Europe/Rome: non è rilievo)
cat > "$TMP/progetto/BcClient.js" <<'EOF'
function fetchTutto(url) {
  const r = UrlFetchApp.fetch(url);
  const json = JSON.parse(r);
  if (!json.value) break;
  Utilities.formatDate(new Date(), "Europe/Rome", "dd/MM");
}
EOF

# manifest webapp anonima
cat > "$TMP/progetto/appsscript.json" <<'EOF'
{"webapp": {"access": "ANYONE_ANONYMOUS", "executeAs": "USER_DEPLOYING"}}
EOF

OUT=$(python3 "$HERE/tools/gas_qualita.py" "$TMP/progetto")

# 1. le regole del tool stesso (le sette regole del banco, applicate qui)
echo "$OUT" | grep -q "Cartella letta:" \
  && ok "stampa la cartella letta (regola 1 del banco)" || ko "non dichiara la cartella"
echo "$OUT" | grep -q "Vecchio.gs" \
  && ok "accetta .js E .gs (regola 3: 11 banchi su 16 filtravano solo .js)" \
  || ko "non considera i .gs"
echo "$OUT" | grep -q "QUESTO NON È UN VERDETTO" \
  && ok "dichiara di non essere un verdetto (il censimento apre i casi)" \
  || ko "si spaccia per verdetto"

# 2. le famiglie presenti: contate
echo "$OUT" | grep -q "test che non possono fallire — 1" \
  && ok "test finto: 1 (testParser senza esito; testConEsito con throw NON contato)" \
  || ko "test finti: $(echo "$OUT" | grep 'non possono fallire')"
echo "$OUT" | grep -q "nomi globali in ombra — 1" && echo "$OUT" | grep -q "aggregaDati.*DIVERGENTI" \
  && ok "nome in ombra DIVERGENTE: aggregaDati con corpi diversi in 2 file" \
  || ko "ombre: $(echo "$OUT" | grep 'ombra')"
echo "$OUT" | grep -q "catch vuoto (muto) — 1" \
  && ok "catch vuoto: 1" || ko "catch: $(echo "$OUT" | grep 'catch vuoto')"
echo "$OUT" | grep -q "clearContents + setValues nella stessa funzione — 1" \
  && ok "clear-poi-scrivi: 1 (funzione sincronizza)" \
  || ko "clear-poi-scrivi: $(echo "$OUT" | grep clearContents)"
echo "$OUT" | grep -q "paginazione chiusa sull'indizio.*— 1" \
  && ok "paginazione indizio: 1 (!json.value → break)" \
  || ko "paginazione: $(echo "$OUT" | grep indizio)"
echo "$OUT" | grep -q "webapp anonima nel manifest — 1" \
  && ok "webapp anonima: 1 col caveat deployment" || ko "webapp: $(echo "$OUT" | grep anonima)"

# 3. i falsi positivi NON accusano (il discriminante, non la forma)
echo "$OUT" | grep -q "fuso come offset fisso 'GMT+N' — 0" \
  && ok "fuso Europe/Rome NON accusato (il falso positivo atteso resta chiuso)" \
  || ko "fuso: accusa il legittimo"
echo "$OUT" | grep -q "segreti hardcoded.*— 0" \
  && ok "nessun segreto nel sintetico: 0 (e mai un valore stampato)" \
  || ko "segreti: $(echo "$OUT" | grep segreti)"

# 4. la domanda discriminante accompagna ogni famiglia
echo "$OUT" | grep -q "domanda: " \
  && ok "ogni famiglia porta la sua domanda discriminante" || ko "domande mancanti"

# 5. guardia di robustezza: cartella inesistente → errore esplicito, non silenzio
python3 "$HERE/tools/gas_qualita.py" "$TMP/inesistente" >/dev/null 2>&1
[ $? -ne 0 ] && ok "cartella inesistente: errore esplicito" || ko "cartella inesistente: esce 0 in silenzio"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
