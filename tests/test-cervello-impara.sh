#!/bin/bash
# test-cervello-impara.sh — il /learn del sistema sotto banco. Tre prove con un
# modello FINTO (mock /api/chat, stesso contratto): una lezione valida diventa
# nota da approvare (link rotti scartati e dichiarati), l'onesto niente non crea
# niente, e nessun doppione. L'ispirazione (everything-claude-code) salva le
# proprie lezioni con auto_approve:false: da noi la parola finale e' del mattino.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d /tmp/test-impara.XXXXXX)
trap 'rm -rf "$TMP"; [ -n "${MOCKPID:-}" ] && kill "$MOCKPID" 2>/dev/null' EXIT

# fixture: un cervello in miniatura + un log di ieri con eventi notevoli
mkdir -p "$TMP/repo/cervello" "$TMP/repo/docs/errori" "$TMP/repo/tools"
cp "$HERE/tools/cervello-annota.sh" "$TMP/repo/tools/"
cp "$HERE/tools/cervello-impara.sh" "$TMP/repo/tools/"
printf -- "---\ntipo: concetto\ndata: 2026-09-21\ntitolo: Teatro\n---\nil verde che mente\n" > "$TMP/repo/cervello/concetto-teatro.md"
printf '# Registro\n## E-001 esempio\n## E-038 esempio\n' > "$TMP/repo/docs/errori/REGISTRO.md"
OGGI=$(date +%F)
{ echo "[$OGGI 10:00:00] === TURNO INIZIATO ==="
  echo "[$OGGI 11:00:00] REPO r/x: caccia: ⚠ AGENTE FALLITO (Ollama?)"
  echo "[$OGGI 12:00:00] REPO r/x: MIGLIORIA pronta: [debito] f"
} > "$TMP/log"

# il mock: serve la risposta che gli si dice, in ordine
mkmock() { # $1 = file con le risposte (una per riga, json-encodate dal chiamante)
  printf '#!/usr/bin/env python3\nimport http.server,sys\nRISP=[l.strip() for l in open(sys.argv[1]) if l.strip()]\nn=[0]\nclass H(http.server.BaseHTTPRequestHandler):\n def do_POST(self):\n  self.rfile.read(int(self.headers.get("Content-Length",0)))\n  i=min(n[0],len(RISP)-1); n[0]+=1\n  b=RISP[i].encode()\n  self.send_response(200);self.send_header("Content-Length",str(len(b)));self.end_headers();self.wfile.write(b)\n def log_message(self,*a):pass\ns=http.server.HTTPServer(("127.0.0.1",0),H)\nprint(s.server_address[1],flush=True)\ns.serve_forever()\n' > "$TMP/serve.py"
}
avvia() { python3 "$TMP/serve.py" "$1" > "$TMP/port" 2>/dev/null & MOCKPID=$!
  for _ in $(seq 1 30); do [ -s "$TMP/port" ] && break; sleep 0.1; done; }
risposta() { python3 -c 'import json,sys; print(json.dumps({"message":{"content":sys.argv[1]}}))' "$1"; }

# ── 1. lezione valida: nota creata, link rotto scartato e dichiarato ─────────
mkmock
printf '%s\n%s\n' \
  "$(risposta '{"titolo":"Il kill durante il banco mutazione","problema":"un kill a meta cp lascia il tool troncato","soluzione":"ogni scrittura passa da temp+mv atomico","quando":"qualunque banco che muta file","link":["concetto-teatro","nota-che-non-esiste"]}')" \
  > "$TMP/risp1.txt"
avvia "$TMP/risp1.txt"
OUT=$(cd "$TMP/repo" && NIGHT_API_URL="http://127.0.0.1:$(cat "$TMP/port")/api/chat" NIGHT_LOG="$TMP/log" bash tools/cervello-impara.sh 2>&1); RC=$?
kill "$MOCKPID" 2>/dev/null; wait "$MOCKPID" 2>/dev/null; MOCKPID=""
NOTA=$(ls "$TMP/repo/cervello/"lezione-*.md 2>/dev/null | head -1)
if [ $RC -eq 0 ] && [ -n "$NOTA" ] \
   && grep -q "stato: da approvare" "$NOTA" \
   && grep -q "concetto-teatro" "$NOTA" \
   && ! grep -q "nota-che-non-esiste" "$NOTA" \
   && echo "$OUT" | grep -q "nota-che-non-esiste"; then
  ok "lezione valida → nota creata (da approvare), link buono tenuto, rotto scartato e dichiarato"
else
  ko "lezione valida: rc=$RC nota=[$NOTA] out=[$OUT]"
fi

# ── 2. onesto niente: nessuna nota ───────────────────────────────────────────
mkmock
printf '%s\n' "$(risposta '{"niente":true,"perche":"giornata piatta, solo contesa"}')" > "$TMP/risp2.txt"
avvia "$TMP/risp2.txt"
OUT=$(cd "$TMP/repo" && NIGHT_API_URL="http://127.0.0.1:$(cat "$TMP/port")/api/chat" NIGHT_LOG="$TMP/log" bash tools/cervello-impara.sh 2>&1); RC=$?
kill "$MOCKPID" 2>/dev/null; wait "$MOCKPID" 2>/dev/null; MOCKPID=""
N_LEZIONI=$(ls "$TMP/repo/cervello/"lezione-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ $RC -eq 0 ] && [ "$N_LEZIONI" = "1" ] && echo "$OUT" | grep -q "onesto niente"; then
  ok "onesto niente → nessuna nuova nota, dichiarato"
else
  ko "onesto niente: rc=$RC lezioni=$N_LEZIONI out=[$OUT]"
fi

# ── 3. niente doppioni: la stessa lezione non si riscrive ────────────────────
mkmock
printf '%s\n%s\n' \
  "$(risposta '{"titolo":"Il kill durante il banco mutazione","problema":"x","soluzione":"y","quando":"z","link":[]}')" \
  > "$TMP/risp3.txt"
avvia "$TMP/risp3.txt"
OUT=$(cd "$TMP/repo" && NIGHT_API_URL="http://127.0.0.1:$(cat "$TMP/port")/api/chat" NIGHT_LOG="$TMP/log" bash tools/cervello-impara.sh 2>&1); RC=$?
kill "$MOCKPID" 2>/dev/null; wait "$MOCKPID" 2>/dev/null; MOCKPID=""
N_LEZIONI=$(ls "$TMP/repo/cervello/"lezione-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ $RC -eq 0 ] && [ "$N_LEZIONI" = "1" ] && echo "$OUT" | grep -q "gia' presente"; then
  ok "stessa lezione riproposta → nessun doppione, dichiarato"
else
  ko "doppioni: rc=$RC lezioni=$N_LEZIONI out=[$OUT]"
fi

# ── 4. (revisione 10 giri, 2026-09-23): una lezione che CONTIENE graffe ─────────
# L'estrazione era `sed 's/.*\({.*}\).*/\1/'`: il `.*` iniziale e' avido e si mangia tutto fino
# all'ULTIMA graffa aperta — una lezione di bash con `${VAR:-x}` diventava «{VAR:-x} …}»,
# JSON rotto, e la lezione vera si perdeva come «risposta non valida».
mkmock
printf '%s\n' "$(risposta 'Ecco: {"titolo":"Default con le graffe","problema":"variabile vuota","soluzione":"usa ${VAR:-x} sempre","quando":"script bash","link":[]} fine')" > "$TMP/risp4.txt"
avvia "$TMP/risp4.txt"
OUT=$(cd "$TMP/repo" && NIGHT_API_URL="http://127.0.0.1:$(cat "$TMP/port")/api/chat" NIGHT_LOG="$TMP/log" bash tools/cervello-impara.sh 2>&1); RC=$?
kill "$MOCKPID" 2>/dev/null; wait "$MOCKPID" 2>/dev/null; MOCKPID=""
[ $RC -eq 0 ] && ls "$TMP/repo/cervello/"lezione-default-con-le-graffe*.md >/dev/null 2>&1 \
  && ok "lezione con \${VAR:-x} dentro → estratta intera, nota creata" || ko "lezione con graffe persa: rc=$RC out=[$OUT]"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
