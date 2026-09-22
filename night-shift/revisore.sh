#!/bin/bash
# revisore.sh — IL CENSORE DELLE PR NOTTURNE (2026-09-18, idea di Luca: «un agente
# revisore, censore, che verifica prova certifica il codice e decide se
# deliberarlo o no»).
#
# Il principio: CHI SCRIVE NON GIUDICA. Le migliorie le scrive qwen3.8-27b:iq3s;
# qui giudica lo STESSO modello (un solo modello dal 2026-09-19, riga 35: il 27b
# faceva 0/3 in 442 s) ma in un processo separato, senza memoria, con istruzioni
# avversarie: l'onere della prova e' della PR, non del revisore.
#
# La deliberazione e' a tre livelli, in ordine di autorita':
#   1. GUARDIE (deterministiche): diff <=60 righe, <=3 file, ASCII, no CRLF,
#      solo PR bozza night/* con titolo 'caccia:', quarantena >=20 min dal push
#      (chi crea non si giudica nello stesso respiro), budget <=5 merge/giorno.
#   2. PROVE (deterministiche): verifiche dichiarate riga per riga + un comando
#      avversario scritto dal modello con allowlist ristretta (deve riuscire).
#   3. GIUDIZIO (il censore): vede diff + prove e delibera APPROVA/RIGETTA.
# Solo se TUTTI e tre dicono si' la PR viene mergiata. Un solo no e' no.
#
# Il patto cambia in modo DICHIARATO: «il si' e' sempre umano» diventa «il si' e'
# del censore, il veto resta umano» — ogni deliberazione finisce nel log e il
# mattino puo sempre fare revert. Mai toccare PR che non siano nostre (night/*).
#
# Uso: revisore.sh <dir-repo> <pr-number>
# Esce: 0 = deliberata (mergiata) · 1 = rigettata (chiusa con motivi)
#       2 = skip (quarantena/guardie/prove rosse — lasciato al giorno) · 3 = errore
# Test: REVISORE_DRY=1 stampa le azioni senza eseguirle; REVISORE_STUB=<script>
#       sostituisce i due cervelli (riceve il ruolo e il prompt, risponde eco).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: revisore.sh <dir-repo> <pr>}"
PR="${2:?uso: revisore.sh <dir-repo> <pr>}"
[ -d "$DIR/.git" ] || { echo "⛔ non è un repo git" >&2; exit 3; }
cd "$DIR"

GIUDICE_MODEL="${REVISORE_MODEL:-qwen3.8-27b:iq3s}"  # (2026-09-19: 14b 1/3 in 22s; 2026-09-21: qwen3.8-27b:iq3s 3/3 in 48s con think:false — un solo modello, decisione di Luca)
AUTORE_MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
MAX_RIGHE=60; MAX_FILE=3; QUARANTENA_MIN=20; BUDGET_GIORNO=5
API="http://localhost:11434/api/chat"
STATE="$DIR/.git/revisore"; mkdir -p "$STATE"
# ai_timeout: wrapper portabile dell'hub (macOS non ha timeout(1))
# shellcheck source=../llm/_timeout.sh
source "$HERE/llm/_timeout.sh" 2>/dev/null || true
# gate_allowlist_ok: la STESSA allowlist del morning gate (test del sistema completo
# 2026-09-20, D2: qui viveva una copia piu' debole, prima parola + qualche token — una
# redirezione `> file` o un `| tee file` passavano e SCRIVEVANO nel repo)
# shellcheck source=lib.sh
source "$HERE/night-shift/lib.sh"

log() { echo "[revisore $(date '+%H:%M:%S')] $*" >&2; }

# ramo di default: origin/HEAD SOLO se il symref esiste davvero, altrimenti il
# ramo corrente. (bug trovato dai test, seconda forma: rev-parse --abbrev-ref
# di un ref irrisoluto STAMPA il nome irrisoluto — "origin/HEAD" — e qualunque
# spoglia produce "HEAD": diff HEAD...HEAD vuoto, guardie vacue, censore che
# giudica il nulla. Il default deve essere VERIFICATO, mai dedotto.)
DB=""
if git show-ref --verify --quiet refs/remotes/origin/HEAD 2>/dev/null; then
  DB=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null); DB="${DB#origin/}"
fi
if [ -z "$DB" ] || ! git show-ref --verify --quiet "refs/heads/$DB" 2>/dev/null; then
  DB=$(git symbolic-ref --short HEAD 2>/dev/null || echo main)
fi

# ── i due cervelli (sostituibili per i test) ────────────────────────────────────
chiedi() { # chiedi <modello> <max-sec> <prompt> → risposta (solo contenuto)
  # il censore (27b) non sta in GPU insieme al 14b del turno: Ollama SCAMBIA i
  # modelli (unload + load ~1-2 min) prima di rispondere — per questo il censore
  # ha 600s di fiato mentre l avversario (14b, gia' caldo) ne ha 300
  local modello="$1" maxsec="$2" prompt="$3"
  if [ -n "${REVISORE_STUB:-}" ]; then
    printf '%s' "$prompt" | bash "$REVISORE_STUB" "$modello"
    return
  fi
  curl -s --max-time "$maxsec" "$API" -d "$(jq -cn --arg m "$modello" --arg p "$prompt" \
    '{model:$m, messages:[{role:"user",content:$p}], stream:false, think:false, options:{temperature:0}}')" \
    | jq -r '.message.content // empty' 2>/dev/null
}

# ══ 1. GUARDIE ══════════════════════════════════════════════════════════════════
PR_JSON=$(gh pr view "$PR" --json number,title,headRefName,isDraft,createdAt,state 2>/dev/null)
[ -n "$PR_JSON" ] || { log "PR #$PR non raggiungibile"; exit 3; }
BRANCH=$(printf '%s' "$PR_JSON" | jq -r '.headRefName')
TITLE=$(printf '%s' "$PR_JSON" | jq -r '.title')
IS_DRAFT=$(printf '%s' "$PR_JSON" | jq -r '.isDraft')
CREATED=$(printf '%s' "$PR_JSON" | jq -r '.createdAt')

case "$BRANCH" in night/*) ;; *) log "guardia: branch $BRANCH non e' night/* — non mio"; exit 2;; esac
case "$TITLE" in caccia:*) ;; *) log "guardia: titolo non 'caccia:' — non mio"; exit 2;; esac
[ "$IS_DRAFT" = "true" ] || { log "guardia: non e' piu' bozza — non mio"; exit 2; }

# (D3, 2026-09-20): data illeggibile = quarantena CHIUSA, non aperta. Prima il fallback
# era 999 minuti: una createdAt storpiata passava la quarantena e arrivava al merge.
ETA_MIN=$(python3 -c "
from datetime import datetime, timezone
c = datetime.fromisoformat('$CREATED'.replace('Z','+00:00'))
print(int((datetime.now(timezone.utc) - c).total_seconds() // 60))" 2>/dev/null) || ETA_MIN=""
if ! [ "${ETA_MIN:-x}" -ge 0 ] 2>/dev/null; then
  log "guardia: createdAt illeggibile ('$CREATED') — quarantena fail-closed, al giorno"
  exit 2
fi
if [ "$ETA_MIN" -lt "$QUARANTENA_MIN" ]; then
  log "guardia: quarantena ${ETA_MIN}min < ${QUARANTENA_MIN}min — chi crea non si giudica nello stesso respiro"
  exit 2
fi

# budget: massimo $BUDGET_GIORNO deliberazioni-merge al giorno, per repo
OGGI=$(date '+%Y-%m-%d')
BUDGET_FILE="$STATE/mergi-$OGGI"
N_MERGI=$(cat "$BUDGET_FILE" 2>/dev/null || echo 0)
[ "$N_MERGI" -lt "$BUDGET_GIORNO" ] || { log "guardia: budget esaurito ($N_MERGI/$BUDGET_GIORNO oggi)"; exit 2; }

# diff: piccolo, pochi file, ASCII, niente CRLF
# (il fetch e' un rinfresco: in produzione il branch di solito c'e' gia' in
# locale — l'ha pushato la caccia da questa stessa copia. Se manca anche in
# locale, il checkout sotto esce comunque con errore)
git fetch -q origin "$BRANCH" 2>/dev/null || true
git checkout -q "$BRANCH" 2>/dev/null || { git checkout -q "$DB"; exit 3; }
DBRANCH="$DB"
ripristina() { git checkout -q "$DBRANCH" 2>/dev/null; }
trap ripristina EXIT

DIFF_FILES=$(git diff --name-only "$DB"...HEAD 2>/dev/null)
N_FILE=$(printf '%s\n' "$DIFF_FILES" | grep -c .)
N_RIGHE=$(git diff --numstat "$DB"...HEAD 2>/dev/null | awk '{a+=$1+$2} END{print a+0}')
# (D4, 2026-09-20): un diff VUOTO passava tutte le guardie (0 <= 60) e veniva deliberato
# — il censore giudicava il nulla e lo mergiava. Niente diff, niente giudizio.
[ "$N_FILE" -ge 1 ] || { log "guardia: diff vuoto ($DB...HEAD) — niente da giudicare, al giorno"; exit 2; }
# (D1, 2026-09-20): chi scrive le prove non le passa. Una PR che tocca .night-verify
# (anche solo per riscriverlo a `true`) non si giudica: le prove sotto sono lette dal
# ramo di default, come fa il morning gate, e questa guardia chiude l'altra via.
if printf '%s\n' "$DIFF_FILES" | grep -qx '.night-verify'; then
  log "guardia: la PR tocca .night-verify — le prove non si giudicano da chi le scrive, al giorno"
  exit 2
fi
[ "$N_FILE" -le "$MAX_FILE" ] || { log "guardia: $N_FILE file (max $MAX_FILE) — al giorno"; exit 2; }
[ "$N_RIGHE" -le "$MAX_RIGHE" ] || { log "guardia: $N_RIGHE righe (max $MAX_RIGHE) — al giorno"; exit 2; }
if ! git diff "$DB"...HEAD | python3 -c '
import sys
for l in sys.stdin:
    if l.startswith("+") and any(ord(c) > 126 or c == "\r" for c in l):
        sys.exit(1)' 2>/dev/null; then
  log "guardia: non-ASCII o CRLF nel diff — al giorno"; exit 2
fi
DIFF=$(git diff "$DB"...HEAD)

# ══ 2. PROVE (deterministiche) ══════════════════════════════════════════════════
PROVE_ROTTE=""
# (D1, 2026-09-20): le prove sono quelle DICHIARATE DALLA REPO sul ramo di default —
# lette da `git show $DB:.night-verify`, eseguite sul working tree della PR. Prima si
# leggeva il file del branch sotto giudizio: la PR poteva scrivere le proprie prove.
NV_DICHIARATE=$(git show "$DB:.night-verify" 2>/dev/null || true)
if [ -n "$NV_DICHIARATE" ]; then
  # (report BusinessPlan): un .night-verify senza comandi NON e' una prova superata
  if [ "$(printf '%s\n' "$NV_DICHIARATE" | grep -vcE '^\s*#|^\s*$' || echo 0)" -eq 0 ]; then
    PROVE_ROTTE="; .night-verify senza comandi (verifiche-vuote)"
  # (2026-09-19): due formati — script intero o riga-per-riga (contratto del turno)
  elif printf '%s\n' "$NV_DICHIARATE" | head -10 | grep -q "^# FORMATO: script"; then
    NV_SCRIPT=$(mktemp /tmp/revisore-nv.XXXXXX); printf '%s\n' "$NV_DICHIARATE" > "$NV_SCRIPT"
    if ! (ai_timeout 900 bash "$NV_SCRIPT" >/dev/null 2>&1 </dev/null); then
      PROVE_ROTTE="; .night-verify (formato script) rosso"
    fi
    rm -f "$NV_SCRIPT"
  elif true; then
  while IFS= read -r NV_CMD; do
    case "$NV_CMD" in ""|\#*) continue;; esac
    NV_SEC=120
    case "$NV_CMD" in
      @*" "*) NV_SEC="${NV_CMD%% *}"; NV_SEC="${NV_SEC#@}"; NV_CMD="${NV_CMD#* }" ;;
    esac
    # (2026-09-19): bash -c come nel turno — i costrutti shell sono righe di
    # script valide, non comandi eseguibili (16/45 rosse false sul Magazzino)
    if ! (ai_timeout "$NV_SEC" bash -c "$NV_CMD" >/dev/null 2>&1 </dev/null); then
      PROVE_ROTTE="$PROVE_ROTTE; $NV_CMD"
    fi
  done <<< "$NV_DICHIARATE"
  fi
else
  PROVE_ROTTE="; .night-verify assente sul ramo di default ($DB)"
fi
[ -z "$PROVE_ROTTE" ] || { log "prove: verifiche dichiarate rosse:$PROVE_ROTTE — al giorno"; exit 2; }
PROVE_VERDI=1

# banco avversario: il modello scrive UN comando allowlistato che deve riuscire
AVV_PROMPT="Sei l'avversario in una code review. Ecco il diff di una pull request. Scrivi UN solo comando shell, eseguibile dalla root della repo, che SMASCHERA un difetto della PR se esiste: deve riuscire (exit 0) se la PR è solida, fallire (exit != 0) se è difettosa. Vincoli rigidissimi: niente rete, niente operazioni distruttive, NESSUN interprete general-purpose (node/python/bash/sh vengono scartati). Ammessi SOLO: grep, cat, diff, wc, head, tail, ls, test, jq, echo, e git in sola lettura (diff/log/show/grep/status/rev-parse/ls-files/blame). Rispondi con UN SOLO blocco di codice contenente il comando, senza spiegazioni.

Diff:
$DIFF"
AVV_RISP=$(chiedi "$AUTORE_MODEL" 300 "$AVV_PROMPT")
AVV_CMD=$(printf '%s' "$AVV_RISP" | sed -n '/^```/,$p' | sed '1d;$d' | grep -v '^$' | head -1)
# validazione: la stessa allowlist per segmento del morning gate (lib.sh: ogni
# segmento inizia con uno strumento di sola lettura, git solo readonly, nessuna
# sostituzione di comando o processo) PIU' il rifiuto delle redirezioni in scrittura
# — (D2, 2026-09-20): `echo pwned > tools/a.sh` passava la vecchia allowlist e
# SOVRASCRIVEVA il file nel working tree, e la PR veniva deliberata comunque.
AVV_VALIDA=0
if [ -n "$AVV_CMD" ]; then
  case "$AVV_CMD" in
    *">"*) AVV_VALIDA=0 ;;
    *) gate_allowlist_ok "$AVV_CMD" && AVV_VALIDA=1 ;;
  esac
fi
if [ "$AVV_VALIDA" -eq 1 ]; then
  # eval lecito: la stringa e' gia' passata dall'allowlist qui sopra; senza eval
  # le virgolette del comando resterebbero CARATTERI e grep cercherebbe '"function'
  if eval "ai_timeout 60 $AVV_CMD" >/dev/null 2>&1 </dev/null; then
    BANCO_ESITO="REGGE (comando avversario riuscito)"
  else
    log "prove: banco avversario ha smascherato la PR ($AVV_CMD)"
    BANCO_ESITO="SMASCHERATA"
  fi
  # l'avversario non lascia tracce nella copia di lavoro (stessa disciplina del gate)
  git checkout -q -- . 2>/dev/null; git clean -fdq 2>/dev/null
else
  BANCO_ESITO="COMANDO INVALIDO (scartato dall'allowlist) — non conta come prova superata"
fi
[ "$BANCO_ESITO" = "REGGE (comando avversario riuscito)" ] || { log "prove: banco: $BANCO_ESITO — al giorno"; exit 2; }

# ══ 3. GIUDIZIO (il censore: cervello diverso da chi ha scritto) ═══════════════
CENS_PROMPT="Sei il CENSORE di una pull request notturna. NON l'hai scritta tu: l'ha scritto un altro modello ($AUTORE_MODEL), tu sei un cervello piu' grande e il tuo compito e' trovare il motivo per RIGETTARLA. L'onore della prova e' della PR: nel dubbio, RIGETTA.

La PR dichiara di essere una piccola miglioria notturna (categoria: morto=eliminazione codice non usato, docs=commenti aggiunti, semplice=semplificazione a comportamento identico, ripetuto=letterale ripetuto estratto a costante).

Prove deterministiche gia' superate: verifiche dichiarate tutte verdi; comando avversario del banco riuscito; diff di $N_RIGHE righe su $N_FILE file.

Diff:
$DIFF

Giudica:
1. il diff fa DAVVERO quello che dichiara la categoria? (un 'docs' che tocca codice: RIGETTA)
2. elimina qualcosa che serve? (una 'variabile morta' che e' usata altrove: RIGETTA)
3. lascia il file coerente e funzionante?
4. i commenti aggiunti dicono la verita' sul codice?

Rispondi SOLO con JSON su una riga: {\"verdetto\": \"APPROVA\"|\"RIGETTA\", \"rischio\": \"basso\"|\"medio\"|\"alto\", \"motivi\": [\"...\", \"...\"]}"
CENS_RISP=$(chiedi "$GIUDICE_MODEL" 300 "$CENS_PROMPT")  # il 14b risponde in secondi: 300 di fiato bastano
VERDETTO=$(printf '%s' "$CENS_RISP" | jq -r '.verdetto // empty' 2>/dev/null)
MOTIVI=$(printf '%s' "$CENS_RISP" | jq -r '.motivi[]?' 2>/dev/null | head -5)
[ -n "$VERDETTO" ] || { log "censore non ha risposto in JSON — al giorno (non si delibera senza verdetto)"; exit 2; }

# ══ DELIBERA ═══════════════════════════════════════════════════════════════════
azione_gh() { # in DRY stampa a stdout, altrimenti esegue silenzioso (niente eval)
  if [ -n "${REVISORE_DRY:-}" ]; then echo "[DRY] $*"; return 0; fi
  "$@" >/dev/null 2>&1
}

if [ "$VERDETTO" = "APPROVA" ]; then
  log "DELIBERA: APPROVA PR #$PR ($N_RIGHE righe, $N_FILE file) — rischio: $(printf '%s' "$CENS_RISP" | jq -r '.rischio // "?"')"
  CERT_FILE=$(mktemp /tmp/revisore-cert.XXXXXX)
  printf 'Deliberata dal revisore notturno (censore: %s, autore: %s).\nProve: verifiche dichiarate verdi · banco avversario superato · guardie diff (%s righe/%s file).\nMotivazioni: %s\nIl veto resta umano: il mattino puo sempre fare revert.\n' \
    "$GIUDICE_MODEL" "$AUTORE_MODEL" "$N_RIGHE" "$N_FILE" "$(echo "$MOTIVI" | tr '\n' ' ' | cut -c1-300)" > "$CERT_FILE"
  azione_gh gh pr ready "$PR" || true
  if azione_gh gh pr merge "$PR" --squash --delete-branch; then
    echo $(( N_MERGI + 1 )) > "$BUDGET_FILE"
    azione_gh gh pr comment "$PR" --body-file "$CERT_FILE" || true
    rm -f "$CERT_FILE"
    log "✅ PR #$PR MERGIATA (deliberazione $(( N_MERGI + 1 ))/$BUDGET_GIORNO di oggi)"
    exit 0
  else
    rm -f "$CERT_FILE"
    log "⚠ merge di PR #$PR fallito — lasciata al giorno"
    exit 2
  fi
else
  log "DELIBERA: RIGETTA PR #$PR — $MOTIVI"
  RIG_FILE=$(mktemp /tmp/revisore-rig.XXXXXX)
  printf 'RIGETTATA dal censore notturno (censore: %s).\nMotivi: %s\n' \
    "$GIUDICE_MODEL" "$(echo "$MOTIVI" | tr '\n' ' ' | cut -c1-400)" > "$RIG_FILE"
  azione_gh gh pr comment "$PR" --body-file "$RIG_FILE" || true
  rm -f "$RIG_FILE"
  azione_gh gh pr close "$PR"
  log "⛔ PR #$PR chiusa col parere motivato"
  exit 1
fi
