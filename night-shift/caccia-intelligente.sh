#!/bin/bash
# caccia-intelligente.sh — usa le LENTI e i PATTERN dell'hub come intelligenza.
#
# NON reinventa l'agente: LEGGE le definizioni già scritte in .claude/agents/
# e .claude/skills/, le usa come system prompt per il modello locale, e
# applica l'analisi a un file specifico. Una chiamata, niente multi-turno.
#
# Uso: caccia-intelligente.sh <dir> [lente] [file]
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: caccia-intelligente.sh <dir>}"
LENTE="${2:-auto}"
FILE_TARGET="${3:-}"
MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
API="http://localhost:11434/api/chat"

cd "$DIR" || exit 2
log() { echo "[caccia $(date '+%H:%M:%S')] $*" >&2; }

# --- LE LENTI: i file dell'hub che contengono l'intelligenza --------------------
# Ogni lente punta a un file REALE (agente o skill) già scritto
DECHE_LENTI=(
  "dev-critic|$HERE/.claude/skills/dev-critic/SKILL.md"
  "revisore-gas|$HERE/.claude/agents/revisore-gas.md"
  "polilivello|$HERE/.claude/skills/polilivello/SKILL.md"
  "post-mortem|$HERE/.claude/skills/post-mortem/SKILL.md"
  "incidenti|$HERE/.claude/skills/incidenti-esterni/SKILL.md"
  "gas-sviluppo|$HERE/.claude/skills/gas-sviluppo/references/metodo.md"
)

# --- SCELTA LENTE (round-robin o specificata) -------------------------------------
if [ "$LENTE" = "auto" ]; then
  RR=$(cat "$HERE/.caccia-rotazione" 2>/dev/null || echo 0)
  IDX=$((RR % ${#DECHE_LENTI[@]}))
  LENTE=$(echo "${DECHE_LENTI[$IDX]}" | cut -d'|' -f1)
  echo $((RR+1)) > "$HERE/.caccia-rotazione"
fi

# trova il file della lente
LENTE_FILE=""
for D in "${DECHE_LENTI[@]}"; do
  [ "$(echo "$D" | cut -d'|' -f1)" = "$LENTE" ] && LENTE_FILE=$(echo "$D" | cut -d'|' -f2) && break
done
[ -z "$LENTE_FILE" ] || [ ! -f "$LENTE_FILE" ] && { log "lente $LENTE non trovata"; exit 2; }

# --- SCELTA BERSAGLIO (file da analizzare) ----------------------------------------
if [ -z "$FILE_TARGET" ]; then
  FILE_TARGET=$(find . -name "*.sh" -o -name "*.py" | grep -v node_modules | grep -v .git | grep -v test | sort -R | head -1)
fi
[ -z "$FILE_TARGET" ] || [ ! -f "$FILE_TARGET" ] && { log "nessun bersaglio"; exit 1; }

# --- LEGGI l'intelligenza: la lente + i pattern correlati ------------------------
LENTE_DEF=$(head -c 3000 "$LENTE_FILE")
FILE_CONTENT=$(head -c 20000 "$FILE_TARGET" 2>/dev/null || echo "(file non leggibile)")

# i 3 pattern più recenti come checklist
PATTERN_CHECKLIST=$(ls -t "$HERE/patterns/"*.md | head -3 | while read PF; do
  echo "- $(basename "$PF" .md): $(head -5 "$PF" | grep -v '^#' | grep -v '^$' | head -1)"
done)

# --- UNA SOLA CHIAMATA con tutta l'intelligenza dentro ----------------------------
PROMPT="You are: $LENTE

Your expertise (from AI_Programmer):
$LENTE_DEF

Known defect patterns to check (from field experience):
$PATTERN_CHECKLIST

Now analyze this file for defects:
=== FILE: $FILE_TARGET ===
$# file_CONTENT non più usata
=== END ===

Report:
1. Which patterns from the list are present in this code?
2. What is the worst issue?
3. If fixable, write the corrected code.
4. If not fixable, explain what decision is needed.

Be specific. Cite pattern names. Reference lines."

log "lente: $LENTE ($LENTE_FILE) · bersaglio: $FILE_TARGET"

RESPONSE=$(curl -sf --max-time 180 "$API" -d "$(jq -n \
  --arg m "$MODEL" --arg p "$PROMPT" \
  '{model:$m, messages:[{role:"user",content:$p}], stream:false, think:false, options:{temperature:0, num_ctx:4096}}')" 2>/dev/null)

[ -z "$RESPONSE" ] && { log "modello non ha risposto"; exit 3; }

VERDETTO=$(echo "$RESPONSE" | jq -r '.message.content // empty')

echo "LENTE: $LENTE"
echo "BERSAGLIO: $FILE_TARGET"
echo ""
echo "$VERDETTO"

# se suggerisce una correzione in un blocco codice, la estraiamo per il chiamante
FIX=$(echo "$VERDETTO" | sed -n '/^```/,/^```/p' | sed '/^```/d')
[ -n "$FIX" ] && echo -e "\nFIX_PROPOSTO:\n$FIX"

if echo "$VERDETTO" | grep -qiE "pattern.*present|worst issue|defect|fragile|missing|error"; then
  log "⚠ $LENTE ha trovato possibili difetti in $FILE_TARGET"
  exit 0
else
  log "$LENTE: $FILE_TARGET analizzato, nessun difetto evidente"
  exit 1
fi
