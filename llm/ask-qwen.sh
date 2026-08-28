#!/bin/bash
# ask-qwen.sh — delega un compito al cervello LOCALE (Qwen3.8-27B via Ollama).
# Contratto comune ai wrapper llm/ask-*: prompt come argomento, contesto via stdin,
# risposta pulita su stdout, statistiche su stderr. Exit 0 ok / 1 errore.
#
# Variabili: QWEN_MODEL (default qwen3.8:27b-mtp-q4_K_M, sovrascrivibile anche con
#            ASK_MODEL) · QWEN_CTX (16384) · QWEN_THINK
#            ASK_TIMEOUT secondi (1800 — la notte non ha limite di tempo, decisione
#            2026-08-21: la soglia resta alta di default, ma ORA è configurabile)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# bug reale (dogfooding, set 1 "armonizza gli agenti"): il prompt veniva validato
# DOPO aver tentato di avviare Ollama — una chiamata senza argomenti (es. "ask-qwen.sh"
# per errore, o un probe automatico) sprecava fino a 30s e poteva avviare un processo
# in background prima di dire "uso: ...". Verificato con `time`: 30.4s reali. Gli altri
# wrapper (ask-glm.sh, ask-opus.sh) validano il prompt PRIMA di ogni side-effect — qui
# si armonizza allo stesso ordine.
PROMPT="${1:-}"
[ -z "$PROMPT" ] && { echo "uso: ask-qwen.sh \"prompt\" [stdin opzionale]" >&2; exit 1; }

# giro 10/10 (set 1 "armonizza gli agenti"): traccia locale minima — vedi llm/_usage.sh.
source "$HERE/_usage.sh"
source "$HERE/_timeout.sh"
trap 'log_ask_usage ask-qwen "${#PROMPT}"' EXIT

# bug reale (set 1 "armonizza gli agenti"): llm/README.md dichiara ASK_MODEL un
# override universale, qui era ignorato — solo QWEN_MODEL funzionava.
MODEL="${QWEN_MODEL:-${ASK_MODEL:-qwen3.8:27b-mtp-q4_K_M}}"
CTX="${QWEN_CTX:-16384}"
THINK="${QWEN_THINK:-false}"
API="http://localhost:11434"

# rischio segnalato (revisione 14 lenti, 2026-08-28): senza --max-time, se il server
# accetta la connessione TCP ma non risponde subito (avvio "a metà"), una singola
# iterazione del poll può bloccarsi oltre il budget implicito di ~30s del loop, prima
# ancora di arrivare alla chiamata principale (quella sì protetta da ai_timeout).
if ! curl -sf --max-time 2 "$API/api/version" >/dev/null 2>&1; then
  OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_CONTEXT_LENGTH="$CTX" \
    /opt/homebrew/bin/ollama serve >> ~/ollama-server.log 2>&1 &
  for _ in $(seq 1 30); do curl -sf --max-time 2 "$API/api/version" >/dev/null 2>&1 && break; sleep 1; done
fi

# stesso bug reale di ask-opus.sh/ask-glm.sh: `[ ! -t 0 ] && $(cat)` senza limite
# può bloccarsi a tempo indefinito quando stdin non è un terminale ma non emette
# EOF subito. Timeout 5s (vedi ask-opus.sh per la riproduzione dal vivo).
STDIN_DATA=""
if [ ! -t 0 ]; then
  # bug reale (revisione 14 lenti, 2026-08-28): allo scadere dei 5s lo stream veniva
  # troncato SENZA alcun avviso — più grave del "blocca" documentato sopra: qui il
  # contenuto è silenziosamente CORROTTO (il prompt parte come se fosse completo).
  # Verificato dal vivo: stream lento (1 riga/2s) troncato a metà entro i 5s.
  set +e
  STDIN_DATA=$(ai_timeout 5 cat 2>/dev/null)
  STDIN_RC=$?
  set -e
  [ "$STDIN_RC" -eq 124 ] && echo "ask-qwen: ATTENZIONE — lo stdin non è arrivato tutto entro 5s, il contesto potrebbe essere TRONCATO (non solo ritardato)" >&2
fi
[ -n "$STDIN_DATA" ] && PROMPT="$PROMPT

---
$STDIN_DATA"

PAYLOAD=$(python3 - "$MODEL" "$CTX" "$THINK" "$PROMPT" <<'PY'
import json, sys
print(json.dumps({
    "model": sys.argv[1],
    "messages": [{"role": "user", "content": sys.argv[4]}],
    "stream": False,
    "think": sys.argv[3] == "true",
    "options": {"num_ctx": int(sys.argv[2]), "temperature": 0.3},
}))
PY
)

# bug reale (dogfooding, set 1 "armonizza gli agenti"): --max-time era fisso a 1800,
# ignorando ASK_TIMEOUT — llm/README.md lo dichiara un override universale per
# TUTTI i wrapper, ma qui non aveva alcun effetto (verificato leggendo il valore
# passato a curl con ASK_TIMEOUT impostato: restava sempre 1800).
TIMEOUT="${ASK_TIMEOUT:-1800}"
START=$(date +%s)
# bug reale (revisione 14 lenti, 2026-08-28): non protetta come ask-opus.sh — se curl
# fallisce (server caduto durante la generazione, rete assente), `set -e` esce subito
# qui, prima di qualunque diagnosi. set +e locale per leggere l'exit code senza farlo
# esplodere (stesso fix di ask-glm.sh).
set +e
RESP=$(curl -s --max-time "$TIMEOUT" "$API/api/chat" -d "$PAYLOAD")
CURL_RC=$?
set -e
if [ "$CURL_RC" -ne 0 ]; then
  echo "ERRORE qwen: curl fallito (rc=$CURL_RC) — server Ollama irraggiungibile ($API)" >&2
  exit 1
fi
END=$(date +%s)

# stesso bug reale del giro 7 in ask-glm.sh: un corpo vuoto/non-JSON (Ollama giù
# a metà avvio, connessione persa) faceva esplodere json.load con un traceback
# Python grezzo invece della diagnosi pulita "ERRORE ollama: ..." promessa dal
# contratto. Stessa difesa: try/except su decode e su message.content.
echo "$RESP" | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
    r = json.loads(raw)
except json.JSONDecodeError:
    print("ERRORE ollama: risposta non valida dal server (non è JSON) —", raw[:200] or "(corpo vuoto)", file=sys.stderr)
    sys.exit(1)
if "error" in r:
    print("ERRORE ollama:", r["error"], file=sys.stderr); sys.exit(1)
try:
    print(r["message"]["content"])
except (KeyError, TypeError):
    print("ERRORE ollama: risposta JSON di forma inattesa (manca message.content) —", raw[:200], file=sys.stderr)
    sys.exit(1)
' || exit 1

echo "$RESP" | python3 -c '
import json, sys
try:
    r = json.load(sys.stdin)
    ev = r.get("eval_count", 0); dur = r.get("eval_duration", 1) / 1e9
    if ev and dur: print(f"[qwen] {ev} token in {dur:.1f}s = {ev/dur:.1f} tok/s", file=sys.stderr)
except Exception: pass
' || true
