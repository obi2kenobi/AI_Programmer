#!/bin/bash
# caccia-lente.sh — la caccia che usa gli strumenti dell'hub + il modello per interpretare.
# Gli strumenti girano, il modello legge il loro output e dice cosa fare.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-.}"
MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"   # NIGHT_API_URL: solo per i test, come negli altri script
cd -- "$DIR" || exit 2
log() { echo "[lente $(date '+%H:%M:%S')] $*" >&2; }

# --- GLI STRUMENTI DELL'HUB che già esistono e funzionano ------------------------
# Ogni lente: nome|comando da eseguire|cosa cercare nell'output
# (2026-09-24, sesto ventaglio, S3 R4): il comando va a `eval`, e $HERE era nudo — in un percorso con lo spazio lo
# strumento non girava, e con un apice la riga non si analizzava. Il percorso entra quotato (printf %q).
HQ=$(printf '%q' "$HERE")
LENTI=(
  "sonde|bash $HQ/tools/giri-ignoranti.sh 2>&1 | tail -25|FIND finding"
  "health|bash $HQ/tools/system-health.sh 2>&1 | head -25|ROSSO DOWN WARN"
  "banco|bash $HQ/tools/banco-passaggio.sh --solo-copertura 2>&1 | tail -10|NON CHIUDERE scoperto rosso"
  "ciclo|bash $HQ/tools/ciclo-vivo.sh 2>&1 | tail -20|finding COLLEGAMENTO FLUSSO"
  "registro|grep -c '^## E-' $HQ/docs/errori/REGISTRO.md 2>&1|zero vuoto"
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

# (S3 R4): uno strumento che non e' partito (rc 126: non eseguibile / una cartella; 127: non trovato) ha un'uscita
# — l'errore della shell — e il modello la leggeva come se fosse il suo risultato: poteva dire «sistema sano».
if [ "$TOOL_RC" -eq 126 ] || [ "$TOOL_RC" -eq 127 ]; then
  log "lo strumento non ha girato (rc $TOOL_RC: $(tail -1 <<<"$TOOL_OUT" | cut -c1-100)): la lente e' MUTA (rc 3), il modello non si chiama"
  exit 3
fi
if [ -z "$TOOL_OUT" ]; then
  # (2026-09-24, Q3 R2): usciva 1 (sana) — uno strumento morto senza output non ha detto niente
  log "strumento non ha prodotto output: la lente e' MUTA (rc 3), ne' sana ne' malata"
  exit 3
fi

# --- Il modello INTERPRETA l'output (contesto piccolo, domanda precisa) --------------
PROMPT="You are a code quality analyst. A tool just ran on this project, exited with code $TOOL_RC (for these tools 0 means clean, non-zero means it found something), and produced this output:

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

# (2026-09-24, terzo ventaglio, V1#6): muto usciva 1, lo stesso codice di «sana», e il turno scriveva
# «lente dichiara il sistema sano». Codici: 0 problemi · 1 sana · 2 cartella assente · 3 modello muto.
if [ -z "$RESPONSE" ]; then
  log "modello non ha risposto: la lente e' MUTA (rc 3), ne' sana ne' malata"
  echo "LENTE: $(echo "$LENTE_DATA" | cut -d'|' -f1)"
  echo "TOOL_RC: $TOOL_RC"
  echo "TOOL_OUTPUT:\n$TOOL_OUT"
  exit 3
fi

VERDETTO=$(echo "$RESPONSE" | jq -r '.message.content // empty')
# (Q3 R2): 200 con il verdetto vuoto finiva «sistema sano» (la prima riga vuota non e' YES)
[ -z "$VERDETTO" ] && { log "verdetto vuoto del modello: la lente e' MUTA (rc 3)"; exit 3; }

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
elif [ "$TOOL_RC" -ne 0 ] && [ "$TOOL_RC" -ne 141 ]; then
  # (2026-09-25, settimo ventaglio, V2 R1): il verdetto dello strumento e' nell'rc (giri-ignoranti, system-health e
  # banco-passaggio escono diverso da 0 quando trovano). Il modello diceva NO e la lente «sistema sano»: il turno
  # migliorava codice appena dichiarato malato. Scelta provvisoria (DEBITI, V2 D1): il deterministico e' il pavimento.
  # 141 = SIGPIPE dal taglio a 50 righe, non un verdetto.
  log "⚠ lente $(echo "$LENTE_DATA" | cut -d'|' -f1): lo strumento esce $TOOL_RC (ha trovato) e il modello dice no — vince lo strumento: PROBLEMI"
  exit 0
else
  log "lente $(echo "$LENTE_DATA" | cut -d'|' -f1): sistema sano"
  exit 1
fi
