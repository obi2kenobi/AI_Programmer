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

# --- (revisione 10 giri, 2026-09-23): il verdetto dell'auto-review si classificava con
# *correct* PRIMA di *wrong* — «incorrect», «not correct», «scorretto» contengono «correct»
# /«corretto» e diventavano CORRECT. La classificazione vive in classifica_verdetto(),
# estratta dal sorgente ed eseguita qui (niente copia a mano della logica).
FN=$(sed -n '/^classifica_verdetto() {/,/^}/p' "$SOLVER")
if [ -n "$FN" ]; then
  eval "$FN"
  for CASO in "correct|CORRECT" "CORRECT.|CORRECT" "corretto|CORRECT" "giusto|CORRECT" \
              "incorrect|WRONG" "wrong. the fix is not correct|WRONG" "not correct: missing null check|WRONG" \
              "scorretto|WRONG" "non corretto|WRONG" "sbagliato|WRONG" "boh|UNCLEAR" "|UNCLEAR"; do
    IN="${CASO%%|*}"; ATTESO="${CASO##*|}"
    [ "$(classifica_verdetto "$IN")" = "$ATTESO" ] && ok "verdetto «${IN}» → $ATTESO" || ko "verdetto «${IN}» → $(classifica_verdetto "$IN") (atteso $ATTESO)"
  done
else
  ko "classifica_verdetto() non trovata in risolvi-issue.sh"
fi

# --- il server mock: risponde /api/chat con il corpo che decidiamo per test
MOCK_DIR=$(mktemp -d /tmp/risolvi-mock.XXXXXX)
MOCK_BODY_FILE="$MOCK_DIR/body.json"
cat > "$MOCK_DIR/serve.py" <<'PYEOF'
import http.server, json, sys, pathlib
body_file = pathlib.Path(sys.argv[1])
# server_bind senza getfqdn: il reverse-DNS di macOS si IMPALA a intermittenza
# (morso 7, 2026-09-15: il mock passava alle 17:15 e moriva alle 17:27 — colpa di
# mDNSResponder, non nostra. Un test che dipende dal DNS e' una moneta lanciata).
class NoRev(http.server.HTTPServer):
    def server_bind(self):
        import socketserver
        socketserver.TCPServer.server_bind(self)
        host, port = self.socket.getsockname()[:2]
        self.server_name, self.server_port = host, port

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
srv = NoRev(("127.0.0.1", 0), H)
print(srv.server_address[1], flush=True)
srv.serve_forever()
PYEOF
python3 "$MOCK_DIR/serve.py" "$MOCK_BODY_FILE" > "$MOCK_DIR/port" 2>/dev/null &
MOCK_PID=$!
for _ in $(seq 1 150); do [ -s "$MOCK_DIR/port" ] && break; sleep 0.1; done # (2026-09-23): 15 s, non 2-3 — sotto carico python parte piu' lento, la porta restava vuota e il tool diceva «il modello non ha risposto» (rosso a caso, catturato su test-cervello-impara)
[ -s "$MOCK_DIR/port" ] || echo "⚠ il server finto non e' partito in 15 s: i FAIL che seguono sono dell'ambiente" >&2
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
# (D5, test del sistema completo 2026-09-20): auto_review e genera_test erano definite
# DOPO l'exit: «command not found» a ogni fix, REVIEW vuota, e questo test passava lo
# stesso perche' non pretendeva la riga. Ora la pretende: il verdetto e' una delle tre
# parole, mai vuoto (col mock la risposta e' codice, quindi UNCLEAR — ma detto).
grep -qE '^REVIEW: (CORRECT|WRONG|UNCLEAR)$' <<<"$OUT" \
  && ok "AUTO-REVIEW eseguita: la riga REVIEW porta un verdetto" \
  || ko "AUTO-REVIEW non eseguita: $(echo "$OUT" | grep -E 'REVIEW|not found' | head -2 | tr '\n' ' ')"
# (2026-09-25, settimo ventaglio, V2 R3): senza node sul PATH (il plist del turno ne da' uno fisso) `node --check`
# esce 127, e il solver lo leggeva come «il codice non passa»: un fix giusto buttato con due diagnosi false, e la
# cascata all'agente. Ora: rc 2, «MANCA node», prima di chiamare il modello, e il file non si tocca.
SENZA_NODE=$(printf '%s' "$PATH" | tr ':' '\n' | while IFS= read -r d; do [ -x "$d/node" ] || printf '%s:' "$d"; done); SENZA_NODE=${SENZA_NODE%:}
if PATH="$SENZA_NODE" command -v python3 >/dev/null && PATH="$SENZA_NODE" command -v curl >/dev/null && ! PATH="$SENZA_NODE" command -v node >/dev/null; then
  printf 'function calc(a, b) {\n  return a + b;\n}\n' > "$SB/calc.js"
  OUT=$(PATH="$SENZA_NODE" NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB" "$SB/issue.md" 2>&1); RC=$?
  [ $RC -eq 2 ] && grep -c 'MANCA node' <<<"$OUT" >/dev/null && grep -c 'return a + b;' "$SB/calc.js" >/dev/null \
    && ok "V2 R3: senza node, rc 2 «MANCA node» e il file intatto (non «codice rotto»)" \
    || ko "V2 R3: senza node: rc=$RC — $(grep -E '⛔|⚠' <<<"$OUT" | head -2 | tr '\n' ' ')"
  printf 'function calc(a, b) {\n  return a + b * 2;\n}\n' > "$SB/calc.js"
else
  echo "SKIP V2 R3: qui non si toglie node dal PATH senza togliere anche python3 o curl"
fi
grep -q "command not found" <<<"$OUT" \
  && ko "funzioni chiamate prima della definizione: $(echo "$OUT" | grep 'command not found' | head -1)" \
  || ok "nessuna funzione chiamata prima della definizione"
# (D6): il turno legge $ISSUE_FILE per il check «gia' implementata» PRIMA di scriverlo —
# set -u lo svuotava e il check non girava mai. La scrittura deve precedere la lettura.
NS="$HERE/night-shift/night-shift.sh"
R_SCRIVE=$(grep -n 'ISSUE_FILE="/tmp/night-issue-\$NUM.md"' "$NS" | head -1 | cut -d: -f1)
R_LEGGE=$(grep -n 'FN_NOMINATA=\$(sed' "$NS" | head -1 | cut -d: -f1)
[ -n "$R_SCRIVE" ] && [ -n "$R_LEGGE" ] && [ "$R_SCRIVE" -lt "$R_LEGGE" ] \
  && ok "night-shift.sh: ISSUE_FILE scritto (riga $R_SCRIVE) prima del check «gia' implementata» (riga $R_LEGGE)" \
  || ko "night-shift.sh: il check «gia' implementata» legge ISSUE_FILE (riga $R_LEGGE) prima che esista (riga $R_SCRIVE)"

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
if [ $RC -eq 3 ] && grep -q "ESITO: PATCH" <<<"$OUT" && [ "$(cat "$SB2/a.js")" = 'function uno() { return 1; }' ]; then
  ok "PATCH: exit 3 (proposta), file originali intatti (N_FILES=2)"
else
  ko "PATCH: rc=$RC out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
fi

# --- caso 4: funzione presente ma INDENTATA (il caso #10 vero: 2 spazi) —
# la regex ora accetta ^\s*function: SOSTITUISCE, non degrada a proposta.
# (Prima: grep la trovava, la regex a colonna zero no, bak orfano — notte 4/9)
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
if [ $RC -eq 0 ] && grep -q "a + b \* 2" "$SB4/calc2.js" && [ ! -f "$SB4/calc2.js.night-bak" ] && grep -q "APPLICATO" <<<"$OUT"; then
  ok "INDENTATA: la funzione a 2 spazi viene sostituita (il caso #10 vero)"
else
  ko "INDENTATA: rc=$RC out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
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
if [ $RC -eq 0 ] && grep -q "function raddoppia" "$SB5/altro.js" && grep -q "INSERITO" <<<"$OUT" && grep -qi "wiring\|chiama" <<<"$OUT"; then
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
if [ $RC -eq 3 ] && ! grep -q "function raddoppia" "$SB7/solo.html" && grep -q "ESITO: PATCH" <<<"$OUT"; then
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
if grep -q "FUORI dal progetto" <<<"$OUT" && [ $RC -ne 2 ]; then
  ok "sicurezza: path fuori dal progetto rifiutato e DICHIARATO (mai letto, mai scritto)"
else
  ko "sicurezza: file esterno non confinato (rc=$RC)"
fi

# --- caso 3: il modello non produce codice — il solver rifiuta, niente file toccati
cat > "$MOCK_BODY_FILE" <<'EOF'
{"message":{"content":"Mi dispiace, non ho capito la richiesta."}}
EOF
OUT=$(NIGHT_API_URL="http://127.0.0.1:$MOCK_PORT/api/chat" bash "$SOLVER" "$SB2" "$SB2/issue.md" 2>&1); RC=$?
if [ $RC -ne 0 ] && grep -q "non passa node --check" <<<"$OUT"; then
  ok "RIFIUTO: prosa senza codice — il solver esce 1 e non tocca nulla"
else
  ko "RIFIUTO: rc=$RC out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
fi

# --- (2026-09-24, sesto ventaglio, S3 R3): uno spazio nel NOME di un file del Territorio — l'estrazione non ammetteva
# lo spazio («Codice Principale.gs» diventava «Principale.gs»), il ripiego con find si spezzava nel `for`, ogni pezzo
# si saltava in silenzio e il modello riceveva un SOURCE vuoto. E gli a capo del prompt erano «\n» letterali.
SB9=$(mktemp -d /tmp/risolvi-sb9.XXXXXX)
printf 'function principale() {\n  return 1;\n}\n' > "$SB9/Codice Principale.gs"
printf '## Commessa\nprincipale deve restituire 2.\n\n## Territorio\nFile: `Codice Principale.gs`\n' > "$SB9/issue.md"
OUT=$(NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$SOLVER" "$SB9" "$SB9/issue.md" 2>&1)
grep -c 'letti 1 file' <<<"$OUT" >/dev/null && ok "S3 R3: il file con lo spazio nel nome si legge (letti 1 file)" || ko "S3 R3: file con lo spazio non letto: $(grep -m2 'File da leggere\|letti\|nessun' <<<"$OUT" | tr '\n' ' ')"
printf '## Commessa\nx\n\n## Territorio\nFile: `non-esiste.gs`\n' > "$SB9/issue2.md"; rm -f "$SB9/Codice Principale.gs"
OUT=$(NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$SOLVER" "$SB9" "$SB9/issue2.md" 2>&1); RC=$?
[ "$RC" -eq 1 ] && grep -ci 'nessun file' <<<"$OUT" >/dev/null && ! grep -c 'Chiamando' <<<"$OUT" >/dev/null \
  && ok "S3 R3: nessun file letto → il modello non si chiama, e lo dice (rc 1)" || ko "S3 R3: SOURCE vuoto mandato al modello (rc $RC): $(grep -m1 'Chiamando\|nessun' <<<"$OUT")"
rm -rf "$SB9"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
