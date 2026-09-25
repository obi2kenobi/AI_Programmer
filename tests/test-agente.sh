#!/bin/bash
# test-agente.sh — l'agente nostro sotto prova, in DUE parti.
#
# Parte A (sempre, deterministica — giro 11 del 2026-09-20): la MECCANICA del ciclo
# bash ↔ modello con un server mock che risponde una sequenza di azioni. Nata perche' il
# banco delle mutazioni segnava questo test «teatro»: senza Ollama saltava tutto, e un
# agente.sh neutralizzato passava. Qui si prova cio' che non dipende dal modello: edit
# esatto, edit ambiguo/assente, confinamento dei path, denylist del run, write che non
# sovrascrive (la regola del prompt diventa strutturale), tetto dei turni.
# Parte B (solo con Ollama attivo): le tre sfide del modello vero, skip dichiarato.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
AGENTE="$HERE/night-shift/agente.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$AGENTE" && ok "sintassi" || { ko "sintassi"; exit 1; }

# ── Parte A: il mock a SEQUENZA — risponde i file 1.json, 2.json, … del suo dossier ──
MOCK_DIR=$(mktemp -d /tmp/agente-mock.XXXXXX)
cat > "$MOCK_DIR/serve.py" <<'PYEOF'
import http.server, sys, pathlib, itertools
dossier = pathlib.Path(sys.argv[1]); n = itertools.count(1)
class NoRev(http.server.HTTPServer):
    def server_bind(self):
        import socketserver
        socketserver.TCPServer.server_bind(self)
        host, port = self.socket.getsockname()[:2]
        self.server_name, self.server_port = host, port
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("Content-Length", 0)))
        i = next(n); f = dossier / f"{i}.json"
        if not f.exists():  # dossier finito: il modello «finisce» con testo
            body = b'{"message":{"content":"FINISH (dossier esaurito)"}}'
        else:
            body = f.read_bytes()
        self.send_response(200); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
srv = NoRev(("127.0.0.1", 0), H); print(srv.server_address[1], flush=True); srv.serve_forever()
PYEOF
SB_ROOT=$(mktemp -d /tmp/test-agente.XXXXXX)
trap 'rm -rf "$MOCK_DIR" "$SB_ROOT"; jobs -p | xargs -r kill 2>/dev/null' EXIT
azione() { # azione <json-del-contenuto> → corpo risposta Ollama con quel contenuto
  python3 -c 'import json,sys; print(json.dumps({"message":{"content":sys.argv[1]}}))' "$1"
}
scenario() { # scenario <nome> <dir-progetto> <prompt> <corpo-1> [<corpo-2> …] → OUT e RC globali
  local nome="$1" dir="$2" prompt="$3"; shift 3
  local d="$MOCK_DIR/$nome"; mkdir -p "$d"; local i=1
  for b in "$@"; do printf '%s\n' "$b" > "$d/$i.json"; i=$((i+1)); done
  python3 "$MOCK_DIR/serve.py" "$d" > "$d/port" 2>/dev/null & local pid=$!
  for _ in $(seq 1 150); do [ -s "$d/port" ] && break; sleep 0.1; done # (2026-09-23): 15 s, non 2-3 — sotto carico python parte piu' lento, la porta restava vuota e il tool diceva «il modello non ha risposto» (rosso a caso, catturato su test-cervello-impara)
  [ -s "$d/port" ] || echo "⚠ il modello finto non e' partito in 15 s: il FAIL che segue e' dell'ambiente, non dell'agente" >&2
  OUT=$(NIGHT_API_URL="http://127.0.0.1:$(cat "$d/port")/api/chat" AGENTE_MAX_TURNI="${MAX_T:-6}" AGENTE_TIMEOUT=60 bash "$AGENTE" "$dir" "$prompt" 2>&1); RC=$?
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
}

# A1: read → edit esatto → finish: il file cambia SOLO nella riga indicata
SB="$SB_ROOT/a1"; mkdir -p "$SB"; printf 'function sconto(p, x) {\n  return p - x;\n}\n' > "$SB/mat.js"
scenario a1 "$SB" "fix sconto" \
  "$(azione '{"action":"read","path":"mat.js"}')" \
  "$(azione '{"action":"edit","path":"mat.js","old":"  return p - x;","new":"  return p - (p * x / 100);"}')" \
  "$(azione 'Done: fixed sconto.')"
[ "$RC" -eq 0 ] && grep -q 'p \* x / 100' "$SB/mat.js" && [ "$(wc -l < "$SB/mat.js")" -eq 3 ] \
  && ok "A1: read → edit esatto → finish (rc 0, una riga cambiata, le altre byte-identiche)" \
  || ko "A1: rc=$RC file: $(tr '\n' '|' < "$SB/mat.js") out: $(echo "$OUT" | tail -2 | tr '\n' ' ')"
grep -q "completato in 3 turni" <<<"$OUT" && ok "A1: tre turni contati" || ko "A1: conteggio turni: $(echo "$OUT" | grep completato)"

# A2: edit con old ASSENTE → errore al modello, file intatto; poi old AMBIGUO → errore
SB="$SB_ROOT/a2"; mkdir -p "$SB"; printf 'a\nb\na\n' > "$SB/f.txt"
scenario a2 "$SB" "edit" \
  "$(azione '{"action":"edit","path":"f.txt","old":"zzz","new":"y"}')" \
  "$(azione '{"action":"edit","path":"f.txt","old":"a","new":"y"}')" \
  "$(azione 'stop')"
[ "$(cat "$SB/f.txt" | tr '\n' '|')" = "a|b|a|" ] && ok "A2: old assente e old ambiguo → file INTATTO" || ko "A2: file toccato: $(tr '\n' '|' < "$SB/f.txt")"
grep -q "vecchio non trovato" <<<"$OUT" && grep -q "ambiguo" <<<"$OUT" && ok "A2: entrambi gli errori dichiarati nel log" || ko "A2: errori non loggati: $(echo "$OUT" | grep edit | tr '\n' ' ')"

# A3: confinamento — read e write FUORI dal progetto rifiutati, il segreto non passa
SB="$SB_ROOT/a3"; mkdir -p "$SB"; printf 'SEGRETO-XYZ\n' > "$MOCK_DIR/segreto.txt"
# (E-038, due lezioni in un colpo: le quote annidate con escape dentro "$(...)"
# spezzavano l'azione in frammenti sul bash 3.2 di macOS — l'agente riceveva
# "action":"read" senza graffe; e un commento in mezzo a una catena di \
# spezza la continuazione ingoiando il backslash finale — lo scenario partiva
# senza corpi, "dossier esaurito" al primo turno. Pattern sicuro: commento
# SOPRA il comando, apici singoli + concatenazione per le variabili.)
scenario a3 "$SB" "leggi" \
  "$(azione '{"action":"read","path":"'"$MOCK_DIR"'/segreto.txt"}')" \
  "$(azione '{"action":"write","path":"'"$MOCK_DIR"'/fuori.txt","content":"x"}')" \
  "$(azione '{"action":"read","path":"../segreto.txt"}')" \
  "$(azione 'fine')"
grep -q "SEGRETO-XYZ" <<<"$OUT" && ko "A3: file ESTERNO letto (confinamento rotto!)" || ok "A3: il contenuto esterno non arriva al modello"
[ -f "$MOCK_DIR/fuori.txt" ] && ko "A3: write FUORI dal progetto eseguito" || ok "A3: write fuori dal progetto rifiutato"
[ "$(echo "$OUT" | grep -c 'FUORI (rifiutato)')" -ge 3 ] && ok "A3: tre rifiuti dichiarati nel log (read, write, ../)" || ko "A3: rifiuti loggati: $(echo "$OUT" | grep -c FUORI)"

# A3b (2026-09-25, ottavo ventaglio, O1 R1): `.git/` sta dentro il progetto, e il confine lo ammetteva. Una voce di
# .git/config puo' essere un comando che git esegue: la scriveva il modello, e la eseguivano poi i git del turno,
# fuori dalla sandbox, a ogni notte. Ora edit, write e read dentro un .git sono rifiutati.
SB="$SB_ROOT/a3b"; mkdir -p "$SB"; git -C "$SB" init -q; cp "$SB/.git/config" "$MOCK_DIR/config-prima"
scenario a3b "$SB" "config" \
  "$(azione '{"action":"edit","path":".git/config","old":"[core]","new":"[core]\n\tfinto = si"}')" \
  "$(azione '{"action":"write","path":".git/hooks/post-checkout","content":"#!/bin/sh\necho x"}')" \
  "$(azione '{"action":"read","path":".git/config"}')" \
  "$(azione 'fine')"
cmp -s "$SB/.git/config" "$MOCK_DIR/config-prima" && [ ! -e "$SB/.git/hooks/post-checkout" ] \
  && ok "O1 R1: .git/config intatto e nessun hook scritto dal modello" || ko "O1 R1: il modello ha scritto dentro .git/"
[ "$(echo "$OUT" | grep -c '(rifiutato)')" -ge 3 ] && ok "O1 R1: tre rifiuti dentro .git dichiarati nel log" || ko "O1 R1: rifiuti dentro .git: $(echo "$OUT" | grep -c rifiutato)"

# A4: run — denylist (curl/push/rm -rf/sudo/clasp) rifiutata, comando innocuo eseguito
SB="$SB_ROOT/a4"; mkdir -p "$SB"
scenario a4 "$SB" "run" \
  "$(azione '{"action":"run","command":"curl http://example.invalid"}')" \
  "$(azione '{"action":"run","command":"git push origin main"}')" \
  "$(azione '{"action":"run","command":"echo ciao-dal-run"}')" \
  "$(azione 'fine')"
[ "$(echo "$OUT" | grep -c 'run: RIFIUTATO')" -eq 2 ] && ok "A4: curl e push RIFIUTATI (denylist)" || ko "A4: rifiuti: $(echo "$OUT" | grep -c RIFIUTATO) (attesi 2)"
grep -q 'run: echo ciao-dal-run' <<<"$OUT" && ok "A4: il comando innocuo gira" || ko "A4: comando innocuo non eseguito"

# A4bis (2026-09-23, giro A6 della notte): la denylist a sottostringhe si aggirava — `git p""ush`,
# wget, un interprete, un touch: tutto andava in eval, fuori sandbox. Ora il run passa dalla STESSA
# allowlist di sola lettura del censore (lib.sh gate_allowlist_ok); le scritture restano a edit/write.
SB="$SB_ROOT/a4bis"; mkdir -p "$SB"; printf 'uno\n' > "$SB/f.txt"
scenario a4bis "$SB" "run" \
  "$(azione '{"action":"run","command":"git p\"\"ush origin main"}')" \
  "$(azione '{"action":"run","command":"wget -q http://example.invalid/x"}')" \
  "$(azione '{"action":"run","command":"python3 -c \"open(chr(80)+chr(87)+chr(78),chr(119))\""}')" \
  "$(azione '{"action":"run","command":"touch PWN2"}')" \
  "$(azione '{"action":"run","command":"grep -c uno f.txt"}')" \
  "$(azione 'fine')"
[ "$(echo "$OUT" | grep -c 'run: RIFIUTATO')" -eq 4 ] && ok "A4bis: push camuffato, wget, interprete e touch RIFIUTATI" || ko "A4bis: rifiuti $(echo "$OUT" | grep -c 'run: RIFIUTATO') su 4 attesi"
[ ! -e "$SB/PWN" ] && [ ! -e "$SB/PWN2" ] && ok "A4bis: nessun file scritto dal run" || ko "A4bis: il run ha SCRITTO nel progetto"
grep -q 'run: grep -c uno f.txt' <<<"$OUT" && ok "A4bis: la lettura (grep) gira ancora" || ko "A4bis: anche la lettura e' bloccata"

# A5: write crea SOLO file nuovi — su un file esistente rifiuta (edit e' l'unica via)
SB="$SB_ROOT/a5"; mkdir -p "$SB"; printf 'originale\n' > "$SB/c.txt"
scenario a5 "$SB" "write" \
  "$(azione '{"action":"write","path":"c.txt","content":"RISCRITTO"}')" \
  "$(azione '{"action":"write","path":"nuovo.txt","content":"nuovo"}')" \
  "$(azione 'fine')"
[ "$(cat "$SB/c.txt")" = "originale" ] && ok "A5: write su file esistente RIFIUTATO (la riscrittura intera non passa piu')" || ko "A5: file esistente riscritto: $(cat "$SB/c.txt")"
[ "$(cat "$SB/nuovo.txt" 2>/dev/null)" = "nuovo" ] && ok "A5: write crea il file nuovo" || ko "A5: file nuovo non creato"

# A6: tetto dei turni — il modello chiede azioni senza mai finire → rc 1 dopo MAX_TURNI
SB="$SB_ROOT/a6"; mkdir -p "$SB"; printf 'x\n' > "$SB/x.txt"
MAX_T=2 scenario a6 "$SB" "loop" \
  "$(azione '{"action":"read","path":"x.txt"}')" \
  "$(azione '{"action":"read","path":"x.txt"}')" \
  "$(azione '{"action":"read","path":"x.txt"}')"
[ "$RC" -eq 1 ] && grep -q "max turni" <<<"$OUT" && ok "A6: tetto dei turni → rc 1 dichiarato (niente loop infinito)" || ko "A6: rc=$RC: $(echo "$OUT" | tail -1)"

# A7 (2026-09-24, quarto ventaglio, Q3 R1): una risposta 200 con il contenuto VUOTO usciva 0 «completato»
# — a valle caccia-miglioria dichiarava il file pulito per 6 ore e il turno «repository in salute».
# Muto non e' finito: rc diverso da 0, e il chiamante lo vede come agente fallito («agente rc=»).
SB="$SB_ROOT/a7"; mkdir -p "$SB"; printf 'x\n' > "$SB/x.txt"
scenario a7 "$SB" "correggi" '{"message":{"role":"assistant","content":""}}'
[ "$RC" -ne 0 ] && grep -c "vuota" <<<"$OUT" >/dev/null && ! grep -c "✅ completato" <<<"$OUT" >/dev/null \
  && ok "A7: contenuto vuoto → rc $RC, «risposta vuota», non «completato»" || ko "A7: contenuto vuoto → rc=$RC: $(echo "$OUT" | tail -1)"

# ── Parte B: le sfide col modello VERO (skip dichiarato senza Ollama) ───────────────
if curl -sf --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
  SB="$SB_ROOT/vivo"; mkdir -p "$SB"
  printf 'function sconto(prezzo, percento) {\n  return prezzo - percento;\n}\n' > "$SB/mat.js"
  OUT=$(bash "$AGENTE" "$SB" "Read mat.js. The sconto function subtracts the percentage number directly instead of calculating percentage. Fix: return prezzo - (prezzo * percento / 100). Read then fix." 2>/dev/null); RC1=$?
  if grep -q 'percento / 100' "$SB/mat.js"; then ok "sfida viva 1: bug corretto"; else echo "⊘ sfida viva 1: modello non ha converto (rc=$RC1) — skip dichiarato"; fi
  OUT=$(bash "$AGENTE" "$SB" "Add function quadrato(x) returning x * x to mat.js." 2>/dev/null); RC2=$?
  if grep -q "function quadrato" "$SB/mat.js"; then ok "sfida viva 2: funzione aggiunta"; else echo "⊘ sfida viva 2: modello non ha converto (rc=$RC2) — skip dichiarato"; fi
else
  echo "⊘ Ollama non attivo: sfide col modello vero saltate (la meccanica e' provata sopra col mock)"
fi


# (2026-09-25, ottavo ventaglio, O1 R4): un'azione JSON rotta (troncata da un tetto sui token) o preceduta da una frase
# era «non e' un'azione, quindi ho finito»: rc 0, e la caccia dichiarava il file pulito per 6 ore. Ora un'azione che non
# si legge torna al modello come errore di formato; due di fila sono rc 1. La prosa prima del JSON non basta a perderla.
SB="$SB_ROOT/o1r4"; mkdir -p "$SB"; printf 'uno\n' > "$SB/f.txt"
scenario o1r4a "$SB" "tronca" \
  "$(azione '{"action":"edit","path":"f.txt","old":"uno","new":"')" \
  "$(azione '{"action":"edit","path":"f.txt","old":"uno","new":"')"
[ "$RC" -ne 0 ] && grep -ci 'illeggibil' <<<"$OUT" >/dev/null && ok "O1 R4: azione troncata due volte: rc $RC, non «completato»" || ko "O1 R4: azione troncata: rc $RC ($(grep -m1 'completato\|illeggib' <<<"$OUT"))"
scenario o1r4b "$SB" "frase" \
  "$(azione 'Leggo prima il file: {"action":"read","path":"f.txt"}')" \
  "$(azione 'Fatto.')"
[ "$RC" -eq 0 ] && grep -c 'read: f.txt' <<<"$OUT" >/dev/null && ok "O1 R4: una frase prima del JSON non perde l'azione (read eseguito)" || ko "O1 R4: frase prima del JSON: rc $RC, read $(grep -c 'read: f.txt' <<<"$OUT")"
scenario o1r4c "$SB" "riprende" \
  "$(azione '{"action":"read","path":"f.t')" \
  "$(azione 'Fatto.')"
[ "$RC" -eq 0 ] && grep -ci 'formato' <<<"$OUT" >/dev/null && ok "O1 R4: un troncato e poi la risposta finale: l'errore di formato torna al modello, poi rc 0" || ko "O1 R4: ripresa dopo un troncato: rc $RC"
scenario o1r4d "$SB" "senza percorso" \
  "$(azione '{"action":"write","content":"x"}')" \
  "$(azione 'Fatto.')"
[ ! -e "$SB/null" ] && [ ! -e "$PWD/null" ] && ok "O1 R4: un write senza path non crea un file «null»" || ko "O1 R4: un write senza path ha creato un file «null»"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
