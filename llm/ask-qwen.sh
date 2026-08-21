#!/bin/bash
# ask-qwen.sh — delega un compito al cervello LOCALE (Qwen3.8-27B via Ollama).
# Contratto comune ai wrapper llm/ask-*: prompt come argomento, contesto via stdin,
# risposta pulita su stdout, statistiche su stderr. Exit 0 ok / 1 errore.
#
# Variabili: QWEN_MODEL (default qwen3.8:27b-mtp-q4_K_M) · QWEN_CTX (16384) · QWEN_THINK
set -euo pipefail

MODEL="${QWEN_MODEL:-qwen3.8:27b-mtp-q4_K_M}"
CTX="${QWEN_CTX:-16384}"
THINK="${QWEN_THINK:-false}"
API="http://localhost:11434"

if ! curl -sf "$API/api/version" >/dev/null 2>&1; then
  OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_CONTEXT_LENGTH="$CTX" \
    /opt/homebrew/bin/ollama serve >> ~/ollama-server.log 2>&1 &
  for _ in $(seq 1 30); do curl -sf "$API/api/version" >/dev/null 2>&1 && break; sleep 1; done
fi

PROMPT="${1:-}"
[ -z "$PROMPT" ] && { echo "uso: ask-qwen.sh \"prompt\" [stdin opzionale]" >&2; exit 1; }
STDIN_DATA=""
[ ! -t 0 ] && STDIN_DATA=$(cat)
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

START=$(date +%s)
RESP=$(curl -s --max-time 1800 "$API/api/chat" -d "$PAYLOAD")
END=$(date +%s)

echo "$RESP" | python3 -c '
import json, sys
r = json.load(sys.stdin)
if "error" in r:
    print("ERRORE ollama:", r["error"], file=sys.stderr); sys.exit(1)
print(r["message"]["content"])
' || exit 1

echo "$RESP" | python3 -c '
import json, sys
try:
    r = json.load(sys.stdin)
    ev = r.get("eval_count", 0); dur = r.get("eval_duration", 1) / 1e9
    if ev and dur: print(f"[qwen] {ev} token in {dur:.1f}s = {ev/dur:.1f} tok/s", file=sys.stderr)
except Exception: pass
' || true
