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
#            GLM_MODEL (default glm-5.3, sovrascrivibile anche con ASK_MODEL) ·
#            ASK_TIMEOUT secondi (600)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

PROMPT="${1:-}"
[ -z "$PROMPT" ] && { echo "uso: ask-glm.sh \"prompt\" [stdin opzionale]" >&2; exit 1; }

# giro 10/10 (set 1 "armonizza gli agenti"): traccia locale minima — vedi llm/_usage.sh.
source "$HERE/_usage.sh"
source "$HERE/_timeout.sh"
trap 'log_ask_usage ask-glm "${#PROMPT}"' EXIT

if [ -z "${ZHIPUAI_API_KEY:-}" ]; then
  cat >&2 <<'EOF'
ask-glm: via programmatica non configurata.

Opzioni:
  1. esporta ZHIPUAI_API_KEY nella shell/launchd per usare l'endpoint OpenAI-compat
  2. usa GLM in sessione ZCode (via naturale: ZCode È GLM 5.3)
EOF
  exit 2
fi

# bug reale (set 1 "armonizza gli agenti", 2026-08-22): `[ ! -t 0 ] && $(cat)` senza
# limite può bloccarsi a tempo indefinito in contesti non interattivi dove stdin non
# è un terminale ma non emette EOF subito (riprodotto dal vivo su ask-opus.sh, stesso
# pattern qui). Timeout 5s: sufficiente per un file già scritto piped via `cat`, non
# per uno stream che arriva lentamente (limite noto, non un uso previsto dal contratto).
STDIN_DATA=""
if [ ! -t 0 ]; then
  # bug reale (revisione 14 lenti, 2026-08-28): allo scadere dei 5s lo stream veniva
  # troncato SENZA alcun avviso — più grave del "si blocca" documentato sopra: qui il
  # contenuto è silenziosamente CORROTTO (il prompt parte come se fosse completo).
  # Verificato dal vivo: stream lento (1 riga/2s) troncato a metà entro i 5s.
  set +e
  STDIN_DATA=$(ai_timeout 5 cat 2>/dev/null)
  STDIN_RC=$?
  set -e
  [ "$STDIN_RC" -eq 124 ] && echo "ask-glm: ATTENZIONE — lo stdin non è arrivato tutto entro 5s, il contesto potrebbe essere TRONCATO (non solo ritardato)" >&2
fi
[ -n "$STDIN_DATA" ] && PROMPT="$PROMPT

---
$STDIN_DATA"

BASE="${GLM_BASE_URL:-https://open.bigmodel.cn/api/paas/v4}"
# bug reale (set 1 "armonizza gli agenti"): llm/README.md dichiara ASK_MODEL un
# override universale per tutti i wrapper ask-*, ma qui era ignorato — solo
# GLM_MODEL funzionava. GLM_MODEL resta la via specifica (precedenza se entrambe
# impostate: chi configura la variabile specifica sa cosa vuole).
MODEL="${GLM_MODEL:-${ASK_MODEL:-glm-5.3}}"
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

# bug reale (revisione 14 lenti, 2026-08-28): questa command substitution non era protetta
# come la sua analoga in ask-opus.sh (stesso "tranello" già documentato là) — se curl
# fallisce (rete assente, endpoint giù: esattamente il caso che il parser Python sotto
# dice di gestire), `set -e` fa uscire lo script SUBITO qui, prima di raggiungere il
# parsing che produce "ERRORE glm: ...". Verificato dal vivo: rc=7, zero output su
# stderr, nessuna diagnosi. set +e locale per leggere l'exit code senza farlo esplodere.
set +e
RESP=$(curl -s --max-time "$TIMEOUT" "$BASE/chat/completions" \
  -H "Authorization: Bearer $ZHIPUAI_API_KEY" -H "Content-Type: application/json" -d "$PAYLOAD")
CURL_RC=$?
set -e
if [ "$CURL_RC" -ne 0 ]; then
  echo "ERRORE glm: curl fallito (rc=$CURL_RC) — rete assente o endpoint irraggiungibile ($BASE)" >&2
  exit 1
fi

# bug reale (set 1 "armonizza gli agenti"): un corpo vuoto/non-JSON (curl senza
# rete, endpoint giù, HTML d'errore) faceva esplodere json.load con un traceback
# Python grezzo su stderr — verificato dal vivo con un corpo vuoto: JSONDecodeError
# non gestita, non la diagnosi pulita "ERRORE glm: ..." che il resto del contratto
# promette. Anche una risposta JSON valida ma di forma inattesa (senza "choices")
# dava lo stesso trattamento (KeyError grezzo).
echo "$RESP" | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
    r = json.loads(raw)
except json.JSONDecodeError:
    print("ERRORE glm: risposta non valida dal server (non è JSON) —", raw[:200] or "(corpo vuoto)", file=sys.stderr)
    sys.exit(1)
if "error" in r:
    print("ERRORE glm:", r["error"], file=sys.stderr); sys.exit(1)
try:
    print(r["choices"][0]["message"]["content"])
except (KeyError, IndexError, TypeError):
    print("ERRORE glm: risposta JSON di forma inattesa (manca choices[0].message.content) —", raw[:200], file=sys.stderr)
    sys.exit(1)
' || exit 1
