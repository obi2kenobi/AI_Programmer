#!/bin/bash
# test-anonimizza-tools.sh — i tre strumenti rizzo-pii sotto banco (2026-10-01).
# Erano SCOPERTI (banco-passaggio): nessun test li citava dal loro arrivo (#126).
# Server PII finto su porta libera: il giro intero pulisci → dizionario →
# ripristina → scan, senza toccare il server vero.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d /tmp/test-anon-tools.XXXXXX)
trap 'rm -rf "$TMP"; [ -n "${NERPID:-}" ] && kill "$NERPID" 2>/dev/null' EXIT

# il server finto: /health 200, /analyze risponde con un FULLNAME mappato
NER="$TMP/ner.py"
cat > "$NER" <<'PY'
import http.server, socket, sys, json
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _r(self, corpo):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(corpo)
    def do_GET(self): self._r(b'{"ok":true}')
    def do_POST(self):
        self.rfile.read(int(self.headers.get("Content-Length", 0)))
        self._r(json.dumps({
            "n_entities": 1, "by_label": {"FULLNAME": 1},
            "mapping": {"[FULLNAME_1]": "Mario Rossi"},
            "anonymized_text": "Il sig. [FULLNAME_1] paga",
            "segments": [{"text": "[FULLNAME_1]", "labels": [{"label": "FULLNAME"}]}],
        }).encode())
with socket.socket() as s:
    s.bind(("127.0.0.1", 0)); port = s.getsockname()[1]; s.close()
print(port, flush=True)
http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()
PY
python3 "$NER" > "$TMP/port" 2>/dev/null & NERPID=$!
for _ in $(seq 1 50); do [ -s "$TMP/port" ] && break; sleep 0.1; done
PORT=$(cat "$TMP/port")
PII_URL="http://127.0.0.1:$PORT"

# 1. pii-scan: rileva l'entita' (e il giro di stdin T5#6 funziona)
OUT=$(PII_URL="$PII_URL" bash "$HERE/tools/pii-scan.sh" "Il sig. Mario Rossi" 2>&1)
grep -q "1 entita' PII\|FULLNAME" <<<"$OUT" && ok "pii-scan: rileva il FULLNAME dal server" || ko "pii-scan: $OUT"

# 2. anonimizza-aziendale pulisci: segnaposto al posto del nome, dizionario salvato
OUT=$(ANON_DIZ_DIR="$TMP/anon-diz" PII_URL="$PII_URL" bash "$HERE/tools/anonimizza-aziendale.sh" pulisci "Il sig. Mario Rossi paga" 2>&1)
if grep -q "FULLNAME_1" <<<"$OUT" && ! grep -q "Mario Rossi" <<<"$OUT"; then
  ok "anonimizza-aziendale: il nome sostituito, mai in chiaro in uscita"
else
  ko "pulisci: $OUT"
fi
[ -s "$TMP/anon-diz/dizionario.json" ] && ok "il dizionario cumulativo e' salvato" || ko "dizionario assente"

# 3. anonimizza.py: il giro inverso col dizionario giusto
RIPR=$(printf 'Il sig. [FULLNAME_1] paga' | python3 "$HERE/tools/anonimizza.py" --diz "$TMP/anon-diz/dizionario.json" --ripristina 2>/dev/null || true)
if grep -q "Mario Rossi" <<<"$RIPR"; then
  ok "anonimizza.py --ripristina: il nome torna dal dizionario"
else
  ko "ripristina non rimette il nome: $RIPR"
fi

# 4. la citazione per la copertura (banco-passaggio): i tre strumenti sono citati qui sopra
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
