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
# (2026-09-23): il file della porta si SVUOTA PRIMA del lancio, qui e non nel processo in
# background — sotto carico il figlio tardava a troncarlo, l'attesa trovava la porta del finto
# PRECEDENTE (gia' ucciso) e il tool diceva «il modello non ha risposto»: 3 rossi su 150.
avvia() { : > "$TMP/port"; python3 "$TMP/serve.py" "$1" > "$TMP/port" 2>/dev/null & MOCKPID=$!
  for _ in $(seq 1 150); do [ -s "$TMP/port" ] && break; sleep 0.1; done # (2026-09-23): 15 s, non 2-3 — sotto carico python parte piu' lento, la porta restava vuota e il tool diceva «il modello non ha risposto» (rosso a caso, catturato su test-cervello-impara)
  [ -s "$TMP/port" ] || echo "⚠ il modello finto non e' partito in 15 s: il FAIL che segue e' dell'ambiente, non del tool" >&2; }
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
   && grep -q "nota-che-non-esiste" <<<"$OUT"; then
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
if [ $RC -eq 0 ] && [ "$N_LEZIONI" = "1" ] && grep -q "onesto niente" <<<"$OUT"; then
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
if [ $RC -eq 0 ] && [ "$N_LEZIONI" = "1" ] && grep -q "gia' presente" <<<"$OUT"; then
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


# ── 5. (2026-09-25, settimo ventaglio, V4 R5): lo slug si faceva con `tr`, che sul GNU lavora in byte: «Perché è così»
# diventava «perchuu-ui-cosuu» (il byte comune delle vocali accentate finiva su «u»), e la chiave anti-doppione cambiava
# con la piattaforma. Ora python, senza accenti e senza maiuscole, come le ancore di sal-indice.
mkmock
printf '%s\n' "$(risposta '{"titolo":"Perché È così: la città","problema":"x","soluzione":"y","quando":"z","link":[]}')" > "$TMP/risp5.txt"
avvia "$TMP/risp5.txt"
OUT=$(cd "$TMP/repo" && NIGHT_API_URL="http://127.0.0.1:$(cat "$TMP/port")/api/chat" NIGHT_LOG="$TMP/log" bash tools/cervello-impara.sh 2>&1); RC=$?
kill "$MOCKPID" 2>/dev/null; wait "$MOCKPID" 2>/dev/null; MOCKPID=""
[ $RC -eq 0 ] && [ -f "$TMP/repo/cervello/lezione-perche-e-cosi-la-citta.md" ] \
  && ok "V4 R5: titolo accentato → slug «perche-e-cosi-la-citta»" || ko "V4 R5: slug: $(ls "$TMP/repo/cervello/" | grep perch | head -1)"

# (2026-09-25, ottavo ventaglio, O3 R5): le lezioni gia' note si prendevano con `grep "^## E-0"` — da E-100 in poi nessuna
# voce nuova del REGISTRO sarebbe entrata nel prompt (oggi siamo a E-049). Il numero della voce non ha un tetto.
! grep -c '\^## E-0"' "$HERE/tools/cervello-impara.sh" >/dev/null && grep -c '\^## E-\[0-9\]' "$HERE/tools/cervello-impara.sh" >/dev/null \
  && ok "O3 R5: le lezioni note si leggono per ogni numero di voce (anche E-100 e oltre)" || ko "O3 R5: le lezioni note si fermano a E-099"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
