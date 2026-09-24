#!/bin/bash
# test-night-verify-riepilogo-suite.sh — 4° ciclo, SET 2 giro 7. Bug reale trovato
# dogfoodando il mio stesso fix del giro 4 (set 1): il loop della suite eseguiva
# davvero tutti i file, ma il report del gate mostra solo il `tail` dell'output
# dell'ULTIMO comando della riga — con 29+ test in un solo `for`, un successo mostrava
# "3 OK, 0 FAIL" (il tail del solo ultimo file), facendo sembrare che fossero girati 3
# controlli in tutto, non l'intera suite. Verificato eseguendo per davvero la riga
# corretta su una mini-suite sintetica (isolata, non i test reali del hub): il tail deve
# sempre mostrare un riepilogo N/TOT, sia al successo che al fallimento (con posizione e
# nome del file che ha fatto fallire).
# (E-029, 2026-09-18): la riga composta `N=0; TOT=...` e' diventata tools/suite.sh
# (contratto: .night-verify e' UN COMANDO per riga). Il guardiano segue il codice:
# controlla la dichiarazione in .night-verify e prova il RUNNER vero.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -Eq "^(@[0-9]+ )?bash tools/suite\.sh$" "$HERE/.night-verify" \
  && ok ".night-verify dichiara il runner (un comando per riga, E-029)" \
  || { ko ".night-verify non invoca piu' il runner della suite — verifiche-vuote in agguato"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }
grep -Eq '^for t in tests/test-\*\.sh' "$HERE/tools/suite.sh" \
  && ok "il runner contiene il loop su TUTTI i test" \
  || { ko "il runner non loopa su tests/test-*.sh — regressione al bug del giro 4"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tests"

# Caso 1: mini-suite tutta verde -> il tail deve riportare N/TOT, non l'output dell'ultimo test
cat > "$TMP/tests/test-a.sh" <<'EOF'
#!/bin/bash
# (revisione 10 giri): la riga di verdetto sta da sola — il runner la pretende (tools/suite.sh)
echo "a: fatto"
echo "1 OK, 0 FAIL"
exit 0
EOF
cat > "$TMP/tests/test-b.sh" <<'EOF'
#!/bin/bash
echo "b: fatto"
echo "1 OK, 0 FAIL"
exit 0
EOF
chmod +x "$TMP/tests/test-a.sh" "$TMP/tests/test-b.sh"

OUT_OK=$(bash "$HERE/tools/suite.sh" "$TMP" 2>&1)
echo "$OUT_OK" | tail -1 | grep -q "2/2" \
  && ok "successo: il tail riporta il conteggio reale (2/2), non l'output dell'ultimo test" \
  || ko "successo: il tail non riporta il conteggio — mostra invece: $(echo "$OUT_OK" | tail -1)"

# Caso 2: un test fallisce -> il tail deve indicare QUALE file e la sua posizione
cat > "$TMP/tests/test-c-fallisce.sh" <<'EOF'
#!/bin/bash
echo "c: rotto di proposito"
exit 1
EOF
chmod +x "$TMP/tests/test-c-fallisce.sh"

OUT_KO=$(bash "$HERE/tools/suite.sh" "$TMP" 2>&1) || true
grep -q "FALLITO.*test-c-fallisce.sh" <<<"$OUT_KO" \
  && ok "fallimento: il tail indica il file esatto che ha fatto fallire la suite" \
  || ko "fallimento: nessuna indicazione di quale file sia fallito"
grep -qE "FALLITO \([0-9]+/[0-9]+\)" <<<"$OUT_KO" \
  && ok "fallimento: la posizione (N/TOT) è riportata" \
  || ko "fallimento: nessuna posizione N/TOT riportata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
