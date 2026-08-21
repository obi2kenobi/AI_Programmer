#!/bin/bash
# ask-glm.sh — delega un compito al cervello GLM via endpoint OpenAI-compatibile Z.ai/Zhipu.
# Contratto comune ai wrapper llm/ask-*: prompt come argomento, contesto via stdin,
# risposta su stdout. Exit 0 ok / 1 errore / 2 via non configurata.
#
# ONESTÀ (2026-08-21): l'endpoint non è testato dal progetto — stessa cautela che
# WayfinderRouter dichiara per GLM. Se la via programmatica non è configurata,
# dice chiaramente come usare GLM (sessione ZCode) invece di fallire in silenzio.
#
# Variabili: ZHIPUAI_API_KEY (richiesta) · GLM_BASE_URL (default open.bigmodel.cn/api/paas/v4)
#            GLM_MODEL (default glm-5.3) · ASK_TIMEOUT secondi (600)
set -euo pipefail

PROMPT="${1:-}"
[ -z "$PROMPT" ] && { echo "uso: ask-glm.sh \"prompt\" [stdin opzionale]" >&2; exit 1; }

if [ -z "${ZHIPUAI_API_KEY:-}" ]; then
  cat >&2 <<'EOF'
ask-glm: via programmatica non configurata.

Opzioni:
  1. esporta ZHIPUAI_API_KEY nella shell/launchd per usare l'endpoint OpenAI-compat
  2. usa GLM in sessione ZCode (via naturale: ZCode È GLM 5.3)
EOF
  exit 2
fi

STDIN_DATA=""
[ ! -t 0 ] && STDIN_DATA=$(cat)
[ -n "$STDIN_DATA" ] && PROMPT="$PROMPT

---
$STDIN_DATA"

BASE="${GLM_BASE_URL:-https://open.bigmodel.cn/api/paas/v4}"
MODEL="${GLM_MODEL:-glm-5.3}"
TIMEOUT="${ASK_TIMEOUT:-600}"

PAYLOAD=$(python3 - "$MODEL" "$PROMPT" <<'PY'
import json, sys
print(json.dumps({
    "model": sys.argv[1],
    "messages": [{"role": "user", "content": sys.argv[2]}],
    "stream": False,
}))
PY
)

RESP=$(curl -s --max-time "$TIMEOUT" "$BASE/chat/completions" \
  -H "Authorization: Bearer $ZHIPUAI_API_KEY" -H "Content-Type: application/json" -d "$PAYLOAD")

echo "$RESP" | python3 -c '
import json, sys
r = json.load(sys.stdin)
if "error" in r:
    print("ERRORE glm:", r["error"], file=sys.stderr); sys.exit(1)
print(r["choices"][0]["message"]["content"])
' || exit 1
