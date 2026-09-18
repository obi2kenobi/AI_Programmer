#!/bin/bash
# caccia-lente.sh — la caccia che usa gli strumenti dell'hub + il modello per interpretare.
# Gli strumenti girano, il modello legge il loro output e dice cosa fare.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-.}"
MODEL="${NIGHT_MODEL:-qwen2.5-coder:14b}"
API="http://localhost:11434/api/chat"
cd "$DIR" || exit 2
log() { echo "[lente $(date '+%H:%M:%S')] $*" >&2; }

# --- GLI STRUMENTI DELL'HUB che già esistono e funzionano ------------------------
# Ogni lente: nome|comando da eseguire|cosa cercare nell'output
LENTI=(
  "sonde|bash $HERE/tools/giri-ignoranti.sh 2>&1 | tail -25|FIND finding"
  "health|bash $HERE/tools/system-health.sh 2>&1 | head -25|ROSSO DOWN WARN"
  "banco|bash $HERE/tools/banco-passaggio.sh --solo-copertura 2>&1 | tail -10|NON CHIUDERE scoperto rosso"
  "ciclo|bash $HERE/tools/ciclo-vivo.sh 2>&1 | tail -20|finding COLLEGAMENTO FLUSSO"
  "registro|grep -c '^## E-' $HERE/docs/errori/REGISTRO.md 2>&1|zero vuoto"
)

# --- Rotazione ---------------------------------------------------------------------------
RR=$(cat "$HERE/.caccia-rotazione" 2>/dev/null || echo 0)
IDX=$((RR % ${#LENTI[@]}))
echo $((RR+1)) > "$HERE/.caccia-rotazione"
LENTE_DATA="${LENTI[$IDX]}"

LENTE_NOME=$(echo "$LENTE_DATA" | cut -d'|' -f2 | xargs basename 2>/dev/null || echo "$LENTE_DATA" | cut -d'|' -f1)
LENTE_CMD=$(echo "$LENTE_DATA" | cut -d'|' -f2)
LENTE_CERCA=$(echo "$LENTE_DATA" | cut -d'|' -f3)

log "lente: $(echo "$LENTE_DATA" | cut -d'|' -f1)"

# --- ESEGUI lo strumento (deterministico, veloce, affidabile) ------------------------
TOOL_OUT=$(eval "$LENTE_CMD" 2>&1 | head -50)
TOOL_RC=$?

if [ -z "$TOOL_OUT" ]; then
  log "strumento non ha prodotto output"
  exit 1
fi

# --- Il modello INTERPRETA l'output (contesto piccolo, domanda precisa) --------------
PROMPT="You are a code quality analyst. A tool just ran on this project and produced this output:

=== TOOL OUTPUT ===
$TOOL_OUT
=== END ===

Questions:
1. Are there any real issues in this output? (YES/NO)
2. If YES: which ones are most important?
3. If NO: is the system healthy?

Be concise. Maximum 5 lines."

log "chiamo il modello per interpretare ($(echo "$TOOL_OUT" | wc -c | tr -d ' ') bytes di output)..."

RESPONSE=$(curl -sf --max-time 60 "$API" -d "$(jq -n \
  --arg m "$MODEL" --arg p "$PROMPT" \
  '{model:$m, messages:[{role:"user",content:$p}], stream:false, options:{temperature:0, num_ctx:2048}}')" 2>/dev/null)

if [ -z "$RESPONSE" ]; then
  log "modello non ha risposto"
  echo "LENTE: $(echo "$LENTE_DATA" | cut -d'|' -f1)"
  echo "TOOL_RC: $TOOL_RC"
  echo "TOOL_OUTPUT:\n$TOOL_OUT"
  exit 1
fi

VERDETTO=$(echo "$RESPONSE" | jq -r '.message.content // empty')

echo "LENTE: $(echo "$LENTE_DATA" | cut -d'|' -f1)"
echo "STRUMENTO_RC: $TOOL_RC"
echo ""
echo "VERDETTO:"
echo "$VERDETTO"

# se ci sono problemi reali
# guarda la risposta alla domanda 1: YES = problemi
PRIMA_RIGA=$(echo "$VERDETTO" | head -1)
if echo "$PRIMA_RIGA" | grep -qiE "^1\.?\s*yes|yes.*issue"; then
  log "⚠ lente $(echo "$LENTE_DATA" | cut -d'|' -f1): PROBLEMI TROVATI"
  exit 0
else
  log "lente $(echo "$LENTE_DATA" | cut -d'|' -f1): sistema sano"
  exit 1
fi
