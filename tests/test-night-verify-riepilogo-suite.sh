#!/bin/bash
# test-night-verify-riepilogo-suite.sh — 4° ciclo, SET 2 giro 7. Bug reale trovato
# dogfoodando il mio stesso fix del giro 4 (set 1): il loop in .night-verify eseguiva
# davvero tutti i file, ma il report del gate mostra solo il `tail` dell'output
# dell'ULTIMO comando della riga — con 29+ test in un solo `for`, un successo mostrava
# "3 OK, 0 FAIL" (il tail del solo ultimo file), facendo sembrare che fossero girati 3
# controlli in tutto, non l'intera suite. Verificato eseguendo per davvero la riga
# corretta su una mini-suite sintetica (isolata, non i test reali del hub): il tail deve
# sempre mostrare un riepilogo N/TOT, sia al successo che al fallimento (con posizione e
# nome del file che ha fatto fallire).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

CMD=$(grep -E '^N=0;.*for t in tests/test-\*\.sh' "$HERE/.night-verify" || true)
[ -n "$CMD" ] && ok ".night-verify contiene la riga con il riepilogo N/TOT" \
  || { ko ".night-verify non contiene più la riga con il riepilogo — regressione al bug del giro 4"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tests"
cd "$TMP"

# Caso 1: mini-suite tutta verde -> il tail deve riportare N/TOT, non l'output dell'ultimo test
cat > tests/test-a.sh <<'EOF'
#!/bin/bash
echo "a: 1 OK, 0 FAIL"
exit 0
EOF
cat > tests/test-b.sh <<'EOF'
#!/bin/bash
echo "b: 1 OK, 0 FAIL"
exit 0
EOF
chmod +x tests/test-a.sh tests/test-b.sh

OUT_OK=$(bash -c "$CMD" 2>&1)
echo "$OUT_OK" | tail -1 | grep -q "2/2" \
  && ok "successo: il tail riporta il conteggio reale (2/2), non l'output dell'ultimo test" \
  || ko "successo: il tail non riporta il conteggio — mostra invece: $(echo "$OUT_OK" | tail -1)"

# Caso 2: un test fallisce -> il tail deve indicare QUALE file e la sua posizione
cat > tests/test-c-fallisce.sh <<'EOF'
#!/bin/bash
echo "c: rotto di proposito"
exit 1
EOF
chmod +x tests/test-c-fallisce.sh

OUT_KO=$(bash -c "$CMD" 2>&1) || true
echo "$OUT_KO" | grep -q "FALLITO.*test-c-fallisce.sh" \
  && ok "fallimento: il tail indica il file esatto che ha fatto fallire la suite" \
  || ko "fallimento: nessuna indicazione di quale file sia fallito"
echo "$OUT_KO" | grep -qE "FALLITO \([0-9]+/[0-9]+\)" \
  && ok "fallimento: la posizione (N/TOT) è riportata" \
  || ko "fallimento: nessuna posizione N/TOT riportata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
