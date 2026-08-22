#!/bin/bash
# night-shift.sh v2.0 — il turno di notte multi-repo del sistema AI_Programmer.
#
# Per ogni repo (argomenti, o night-shift/repos.conf senza argomenti):
# issue aperte con label night-shift → branch night/issue-N → OpenCode headless (Qwen locale)
# → commit → PR BOZZA (mai push su main) → commento nell'issue.
#
# Tutto ciò che tre notti su REPO-A hanno insegnato è qui dentro:
#   - sonda di salute del server (errori Metal dopo lunga vita → riavvio automatico)
#   - loop delle issue su array (lo stdin del while read veniva mangiato)
#   - bash 3.2 (niente mapfile) e cd nel subshell (l'agente lavorava nella directory sbagliata)
#   - idempotenza completa (PR aperta → skip; PR fusa → chiude l'issue rimasta aperta)
#   - NESSUN LIMITE DI TEMPO (deciso da Luca 2026-08-21): finché non ha finito.
#     Guardia anti-loop: pkill -f "opencode run" libera il Mac.
#   - keyword inglese "Closes #N" (l'italiana non auto-chiude le issue al merge)
#   - git clean per issue (un fallimento non lascia rifiuti al commit successivo)
#
# repos.conf: una riga per repo, "owner/repo [tipo_commit]" — LOCALE e gitignored.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib.sh"
CONF="$HERE/repos.conf"
LOG="$HOME/night-shift.log"
WORK="$HOME/night-shift-work"
MODEL_TAG="qwen3.8:27b-mtp-q4_K_M"
OCPROVIDER="ollama/$MODEL_TAG"
DEFAULT_TYPE="chore"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

# --- La lista delle repo -------------------------------------------------------
REPO_LIST=()
if [ $# -gt 0 ]; then
  for a in "$@"; do REPO_LIST+=("$a"); done
else
  [ -f "$CONF" ] || { echo "uso: night-shift.sh owner/repo ... — oppure crea $CONF (vedi repos.conf.example)" >&2; exit 1; }
  # Formato: owner/repo [tipo] [cadenza]
  # Cadence: giornaliera (default), settimanale, o giorno settimana (lun/mar/.../dom)
  GIORNO_ODIerno=$(date '+%u')  # 1=lun ... 7=dom
  declare -a GIORNI=(lun mar mer gio ven sab dom)
  OGGI=${GIORNI[$((GIORNO_ODIerno-1))]}
  while IFS= read -r line; do
    line="${line%%#*}"; [ -z "$(echo "$line" | tr -d '[:space:]')" ] && continue
    CAD=$(echo "$line" | awk '{print $3}')
    ENTRY=$(echo "$line" | awk '{print $1, $2}')
    case "$CAD" in
      ""|giornaliera) REPO_LIST+=("$ENTRY") ;;
      settimanale) [ "$OGGI" = "lun" ] && REPO_LIST+=("$ENTRY") ;;
      lun|mar|mer|gio|ven|sab|dom) [ "$CAD" = "$OGGI" ] && REPO_LIST+=("$ENTRY") ;;
      *) log "ATTENZIONE: cadenza '$CAD' sconosciuta in '$ENTRY', la salto" ;;
    esac
  done < "$CONF"
fi
[ "${#REPO_LIST[@]}" -eq 0 ] && { echo "nessuna repo configurata" >&2; exit 1; }

# --- Sonda di salute del server Ollama -----------------------------------------
ensure_server() {
  curl -sf --max-time 3 http://localhost:11434/api/version >/dev/null 2>&1 && return 0
  log "Avvio server Ollama..."
  OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_CONTEXT_LENGTH=16384 \
    /opt/homebrew/bin/ollama serve >> ~/ollama-server.log 2>&1 &
  for _ in $(seq 1 30); do
    curl -sf --max-time 1 http://localhost:11434/api/version >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}
probe() {
  curl -sf --max-time 120 http://localhost:11434/api/chat -d \
    "{\"model\":\"$MODEL_TAG\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"stream\":false,\"think\":false,\"options\":{\"num_ctx\":2048}}" \
    | grep -q '"content":"'
}

ensure_server || { log "ERRORE: server Ollama non disponibile"; exit 1; }
ollama list 2>/dev/null | grep -q "$MODEL_TAG" || { log "ERRORE: modello $MODEL_TAG assente (ollama pull $MODEL_TAG)"; exit 1; }
# Finding #3 (2026-08-21): opencode orfani di ore rubano il modello e inquinano i turni.
# Il turno È l'unico proprietario legittimo di "opencode run" mentre gira: si ripulisce prima.
pkill -f "opencode run" 2>/dev/null && log "Puliti processi opencode orfani" && sleep 2 || true

if ! probe; then
  log "Sonda fallita: riavvio server (errori Metal dopo lunga vita)..."
  # Finding #4 (2026-08-21): il server è di LAUNCHD (KeepAlive) — se lo killiamo e ne
  # avviamo uno nostro, lui resuscita e ci contende la porta: si perde la gara entrambi.
  # Strategia: se l'agente esiste, KICKSTART a lui e si aspetta la sua resurrezione;
  # solo senza agente (altre macchine) si avvia un'istanza propria.
  if launchctl list 2>/dev/null | grep -q "ollama"; then
    launchctl kickstart -k "gui/$(id -u)/$(launchctl list | awk '/ollama/{print $3}')" 2>/dev/null
    for _ in $(seq 1 30); do
      curl -sf --max-time 1 http://localhost:11434/api/version >/dev/null 2>&1 && break
      sleep 2
    done
  else
    pkill -f "ollama serve" 2>/dev/null; sleep 4
    OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_CONTEXT_LENGTH=16384 \
      /opt/homebrew/bin/ollama serve >> ~/ollama-server.log 2>&1 &
    sleep 8
  fi
  probe || { log "ERRORE: server non risponde nemmeno dopo il riavvio"; exit 1; }
  log "Server riavviato e sano"
fi

# --- Il turno per una repo -----------------------------------------------------
shift_repo() {
  local ENTRY="$1" REPO="${1%% *}" CTYPE
  CTYPE=$(echo "$ENTRY" | awk '{print $2}'); [ -z "$CTYPE" ] && CTYPE="$DEFAULT_TYPE"
  log "===== REPO $REPO (commit: $CTYPE) ====="

  gh auth status >/dev/null 2>&1 || { log "ERRORE: gh non autenticato"; return 1; }

  # Lock per repo (finding #5, 2026-08-21): il turno manuale e quello delle 23:00 non si
  # pestano i piedi. Lock a directory con età: un lock più vecchio di 12h è Considerato morto.
  local LOCK="$WORK/.lock-${REPO//\//_}"
  if [ -d "$LOCK" ] && [ $(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) )) -lt 43200 ]; then
    log "REPO $REPO: lock attivo di un altro turno, salto"
    return 0
  fi
  mkdir -p "$LOCK"
  trap 'rmdir "$LOCK" 2>/dev/null' RETURN

  local DIR="$WORK/${REPO##*/}"
  # review §2.2: il default branch si DETECTA (mai assumere main) e un checkout fallito
  # si dice forte e si risolve col riclone — mai continuare su stato stantio in silenzio
  if [ -d "$DIR/.git" ]; then
    git -C "$DIR" fetch origin --prune -q
  else
    gh repo clone "$REPO" "$DIR" -- --depth=50 -q || { log "ERRORE: clone di $REPO fallito"; return 1; }
  fi
  local DB
  DB=$(default_branch "$DIR") || log "ATTENZIONE: default branch non rilevato in $REPO, assumo main"
  if ! git -C "$DIR" checkout "$DB" -q 2>/dev/null || ! git -C "$DIR" reset --hard "origin/$DB" -q; then
    log "ERRORE: checkout/reset di $DB fallito in $DIR — riclono pulito"
    rm -rf "$DIR"
    gh repo clone "$REPO" "$DIR" -- --depth=50 -q || { log "ERRORE: riclone di $REPO fallito"; return 1; }
  fi
  git -C "$DIR" config user.name  >/dev/null 2>&1 || git -C "$DIR" config user.name  "Night Shift"
  git -C "$DIR" config user.email >/dev/null 2>&1 || git -C "$DIR" config user.email "night-shift@localhost"

  local ISSUES COUNT
  ISSUES=$(gh issue list -R "$REPO" --label night-shift --state open --json number,title,body --limit 50)
  COUNT=$(echo "$ISSUES" | jq 'length')
  [ "$COUNT" -ge 50 ] && log "ATTENZIONE: limite 50 issue raggiunto in $REPO — possibile troncamento silenzioso (review §5)"
  log "TURNO su $REPO: $COUNT issue in coda"
  [ "$COUNT" -eq 0 ] && { log "$REPO: nessuna issue night-shift. Buonanotte."; return 0; }

  local PR_CREATED=0 FAILED=0 IDX=0
  local ROWS=()
  while IFS= read -r line; do ROWS+=("$line"); done < <(echo "$ISSUES" | jq -c '.[]')

  while [ "$IDX" -lt "${#ROWS[@]}" ]; do
    local row="${ROWS[$IDX]}"; IDX=$((IDX+1))
    local NUM TITLE BODY BRANCH
    NUM=$(echo "$row" | jq -r '.number')
    TITLE=$(echo "$row" | jq -r '.title')
    BODY=$(echo "$row" | jq -r '.body // ""')
    [ -z "$NUM" ] || [ "$NUM" = "null" ] && continue

    # Miglioramento #1 (analisi processo 2026-08-21): il processo non dipende più dalla
    # disciplina dell'operatore — un'issue night-shift senza sezione "## Design" NON parte.
    # Il design può essere un link, un riferimento al SAL del progetto, o tre righe di ratio:
    # deve esserci, dichiarato, PRIMA del lavoro.
    # Qualità minima delle sezioni (giro 8/10): "## Design" con 3 parole passa il gate
    # formale ma non il metodo. Il Design deve dire DA DOVE nasce (SAL/analisi/rif),
    # il Territorio deve nominare almeno un file.
    DESIGN_BODY=$(printf '%s' "$BODY" | awk '/^## Design/{f=1;next} /^## /{f=0} f' | tr -d '[:space:]')
    if [ "${#DESIGN_BODY}" -lt 80 ]; then
      log "Issue #$NUM: sezione ## Design troppo povera (${#DESIGN_BODY} char < 80) — serve il DA DOVE (SAL, analisi, riferimento)"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: la sezione \`## Design\` è troppo povera (${#DESIGN_BODY} caratteri utili). Il design dichiara da dove nasce la commessa (link al SAL, all'analisi, o tre righe di ratio sostanziale)." >/dev/null 2>&1
      continue
    fi
    TERR_BODY=$(printf '%s' "$BODY" | awk '/^## Territorio/{f=1;next} /^## /{f=0} f')
    if ! printf '%s' "$TERR_BODY" | grep -qE '\.[a-z]{2,4}\b|file|riga|documento|md\b'; then
      log "Issue #$NUM: ## Territorio senza file/righe nominate — il territorio si dichiara con precisione"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: la sezione \`## Territorio\` non nomina file, righe né documenti. Il territorio si dichiara con precisione (file e dimensione) — altrimenti il lavoro va al giorno." >/dev/null 2>&1
      continue
    fi

    # Regola del territorio (2026-08-22): senza dichiarazione, la commessa non parte
    if ! printf '%s' "$BODY" | grep -q "^## Territorio"; then
      log "Issue #$NUM: SENZA sezione ## Territorio — il processo la richiede, skip con commento"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: manca la sezione \`## Territorio\` (quanto codice serve leggere). La lezione dell'11 ore: la notte converge solo su territori piccoli e indicati — dichiara il territorio, o se è grande assegnala al giorno." >/dev/null 2>&1
      continue
    fi

    if ! printf '%s' "$BODY" | grep -q "^## Design"; then
      log "Issue #$NUM: SENZA sezione ## Design — il processo la richiede, skip con commento"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Il turno di notte salta questa issue: manca la sezione \`## Design\` (anche solo un link o tre righe di ratio). Il processo di AI_Programmer richiede che ogni commessa dichiar il suo design prima del lavoro — aggiungila e la prossima notte riparte." >/dev/null 2>&1
      continue
    fi

    # Idempotenza: PR aperta → skip; PR fusa → chiude l'issue e skip
    local PR_STATE
    PR_STATE=$(gh pr view "night/issue-$NUM" -R "$REPO" --json state -q .state 2>/dev/null)
    if [ "$PR_STATE" = "OPEN" ]; then log "Issue #$NUM: PR già aperta, skip"; continue; fi
    if [ "$PR_STATE" = "MERGED" ]; then
      log "Issue #$NUM: PR già fusa, chiudo l'issue e skip"
      gh issue close "$NUM" -R "$REPO" --comment "Chiusa automaticamente: la PR sul branch night/issue-$NUM è stata fusa." >/dev/null 2>&1
      continue
    fi

    BRANCH="night/issue-$NUM"
    log "--- Issue #$NUM: $TITLE"
    git -C "$DIR" checkout -B "$BRANCH" "origin/$DB" -q
    git -C "$DIR" clean -fdq

    local PROMPT="Risolvi questa GitHub issue. Lavora in modo autonomo e convergi: leggi i file rilevanti UNA volta sola, se un file necessario non esiste CREALLO subito (non cercarlo ripetutamente), scrivi le modifiche, esegui i test se presenti, poi termina. Modifica solo i file strettamente necessari. Se una cartella è dichiarata specchio o sola lettura (le cartelle specchio dichiarate dalla repo), non scriverci MAI. Rispetta le convenzioni di commit del repo.

Issue #$NUM: $TITLE

$BODY"

    # NESSUN LIMITE DI TEMPO (decisione 2026-08-21). cd nel subshell: dentro la repo.
    ( cd "$DIR" && opencode run --model "$OCPROVIDER" "$PROMPT" ) >> "$LOG" 2>&1
    local OP_RC=$?
    pkill -f "opencode run" 2>/dev/null

    if [ "$OP_RC" -ne 0 ]; then
      log "Issue #$NUM: OpenCode fallito, skip"
      FAIL_PREC=$(gh issue view "$NUM" -R "$REPO" --json comments -q '[.comments[].body | select(test("esecuzione fallita"))] | length' 2>/dev/null || echo 0)
      if [ "${FAIL_PREC:-0}" -ge 1 ]; then
        gh issue comment "$NUM" -R "$REPO" --body "🌙 Turno di notte: esecuzione fallita per la $((FAIL_PREC+1))ª volta. Regola dell'A/B: due fallimenti notturni = territorio da giorno — valuta di passarla al giorno (Claude/GLM la chiudono in minuti)." >/dev/null 2>&1
      else
        gh issue comment "$NUM" -R "$REPO" --body "🌙 Turno di notte: esecuzione fallita (vedi log locale). Riproverà alla prossima esecuzione." >/dev/null 2>&1
      fi
      FAILED=$((FAILED+1)); continue
    fi

    if git -C "$DIR" diff --quiet && [ -z "$(git -C "$DIR" status --porcelain)" ]; then
      log "Issue #$NUM: nessuna modifica prodotta, skip"
      FAILED=$((FAILED+1)); continue
    fi

    git -C "$DIR" add -A
    git -C "$DIR" commit -q -m "$CTYPE: night issue #$NUM — $TITLE" || { log "Issue #$NUM: commit fallito"; FAILED=$((FAILED+1)); continue; }
    git -C "$DIR" push -q -u origin "$BRANCH" || { log "Issue #$NUM: push fallito"; FAILED=$((FAILED+1)); continue; }

    local PR_URL
    PR_URL=$(gh pr create -R "$REPO" --draft --base "$DB" --head "$BRANCH" \
      --title "night: $TITLE" \
      --body "PR bozza dal turno di notte (Qwen3.8-27B locale via AI_Programmer).

Closes #$NUM al merge. La keyword resta INGLESE: GitHub non auto-chiude con le traduzioni.

## Da verificare al gate del mattino
- [ ] La modifica fa ciò che chiede l'issue
- [ ] Nessun effetto collaterale fuori scope
- [ ] Verifiche dichiarate della repo passano
- [ ] Banco avversariale (morning-gate) senza smentite" 2>/dev/null) || { log "Issue #$NUM: creazione PR fallita"; FAILED=$((FAILED+1)); continue; }

    gh issue comment "$NUM" -R "$REPO" --body "🌙 Turno di notte completato: PR bozza pronta per il gate del mattino → $PR_URL" >/dev/null 2>&1
    log "Issue #$NUM: PR creata → $PR_URL"
    PR_CREATED=$((PR_CREATED+1))
    git -C "$DIR" checkout main -q
  done

  log "REPO $REPO FINITA: $PR_CREATED PR bozza, $FAILED fallite"
}

# --- Esecuzione -----------------------------------------------------------------
log "=== TURNO INIZIATO (${#REPO_LIST[@]} repo in coda) ==="
GLOBAL_RC=0
for ENTRY in "${REPO_LIST[@]}"; do
  shift_repo "$ENTRY" || GLOBAL_RC=1
done
log "=== TURNO FINITO ==="
exit $GLOBAL_RC
