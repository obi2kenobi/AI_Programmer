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
#   - WATCHDOG per-issue (Luca, 2026-08-31): TIMEOUT_MINUTI default 240, override con NIGHT_SHIFT_TIMEOUT. Il no-limit è costato 3 notti.
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
# log() PRIMA di qualunque uso: il self-pull qui sotto la chiamava quando ancora
# non esisteva e il messaggio finiva a /usr/bin/log di macOS ("Unknown subcommand"),
# né console né $LOG — l'esito dell'aggiornamento dell'hub era INVISIBILE.
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }
rotate_log_if_big "$LOG"

# 2026-08-29 (dal campo): la copia operativa era 5 commit indietro e la notte ha
# girato col metodo stantio. Il turno si aggiorna DA SOLO prima di partire:
# l'hub è un repo git, pull --ff-only (mai merge automatici nel turno).
if git -C "$HERE" pull -q --ff-only >/dev/null 2>&1; then
  log "Hub aggiornato all'ultimo metodo prima del turno"
else
  log "ATTENZIONE: hub non aggiornabile (pull --ff-only fallito) — il turno gira col metodo che c'e'"
fi
WORK="$HOME/night-shift-work"
MODEL_TAG="qwen2.5-coder:14b"
OCPROVIDER="ollama/$MODEL_TAG"
DEFAULT_TYPE="chore"

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
  # E-002 (4a ricorrenza, 2026-09-04): curl | grep -q sotto pipefail — grep esce al
  # match, curl prende SIGPIPE, la sonda boccia un server sano. Cattura prima.
  local RISPOSTA
  RISPOSTA=$(curl -sf --max-time 120 http://localhost:11434/api/chat -d \
    "{\"model\":\"$MODEL_TAG\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"stream\":false,\"think\":false,\"options\":{\"num_ctx\":2048}}") \
    && grep -q '"content":"' <<<"$RISPOSTA"
}

ensure_server || { log "ERRORE: server Ollama non disponibile"; exit 1; }
# (2026-09-03: launchd ha PATH=/usr/bin:/bin — ollama sta in ~/.local/bin o /opt/homebrew/bin.
# Il turno partiva e moriva in 4 secondi col/modello assente" perché non LO TROVAVA, non perché
# mancasse. PATH esteso prima di qualunque comando ollama.)
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
# E-002 (4a ricorrenza, 2026-09-04): ollama list | grep -q sotto pipefail ha bocciato
# il turno alle 23:00 del 3/9 CON il modello presente e trovato (grep -q esce al match,
# ollama list prende SIGPIPE, rc 141, pipefail). Cattura prima, confronta poi.
LISTA_MODELLI=$(ollama list 2>/dev/null)
grep -q "$MODEL_TAG" <<<"$LISTA_MODELLI" || { log "ERRORE: modello $MODEL_TAG assente (ollama pull $MODEL_TAG)"; exit 1; }
# Finding #3 (2026-08-21): opencode orfani di ore rubano il modello e inquinano i turni.
# Il turno È l'unico proprietario legittimo di "opencode run" mentre gira: si ripulisce prima.
pkill -f "opencode run" 2>/dev/null && log "Puliti processi opencode orfani" && sleep 2 || true

if ! probe; then
  log "Sonda fallita: riavvio server (errori Metal dopo lunga vita)..."
  # Finding #4 (2026-08-21): il server è di LAUNCHD (KeepAlive) — se lo killiamo e ne
  # avviamo uno nostro, lui resuscita e ci contende la porta: si perde la gara entrambi.
  # Strategia: se l'agente esiste, KICKSTART a lui e si aspetta la sua resurrezione;
  # solo senza agente (altre macchine) si avvia un'istanza propria.
  AGENTI_ATTIVI=$(launchctl list 2>/dev/null)
  if grep -q "ollama" <<<"$AGENTI_ATTIVI"; then
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
  # bug reale (revisione 14 lenti, 2026-08-28): `mkdir -p` non fallisce mai se la directory
  # esiste già — il vecchio controllo "-d && età" sopra era comunque non atomico (finestra
  # fra il test e la creazione), ma la vera falla era qui: due processi in corsa passavano
  # entrambi il controllo ed entrambi "acquisivano" il lock. Riprodotto dal vivo. `mkdir`
  # semplice (senza -p) è l'idioma standard per un lock atomico a directory: fallisce con
  # EEXIST se un altro processo l'ha già creata un istante prima.
  if ! mkdir "$LOCK" 2>/dev/null; then
    if [ -d "$LOCK" ] && [ $(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) )) -ge 43200 ]; then
      log "REPO $REPO: lock scaduto (>12h), rimosso"
      rmdir "$LOCK" 2>/dev/null
      mkdir "$LOCK" 2>/dev/null || { log "REPO $REPO: lock attivo di un altro turno, salto"; return 0; }
    else
      log "REPO $REPO: lock attivo di un altro turno, salto"
      return 0
    fi
  fi
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
  # giro 8/10 (set 2 "capacità di progettare"): proposta mai implementata di
  # docs/test-processo-2026-08-21.md ("il turno scrive nel log l'esito-fase
  # design-linked: sì/no — il dato per misurare se il miglioramento funziona").
  # Conta quante issue saltano per Design/Territorio insufficiente in questo turno.
  local SKIPPED_DESIGN=0
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
    #
    # bug reale (dogfooding, set 2 "capacità di progettare", 2026-08-22): i controlli di
    # ASSENZA (sotto) stavano DOPO quelli di QUALITÀ (sopra) — quando una sezione manca
    # del tutto, la sua estrazione awk produce stringa vuota, che il controllo di qualità
    # intercetta SEMPRE per primo (lunghezza 0 < 80, o nessun pattern file trovato in
    # stringa vuota) con un messaggio meno preciso ("troppo povera" invece di "assente").
    # I due commenti dedicati "manca la sezione" non sono MAI arrivati a un operatore
    # reale — verificato con simulazione. Ordine corretto: assenza prima, qualità dopo.
    if ! grep -q "^## Territorio" <<<"$BODY"; then
      log "Issue #$NUM: SENZA sezione ## Territorio — il processo la richiede, skip con commento"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: manca la sezione \`## Territorio\` (quanto codice serve leggere). La lezione dell'11 ore: la notte converge solo su territori piccoli e indicati — dichiara il territorio, o se è grande assegnala al giorno." >/dev/null 2>&1
      SKIPPED_DESIGN=$((SKIPPED_DESIGN+1)); continue
    fi

    if ! grep -q "^## Design" <<<"$BODY"; then
      log "Issue #$NUM: SENZA sezione ## Design — il processo la richiede, skip con commento"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Il turno di notte salta questa issue: manca la sezione \`## Design\` (anche solo un link o tre righe di ratio). Il processo di AI_Programmer richiede che ogni commessa dichiar il suo design prima del lavoro — aggiungila e la prossima notte riparte." >/dev/null 2>&1
      SKIPPED_DESIGN=$((SKIPPED_DESIGN+1)); continue
    fi

    DESIGN_RAW=$(printf '%s' "$BODY" | awk '/^## Design/{f=1;next} /^## /{f=0} f')
    DESIGN_BODY=$(printf '%s' "$DESIGN_RAW" | tr -d '[:space:]')
    if [ "${#DESIGN_BODY}" -lt 80 ]; then
      log "Issue #$NUM: sezione ## Design troppo povera (${#DESIGN_BODY} char < 80) — serve il DA DOVE (SAL, analisi, riferimento)"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: la sezione \`## Design\` è troppo povera (${#DESIGN_BODY} caratteri utili). Il design dichiara da dove nasce la commessa (link al SAL, all'analisi, o tre righe di ratio sostanziale)." >/dev/null 2>&1
      SKIPPED_DESIGN=$((SKIPPED_DESIGN+1)); continue
    fi
    # bug reale (dogfooding, set 2 "capacità di progettare"): la sola lunghezza è una
    # soglia bucabile con prosa di riempimento senza alcun DA-DOVE reale — verificato dal
    # vivo con una frase di 87 caratteri, nessun link/SAL/issue/file, che passava il gate.
    # Stesso pattern citazione-non-presidio già chiuso altrove nel repo (privacy-check.sh,
    # segreto-come-impronta): una lunghezza non è una fonte. Richiede almeno UN riferimento
    # verificabile (URL, link markdown, SAL.md, un'issue #N, o un percorso di file).
    if ! grep -qiE 'https?://|\[[^]]+\]\([^)]+\)|SAL(\.md)?\b|(issue|pr|#)[[:space:]]*#?[0-9]+|\.[a-z]{2,4}\b' <<<"$DESIGN_RAW"; then
      log "Issue #$NUM: ## Design senza un riferimento reale (link/SAL/issue/file) — solo prosa di riempimento"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: la sezione \`## Design\` è lunga ma non cita nulla di verificabile (un link, \`SAL.md\`, un'issue \`#N\`, o un file). Il DA-DOVE deve poter essere controllato da chi legge, non solo affermato." >/dev/null 2>&1
      SKIPPED_DESIGN=$((SKIPPED_DESIGN+1)); continue
    fi
    TERR_BODY=$(printf '%s' "$BODY" | awk '/^## Territorio/{f=1;next} /^## /{f=0} f')
    if ! grep -qE '\.[a-z]{2,4}\b|file|riga|documento|md\b' <<<"$TERR_BODY"; then
      log "Issue #$NUM: ## Territorio senza file/righe nominate — il territorio si dichiara con precisione"
      gh issue comment "$NUM" -R "$REPO" --body "🌙 Saltata: la sezione \`## Territorio\` non nomina file, righe né documenti. Il territorio si dichiara con precisione (file e dimensione) — altrimenti il lavoro va al giorno." >/dev/null 2>&1
      SKIPPED_DESIGN=$((SKIPPED_DESIGN+1)); continue
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

    # gap reale (dogfooding, set 3 "flusso delle idee", 2026-08-22): il prompt parlava di
    # "cartelle specchio dichiarate dalla repo" ma non esisteva NESSUN file/convenzione con
    # cui una repo potesse dichiararle — citazione senza presidio, identica nello spirito a
    # /design-doc prima del Set 2. Convenzione minima: .night-mirror nella repo, una
    # cartella per riga (stesso formato di .night-verify). Se presente, le cartelle vengono
    # elencate DAVVERO nel prompt (non solo evocate in astratto); se assente, la frase sulle
    # cartelle specchio non viene nemmeno scritta — non ha senso menzionare un vincolo che
    # per questa repo non esiste.
    MIRROR_NOTE=""
    if [ -f "$DIR/.night-mirror" ]; then
      MIRROR_LIST=$(grep -vE '^\s*#|^\s*$' "$DIR/.night-mirror" | tr '\n' ',' | sed 's/,$//')
      [ -n "$MIRROR_LIST" ] && MIRROR_NOTE=" Cartelle specchio/sola lettura DICHIARATE da questa repo (.night-mirror), non scriverci MAI: $MIRROR_LIST."
    fi
    local PROMPT="Risolvi questa GitHub issue in MODO INCREMENTALE. REGOLA ANTI-LOOP (4 notti perse così — NON ignorarla):

1. NON rileggere un file che hai già letto in questa sessione. Se hai la lista delle funzioni, lavori da quella.
2. Dopo al massimo TRE letture di file, SMETTI di leggere e INIZIA A SCRIVERE. Anche sbagliato: si corregge dopo, ma si scrive.
3. Il piano NON si riscrive: se l'hai già formulato una volta, vai al passo di scrittura successivo.
4. Se dopo 5 minuti non hai scritto NESSUNA riga di codice, qualcosa è rotto: scrivi la modifica più piccola possibile (anche una riga) per sbloccarti, poi continua da lì.
5. NON rieseguire grep che hai già fatto. Se hai trovato le funzioni, usale.

Se ti accorgi di essere in loop (stesso pensiero, stessa lettura, nessuna scrittura): FERMA TUTTO, scrivi UNA riga di commento nel file target che dice cosa stavi per fare, e termina con esito 'loop-dichiarato'. Meglio una riga scritta che dieci ore di lettura.

Lavora in modo autonomo e convergi. Modifica solo i file strettamente necessari.$MIRROR_NOTE Rispetta le convenzioni di commit del repo.

Issue #$NUM: $TITLE

$BODY"

    # DAL 2026-09-02: risolutore SENZA agente (risolvi-issue.sh) — 20 test: 10/10
    # convergono col 14B coder (17s medi) contro 0/10 con opencode (loop infinito).
    # Il problema non era il modello: era l'agente. Questo script chiama Ollama
    # direttamente, il modello risponde col codice, lo script lo applica e verifica.
    NIGHT_SOLVER="${HERE}/risolvi-issue.sh"
    if [ -f "$NIGHT_SOLVER" ]; then
      log "Issue #$NUM: risolutore senza agente (risolvi-issue.sh)"
      # scarica l'issue in un file locale per lo script
      ISSUE_FILE="/tmp/night-issue-$NUM.md"
      printf '%s\n' "$BODY" > "$ISSUE_FILE"
      OUT=$(NIGHT_MODEL="${NIGHT_MODEL:-qwen2.5-coder:14b}" bash "$NIGHT_SOLVER" "$DIR" "$ISSUE_FILE" 2>&1)
      RC=$?
      log "Issue #$NUM: $OUT"
      if [ $RC -eq 0 ]; then
        # il fix è applicato: commit e push
        ( cd "$DIR" && git add -A && git commit -qm "$TIPO: issue #$NUM — $TITLE (risolvi-issue.sh, modello locale)" && git push -q origin "$BRANCH" 2>&1 | tail -1 )
        log "Issue #$NUM: fix committato e pushato"
        PR_URL=$(cd "$DIR" && gh pr create --fill 2>&1 | tail -1)
        log "Issue #$NUM: PR $PR_URL"
      else
        log "Issue #$NUM: risolutore non ha converto (rc=$RC) — si passa oltre"
      fi
      rm -f "$ISSUE_FILE"
      continue
    fi

    # WATCHDOG PER-ISSUE (decisione di Luca, 2026-08-31 — DEBITI saldato). Il no-limit
    # (2026-08-21) è costato 3 notti (28-30/8: loop da 59h, job vivo che blocca launchd)
    # e oggi sta bruciando ancora. Il watchdog è il pattern watchdog-guardato applicato
    # al turno stesso: l'agente ha TIMEOUT_MINUTI (default 240 = 4h), la review del
    # mattino resta l'appello. NON è un limite alla qualità: è il limite al loop.
    TIMEOUT_MINUTI="${NIGHT_SHIFT_TIMEOUT:-240}"
    ( cd "$DIR" && opencode run --model "$OCPROVIDER" "$PROMPT" ) >> "$LOG" 2>&1 &
    AGENTE_PID=$!
    ( sleep $((TIMEOUT_MINUTI * 60)); kill $AGENTE_PID 2>/dev/null && log "⚠ issue #$NUM: WATCHDOG scattato a ${TIMEOUT_MINUTI}min — ucciso, il piano nel log resta la ripartenza" ) &
    WATCHDOG_PID=$!
    wait $AGENTE_PID 2>/dev/null
    RC=$?
    kill $WATCHDOG_PID 2>/dev/null || true
    if [ $RC -ne 0 ] && ! kill -0 $AGENTE_PID 2>/dev/null; then
      # il watchdog l'ha ucciso (o è morto da sé): si passa alla issue successiva, il turno NON si blocca
      log "⚠ issue #$NUM: agente terminato (rc=$RC) — si passa oltre, il piano è nel log"
    fi

    # Rilevatore di loop-di-riletture (notti 28/8 e 31/8: il prompt anti-loop da solo
    # NON basta — il modello lo ignora e rilegge le stesse finestre per ore).
    # DUE firme post-run: (a) righe consecutive identiche, (b) la stessa finestra
    # di Read ripetuta più di 10 volte (la firma reale del 31/8: offset=655 ripetuto 21 volte).
    local CODA NREP WINS
    CODA=$(tail -40 "$LOG" | grep -vE '^[[:space:]]*$' | uniq -c | sort -rn | head -1)
    NREP=$(echo "$CODA" | awk '{print $1}')
    # firma (b): la stessa finestra Read ripetuta oltre 10 volte in tutta la sessione
    WINS=$(grep -a "Read " "$LOG" | grep -oE "offset=[0-9]+, limit=[0-9]+" | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
    if [ "${NREP:-0}" -ge 3 ] || [ "${WINS:-0}" -gt 10 ]; then
      log "⚠ issue #$NUM: LOOP DI RIPLETTURA rilevato ($NREP ripetizioni consecutive senza esecuzione) — issue lasciata aperta; il piano già scritto nel log è il punto di ripartenza, non un punto da rifare"
      echo "$(date '+%Y-%m-%d'),$(repo_code "$REPO"),#$NUM,#$NUM,loop-rilettura,—," >> "${HUB_METRICS:-/dev/null}" 2>/dev/null || true
    fi
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
    # bug reale (revisione 14 lenti, 2026-08-28): "main" hardcoded nonostante SAL.md
    # dichiarasse chiuso il refactor "§2.2 main hardcoded in 6 punti" — restava questo
    # settimo punto. Su un repo con default branch diverso da "main" falliva silenziosamente
    # (nessun ||, niente -e) e lasciava $DIR checked-out sull'ultimo branch night/issue-N.
    git -C "$DIR" checkout "$DB" -q
  done

  # bug reale (dogfooding, nuovo ciclo 10 giri): PR_CREATED/FAILED sono `local` a
  # questa funzione — una volta finita, spariscono. Il SAL scritto dopo il for
  # più sotto li leggeva vuoti ad OGNI turno reale (verificato con simulazione:
  # una variabile local non esiste più fuori dalla funzione che l'ha dichiarata).
  # Si aggregano qui nei contatori globali, prima che il contesto locale sparisca.
  TOT_PR_CREATED=$((TOT_PR_CREATED+PR_CREATED))
  TOT_FAILED=$((TOT_FAILED+FAILED))
  TOT_SKIPPED_DESIGN=$((TOT_SKIPPED_DESIGN+SKIPPED_DESIGN))
  log "REPO $REPO FINITA: $PR_CREATED PR bozza, $FAILED fallite, $SKIPPED_DESIGN saltate per Design/Territorio"
}

# --- Esecuzione -----------------------------------------------------------------
log "=== TURNO INIZIATO (${#REPO_LIST[@]} repo in coda) ==="
GLOBAL_RC=0
TOT_PR_CREATED=0
TOT_FAILED=0
TOT_SKIPPED_DESIGN=0
for ENTRY in "${REPO_LIST[@]}"; do
  shift_repo "$ENTRY" || GLOBAL_RC=1
done
log "=== TURNO FINITO ==="

# Giro 9/10: il turno scrive il proprio SAL nel hub (la memoria non dipende da chi ricorda)
HUB_SAL="$HERE/SAL.md"
if [ -f "$HUB_SAL" ]; then
  DT=$(date '+%Y-%m-%d')
  cat >> "$HUB_SAL" <<SALEOF

### $DT, turno automatico — $TOT_PR_CREATED PR create, $TOT_FAILED fallite, $TOT_SKIPPED_DESIGN saltate per Design/Territorio insufficiente

$(grep -aE "^\[|^--- Issue|^===== REPO" "$LOG" | tail -20 | sed 's/^/  /')
SALEOF
  log "SAL del hub aggiornato con l'esito del turno"
fi

exit $GLOBAL_RC
