#!/bin/bash
# test-agente-privacy.sh — P1.10: con AGENTE_ANONIMIZZA=1 nessun read/run puo'
# rimandare contenuto grezzo al modello quando la catena PII e' degradata.
# rete: localhost (LLM e server PII finti, mai servizi o dati reali)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
T=$(mktemp -d /tmp/test-agente-privacy.XXXXXX)
PASS=0; FAIL=0; PIDS=""
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
trap 'for p in $PIDS; do kill "$p" 2>/dev/null || true; done; rm -rf "$T"' EXIT

cat > "$T/llm.py" <<'PY'
import http.server, pathlib, sys
root=pathlib.Path(sys.argv[1]); count=pathlib.Path(sys.argv[2])
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        raw=self.rfile.read(int(self.headers.get('Content-Length',0)))
        with open(count,'ab') as f: f.write(raw+b'\n')
        nfile=root/'numero-richieste'
        n=int(nfile.read_text())+1 if nfile.exists() else 1
        nfile.write_text(str(n))
        text='{"action":"read","path":"f.txt"}' if n==1 else 'finito'
        with open(root/'sequenza','a') as f: f.write(str(n)+' '+text+'\n')
        body=('{"message":{"content":'+__import__('json').dumps(text)+'}}').encode()
        self.send_response(200); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self,*a): pass
s=http.server.HTTPServer(('127.0.0.1',0),H); print(s.server_address[1],flush=True); s.serve_forever()
PY
cat > "$T/pii.py" <<'PY'
import http.server, json, pathlib, sys
mode=sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body=b'{}'; self.send_response(200); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_POST(self):
        raw=self.rfile.read(int(self.headers.get('Content-Length',0)))
        text=json.loads(raw).get('text','')
        if mode=='empty': out={'anonymized_text':'','mapping':{}}
        elif mode=='malformed': out={}
        else: out={'anonymized_text':text.replace('Mario Rossi','[FULLNAME_1]'),'mapping':{'[FULLNAME_1]':'Mario Rossi'}}
        body=json.dumps(out).encode(); self.send_response(200); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self,*a): pass
s=http.server.HTTPServer(('127.0.0.1',0),H); print(s.server_address[1],flush=True); s.serve_forever()
PY

# run_case <nome> <modalita'> <azione-json> [tool-path]
# Scrive in REQ tutte le richieste arrivate al LLM: se il valore sintetico
# compare qui, la privacy e' fallita anche se il log esterno sembra pulito.
run_case() {
  local name="$1" mode="$2" action="$3" tool="${4:-$HERE/tools/anonimizza.py}"
  local d="$T/$name"; mkdir -p "$d/proj"
  printf 'Mario Rossi\n' > "$d/proj/f.txt"
  python3 "$T/llm.py" "$d" "$d/requests" > "$d/llm-port" 2>/dev/null & local lp=$!; PIDS="$PIDS $lp"
  for _ in $(seq 1 100); do [ -s "$d/llm-port" ] && break; sleep 0.05; done
  local pii_url='http://127.0.0.1:1'
  if [ "$mode" != down ]; then
    python3 "$T/pii.py" "$mode" > "$d/pii-port" 2>/dev/null & local pp=$!; PIDS="$PIDS $pp"
    for _ in $(seq 1 100); do [ -s "$d/pii-port" ] && break; sleep 0.05; done
    pii_url="http://127.0.0.1:$(cat "$d/pii-port")"
  fi
  # Il mock risponde sempre read alla prima chiamata; per il caso run cambia
  # l'azione nella directory usata dal server senza cambiare il protocollo.
  if [[ "$action" == *'"run"'* ]]; then
    # il server legge la scelta da questo file a ogni richiesta
    printf 'run\n' > "$d/mode-azione"
  fi
  # Un dossier minimale: primo contenuto = azione richiesta dal caso.
  # Si usa una variante del server col contenuto nel file action, se presente.
  printf '%s\n' "$action" > "$d/action"
  OUT=$(AGENTE_ANONIMIZZA=1 AGENTE_ANONIMIZZA_TOOL="$tool" PII_URL="$pii_url" \
    NIGHT_API_URL="http://127.0.0.1:$(cat "$d/llm-port")/api/chat" AGENTE_MAX_TURNI=3 AGENTE_TIMEOUT=20 \
    bash "$HERE/night-shift/agente.sh" "$d/proj" test 2>&1); RC=$?
  REQ="$d/requests"
  kill "$lp" 2>/dev/null || true; wait "$lp" 2>/dev/null
  if [ "$mode" != down ]; then kill "$pp" 2>/dev/null || true; wait "$pp" 2>/dev/null; fi
}

# Il server LLM ha bisogno dell'azione del caso; patchiamo solo la fixture,
# non l'agente: action file letto a ogni prima richiesta, poi risposta finale.
python3 - "$T/llm.py" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace("text='{\"action\":\"read\",\"path\":\"f.txt\"}' if n==1 else 'finito'", "text=pathlib.Path(sys.argv[1], 'action').read_text().strip() if n==1 else 'finito'")
open(p,'w').write(s)
PY

run_case read_ok normal '{"action":"read","path":"f.txt"}'
! grep -q 'Mario Rossi' "$REQ" && grep -q 'FULLNAME_1' "$REQ" \
  && ok "read sano: al modello arriva il placeholder, non il valore" || { ko "read sano: valore grezzo o placeholder assente"; cat "$T/read_ok/sequenza" 2>/dev/null; printf '%s\n' "$OUT"; }
run_case read_empty empty '{"action":"read","path":"f.txt"}'
! grep -q 'Mario Rossi' "$REQ" && grep -q 'BLOCCATO\|blocked' <<<"$OUT" \
  && ok "anonimizzazione vuota: read BLOCCATO, mai fallback grezzo" || ko "read vuoto ha trasmesso il valore o non dichiara il blocco"
run_case read_bad malformed '{"action":"read","path":"f.txt"}'
! grep -q 'Mario Rossi' "$REQ" && grep -q 'BLOCCATO\|blocked' <<<"$OUT" \
  && ok "risposta PII malformata: read BLOCCATO" || ko "risposta malformata ha trasmesso il valore"
run_case read_tool normal '{"action":"read","path":"f.txt"}' "$T/tool-assente.py"
! grep -q 'Mario Rossi' "$REQ" && grep -q 'BLOCCATO\|blocked' <<<"$OUT" \
  && ok "tool anonimizzatore assente: read BLOCCATO" || ko "tool assente ha trasmesso il valore"
run_case run_ok normal '{"action":"run","command":"cat f.txt"}'
! grep -q 'Mario Rossi' "$REQ" && grep -q 'FULLNAME_1' "$REQ" \
  && ok "run sano, anche in sandbox: output anonimizzato prima del modello" || ko "run sano ha trasmesso valore grezzo"
run_case run_down down '{"action":"run","command":"cat f.txt"}'
! grep -q 'Mario Rossi' "$REQ" && grep -qi 'blocked\|BLOCCATO' <<<"$OUT" \
  && ok "server PII spento: run BLOCCATO, non raw output" || ko "run con server spento ha trasmesso il valore"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
