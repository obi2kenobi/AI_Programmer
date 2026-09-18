#!/bin/bash
# caccia-miglioria.sh — la caccia che MIGLIORA il codice (2026-09-17).
#
# Nata dalla domanda di Luca: «questo sistema cerca anche di migliorare il repo?».
# Diagnosi: auto-fix = manutenzione (indici, citazioni, CRLF); caccia-lente =
# verifica (gli strumenti girano, il modello dice 'tutto bene'); NESSUNO migliorava
# il codice. Questo script è il pezzo che manca: l'agente SCRIVE una miglioria.
#
# Il metodo (lezione della caccia generica: non convergeva): UN file, UNA
# categoria, UN prompt focused. Le categorie sono conservative — morte certa,
# non gusto: codice morto, commenti mancanti, semplificazioni a comportamento
# identico, letterali ripetuti. E il permesso di dire "non c'è niente":
# inventare lavoro è peggio che non trovarlo (il vecchio prompt 'Be AGGRESSIVE'
# produceva rumore, ed era pure codice morto: mai passato a nessuno).
#
# Uso: caccia-miglioria.sh <dir-repo>
# Esce: 0 = miglioria pronta nel working tree (gate superato) — il chiamante committa
#       1 = niente da migliorare (o gate bocciato) — working tree ripristinato
#       2 = errore d'uso
#
# Stato in <repo>/.git/miglioria/: mai committato, sempre presente, e una
# rotazione file/categoria per non martellare sempre lo stesso punto.
# Override per test e debug: MIGLIORIA_CAT, MIGLIORIA_FILE, MIGLIORIA_AGENT.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: caccia-miglioria.sh <dir-repo>}"
[ -d "$DIR/.git" ] || { echo "⛔ non è un repo git: $DIR" >&2; exit 2; }
cd "$DIR"

STATE="$DIR/.git/miglioria"
mkdir -p "$STATE"
COOLDOWN=21600  # 6h: un file dichiarato 'niente da migliorare' in una categoria non si ritocca
AGENT_CMD="${MIGLIORIA_AGENT:-$HERE/night-shift/agente.sh}"
MAX_RIGHE_DIFF=40
MAX_FILE=2

log() { echo "[miglioria $(date '+%H:%M:%S')] $*" >&2; }

# --- le categorie: istruzioni brevi, oneste, UNA cosa sola ----------------------
CATS=(morto docs semplice ripetuto)
CAT_MORTO="TASK: find exactly ONE of these and remove it:
- a variable or constant that is declared or assigned but never used anywhere in the file, OR
- a block of commented-out code (2+ consecutive comment lines that are old code, not documentation).
Remove it completely. If there is truly none, change nothing and say so."
CAT_DOCS="TASK: find ONE function that has no comment above it, and add a short comment (1-3 lines) explaining what it does and why. Only ADD comment lines: do not modify, move or delete any code. If every function is already documented, change nothing and say so."
CAT_SEMPLICE="TASK: find ONE small simplification that keeps behavior EXACTLY the same — e.g. a variable assigned once and used once right after (inline it), a condition duplicated in the same expression, an unnecessary intermediate copy. Apply only that one. If nothing is safely simplifiable, change nothing and say so."
CAT_RIPETUTO="TASK: find ONE literal (string or number) that appears 2+ times with the same meaning in the file, and extract it to a named constant at the top, updating all occurrences. If no literal is meaningfully repeated, change nothing and say so."

istruzione() {
  case "$1" in
    morto)    printf '%s' "$CAT_MORTO" ;;
    docs)     printf '%s' "$CAT_DOCS" ;;
    semplice) printf '%s' "$CAT_SEMPLICE" ;;
    ripetuto) printf '%s' "$CAT_RIPETUTO" ;;
    debito)   printf '%s' "$CAT_DEBITO" ;;
    *) return 1 ;;
  esac
}

# (2026-09-18, Luca: «si'» — il debito censito si SALDA): fix meccanici per le
# famiglie del registro. Ogni nuova famiglia che entra nel censimento entra qui.
CAT_DEBITO_E002="TASK: convert THAT ONE pipeline site to cattura-prima (the canon fix for the E-002 family: with pipefail, a producer that writes past the first match dies of SIGPIPE and the whole pipeline lies). Steps: capture the pipeline output into a local variable FIRST, then test it with grep -q pattern <<<\"\$VAR\". Preserve EXACT behavior: same patterns, same case flags, same branches on both grep outcomes. Touch only that site, nothing else."
CAT_DEBITO_E032="TASK: convert THAT ONE test line so its fixture lives in QUARANTENA, not in the live repo (E-032 family: a fixture planted in the real repo is visible to every concurrent check). Steps: create a scratch dir with mktemp -d and a trap cleanup, and write the fixture there; point the test assertions at the scratch. The live repo files must NOT be modified."
CAT_DEBITO="$CAT_DEBITO_E002"

# --- i file candidati: tracciati, codice, piccoli (stesso limite del solver) ----
list_files() {
  git ls-files -- '*.sh' '*.py' '*.js' '*.gs' '*.html' '*.css' 2>/dev/null \
    | while IFS= read -r f; do
        [ -f "$f" ] || continue
        sz=$(wc -c < "$f" | tr -d ' ')
        [ "$sz" -le 24000 ] && printf '%s\n' "$f"
      done
}

# marker di 'niente trovato' per file+categoria, con scadenza
marker_name() { printf 'clean.%s.%s' "$1" "$(printf '%s' "$2" | tr '/.' '__')"; }
in_cooldown() {
  local m="$STATE/$(marker_name "$1" "$2")"
  [ -f "$m" ] || return 1
  local eta=$(( $(date +%s) - $(stat -f %m "$m" 2>/dev/null || echo 99999999999) ))
  [ "$eta" -lt "$COOLDOWN" ]
}

# --- il gate: la frontiera tra 'miglioria' e 'riscrittura' ----------------------
# Nessun diff passa senza: poche righe, pochi file, sintassi valida, solo ASCII
# (il registro della repo è ASCII: 'e' non 'è'), niente CRLF.
gate() {
  local files n tot
  files=$(git diff --name-only 2>/dev/null)
  [ -n "$files" ] || { log "gate: nessun diff"; return 1; }
  n=$(printf '%s\n' "$files" | grep -c .)
  [ "$n" -le "$MAX_FILE" ] || { log "gate BOCCIA: $n file toccati (max $MAX_FILE)"; return 1; }
  tot=$(git diff --numstat | awk '{a+=$1+$2} END{print a+0}')
  [ "$tot" -le "$MAX_RIGHE_DIFF" ] || { log "gate BOCCIA: $tot righe cambiate (max $MAX_RIGHE_DIFF)"; return 1; }
  if ! git diff | python3 -c '
import sys
for l in sys.stdin:
    if l.startswith("+") and any(ord(c) > 126 or c == "\r" for c in l):
        sys.exit(1)' 2>/dev/null; then
    log "gate BOCCIA: non-ASCII o CRLF nelle righe aggiunte"; return 1
  fi
  while IFS= read -r f; do
    case "$f" in
      *.sh)  bash -n "$f" 2>/dev/null || { log "gate BOCCIA: sintassi bash — $f"; return 1; } ;;
      *.py)  python3 -c "compile(open('$f').read(), '$f', 'exec')" 2>/dev/null || { log "gate BOCCIA: sintassi py — $f"; return 1; } ;;
      *.js|*.gs)
        command -v node >/dev/null 2>&1 && ! node --check "$f" 2>/dev/null \
          && { log "gate BOCCIA: sintassi js — $f"; return 1; } ;;
    esac
  done <<< "$files"
  return 0
}

ripristina() { git reset -q --hard && git clean -qfd; }

# --- scelta file + categoria (rotazione, salta i cooldown) ----------------------
# PRIMA il debito del registro (Luca 2026-09-18): un sito per finestra, il fix
# e' meccanico, il censimento dice dove. Saldato o rinviato: un tentativo per
# sito, niente martellamento.
SITO=""; FAMIGLIA=""; CAT=""
if [ -z "${MIGLIORIA_CAT:-}" ] && [ -f "$HERE/tools/caccia-registro.sh" ]; then
  PROSSIMO=$(bash "$HERE/tools/caccia-registro.sh" --prossimo "$DIR" 2>/dev/null | head -1)
  if [ -n "$PROSSIMO" ]; then
    FAMIGLIA=$(printf '%s' "$PROSSIMO" | cut -d'|' -f1)
    SITO=$(printf '%s' "$PROSSIMO" | cut -d'|' -f2)
    CAT="debito"
    case "$FAMIGLIA" in
      E-002) CAT_DEBITO="$CAT_DEBITO_E002" ;;
      E-032) CAT_DEBITO="$CAT_DEBITO_E032" ;;
    esac
  fi
fi
CAT_IDX=$(cat "$STATE/cat-idx" 2>/dev/null || echo 0)
[ -n "$CAT" ] || CAT="${MIGLIORIA_CAT:-${CATS[$(( CAT_IDX % ${#CATS[@]} ))]}}"
[ "$CAT_IDX" -eq "$CAT_IDX" ] 2>/dev/null || CAT="morto"  # indice corrotto: torna al certo
echo $(( CAT_IDX + 1 )) > "$STATE/cat-idx"
istruzione "$CAT" >/dev/null || { log "categoria sconosciuta: $CAT"; exit 2; }

FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(list_files)
[ ${#FILES[@]} -eq 0 ] && { log "nessun file codice candidato (≤24KB)"; exit 1; }

TARGET="${MIGLIORIA_FILE:-}"
[ -n "$SITO" ] && TARGET="${SITO%:*}"   # il debito dice il file: la riga va nel prompt
if [ -z "$TARGET" ]; then
  FIDX=$(cat "$STATE/coda-idx" 2>/dev/null || echo 0)
  [ "$FIDX" -eq "$FIDX" ] 2>/dev/null || FIDX=0
  echo $(( FIDX + 1 )) > "$STATE/coda-idx"
  i=0
  while [ "$i" -lt ${#FILES[@]} ]; do
    f="${FILES[$(( (FIDX + i) % ${#FILES[@]} ))]}"
    if in_cooldown "$CAT" "$f"; then i=$((i+1)); continue; fi
    TARGET="$f"; break
  done
fi
[ -n "$TARGET" ] || { log "tutti i file in cooldown per '$CAT' — riprova più tardi"; exit 1; }
[ -f "$TARGET" ] || { log "file inesistente: $TARGET"; exit 2; }

log "categoria '$CAT' su $TARGET"

# --- l'agente lavora (confinato: read/write/run dentro la repo, denylist attiva) -
SITO_NOTA=""
[ -n "$SITO" ] && SITO_NOTA=" The exact site is line ${SITO##*:} of this file."

PROMPT="You are improving the file '$TARGET' of this repository. Work only on this file unless a strictly required follow-up edit is needed (max $MAX_FILE files total).$SITO_NOTA

$(istruzione "$CAT")

Rules:
- Exactly ONE improvement. Minimal diff: no reformatting, no reindenting, no renames beyond the task.
- If nothing fits honestly, change nothing and say so: inventing work is worse than finding none.
- Any comment you write must be ASCII only (English, or Italian without accented letters).
- After writing, read the file back and verify your edit."

AGENTE_RC=0
AGENTE_TIMEOUT="${AGENTE_TIMEOUT:-240}" bash "$AGENT_CMD" "$DIR" "$PROMPT" 2>/dev/null || AGENTE_RC=$?

if [ "$AGENTE_RC" -ne 0 ]; then
  log "agente rc=$AGENTE_RC — ripristino e passo oltre"
  ripristina
  exit 1
fi

# il debito e' un tentativo solo: se l'agente non lo salda, il sito e' rinviato
# (resta nel censimento, il giorno lo vede e decide)
if [ -n "$SITO" ]; then
  mkdir -p "$DIR/.git/caccia-registro"
  echo "$SITO" >> "$DIR/.git/caccia-registro/rinviati"
fi
if git diff --quiet 2>/dev/null; then
  log "'$CAT' su $TARGET: niente da migliorare (dichiarato pulito per ${COOLDOWN}s)"
  touch "$STATE/$(marker_name "$CAT" "$TARGET")"
  exit 1
fi

if ! gate; then
  log "miglioria bocciata dal gate — ripristino (il gate protegge il mattino da noi)"
  ripristina
  exit 1
fi
# il gate ha passato il fix del debito: il sito e' SALDATO (esci dalla coda dei
# rinviati ed entra nei saldati — il censimento lo riconfermera' col conteggio)
if [ -n "$SITO" ]; then
  sed -i '' "/^${SITO//\//\/}$/d" "$DIR/.git/caccia-registro/rinviati" 2>/dev/null || true
  echo "$SITO" >> "$DIR/.git/caccia-registro/saldati"
fi

RIGHE=$(git diff --numstat | awk '{a+=$1+$2} END{print a+0}')
FILE_TOCATI=$(git diff --name-only | tr '\n' ' ')
echo "MIGLIORIA [$CAT] $TARGET — $RIGHE righe: ${FILE_TOCATI}"
log "miglioria pronta: [$CAT] $TARGET ($RIGHE righe) — il chiamante committa"
exit 0
