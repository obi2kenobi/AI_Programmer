#!/bin/bash
# test-risolvi-issue.sh — il risolutore notturno senza agente, contro un server mock.
# Nato dal banco di passaggio del 2026-09-04 (copertura): il solver era nato con 20
# prove manuali e nessun presidio di suite. Qui si provano i tre esiti che promette:
# APPLICATO (sostituzione verificata), PATCH (territorio non applicabile direttamente),
# e il rifiuto (modello senza codice). Più l'igiene E-002: niente pipe in grep -q.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SOLVER="$HERE/night-shift/risolvi-issue.sh"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "OK   $1"; }
ko()  { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$SOLVER" ] || { echo "FAIL risolvi-issue.sh non eseguibile"; exit 1; }

# --- igiene E-002: il solver gira con pipefail, niente produttori in pipe verso grep -q
if grep -q '| grep -q' "$SOLVER"; then
  ko "E-002: pipeline grep -q presente (SIGPIPE sotto pipefail)"
else
  ok "E-002: nessuna pipeline grep -q (cattura-prima)"
fi

# --- il server mock: risponde /api/chat con il corpo che decidiamo per test
MOCK_DIR=$(mktemp -d /tmp/risolvi-mock.XXXXXX)
MOCK_BODY_FILE="$MOCK_DIR/body.json"
cat > "$MOCK_DIR/serve.py" <<'PYEOF'
import http.server, json, sys, pathlib
body_file = pathlib.Path(sys.argv[1])
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = body_file.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a):
        pass
srv = http.server.HTTPServer(("127.0.0.1", 0), H)
print(srv.server_address[1], flush=True)
srv.serve_forever()
PYEOF
python3 "$MOCK_DIR/serve.py" "$MOCK_BODY_FILE" > "$MOCK_DIR/port" 2>/dev/null &
MOCK_PID=$!
for _ in $(seq 1 20); do [ -s "$MOCK_DIR/port" ] && break; sleep 0.1; done
MOCK_PORT=$(cat "$MOCK_DIR/port")
trap '{ kill $MOCK_PID 2>/dev/null; wait $MOCK_PID 2>/dev/null; } 2>/dev/null; rm -rf "$MOCK_DIR" "$SB" "$SB2" "$SB4" "$SB5" "$SB6" "$SB7" "$SB8"' EXIT
ok "server mock su porta $MOCK_PORT"

# --- caso 1: APPLICATO — una funzione rotta, il mock la restituisce corretta
SB=$(mktemp -d /tmp/risolvi-sb.XXXXXX)
cat > "$SB/calc.js" <<'EOF'
function calc(a, b) {
  return a + b;
}
EOF
cat > "$SB/issue.md" <<'EOF'
## Commessa
calc deve moltiplicare b per 2 prima di sommarlo ad a.

## Territorio
File: calc.js (7 righe)

## Verifica
node --check calc.js
EOF
cat > "$MOCK_BODY_FILE" <<'EOF'
{"message":{"content":"Ecco la correzione:\n```javascript\nfunction calc(a, b) {\n  return a + b * 2;\n}\n```\n"}}
EOF
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB" "$SB/issue.md" 2>&1); RC=$?
if [ $RC -eq 0 ] && grep -q 'a + b \* 2' "$SB/calc.js" && [ ! -f "$SB/calc.js.night-bak" ]; then
  ok "APPLICATO: funzione sostituita, verificata, backup pulito"
else
  ko "APPLICATO: rc=$RC — file: $(cat "$SB/calc.js" | tr '\n' ' ') — out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
fi

# --- caso 2: PATCH — territorio con due file: nessuna applicazione diretta
SB2=$(mktemp -d /tmp/risolvi-sb2.XXXXXX); SB="$SB2"
printf 'function uno() { return 1; }\n' > "$SB2/a.js"
printf 'function due() { return 2; }\n' > "$SB2/b.js"
cat > "$SB2/issue.md" <<'EOF'
## Commessa
rifattorizza entrambi i file.

## Territorio
File: a.js e b.js

## Verifica
node --check
EOF
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB2" "$SB2/issue.md" 2>&1); RC=$?
if [ $RC -eq 3 ] && echo "$OUT" | grep -q "ESITO: PATCH" && [ "$(cat "$SB2/a.js")" = 'function uno() { return 1; }' ]; then
  ok "PATCH: exit 3 (proposta), file originali intatti (N_FILES=2)"
else
  ko "PATCH: rc=$RC out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
fi

# --- caso 4: PROPOSTA con bak da pulire — funzione presente ma indentata:
# grep la trova, la regex di sostituzione (^function a colonna 0) no: il bak
# creato prima del tentativo dev'essere rimosso (notte 4/9: finiva in PR)
SB4=$(mktemp -d /tmp/risolvi-sb4.XXXXXX)
# bersaglio con funzione NON a colonna zero: la regex ^function non la becca
printf 'if (true) {\n  function calc(a, b) {\n    return a + b;\n  }\n}\n' > "$SB4/calc2.js"
cat > "$SB4/issue.md" <<'ISSA'
## Commessa
correggi calc.

## Territorio
File: calc2.js

## Verifica
node --check
ISSA
cat > "$MOCK_BODY_FILE" <<'EOF'
{"message":{"content":"```javascript\nfunction calc(a, b) {\n  return a + b * 2;\n}\n```\n"}}
EOF
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB4" "$SB4/issue.md" 2>&1); RC=$?
if [ $RC -eq 3 ] && [ ! -f "$SB4/calc2.js.night-bak" ] && echo "$OUT" | grep -q "ESITO: PATCH"; then
  ok "PROPOSTA: sostituzione fallita = exit 3 e NESSUN bak lasciato in giro"
else
  ko "PROPOSTA: rc=$RC bak=$([ -f "$SB4/calc2.js.night-bak" ] && echo presente || echo assente) out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
fi

# --- caso 3b: FUNZIONE NUOVA in .js — la issue Feature si risolve: INSERITO, wiring dichiarato
# (fase B adattiva: l'issue #10 era ferma da tre notti perche' le Feature degradavano a proposta)
SB5=$(mktemp -d /tmp/risolvi-sb5.XXXXXX)
printf 'function esistente() { return 1; }\n' > "$SB5/altro.js"
cat > "$SB5/issue.md" <<'ISSA'
## Commessa
aggiungi la funzione raddoppia(x).

## Territorio
File: altro.js

## Verifica
node --check
ISSA
cat > "$MOCK_BODY_FILE" <<'EOF'
{"message":{"content":"```javascript\nfunction raddoppia(x) {\n  return x * 2;\n}\n```\n"}}
EOF
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB5" "$SB5/issue.md" 2>&1); RC=$?
if [ $RC -eq 0 ] && grep -q "function raddoppia" "$SB5/altro.js" && echo "$OUT" | grep -q "INSERITO" && echo "$OUT" | grep -qi "wiring\|chiama"; then
  ok "INSERITO: funzione nuova aggiunta al file, wiring mancante DICHIARATO"
else
  ko "INSERITO: rc=$RC out: $(echo "$OUT" | tail -3 | tr '\n' ' ')"
fi

# --- caso 3c: funzione nuova in .html — inserita PRIMA dell'ultimo </script>
SB6=$(mktemp -d /tmp/risolvi-sb6.XXXXXX)
printf '<html><body><script>\nfunction vecchia() { return 1; }\n</script>\n</body></html>\n' > "$SB6/pag.html"
sed 's/altro\.js/pag.html/' "$SB5/issue.md" > "$SB6/issue.md"
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB6" "$SB6/issue.md" 2>&1); RC=$?
if [ $RC -eq 0 ] && grep -q "function raddoppia" "$SB6/pag.html"; then
  python3 -c "
s = open('$SB6/pag.html').read()
ok = s.index('function raddoppia') < s.rindex('</script>') and s.rindex('function raddoppia') > s.rindex('<script>')
print('INSERITO-HTML-OK' if ok else 'POS-SBAGLIATA')" | grep -q INSERITO-HTML-OK \
    && ok "INSERITO-HTML: dentro l'ultimo blocco script, non dopo </html>" \
    || ko "INSERITO-HTML: posizione sbagliata"
else
  ko "INSERITO-HTML: rc=$RC"
fi

# --- caso 3d: .html SENZA </script>: rifiuto dichiarato, nessuna inserzione alla cieca
SB7=$(mktemp -d /tmp/risolvi-sb7.XXXXXX)
printf '<html><body><p>nessuno script qui</p></body></html>\n' > "$SB7/solo.html"
sed 's/altro\.js/solo.html/' "$SB5/issue.md" > "$SB7/issue.md"
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB7" "$SB7/issue.md" 2>&1); RC=$?
if [ $RC -eq 3 ] && ! grep -q "function raddoppia" "$SB7/solo.html" && echo "$OUT" | grep -q "ESITO: PATCH"; then
  ok "RIFIUTO-HTML: senza punto dichiarato resta proposta (mai inserzione alla cieca)"
else
  ko "RIFIUTO-HTML: rc=$RC"
fi

# --- caso S1 (sicurezza, set 2026-09-07): il Territorio di un issue non legge/scrive
# FUORI dal progetto. Attacco provato prima della cura: /tmp/segreto-finto.py veniva
# letto e incollato nel prompt al modello. Un issue e' input esterno fino a una lettura.
SB8=$(mktemp -d /tmp/risolvi-sb8.XXXXXX)
printf 'function fuori() { return 1; }\n' > "$MOCK_DIR/segreto-fuori.js"   # FUORI da $SB8
printf 'function dentro() { return 1; }\n' > "$SB8/dentro.js"
{ echo "## Commessa"; echo "usa i file indicati."; echo ""; echo "## Territorio"; echo "File: $MOCK_DIR/segreto-fuori.js e dentro.js"; echo ""; echo "## Verifica"; echo "node --check"; } > "$SB8/issue.md"
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB8" "$SB8/issue.md" 2>&1); RC=$?
if echo "$OUT" | grep -q "FUORI dal progetto" && [ $RC -ne 2 ]; then
  ok "sicurezza: path fuori dal progetto rifiutato e DICHIARATO (mai letto, mai scritto)"
else
  ko "sicurezza: file esterno non confinato (rc=$RC)"
fi

# --- caso 3: il modello non produce codice — il solver rifiuta, niente file toccati
cat > "$MOCK_BODY_FILE" <<'EOF'
{"message":{"content":"Mi dispiace, non ho capito la richiesta."}}
EOF
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB2" "$SB2/issue.md" 2>&1); RC=$?
if [ $RC -ne 0 ] && echo "$OUT" | grep -q "non passa node --check"; then
  ok "RIFIUTO: prosa senza codice — il solver esce 1 e non tocca nulla"
else
  ko "RIFIUTO: rc=$RC out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
