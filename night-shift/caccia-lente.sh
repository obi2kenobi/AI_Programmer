#!/bin/bash
# caccia-lente.sh — la caccia che usa gli strumenti dell'hub + il modello per interpretare.
# Gli strumenti girano, il modello legge il loro output e dice cosa fare.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-.}"
MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"   # NIGHT_API_URL: solo per i test, come negli altri script
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

# (2026-09-24, notte dei giri, T6#2): il comando contiene a sua volta una pipe (`… | tail -25`): con
# `cut -d'|' -f2` si tagliava alla prima, e quattro lenti su cinque giravano senza il loro filtro — il
# modello leggeva le prime 50 righe invece delle ultime 25 — mentre le parole-spia ricevevano il filtro.
# Ora: il nome e' il PRIMO campo, le parole-spia l'ULTIMO, il comando tutto cio' che sta in mezzo.
LENTE_NOME="${LENTE_DATA%%|*}"
LENTE_RESTO="${LENTE_DATA#*|}"
LENTE_CERCA="${LENTE_RESTO##*|}"
LENTE_CMD="${LENTE_RESTO%|*}"

log "lente: $LENTE_NOME"
log "comando: $LENTE_CMD"
log "parole-spia: $LENTE_CERCA"

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

Words that usually signal a problem in this tool's output: $LENTE_CERCA

Questions:
1. Are there any real issues in this output? (YES/NO)
2. If YES: which ones are most important?
3. If NO: is the system healthy?

Be concise. Maximum 5 lines."

log "chiamo il modello per interpretare ($(echo "$TOOL_OUT" | wc -c | tr -d ' ') bytes di output)..."

# (T5#6, 2026-09-23): il prompt (con l'uscita dello strumento) su stdin, mai negli argomenti
RESPONSE=$(printf '%s' "$PROMPT" | jq -Rs --arg m "$MODEL" \
  '. as $p | {model:$m, messages:[{role:"user",content:$p}], stream:false, think:false, options:{temperature:0, num_ctx:2048}}' \
  | curl -sf --max-time 60 "$API" --data-binary @- 2>/dev/null)

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
if grep -qiE "^1\.?\s*yes|yes.*issue" <<<"$PRIMA_RIGA"; then
  log "⚠ lente $(echo "$LENTE_DATA" | cut -d'|' -f1): PROBLEMI TROVATI"
  exit 0
else
  log "lente $(echo "$LENTE_DATA" | cut -d'|' -f1): sistema sano"
  exit 1
fi
