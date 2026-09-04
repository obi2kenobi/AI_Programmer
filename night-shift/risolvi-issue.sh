#!/bin/bash
# risolvi-issue.sh — il risolutore notturno SENZA agente: legge l'issue, legge i file,
# chiede a Ollama (LOCALE, sul Mac) il codice corretto, lo scrive, lo verifica.
#
# Nato dai test del 2026-09-02: opencode + tool-calls fa loopare QUALSIASI modello locale
# (il modello legge, fa il piano, e invece di scrivere rilegge). Chiamato direttamente
# via API Ollama (sempre locale), lo stesso modello produce il codice giusto al primo colpo.
# Questo script elimina l'agente: è il PATTO «il modello scrive, lo script applica».
#
# Uso: risolvi-issue.sh <dir-progetto> <issue-md>
#   <issue-md> = file locale con la commessa (Design/Commessa/Verifica/Territorio)
# Esce: 0 = fix applicato e verificato · 1 = fallito · 2 = uso errato
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: risolvi-issue.sh <dir-progetto> <issue-md>}"
ISSUE="${2:?uso: risolvi-issue.sh <dir-progetto> <issue-md>}"
MODEL="${NIGHT_MODEL:-qwen2.5-coder:14b}"
# NIGHT_API_URL: solo per i test (server mock) — di norma non si tocca
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"
[ -d "$DIR" ] || { echo "⛔ dir inesistente: $DIR" >&2; exit 2; }
[ -f "$ISSUE" ] || { echo "⛔ issue inesistente: $ISSUE" >&2; exit 2; }

log() { echo "[$(date '+%H:%M:%S')] $*" >&2; }

# --- 1. individua i file da leggere (dal Territorio dell'issue, o tutti i .gs/.js) ---
TERRitorio=$(sed -n '/^## Territorio/,/^## /p' "$ISSUE" | grep -oE '[a-zA-Z0-9_/.-]+\.(gs|js|html|py)' | sort -u | head -5)
if [ -z "$TERRitorio" ]; then
  # fallback: i file più piccoli del progetto (il territorio piccolo è quello fattibile)
  TERRitorio=$(find "$DIR" -type f \( -name '*.gs' -o -name '*.js' \) -size -50k | sort | head -3)
fi
log "File da leggere: $TERRitorio"

# --- 2. legge i file e costruisce il prompt ---
FILES_CONTENT=""
for F in $TERRitorio; do
  # il chiamante (night-shift.sh) NON cd-a dentro $DIR: i percorsi del Territorio
  # vanno risolti contro $DIR, non contro la CWD di chi lancia (bug colto dal test
  # di suite 2026-09-04: i 20 test manuali giravano da dentro la dir e non lo vedevano)
  [ -f "$F" ] || F="$DIR/$F"
  [ -f "$F" ] || continue
  REL_PATH=$(realpath --relative-to="$DIR" "$F" 2>/dev/null || echo "$F")
  FILES_CONTENT+="=== FILE: $REL_PATH ===\n$(cat "$F")\n\n"
done

COMMESSA=$(cat "$ISSUE")

PROMPT=$(cat <<EOF
You are a coding assistant. Read the following GitHub issue and the source code. Write the EXACT code changes needed. Output ONLY the modified functions with their full body, wrapped in code blocks. Do NOT re-read files, do NOT ask questions, do NOT explain: just output the corrected code.

=== ISSUE ===
$COMMESSA
=== END ISSUE ===

=== SOURCE CODE ===
$FILES_CONTENT
=== END SOURCE ===

Output the complete modified function(s) now:
EOF
)

# --- 3. chiamata a Ollama (LOCALE) ---
log "Chiamando $MODEL su localhost..."
START=$(date +%s)
RESPONSE=$(curl -sf --max-time 300 "$API" -d "$(jq -n --arg m "$MODEL" --arg p "$PROMPT" '{model:$m, messages:[{role:"user",content:$p}], stream:false, options:{temperature:0}}')" 2>&1)
RC=$?
ELAPSED=$(( $(date +%s) - START ))
if [ $RC -ne 0 ]; then
  log "⛔ Ollama non ha risposto (rc=$RC, ${ELAPSED}s)"
  exit 1
fi
log "Ollama ha risposto in ${ELAPSED}s"

# --- 4. estrai il codice dalla risposta ---
CODE=$(echo "$RESPONSE" | jq -r '.message.content' | sed -n '/^```/,/^```/p' | sed '/^```/d')
if [ -z "$CODE" ]; then
  # fallback: la risposta intera potrebbe essere codice senza fence
  CODE=$(echo "$RESPONSE" | jq -r '.message.content')
fi
if [ -z "$CODE" ] || [ "$CODE" = "null" ]; then
  log "⛔ Il modello non ha prodotto codice"
  exit 1
fi

# --- 5. verifica sintattica del codice ricevuto ---
echo "$CODE" | node --check - 2>/dev/null
SYNTAX_OK=$?
if [ $SYNTAX_OK -ne 0 ]; then
  # potrebbe essere HTML misto: verifica che almeno contenga function o var
  # (E-002: niente pipe in grep -q sotto pipefail — cattura prima)
  grep -qE 'function |var |let |const ' <<<"$CODE" || {
    log "⛔ Il codice ricevuto non passa node --check né contiene codice JS riconoscibile"
    echo "$CODE" | head -5 >&2
    exit 1
  }
  log "⚠ node --check non passa ma contiene JS (possibile HTML misto)"
fi

# --- 6. salva il codice in un file di patch (l'umano o il turno lo applica) ---
PATCH_FILE="$DIR/.night-patch-$(date +%s).js"
echo "$CODE" > "$PATCH_FILE"
log "Codice salvato in $(basename $PATCH_FILE) ($(echo "$CODE" | wc -l | tr -d ' ') righe)"

# --- 7. se c'è UN solo file e UN solo blocco di codice: applica direttamente ---
N_FILES=$(echo "$TERRitorio" | wc -w | tr -d ' ')
N_BLOCKS=$(echo "$CODE" | grep -c "^function \|^  function " || true)
if [ "$N_FILES" -eq 1 ] && grep -q "^function " <<<"$CODE"; then
  TARGET_FILE=$(echo "$TERRitorio" | head -1)
  [ -f "$TARGET_FILE" ] || TARGET_FILE="$DIR/$TARGET_FILE"
  TARGET_FN=$(echo "$CODE" | grep -oE '^function [a-zA-Z_]+' | head -1 | sed 's/function //')
  if [ -n "$TARGET_FN" ] && grep -q "function $TARGET_FN" "$TARGET_FILE"; then
    log "Applicando: sostituisco $TARGET_FN in $(basename $TARGET_FILE)"
    # backup
    cp "$TARGET_FILE" "$TARGET_FILE.night-bak"
    # sostituzione: rimuovi la vecchia funzione, inserisci la nuova
    python3 - "$TARGET_FILE" "$PATCH_FILE" "$TARGET_FN" <<'PYEOF'
import sys, re
target, patch, fn = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(target).read()
new_fn = open(patch).read().strip()
# trova la funzione vecchia (dalla dichiarazione alla chiusura con indentazione coerente)
pattern = re.compile(r'(^function ' + re.escape(fn) + r'\([^)]*\)\s*\{.*?^\})', re.M | re.S)
match = pattern.search(src)
if match:
    src = src[:match.start()] + new_fn + src[match.end():]
    open(target, 'w').write(src)
    print(f"FUNZIONE-SOSTITUITA {fn}")
else:
    print(f"FUNZIONE-NON-TROVATA {fn}")
    sys.exit(1)
PYEOF
    if [ $? -eq 0 ]; then
      # verifica: node --check sulla PATCH (il file .html/.gs contiene HTML misto,
      # node --check sull'intero fallirebbe sempre — si verifica il codice JS puro)
      if echo "$CODE" | node --check - 2>/dev/null; then
        log "✅ Fix applicato e verificato (node --check passa)"
        rm -f "$TARGET_FILE.night-bak"
        echo "ESITO: APPLICATO $(basename $TARGET_FILE) $TARGET_FN ${ELAPSED}s"
        exit 0
      else
        log "⛔ node --check fallisce sul file modificato: rollback"
        cp "$TARGET_FILE.night-bak" "$TARGET_FILE"
        rm -f "$PATCH_FILE"
        exit 1
      fi
    fi
  fi
fi

# se non può applicare direttamente: il codice è nel patch file
log "Codice pronto in $(basename $PATCH_FILE) (applicazione manuale o da giro successivo)"
echo "ESITO: PATCH $(basename $PATCH_FILE) ${ELAPSED}s"
exit 0
