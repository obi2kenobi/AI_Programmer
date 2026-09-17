#!/bin/bash
# agente.sh — L'AGENTE NOSTRO v2 (2026-09-17): ciclo multi-turno bash ↔ Ollama.
#
# Il patto: il modello chiede di leggere/scrivere/eseguire con JSON nel contenuto,
# e QUESTO script esegue e rimanda il risultato come prossimo messaggio.
# Nessun protocollo tool-calls strutturato: conversazione naturale multi-turno.
#
# Uso: agente.sh <dir-progetto> <prompt>
# Esce: 0 = lavoro completato · 1 = fallito · 2 = uso · 3 = timeout
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: agente.sh <dir> <prompt>}"
PROMPT="${2:?uso: agente.sh <dir> <prompt>}"
MODEL="${NIGHT_MODEL:-qwen2.5-coder:14b}"
API="http://localhost:11434/api/chat"
MAX_TURNI="${AGENTE_MAX_TURNI:-8}"
TIMEOUT_TOTALE="${AGENTE_TIMEOUT:-300}"

[ -d "$DIR" ] || { echo "⛔ dir inesistente: $DIR" >&2; exit 2; }
cd "$DIR"

log() { echo "[agente $(date '+%H:%M:%S')] $*" >&2; }
T_INIZIO=$(date +%s)

# il system prompt: dice al modello COSA può fare e COME chiederlo
SYSTEM="You are a coding agent working in a project directory. You can:
1. READ a file: respond with JSON {\"action\":\"read\",\"path\":\"filename\"}
2. WRITE a file: respond with JSON {\"action\":\"write\",\"path\":\"filename\",\"content\":\"full file content\"}
3. RUN a command: respond with JSON {\"action\":\"run\",\"command\":\"the command\"}
4. FINISH: respond with your final answer as plain text (no JSON).

Rules: always read a file before writing it. One action per response. When done, respond with your final answer as text."

# la conversazione: parte con system + user
CONV=$(jq -n --arg sys "$SYSTEM" --arg p "$PROMPT" \
  '[{"role":"system","content":$sys},{"role":"user","content":$p}]')

TURNO=0
while [ "$TURNO" -lt "$MAX_TURNI" ]; do
  TURNO=$((TURNO+1))
  ELAPSED=$(( $(date +%s) - T_INIZIO ))
  [ "$ELAPSED" -gt "$TIMEOUT_TOTALE" ] && { log "⛔ timeout ${TIMEOUT_TOTALE}s"; exit 3; }

  RESPONSE=$(curl -sf --max-time 120 "$API" -d "$(jq -n \
    --arg m "$MODEL" \
    --argjson msgs "$CONV" \
    '{model:$m, messages:$msgs, stream:false, options:{temperature:0, num_ctx:4096}}')" 2>/dev/null)

  [ -z "$RESPONSE" ] && { log "⛔ Ollama non ha risposto (turno $TURNO)"; exit 1; }

  CONTENT=$(echo "$RESPONSE" | jq -r '.message.content // empty')
  log "turno $TURNO (${ELAPSED}s): il modello risponde"

  # prova a parsare come JSON action (spogliando i fence markdown)
  STRIPPED=$(echo "$CONTENT" | sed 's/^```[a-z]*//; s/```$//' | tr -d '\n' | sed 's/^ *//; s/ *$//')
  ACTION=$(echo "$STRIPPED" | jq -r '.action // empty' 2>/dev/null)

  if [ -z "$ACTION" ]; then
    # non è un'action: il modello ha finito
    log "✅ completato in $TURNO turni (${ELAPSED}s)"
    echo "$CONTENT"
    exit 0
  fi

  RESULT=""
  case "$ACTION" in
    read)
      FPATH=$(echo "$STRIPPED" | jq -r '.path')
      REAL=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FPATH" 2>/dev/null)
      REAL_DIR=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$DIR")
      case "$REAL" in "$REAL_DIR"|"$REAL_DIR"/*)
        if [ -f "$REAL" ]; then
          RESULT="File $FPATH content:\n$(head -c 24000 "$REAL")"
          log "  read: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes)"
        else
          RESULT="ERROR: file not found: $FPATH"
          log "  read: $FPATH NON TROVATO"
        fi ;;
        *)
        RESULT="ERROR: path outside project"
        log "  read: $FPATH FUORI (rifiutato)" ;;
      esac ;;

    write)
      FPATH=$(echo "$STRIPPED" | jq -r '.path')
      FCONTENT=$(echo "$STRIPPED" | jq -r '.content')
      REAL=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FPATH" 2>/dev/null)
      REAL_DIR=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$DIR")
      case "$REAL" in "$REAL_DIR"|"$REAL_DIR"/*)
        mkdir -p "$(dirname "$REAL")"
        echo "$FCONTENT" > "$REAL"
        RESULT="OK: wrote to $FPATH"
        log "  write: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes)" ;;
        *)
        RESULT="ERROR: path outside project"
        log "  write: $FPATH FUORI (rifiutato)" ;;
      esac ;;

    run)
      CMD=$(echo "$STRIPPED" | jq -r '.command')
      case "$CMD" in
        *clasp*|*push*|*deploy*|*curl*|*git\ push*|*rm\ -rf*|*sudo*)
          RESULT="ERROR: command not allowed"
          log "  run: RIFIUTATO: $CMD" ;;
        *)
          RESULT="Command: $CMD\nOutput:\n$(eval "$CMD" 2>&1 | head -30)"
          log "  run: $CMD" ;;
      esac ;;

    *)
      RESULT="ERROR: unknown action: $ACTION"
      log "  azione sconosciuta: $ACTION" ;;
  esac

  # aggiorna la conversazione: risposta del modello + risultato dell'azione
  CONV=$(echo "$CONV" | jq \
    --arg content "$CONTENT" \
    --arg result "$RESULT" \
    '. + [{"role":"assistant","content":$content},{"role":"user","content":$result}]')

done

log "⛔ max turni ($MAX_TURNI) senza completamento"
exit 1
