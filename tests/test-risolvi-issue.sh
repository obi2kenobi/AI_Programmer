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
trap '{ kill $MOCK_PID 2>/dev/null; wait $MOCK_PID 2>/dev/null; } 2>/dev/null; rm -rf "$MOCK_DIR" "$SB" "$SB2" "$SB4"' EXIT
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
