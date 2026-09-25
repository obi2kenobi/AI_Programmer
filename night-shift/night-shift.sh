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
#     Guardia anti-loop: ferma_opencode_del_turno (lib.sh) ferma il SUO opencode e libera il Mac (R5 R6).
#   - keyword inglese "Closes #N" (l'italiana non auto-chiude le issue al merge)
#   - git clean per issue (un fallimento non lascia rifiuti al commit successivo)
#
# repos.conf: una riga per repo, "owner/repo [tipo_commit]" — LOCALE e gitignored.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# (test dei 30 minuti, 2° giro — mistero n.1 RISOLTO): launchd parte con cwd=/ e i test,
# le sonde e i glob del turno assumono la RADICE del repo come cwd ('night-shift/*.sh'
# letterale, porte introvabili, gate rosso con 3 falsi difetti). Il turno DICHIAARA la
# sua radice e ci si porta: tutti i processi figli la ereditano.
cd "$HERE/.." || exit 1
source "$HERE/lib.sh"
# ai_timeout: wrapper portabile (macOS non ha timeout(1)) — vive in llm/_timeout.sh
# shellcheck source=../../llm/_timeout.sh
source "$HERE/../llm/_timeout.sh" 2>/dev/null || true
CONF="$HERE/repos.conf"
LOG="$HOME/night-shift.log"
# log() PRIMA di qualunque uso: il self-pull qui sotto la chiamava quando ancora
# non esisteva e il messaggio finiva a /usr/bin/log di macOS ("Unknown subcommand"),
# né console né $LOG — l'esito dell'aggiornamento dell'hub era INVISIBILE.
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }
rotate_log_if_big "$LOG"

# --- Lock GLOBALE del turno (2026-09-15, finestra oraria; Q10, 2026-09-23, giro A5 della notte):
# si prende PRIMA di tutto. Stava dopo il self-pull (reset --hard dell'hub sotto il turno vivo)
# e dopo il pkill degli opencode (l'agente del turno vivo): il turno manuale accanto a quello
# delle 23:00 faceva il danno e solo dopo usciva. Il lock porta il PID e resta preso attraverso
# l'exec di fine ciclo (stesso PID): nessuna finestra fra un ciclo e il successivo. Regole in lib.sh
# prendi_lock_turno (testata in tests/test-lib.sh).
TURN_LOCK="$HOME/night-shift-work/.lock-turno"
mkdir -p "$HOME/night-shift-work"
if ! prendi_lock_turno "$TURN_LOCK"; then
  log "turno precedente ancora vivo (PID $(cat "$TURN_LOCK/pid" 2>/dev/null || echo '?')): questo avvio saluta ed esce, senza toccare nulla"
  exit 0
fi
trap 'rm -rf "$TURN_LOCK"' EXIT

# 2026-08-29 (dal campo): la copia operativa era 5 commit indietro e la notte ha
# girato col metodo stantio. Il turno si aggiorna DA SOLO prima di partire:
# l'hub è un repo git: fetch + reset --hard sul main remoto (mai merge automatici nel
# turno — la copia operativa non ha lavoro proprio da preservare; era «pull --ff-only»).
# (audit-3, 2026-09-23): il turno PARTE SEMPRE DA MAIN. Stanotte la copia viva
# e' rimasta parcheggiata su un ramo di probe (un test esterno ricorrente che
# committa e spinge): il self-pull seguiva il ramo e il turno girava col codice
# vecchio per ore. Ora: qualunque ramo trovi, torna a main e si allinea —
# dichiarando se ha dovuto scalare qualcosa.
# (2026-09-24, R5 R1): il reset nudo buttava il lavoro del giorno; allinea_hub (lib.sh) lo mette da parte e lo dice
allinea_hub "$HERE" 2>&1 | while IFS= read -r l; do log "self-pull: $l"; done
log "$(ambiente_turno)"   # T3#6: bash, ramo di timeout, sandbox — le differenze Mac/Linux si leggono qui
# (studio deepseek-harness profiles, 2026-09-23): la configurazione del turno
# vive in UNA dichiarazione (profiles/notturno.conf) ricomposta a ogni ciclo —
# il nostro exec-per-ciclo e' un hot-reload gratis. I default nel codice sono
# fallback di emergenza, non la fonte.
if [ -f "$HERE/../tools/profilo.sh" ]; then
  . "$HERE/../tools/profilo.sh" notturno
fi
WORK="$HOME/night-shift-work"
MODEL_TAG="${MODELLO:-qwen3.8-27b:iq3s}"
OCPROVIDER="ollama/$MODEL_TAG"
DEFAULT_TYPE="chore"

# --- La lista delle repo -------------------------------------------------------
REPO_LIST=()
if [ $# -gt 0 ]; then
  for a in "$@"; do REPO_LIST+=("$a"); done
else
  [ -f "$CONF" ] || { echo "uso: night-shift.sh owner/repo ... — oppure crea $CONF (vedi repos.conf.example)" >&2; exit 1; }
  # Formato: owner/repo [tipo] — (la cadenza del terzo campo e' stata rimossa
  # l'2026-09-23, audit: rami orfani, mai alimentati, non documentati)
  while IFS= read -r line; do
    line="${line%%#*}"; [ -z "$(echo "$line" | tr -d '[:space:]')" ] && continue
    CAD=$(echo "$line" | awk '{print $3}')
    ENTRY=$(echo "$line" | awk '{print $1, $2}')
    case "$CAD" in
      ""|giornaliera) REPO_LIST+=("$ENTRY") ;;
      # (audit 2026-09-23: i rami 'settimanale' e 'lun|mar|...' rimossi sopra:
      # il terzo campo cadenza non esiste in nessun repos.conf — ramificazione
      # orfana. Resta l'avviso per i casi sconosciuti.)
      *) log "ATTENZIONE: cadenza '$CAD' sconosciuta in '$ENTRY', la salto" ;;
    esac
  done < "$CONF"
fi
[ "${#REPO_LIST[@]}" -eq 0 ] && { echo "nessuna repo configurata" >&2; exit 1; }

# --- Sonda di salute del server Ollama -----------------------------------------
ensure_server() {
  curl -sf --max-time 3 http://localhost:11434/api/version >/dev/null 2>&1 && return 0
  log "Avvio server Ollama..."
  OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_CONTEXT_LENGTH=16384 OLLAMA_KEEP_ALIVE=-1 \
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
  # (2026-09-21, iq3s 12GB): il caricamento a freddo supera i 120s — la sonda
  # uccideva un server sano a meta' caricamento (due volte di fila: turno morto).
  RISPOSTA=$(curl -sf --max-time "${SONDA_SEC:-240}" http://localhost:11434/api/chat -d \
    "{\"model\":\"$MODEL_TAG\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"stream\":false,\"think\":false,\"keep_alive\":-1,\"options\":{\"num_ctx\":2048}}") \
    && grep -q '"content":"' <<<"$RISPOSTA"
}

# (2026-09-22, la notte delle 11 ore buie): un wedge alle 23:05 ha fatto fallire
# la sonda due volte di fila e il turno e' USCITO per sempre — nessuno lo
# riportava su fino al mattino. Contraddizione col nostro stesso credo: il
# watchdog di ciclo accetta di girare senza cervello e dichiararlo, ma la
# sonda d'avvio ammazzava il turno. Ora si riprova: sei round con pause di
# cinque minuti (mezz'ora di pazienza) prima di arrendersi. Un wedge vero
# passa; un server morto per sempre e' un'altra malattia, e si dichiara.
SERVER_ROUND=0
until ensure_server; do
  SERVER_ROUND=$((SERVER_ROUND+1))
  if [ "$SERVER_ROUND" -ge "${SONDA_ROUND:-6}" ]; then
    # (Q12, 2026-09-23): qui c'era `exit 1` con la promessa «il prossimo ciclo riprovera'» — ma il
    # plist parte alle 23:00 e non ha KeepAlive: nessuno riportava il turno fino alla sera dopo.
    # Il ciclo riparte da capo (stesso PID: il lock resta suo), e il log lo dice.
    log "ERRORE: server Ollama sordo dopo $SERVER_ROUND round (30 minuti) — riparto da capo fra 5 minuti (nessun launchd mi riporterebbe prima delle 23:00)"
    sleep 300
    exec bash "$HERE/night-shift.sh" "$@"
  fi
  log "⚠ server non visto (round $SERVER_ROUND/${SONDA_ROUND:-6}): attendo 5 minuti e riprovo — non esco per un wedge transitorio"
  sleep 300
done
# (2026-09-03: launchd ha PATH=/usr/bin:/bin — ollama sta in ~/.local/bin o /opt/homebrew/bin.
# Il turno partiva e moriva in 4 secondi col/modello assente" perché non LO TROVAVA, non perché
# mancasse. PATH esteso prima di qualunque comando ollama.)
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
# (2026-09-24, quarto ventaglio, Q2 R2): senza jq il ping di generazione restava vuoto, il turno scriveva
# «Ollama wedged» e rianimava (pkill) un server sano, a ogni ciclo; «jq: command not found» finiva solo nel
# console log di launchd. Gli attrezzi si controllano prima di qualunque diagnosi (dopo il PATH esteso).
if MANCANO=$(dipendenze_mancanti jq curl python3 git); then :; else
  log "⛔ MANCA $MANCANO: il turno non parte — ogni diagnosi (Ollama, suite, PR) sarebbe falsa"; exit 1
fi
# (2026-09-15, dall'auto-esame): senza LANG/LC_ALL, il git di Apple rifiuta \x{4E00}
# in git grep -P («code point too large»): il controllo glifi false-verdava in tutto
# il banco notturno. Il locale e' parte dell'ambiente di verita', non un orpello.
export LANG="${LANG:-en_US.UTF-8}" LC_ALL="${LC_ALL:-en_US.UTF-8}"
# E-002 (4a ricorrenza, 2026-09-04): ollama list | grep -q sotto pipefail ha bocciato
# il turno alle 23:00 del 3/9 CON il modello presente e trovato (grep -q esce al match,
# ollama list prende SIGPIPE, rc 141, pipefail). Cattura prima, confronta poi.
LISTA_MODELLI=$(ollama list 2>/dev/null)
grep -qi "$MODEL_TAG" <<<"$LISTA_MODELLI" || { log "ERRORE: modello $MODEL_TAG assente (ollama pull $MODEL_TAG)"; exit 1; }
# Finding #3 (2026-08-21): opencode orfani di ore rubano il modello e inquinano i turni.
# Il turno È l'unico proprietario legittimo di "opencode run" mentre gira: si ripulisce prima.
# (2026-09-24, quinto ventaglio, R5 R6): ma solo del SUO — `pkill -f "opencode run"` uccideva anche quello del
# giorno. Il PID lo scrive il ramo opencode qui sotto; l'orfano vero di un turno morto e' il file rimasto.
OPENCODE_PID_FILE="$WORK/.opencode-turno.pid"
ferma_opencode_del_turno "$OPENCODE_PID_FILE" && log "Puliti processi opencode orfani (del turno: il PID nel file)" && sleep 2 || true

# (2026-09-22, seconda metà della cura dopo le 11 ore buie): ANCHE questa sonda
# di generazione uccideva il turno al secondo colpo (23:09, 10:24) — l'exit a
# riga 153 scavalca la pazienza messa su ensure_server. Stessa medicina: sei
# round con pause di cinque minuti. Un wedge vero passa.
PROBE_ROUND=0
while ! probe; do
  PROBE_ROUND=$((PROBE_ROUND+1))
  if [ "$PROBE_ROUND" -ge "${SONDA_ROUND:-6}" ]; then
    # (Q12): il log prometteva che KeepAlive l'avrebbe riportato — il plist non ce l'ha. Si riparte da capo.
    log "ERRORE: server sordo dopo $PROBE_ROUND round di sonda (30 minuti) — riparto da capo fra 5 minuti (nessun launchd mi riporterebbe prima delle 23:00)"
    sleep 300
    exec bash "$HERE/night-shift.sh" "$@"
  fi
  log "⚠ Sonda di generazione muta (round $PROBE_ROUND/${SONDA_ROUND:-6}): riavvio server e attendo 5 minuti — un wedge transitorio passa, non esco per lui"
  # Finding #4 (2026-08-21): il server è di LAUNCHD (KeepAlive) — se lo killiamo e ne
  # avviamo uno nostro, lui resuscita e ci contende la porta: si perde la gara entrambi.
  # Strategia: se l'agente esiste, KICKSTART a lui e si aspetta la sua resurrezione;
  # solo senza agente (altre macchine) si avvia un'istanza propria.
  # (2026-09-24, V5 R4): la strategia vive in lib.sh rianima_ollama, l'unico gesto di riavvio
  rianima_ollama 2>&1 | while IFS= read -r l; do log "$l"; done
  sleep 300
done
[ "$PROBE_ROUND" -gt 0 ] && log "Server tornato a generare (dopo $PROBE_ROUND round di pazienza)"

# --- Il turno per una repo -----------------------------------------------------
shift_repo() {
  local ENTRY="$1" REPO="${1%% *}" CTYPE
  CTYPE=$(echo "$ENTRY" | awk '{print $2}'); [ -z "$CTYPE" ] && CTYPE="$DEFAULT_TYPE"
  log "===== REPO $REPO (commit: $CTYPE) ====="

  gh auth status >/dev/null 2>&1 || { log "ERRORE: gh non autenticato"; return 1; }

  # Lock per repo (finding #5, 2026-08-21): il turno manuale e quello delle 23:00 non si
  # pestano i piedi. (2026-08-28): mkdir semplice, atomico — `mkdir -p` non fallisce mai.
  # (2026-09-24, notte dei giri, T2#4): contava l'ETA' (12 h): dopo un kill -9 il turno riavviato
  # prendeva il lock globale e poi saltava la repo per 12 ore scrivendo «lock attivo di un altro
  # turno», che era falso. Ora la regola del lock globale: il PID dentro, vivo e del turno = occupato,
  # morto o di un altro programma = orfano, preso subito (prendi_lock_turno in lib.sh, testata).
  local LOCK="$WORK/.lock-${REPO//\//_}"
  if ! prendi_lock_turno "$LOCK"; then
    log "REPO $REPO: lock attivo di un altro turno vivo (PID $(cat "$LOCK/pid" 2>/dev/null || echo '?')), salto"
    return 0
  fi
  trap 'rm -rf "$LOCK"' RETURN

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
    # (E-027, 2026-09-16): il riclono HA CANCELLATO lo stato gitignored della coda
    # (repos.conf, repos.key, .sal-turni.md) — e quando il clone e' fallito, quello
    # stato era PERDUTO. Lo stato locale si SALVA prima del rm, si RIPRISTINA dopo.
    mkdir -p "$WORK/.state-salvate"
    for ST in repos.conf repos.key; do
      [ -f "$DIR/night-shift/$ST" ] && cp "$DIR/night-shift/$ST" "$WORK/.state-salvate/$ST"         && log "stato salvato prima del riclono: $ST"
    done
    [ -f "$DIR/night-shift/.sal-turni.md" ] && cp "$DIR/night-shift/.sal-turni.md" "$WORK/.state-salvate/"
    # (E-033, 2026-09-19): MAI rm prima di un clone verificato. Un blip di rete
    # di 30 secondi ha fatto fallire checkout/reset E clone nello stesso istante:
    # copia cancellata senza sostituta, processo morto sul exec (script file
    # inesistente), turno FERMO per 40 minuti (beccato da turno-vivo). Clone in
    # dir NUOVA, scambio solo al successo; se il clone fallisce la copia VECCHIA
    # resta — una copia stantia batte nessuna copia, e si riprova al prossimo giro.
    NUOVA="$DIR.nuova-$$"
    rm -rf "$NUOVA"
    if gh repo clone "$REPO" "$NUOVA" -- --depth=50 -q; then
      if [ "$(basename "$REPO")" = "AI_Programmer" ] && [ -d "$WORK/.state-salvate" ]; then
        for ST in repos.conf repos.key .sal-turni.md; do
          [ -f "$WORK/.state-salvate/$ST" ] && cp "$WORK/.state-salvate/$ST" "$NUOVA/night-shift/$ST" 2>/dev/null && log "stato ripristinato nel riclono: $ST"
        done
      fi
      rm -rf "$DIR" && mv "$NUOVA" "$DIR" && log "riclono riuscito: copia nuova al posto (scambio atomico)"
    else
      rm -rf "$NUOVA"
      log "⚠ riclone di $REPO fallito — RESTO sulla copia esistente (stantia ma viva), riprovo al prossimo giro"
    fi
  fi
  git -C "$DIR" config user.name  >/dev/null 2>&1 || git -C "$DIR" config user.name  "Night Shift"
  git -C "$DIR" config user.email >/dev/null 2>&1 || git -C "$DIR" config user.email "night-shift@localhost"

  local ISSUES COUNT
  # (2026-09-24, Q2 R5): «0 issue» e «non so» non sono la stessa cosa — con la coda illeggibile la repo si
  # salta in questo ciclo (niente caccia al posto delle commesse), e il log lo dice
  if ! ISSUES=$(leggi_coda "$REPO" 2>"$WORK/.coda-errore"); then
    log "⚠ TURNO su $REPO: coda ILLEGGIBILE ($(cat "$WORK/.coda-errore")) — non «0 issue»: la repo si salta in questo ciclo"
    return 0
  fi
  COUNT=$(echo "$ISSUES" | jq 'length')
  [ "$COUNT" -ge 50 ] && log "ATTENZIONE: limite 50 issue raggiunto in $REPO — possibile troncamento silenzioso (review §5)"
  log "TURNO su $REPO: $COUNT issue in coda"

  # (2026-09-15, domanda di Luca: «compiti per migliorare la notte») — SE LA REPO IN CODA
  # E' L'HUB STESSO (clone dello stesso origin), il turno si AUTO-ESAMINA: ciclo-vivo +
  # banco veloce girano sulla copia viva (gia' self-pullata), e ogni finding diventa una
  # issue aperta per il giorno — IDEMPOTENTE (issue aperta con lo stesso prefisso: niente
  # duplicate notte dopo notte). Il solver sa riparare JS/GAS, non i tool shell dell'hub:
  # la notte TROVA E SEGNALA, il giorno dispone. Mai il contrario.
  HUB_ORIGIN=$(git -C "$HERE" remote get-url origin 2>/dev/null || true)
  REPO_ORIGIN=$(git -C "$DIR" remote get-url origin 2>/dev/null || true)

  # AUTO-VERIFICA ESTESA (2026-09-16): OGNI repo con .night-verify viene esaminata
  # ogni ciclo. L'HUB fa auto-esame + auto-fix; le altre fanno girare i comandi
  # dichiarati, e ogni rosso diventa issue per il giorno. Estende il ragionamento
  # dell'auto-miglioramento a tutte le repo onboardate allo standard.
  if [ -f "$DIR/.night-verify" ]; then
    NV_ROSSI=0
    NV_TOTALI=0
    NV_ROSSI_LISTA=""   # i comandi rossi, per il corpo dell'issue (D16)
    NV_ROSSI_CMD=""     # (S1 R1): gli stessi, nudi, per il blocco da incollare
    # (2026-09-19, prima notte sul Magazzino): due FORMATI dichiarati. Il suo
    # .night-verify e' un PROGRAMMA di 505 righe (blocchi multi-riga, stato che
    # attraversa le righe): riga-per-riga non puo' girare, e non si riscrive
    # il lavoro altrui per comodita' del parser. Chi dichiara
    # `# FORMATO: script` nelle prime righe viene eseguito INTERO (una verifica,
    # budget 900s); senza marcatura resta riga-per-riga come sempre.
    if head -10 "$DIR/.night-verify" 2>/dev/null | grep -c "^# FORMATO: script" >/dev/null; then
      NV_TOTALI=1
      if (cd "$DIR" && ai_timeout 900 bash .night-verify >/dev/null 2>&1 </dev/null); then
        log "REPO $REPO: .night-verify (formato script): VERDE"
      else
        NV_ROSSI=1
        NV_ROSSI_LISTA=".night-verify intero (formato script)"
        log "REPO $REPO: VERIFICA ROSSA: .night-verify intero (formato script)"
      fi
    fi
    if [ "$NV_TOTALI" -eq 0 ]; then
    while IFS= read -r NV_CMD; do
      riga_verifica_vuota "$NV_CMD" && continue   # (V1 R5): anche spazi, TAB e commenti indentati
      # (E-029, seconda lezione): ogni riga ha budget 120s di default. La riga
      # puo' dichiararne uno suo con il prefisso `@<sec> ` — la suite completa
      # dura ~300s e con il budget standard moriva a meta' (era ROSSA stabile:
      # prima, da riga composta, sfuggiva al timeout per caso).
      NV_SEC=120
      case "$NV_CMD" in
        @*" "*) NV_SEC="${NV_CMD%% *}"; NV_SEC="${NV_SEC#@}"; NV_CMD="${NV_CMD#* }" ;;
      esac
      NV_TOTALI=$((NV_TOTALI+1))
      # (E-030): il loop legge da file redirect: il comando eredita quello
      # stdin e un test che legge stdin SI MANGIA le righe successive del file
      # (la suite completa a 420s lo faceva: sal-indice spariva, 5/6 dichiarate).
      # </dev/null: il comando non tocca MAI il file delle verifiche.
      # (2026-09-19, prima notte sulla repo del magazzino): la riga passa
      # a bash -c COME SCRIPT — i costrutti shell (for, prefissi d'ambiente,
      # assegnazioni) non sono comandi eseguibili e con ai_timeout anteposto
      # morivano tutti (16/45 rosse false). Il morning-gate faceva gia' cosi:
      # era il turno l'asimmetria. Niente eval: la riga e' UN argomento.
        # (V4#1, 2026-09-24): esegui_verifica (lib.sh) tiene l'uscita in un file del lavoro del turno e
        # distingue VERDE (con la durata: il margine sul budget si legge nel log), ROSSA e SFORO
        NV_OUT="$WORK/.night-verify-${REPO//\//_}-$NV_TOTALI.log"
        if NV_ESITO=$(esegui_verifica "$DIR" "$NV_SEC" "$NV_CMD" "$NV_OUT"); then
          log "REPO $REPO: verifica $NV_ESITO: $NV_CMD"
        else
          NV_ROSSI=$((NV_ROSSI+1))
          NV_ROSSI_CMD="${NV_ROSSI_CMD:+$NV_ROSSI_CMD
}$NV_CMD"
          NV_ROSSI_LISTA="${NV_ROSSI_LISTA:+$NV_ROSSI_LISTA
}$NV_CMD — $NV_ESITO"
          # «VERIFICA ROSSA:» resta il prefisso: dashboard.py e cervello-impara.sh lo cercano, anche per lo sforo
          log "REPO $REPO: VERIFICA ROSSA: $NV_CMD — $NV_ESITO (uscita in $NV_OUT)"
        fi
      done < "$DIR/.night-verify"
    fi
    # (report BusinessPlan): zero comandi dichiarati NON e' verde — l'assenza di
    # verifiche non si puo' confondere col loro successo. La forma piu' pura del
    # difetto che il metodo combatte.
    if [ "$NV_TOTALI" -eq 0 ]; then
      NV_ROSSI=1
      NV_ROSSI_LISTA="verifiche-vuote (.night-verify senza comandi)"
      log "REPO $REPO: VERIFICA ROSSA: verifiche-vuote (.night-verify senza comandi)"
    fi
    if [ "$NV_ROSSI" -gt 0 ]; then
      NV_ISSUE=$(gh issue list --limit 1000 -R "$REPO" --state open --json title -q '.[].title' 2>/dev/null || true)
      if ! grep -qF "[night-verify]" <<<"$NV_ISSUE"; then
        # (D16, test del sistema completo 2026-09-20): il corpo diceva «I dettagli sono nel
        # log del turno» — da remoto il giorno non poteva disporre (issue #95 aperta cosi'
        # dal 18/9). Il comando rosso va NEL corpo: e' l'unica cosa che serve per agire.
        gh issue create -R "$REPO" -t "[night-verify] $NV_ROSSI verifiche rosse nell'auto-esame" -b "Il turno notturno ha eseguito i comandi in .night-verify: $NV_ROSSI su $NV_TOTALI sono rossi.

Comandi rossi (eseguiti dalla radice della repo, budget 120s salvo prefisso @sec):
$(printf '%s\n' "$NV_ROSSI_LISTA" | sed 's/^/- `/; s/$/`/')
${NV_ROSSI_CMD:+
Per riprodurli, dalla radice della repo (ognuno gira in una shell figlia, come nel turno: una riga che finisce in \`exit\` non chiude il terminale):
$(comandi_da_incollare "$NV_ROSSI_CMD")
}
Correggere il comando o il codice che verifica, chiudere l'issue quando tornano verdi." >/dev/null 2>&1 \
          && log "REPO $REPO: issue [night-verify] aperta ($NV_ROSSI/$NV_TOTALI rossi)"
      else
        log "REPO $REPO: $NV_ROSSI/$NV_TOTALI rosse — issue gia' aperta"
      fi
    else
      log "REPO $REPO: .night-verify $NV_TOTALI/$NV_TOTALI verdi"
    fi
  fi

  # (2026-09-19, domanda di Luca: le installazioni di mesi fa danno problemi?):
  # SI' — il CLAUDE.md del Magazzino distava 37 righe, e i mirror divergono in
  # silenzio mentre l'hub aggiorna. Il turno ora MISURA il drift a ogni ciclo
  # (la salute si dichiara coi debiti E con l'allineamento) e, se divergente,
  # apre UNA sola PR di riallineo (--standard: mai push su main). Il CLAUDE.md
  # e' il canarino: cambia piu' spesso, la PR porta tutto lo standard.
  if [ -n "$HUB_ORIGIN" ] && [ "$HUB_ORIGIN" != "$REPO_ORIGIN" ] && [ -f "$HERE/../tools/sync-repo.sh" ]; then
    if bash "$HERE/../tools/sync-repo.sh" --from-local "$DIR" >/dev/null 2>&1; then
      log "REPO $REPO: standard: ALLINEATO all'hub"
    else
      log "REPO $REPO: standard: DIVERGENTE dall'hub — verifico se c'e' gia' una PR di riallineo"
      PR_SYNC=$(gh pr list --limit 1000 -R "$REPO" --state open --json title -q '.[].title' 2>/dev/null || true)
      if grep -qF "adotta lo standard" <<<"$PR_SYNC"; then
        log "REPO $REPO: PR di riallineo gia' aperta — aspetto il merge"
      else
        SYNC_OUT=$(bash "$HERE/../tools/sync-repo.sh" "$REPO" --standard 2>&1 | tail -1)
        # (D15, test del sistema completo 2026-09-20): il log diceva «PR di riallineo
        # aperta:» seguito da QUALUNQUE ultima riga — anche «impossibile leggere
        # CLAUDE.md». La PR e' aperta solo se sync-repo lo dice con la sua URL.
        case "$SYNC_OUT" in
          *"PR aperta https://"*) log "REPO $REPO: PR di riallineo aperta: $SYNC_OUT" ;;
          *"GIÀ A STANDARD"*)     log "REPO $REPO: riallineo: $SYNC_OUT" ;;
          *)                      log "⚠ REPO $REPO: riallineo NON riuscito (nessuna PR): $SYNC_OUT" ;;
        esac
      fi
    fi
  fi

  if [ -n "$HUB_ORIGIN" ] && [ "$HUB_ORIGIN" = "$REPO_ORIGIN" ]; then
    log "REPO $REPO: e' l'HUB — auto-esame notturno (ciclo-vivo + banco veloce)"
    CICLO_OUT=$(bash "$HERE/../tools/ciclo-vivo.sh" 2>&1 || true)
    N_FIND=$(echo "$CICLO_OUT" | grep -cE "^  · [A-Z]" || true)
    # (2026-09-16): il fixer ora LEGGE il ciclo-vivo, non solo la propria scansione.
    # I finding COLLEGAMENTO (livello 2) sono pattern non citati: stesso fix.
    # I finding FLUSSI/ARCHITETTURA (livelli 3-4) vengono contati e dichiarati:
    # la notte non li cura, ma non li nasconde nemmeno.
    if [ "$N_FIND" -gt 0 ]; then
      CICLO_LIV=$(echo "$CICLO_OUT" | grep -oE "Livello: [0-9]+" | head -1)
      CICLO_TIPI=$(echo "$CICLO_OUT" | grep -oE "COLLEGAMENTO|FLUSSO|ARCHITETTURA|META" | sort | uniq -c | tr '\n' ' ')
      log "REPO $REPO: ciclo-vivo $CICLO_LIV — $CICLO_TIPI (il fixer cura i COLLEGAMENTO, gli altri vanno all'issue)"
    fi
    # ── AUTO-MIGLIORAMENTO SICURO (2026-09-15, finestra 23-06) ────────────────
    # Solo fix MECCANICI DI CATEGORIA NOTA, su BRANCH, col banco che deve restare
    # CHIUSO: se qualcosa non torna, il branch si butta e resta l'issue. Mai main,
    # mai decisioni: la notte corregge le forme che conosce, il giorno dispone il resto.
    FIX_APPLICATI=0
    # la scansione e' DIRETTA (non attraverso il ciclo-vivo: il suo livello dipende
    # dagli streak e la lente dei collegamenti puo' non girare stasera — un fixer
    # che dipende da una lente che forse parte non e' un fixer)
    # (2026-09-24, terzo ventaglio, V1#4): era `$(… <<'PYSCAN' 2>/dev/null || true` — su bash 5.2 un errore
    # di sintassi A RUNTIME (bash -n passa), e l'auto-esame dell'hub moriva qui ogni notte saltando fixer,
    # banco, censore e caccia. La redirezione va prima dell'heredoc, e `|| true` fuori dalla sostituzione.
    NON_CITATI=$(cd "$DIR" && python3 - 2>/dev/null <<'PYSCAN'
import glob, os, re
# corpus ALLINEATO al dente (ciclo-vivo lente 2): references + agents. Le SKILL.md
# NON contano: la lente non le guarda, e un fixer che guarda piu' largo del dente
# non vede il finding che il dente vede (morso 5, 2026-09-15).
corpus = ""
for f in glob.glob('.claude/skills/gas-sviluppo/references/*.md') + glob.glob('.claude/agents/*.md'):
    corpus += open(f, errors='ignore').read()
for p in sorted(glob.glob('patterns/*.md')):
    base = os.path.basename(p)[:-3]
    if base != 'README' and '`' + base + '`' not in corpus:
        print(base)
PYSCAN
) || true
    if [ "$N_FIND" -gt 0 ] || [ -n "$NON_CITATI" ]; then
      BRANCH="notte/auto-$(date +%Y%m%d-%H%M)"
      if git -C "$DIR" checkout -b "$BRANCH" -q 2>/dev/null; then
        # fix 1: pattern mai citato dal canone → citazione nell'indice per tema del metodo
        for PAT in $NON_CITATI; do
          MET="$DIR/.claude/skills/gas-sviluppo/references/metodo.md"
          if [ -f "$DIR/patterns/$PAT.md" ] && ! grep -q "\`$PAT\`" "$MET"; then
            python3 - "$MET" "$PAT" <<'PYFIX'
import sys, re
met, pat = sys.argv[1], sys.argv[2]
s = open(met).read()
riga = "**Metodo e processo**:"
if riga in s:
    s = s.replace(riga, riga + " · `" + pat + "`", 1)
    open(met, "w").write(s)
    print("citato")
PYFIX
            if [ "$?" -eq 0 ] && grep -q "\`$PAT\`" "$MET"; then
              cp "$DIR/.claude/skills/gas-sviluppo/references/metodo.md" "$DIR/.opencode/skills/gas-sviluppo/references/metodo.md" 2>/dev/null || true
              log "REPO $REPO: auto-fix — pattern '$PAT' citato nell'indice del metodo (gemello .opencode sincronizzato)"
              FIX_APPLICATI=$((FIX_APPLICATI+1))
            fi
          fi
        done
        # fix 2: indice del SAL fermo → rigenerato.
        # (2026-09-18: prima lanciava giri-ignoranti.sh completo (3 minuti!) solo per
        # leggere S16, e S16 aveva un falso positivo che lo faceva girare a vuoto
        # OGNI ciclo. Ora il controllo è diretto: l'ultima voce ### del SAL deve
        # essere nella tabella dell'indice — una riga python, non una batteria.)
        if ! python3 -c "
import re, sys
sal = open('$DIR/SAL.md').read()
voci = re.findall(r'^### (.+)$', sal, re.M)
if not voci: sys.exit(1)
ultima = voci[-1][:40]
blocco = sal[sal.find('<!-- SAL-INDICE'):sal.find('## ', sal.find('<!-- SAL-INDICE')+100)]
sys.exit(0 if ultima in blocco else 1)
" 2>/dev/null; then
          # (2026-09-24, quinto ventaglio, R5 R5): era "$HERE/../tools/sal-indice.sh" — riscriveva il SAL della
          # COPIA VIVA (dove lavora il giorno) e il diff qui sotto guardava il ramo, intatto: fix mai arrivato
          bash "$DIR/tools/sal-indice.sh" >/dev/null 2>&1
          # solo se ha prodotto un diff reale (niente fix fantasma)
          if ! git -C "$DIR" diff --quiet -- SAL.md 2>/dev/null; then
            FIX_APPLICATI=$((FIX_APPLICATI+1))
            log "REPO $REPO: auto-fix — indice del SAL rigenerato (S16)"
          fi
        fi
        # fix 3: CRLF nei .sh → bonificati (passano bash -n, muoiono a runtime)
        CRLF_FILES=$(grep -rl $'\r' "$DIR"/tools/*.sh "$DIR"/night-shift/*.sh "$DIR"/tests/*.sh 2>/dev/null | head -5 || true)
        if [ -n "$CRLF_FILES" ]; then
          for CF in $CRLF_FILES; do
            # (Q12): `mv` del temporaneo perdeva +x (e la PR portava un cambio di modo 755→644):
            # si riscrive il contenuto nello STESSO file, che tiene i suoi permessi
            LC_ALL=C tr -d '\r' < "$CF" > "$CF.tmp" && cat "$CF.tmp" > "$CF" && rm -f "$CF.tmp"
            log "REPO $REPO: auto-fix — CRLF bonificato in $(basename "$CF")"
            FIX_APPLICATI=$((FIX_APPLICATI+1))
          done
        fi
        # fix 4: indice pattern README non alfabetico → riordinato
        # (revisione 10 giri, 2026-09-23): l'esito si leggeva al ROVESCIO — dopo un riordino
        # riuscito l'indice e' in ordine e finiva nel ramo «gia' in ordine» (mai contato); un
        # python fallito finiva nel ramo «riordinato». Ora conta se il file e' CAMBIATO.
        IDX_PRIMA=$(cksum < "$DIR/patterns/README.md" 2>/dev/null)
        python3 - "$DIR/patterns/README.md" <<'PYIDX' 2>/dev/null
import sys
p = sys.argv[1]
lines = open(p).read().split('\n')
rows = [l for l in lines if l.startswith('| [')]
if rows and rows != sorted(rows, key=lambda l: l.split(']')[0].lower()):
    rows.sort(key=lambda l: l.split(']')[0].lower())
    out = []
    done = False
    for l in lines:
        if l.startswith('| [') and not done:
            out.extend(rows); done = True
            continue
        if l.startswith('| ['): continue
        out.append(l)
    open(p, 'w').write('\n'.join(out))
    print('INDICE-RIORDINATO')
PYIDX
        if [ -n "$IDX_PRIMA" ] && [ "$(cksum < "$DIR/patterns/README.md" 2>/dev/null)" != "$IDX_PRIMA" ]; then
          log "REPO $REPO: auto-fix — indice pattern riordinato (alfabetico)"
          FIX_APPLICATI=$((FIX_APPLICATI+1))
        fi
        if ! git -C "$DIR" diff --quiet 2>/dev/null || ! git -C "$DIR" diff --cached --quiet 2>/dev/null; then
          FIX_APPLICATI=$((FIX_APPLICATI+1))  # c'e' carne vera: il commit e' legittimo
        else
          FIX_APPLICATI=0
          log "REPO $REPO: auto-fix senza diff (gia' a posto?) — niente commit, niente PR"
        fi
        if [ "$FIX_APPLICATI" -gt 0 ]; then
          # IL GATE DEL FIXER: suite completa + sonde devono passare sul branch.
          # (non il banco intero: il suo 5/7 privacy dipende dalla repos.key LOCALE della
          # macchina — una QUESTIONE DI POLITICA aperta non deve bloccare i fix meccanici;
          # le issue [banco] la tengono viva per il giorno. Dichiarato, mai nascosto.)
          GATE_OK=0
          # (revisione 10 giri, 2026-09-23): l'esito del banco si buttava (`|| true`) e il commit
          # e la PR dicevano comunque «banco CHIUSO». Ora il banco rosso ferma il gate.
          BANCO_OK=0
          # (V1#5, 2026-09-24): il banco e le sonde del RAMO ($DIR), non della copia viva — questi strumenti
          # fanno cd nella propria radice: lanciati da $HERE giudicavano la copia viva. Senza lo strumento nel
          # ramo il gate resta chiuso (fallisce dal lato sicuro).
          ai_timeout 300 bash "$DIR/tools/banco-passaggio.sh" --solo-copertura >/dev/null 2>&1 && BANCO_OK=1
          [ "$BANCO_OK" -eq 1 ] || log "REPO $REPO: banco di copertura ROSSO sul branch notte — gate chiuso, niente commit"
          PASS_T=0; FAIL_T=0
          # (V1#1, V1#5, V4#6, 2026-09-24): i banchi del RAMO con i fix ($DIR), ciascuno sotto tetto — lib.sh gate_banchi
          GATE_OUT=$(gate_banchi "$DIR" 300)
          read -r _ PASS_T FAIL_T <<<"$(tail -1 <<<"$GATE_OUT")"
          while IFS= read -r l; do
            case "$l" in
              amber\ *) log "REPO $REPO: gate-amber in ${l#amber } — passato al retry (transitorio)" ;;
              rosso\ *) log "REPO $REPO: gate-rosso in ${l#rosso }" ;;
            esac
          done <<<"$GATE_OUT"
          [ "$BANCO_OK" -eq 1 ] && [ "$FAIL_T" -eq 0 ] && ai_timeout 300 bash "$DIR/tools/giri-ignoranti.sh" >/dev/null 2>&1 && GATE_OK=1
          if [ "$GATE_OK" -eq 1 ]; then
            ERR_NOTTE=$(mktemp /tmp/night-commit-err.XXXXXX)
            # (ottavo ventaglio, O5 R1): i rami notte/auto-* con una PR aperta, per il controllo del doppione qui sotto
            APERTE_NOTTE=()
            while IFS= read -r _r; do [ -n "$_r" ] && APERTE_NOTTE+=("$_r"); done \
              < <(cd "$DIR" && gh pr list --state open --limit 1000 --json headRefName -q '.[].headRefName' 2>/dev/null | grep '^notte/auto-' || true)
            # TUTTI e TRE i comandi col stderr catturato (prima catturavo solo git add:
            # il commit moriva nel pre-commit hook e l'stderr andava nel vuoto)
            # (T5#2b, 2026-09-24): qui resta `add -A` per scelta — i fix sono deterministici (nessun
            # modello, nessuna lettura fuori dal progetto) e uno puo' creare lo specchio .opencode/
            if git -C "$DIR" add -A 2>"$ERR_NOTTE" \
               && git -C "$DIR" commit -qm "notte: auto-miglioramento meccanico (banco CHIUSO, PR bozza per il giorno)

Fix applicati dalla finestra notturna 23-06: $FIX_APPLICATI. Solo categorie
meccaniche note; il banco veloce e' CHIUSO su questo branch; PR bozza per la
review del giorno." 2>>"$ERR_NOTTE" \
               && { ! NOTTE_DOPPIA=$(caccia_gia_aperta "$DIR" "origin/$DB" ${APERTE_NOTTE[@]+"${APERTE_NOTTE[@]}"}) \
                    || { echo "DOPPIONE: lo stesso diff e' gia' in una PR aperta ($NOTTE_DOPPIA)" >>"$ERR_NOTTE"; false; }; } \
               && forme_prima_del_push "$DIR" "origin/$DB" >>"$ERR_NOTTE" 2>&1 \
               && git -C "$DIR" push -q -u origin "$BRANCH" 2>>"$ERR_NOTTE"; then
              PR_NOTTE=$(cd "$DIR" && gh pr create --draft --head "$BRANCH" --title "notte: auto-miglioramento meccanico del $(date +%F)" --body "Generata dalla finestra notturna 23-06. Fix meccanici di categoria nota, banco CHIUSO. La notte non decide: questa PR aspetta la review del giorno." 2>&1 | tail -1)
              log "REPO $REPO: PR bozza di auto-miglioramento → $PR_NOTTE ($FIX_APPLICATI fix, banco CHIUSO)"
              log "REPO $REPO: $(lente_pr "$DIR" "origin/$DB" "$BRANCH" "$PR_NOTTE")"  # D2: lente sicurezza automatica
            elif grep -c '^DOPPIONE' "$ERR_NOTTE" >/dev/null 2>&1; then
              # (2026-09-25, ottavo ventaglio, O5 R1): il ramo cambia nome a ogni minuto, e ogni ciclo apriva una PR nuova e
              # identica finche' la prima non era fusa (3 cicli, 3 PR, stesso patch-id). Come per le cacce (V1#2).
              log "REPO $REPO: auto-miglioramento: $(grep -m1 '^DOPPIONE' "$ERR_NOTTE") — nessuna PR nuova, ramo locale buttato"
              git -C "$DIR" reset -q --hard "origin/${DB:-main}"
            else
              log "⚠ REPO $REPO: commit o push del branch notte FALLITI — albero ripristinato, il rilievo resta nell'issue"
              log "⚠ stderr del commit/push: $(head -c 400 "$ERR_NOTTE" | tr '\n' ' ')"
              # (revisione 10 giri): $DB, gia' calcolato — la ri-derivazione con rev-parse, senza
              # origin/HEAD, stampava «origin/HEAD» + «main» (due righe) sotto pipefail
              git -C "$DIR" reset -q --hard "origin/${DB:-main}"
            fi
          else
            log "⚠ REPO $REPO: auto-fix BOCCIATI dal banco — branch scartato (resta il rilievo)"
            git -C "$DIR" reset -q --hard HEAD
          fi
          git -C "$DIR" checkout -q "${DB:-main}"
        fi
      fi
    fi
    # ── fine auto-miglioramento sicuro ────────────────────────────────────────
    if [ "$N_FIND" -gt 0 ]; then
      CICLO_TITOLO="[ciclo-vivo] $N_FIND finding dell'auto-esame notturno"
      ISSUE_APERTE=$(gh issue list --limit 1000 -R "$REPO" --state open --json title -q '.[].title' 2>/dev/null || true)
      if grep -qF "[ciclo-vivo]" <<<"$ISSUE_APERTE"; then
        log "REPO $REPO: rilievo ciclo-vivo gia' aperto — niente duplicati, aspetta il giorno"
      else
        echo "$CICLO_OUT" > /tmp/night-ciclo-$$.md
        if gh issue create -R "$REPO" -t "$CICLO_TITOLO" -F /tmp/night-ciclo-$$.md >/dev/null 2>&1; then
          log "REPO $REPO: aperta issue '$CICLO_TITOLO' — il giorno dispone"
        else
          log "⚠ REPO $REPO: creazione issue ciclo-vivo fallita — rilievo nel log"
        fi
        rm -f /tmp/night-ciclo-$$.md
      fi
    else
      if [ "${NV_ROSSI:-0}" -gt 0 ]; then
        log "REPO $REPO: ciclo-vivo pulito (0 finding) — MA $NV_ROSSI verifiche .night-verify rosse (issue gia' aperta)"
      else
        log "REPO $REPO: ciclo-vivo pulito (0 finding)"
      fi
    fi
    BANCO_OUT=$(bash "$HERE/../tools/banco-passaggio.sh" --veloce 2>&1 || true)
    if ! echo "$BANCO_OUT" | tail -1 | grep -c "CHIUSO" >/dev/null; then
      ISSUE_APERTE=$(gh issue list --limit 1000 -R "$REPO" --state open --json title -q '.[].title' 2>/dev/null || true)
      if grep -qF "[banco]" <<<"$ISSUE_APERTE"; then
        log "REPO $REPO: banco rosso MA issue [banco] gia' aperta — niente duplicati, aspetta il giorno"
      elif true; then
        echo "$BANCO_OUT" > /tmp/night-banco-$$.md
        gh issue create -R "$REPO" -t "[banco] rosso nell'auto-esame notturno" -F /tmp/night-banco-$$.md >/dev/null 2>&1           && log "REPO $REPO: banco ROSSO — issue aperta per il giorno"           || log "⚠ REPO $REPO: banco rosso e creazione issue fallita — verdetto nel log"
        rm -f /tmp/night-banco-$$.md
      fi
    else
      log "REPO $REPO: banco veloce CHIUSO"
    fi
  fi

  # (2026-09-18, Luca: «un agente revisore, censore, che verifica prova certifica
  # il codice e decide se deliberarlo o no»): ogni ciclo, UNA PR bozza night/*
  # passa dal censore — guardie deterministiche, prove sul branch, giudizio di
  # un processo separato senza la memoria di chi ha scritto (stesso modello dal
  # 2026-09-19 — cervello/decisione-modello-unico.md —, istruzioni e ruolo diversi: chi scrive non giudica). La quarantena (>=20 min) la decide il revisore:
  # chi crea non si giudica nello stesso respiro. Il veto resta umano.
  if [ -f "$HERE/revisore.sh" ]; then
    # (revisione 10 giri): la candidata si sceglie coi predicati del censore (lib.sh
    # candidata_censore) — prima una PR di issue in testa affamava le caccia dietro di lei
    # (2026-09-25, ottavo ventaglio, O2 R2): --limit 200, non 20 — con 20 PR piu' nuove davanti nessuna caccia arrivava al
    # giudizio, in silenzio. Ogni lista del turno dichiara il suo limite (tests/test-lib.sh lo pretende).
    REVISORE_CANDIDATA=$(cd "$DIR" && gh pr list --state open --json number,headRefName,isDraft,title,createdAt --limit 200 2>/dev/null \
      | candidata_censore)
    if [ -n "${REVISORE_CANDIDATA:-}" ]; then
      log "REPO $REPO: PR #$REVISORE_CANDIDATA in quarantena — la porto al CENSORE"
      REVISORE_OUT=$(bash "$HERE/revisore.sh" "$DIR" "$REVISORE_CANDIDATA" 2>&1); REVISORE_RC=$?
      # (audit 2026-09-23, corretto al secondo giro): le firme "DELIBERA:" vivevano
      # su stderr catturato e ingoiato. La prima cura grepava "^DELIBERA:" — MAI
      # match: il log() del revisore antepone "[revisore HH:MM:SS] ". Si cerca la
      # firma DENTRO la riga, non all'inizio.
      while IFS= read -r _dl; do log "REPO $REPO: $_dl"; done < <(grep -a "DELIBERA: APPROVA\|DELIBERA: RIGETTA" <<<"$REVISORE_OUT" | sed 's/^\[revisore [^]]*\] //')
      case "$REVISORE_RC" in
        0) log "REPO $REPO: ✅ censore ha DELIBERATO il merge: PR #$REVISORE_CANDIDATA" ;;
        1) log "REPO $REPO: ⛔ censore ha RIGETTATO la PR #$REVISORE_CANDIDATA (chiusa con motivi)" ;;
        2) log "REPO $REPO: censore rinvia la PR #$REVISORE_CANDIDATA al giorno ($(echo "$REVISORE_OUT" | tail -1 | cut -c1-100))" ;;
        *) log "REPO $REPO: ⚠ censore in errore sulla PR #$REVISORE_CANDIDATA (rc=$REVISORE_RC)" ;;
      esac
    fi
    # (D10, decisione di Luca 2026-09-23: «b»): una PR di ISSUE per ciclo riceve il PARERE del
    # censore — stesse guardie e prove, giudizio contro il testo della issue, un commento motivato;
    # mai la fusione, che resta di Luca. Un parere per commit (lib.sh candidata_parere).
    PARERE_CANDIDATA=$(cd "$DIR" && gh pr list --state open --json number,headRefName,isDraft,title,headRefOid --limit 200 2>/dev/null \
      | candidata_parere "$DIR/.git/revisore")
    if [ -n "${PARERE_CANDIDATA:-}" ]; then
      log "REPO $REPO: PR di issue #$PARERE_CANDIDATA — la porto al CENSORE per il parere (non fonde)"
      PARERE_OUT=$(bash "$HERE/revisore.sh" "$DIR" "$PARERE_CANDIDATA" 2>&1); PARERE_RC=$?
      case "$PARERE_RC" in
        4) log "REPO $REPO: $(grep -a 'PARERE:' <<<"$PARERE_OUT" | tail -1 | sed 's/^\[revisore [^]]*\] //') (commento sulla PR)" ;;
        2) log "REPO $REPO: parere sulla PR #$PARERE_CANDIDATA rinviato ($(echo "$PARERE_OUT" | tail -1 | cut -c1-100))" ;;
        *) log "REPO $REPO: ⚠ censore in errore sul parere della PR #$PARERE_CANDIDATA (rc=$PARERE_RC)" ;;
      esac
    fi
  fi

  if [ "$COUNT" -eq 0 ]; then
    # (2026-09-17, intuizione di Luca: «il sistema deve scovare errori, migliorie,
    # ed altro — se lo deve fare il lavoro»). Niente issue? LA CACCIA PARTE.
    # L'agente legge il codice e trova UNA cosa da migliorare. Non aspetta:
    # crea il proprio lavoro. Se anche la caccia non trova niente, ALLORA buonanotte.
    if [ -f "$HERE/agente.sh" ]; then
      # (miglioria dal test 1h): COOLDOWN — se la caccia ha detto 'pulito' su questa
      # repo negli ultimi 30 minuti, non rimontarla. File marker con timestamp.
      CACCIA_MARKER="$WORK/.caccia-pulita-${REPO//\//_}"
      if [ -f "$CACCIA_MARKER" ]; then
        CACCIA_ETA=$(( $(date +%s) - $(mtime "$CACCIA_MARKER") ))
        if [ "$CACCIA_ETA" -lt "${CACCIATORIA_COOLDOWN_SEC:-1800}" ]; then  # profilo (D11)
          log "REPO $REPO: caccia in cooldown (${CACCIA_ETA}s < 30min: già dichiarata pulita)"
          return 0
        fi
      fi
      local PR_CREATED=0  # serve alla caccia (che gira prima del loop issue)
  log "REPO $REPO: nessuna issue — attivo la CACCIA (il lavoro se lo trova il sistema)"
      # branch dedicato alla caccia (l'agente modifica su branch, mai su main)
      CACCIA_BRANCH="night/caccia-$(date +%Y%m%d-%H%M%S)"
      git -C "$DIR" checkout -b "$CACCIA_BRANCH" -q 2>/dev/null || true
      CACCIA_OUT=$(bash "$HERE/caccia-lente.sh" "$DIR" 2>&1)
      CACCIA_RC=$?
      # (E-031, 2026-09-18): le convenzioni di caccia-lente sono rc=0 = LENTE HA
      # TROVATO PROBLEMI, rc=1 = SANA (o strumento muto). L'integrazione originale
      # le aveva INVERTITE: la sana diventava 'non ha converto' — e la miglioria
      # (che partiva solo su rc=0) non girava MAI nei giri buoni; i problemi
      # dichiarati dalla lente diventavano 'pulita' + cooldown: i veri segnali
      # zittiti per 30 minuti. La finestra GIUSTA per migliorare e' quando le
      # lenti dicono SANA: il codice sta in piedi, si puo' alzare il livello.
      MIGLIORIA_RC=1 MIGLIORIA_OUT="" MIGLIORIA_TENTATA=0
      if [ "$CACCIA_RC" -eq 1 ] && git -C "$DIR" diff --quiet 2>/dev/null; then
        log "REPO $REPO: caccia: lente dichiara il sistema sano — provo a MIGLIORARE il codice"
        MIGLIORIA_TENTATA=1
        MIGLIORIA_T0=$(date +%s)
        MIGLIORIA_OUT=$(bash "$HERE/caccia-miglioria.sh" "$DIR" 2>&1)
        MIGLIORIA_RC=$?
        # (audit 2026-09-23): "TRASFORMATORE deterministico" e "gate BOCCIA"
        # morivano qui come le DELIBERE — il funnel diceva "0 per sempre".
        while IFS= read -r _mg; do log "REPO $REPO: $_mg"; done < <(grep -aE "TRASFORMATORE deterministico|gate BOCCIA|agente: .*(⚠|⛔|rianima_ollama: esito)" <<<"$MIGLIORIA_OUT")   # (R4 R3): anche i wedge dell'agente
        # (strumento, 2026-09-19): la riga-categoria in produzione — senza questa
        # riga non si sa SE la finestra abbia pagato un debito o girato a rotazione
        log "REPO $REPO: caccia-interna: $(echo "$MIGLIORIA_OUT" | grep -a "categoria" | head -1 | cut -c1-140)"
      elif [ "$CACCIA_RC" -eq 0 ]; then
        log "REPO $REPO: caccia: ⚠ LENTE SEGNALA: $(echo "$CACCIA_OUT" | grep -a -A3 '^VERDETTO' | tail -2 | head -1 | cut -c1-140)"
      fi
      ORIGINE=""
      [ "$MIGLIORIA_RC" -eq 0 ] && ORIGINE="miglioria"
      if [ -n "$ORIGINE" ]; then
        # (studio gsd-pi, cost-per-unit): il costo della consegna in secondi
        # di GPU — la dashboard lo mostrera' nel funnel
        MIGLIOREA_DURATA=$(( $(date +%s) - MIGLIORIA_T0 ))
        log "REPO $REPO: 🎯 MIGLIORIA pronta (${MIGLIOREA_DURATA}s GPU): $(echo "$MIGLIORIA_OUT" | grep -a '^MIGLIORIA' | tail -1 | cut -c1-120)"
        local MSG_PR="improve: miglioria notturna — $(echo "$MIGLIORIA_OUT" | grep -a '^MIGLIORIA' | tail -1 | cut -c1-80)"
        # usa il flusso commit/push/PR — e quando fallisce, DICE PERCHE'
        # (la prima consegna vera e' morta qui, con l'errore vero ingoiato)
        # (V1#2, 2026-09-24): le cacce con una PR aperta — se una porta gia' lo stesso diff, niente PR doppia
        CACCE_APERTE=$(cd "$DIR" && gh pr list --limit 1000 --state open --json headRefName -q '.[].headRefName' 2>/dev/null | grep '^night/caccia-' || true)
        ERR_CONSEGNA=$(cd "$DIR" && aggiungi_consegna "$DIR" 2>&1 && git commit -qm "$MSG_PR" 2>&1 \
          && { ! DOPPIA=$(caccia_gia_aperta "$DIR" "origin/$DB" $CACCE_APERTE) || { echo "DOPPIONE di una caccia gia' aperta ($DOPPIA): stesso diff, nessuna PR nuova"; false; }; } \
          && forme_prima_del_push "$DIR" "origin/$DB" && git push -u origin "$CACCIA_BRANCH" 2>&1)
        if [ $? -eq 0 ]; then
          grep 'NON dichiarato' <<<"$ERR_CONSEGNA" | while IFS= read -r l; do log "REPO $REPO: $l"; done   # T5#2b: detto, mai taciuto
          PR_CACCIA=$(cd "$DIR" && gh pr create --draft --head "$CACCIA_BRANCH" --title "caccia: miglioria al codice dall'agente notturno" --body "Prodotto dal turno notturno autonomo (miglioria). Il gate ha verificato: diff piccolo, sintassi valida. Verificare il diff prima del merge." 2>&1 | tail -1)
          # (2026-09-25, ottavo ventaglio, O2 R4): si conta solo una PR vera — con gh in errore (rate limit) la «PR» era il
          # messaggio d'errore, il SAL scriveva «1 PR bozza» e il freno del rate limit (dorme solo a zero PR) non scattava
          case "$PR_CACCIA" in
            https://*)
              log "REPO $REPO: PR di $ORIGINE → $PR_CACCIA"
              log "REPO $REPO: $(lente_pr "$DIR" "origin/$DB" "$CACCIA_BRANCH" "$PR_CACCIA")"  # D2: lente sicurezza automatica
              PR_CREATED=$((PR_CREATED+1)) ;;  # locale a shift_repo, inizializzata prima della caccia
            *) log "⚠ REPO $REPO: PR di $ORIGINE NON creata (il ramo $CACCIA_BRANCH e' spinto): $(tail -1 <<<"$PR_CACCIA" | cut -c1-120)" ;;
          esac
          git -C "$DIR" checkout "$DB" -q
        elif grep -c '^DOPPIONE' <<<"$ERR_CONSEGNA" >/dev/null; then
          log "REPO $REPO: $(grep '^DOPPIONE' <<<"$ERR_CONSEGNA" | head -1) — ramo locale buttato"
          git -C "$DIR" reset -q --hard
          git -C "$DIR" checkout "$DB" -q
          git -C "$DIR" branch -D "$CACCIA_BRANCH" -q 2>/dev/null || true
        else
          log "⚠ REPO $REPO: commit/push della $ORIGINE fallito — ripristino — ERRORE: $(echo "$ERR_CONSEGNA" | tail -2 | tr '\n' ' ' | cut -c1-200)"
          git -C "$DIR" reset -q --hard
          git -C "$DIR" checkout "$DB" -q
        fi
      elif [ "$CACCIA_RC" -eq 0 ]; then
        log "REPO $REPO: caccia: problemi segnalati dalla lente — nessun fix automatico qui, il giorno giudica (auto-esame e issue)"
        git -C "$DIR" checkout "$DB" -q 2>/dev/null || true
        git -C "$DIR" branch -D "$CACCIA_BRANCH" -q 2>/dev/null || true
      elif [ "$CACCIA_RC" -eq 3 ] || [ "$CACCIA_RC" -eq 2 ]; then
        # (2026-09-24, V1#6): il modello non ha risposto — non e' salute, e niente cooldown della salute:
        # il ciclo dopo la lente riprova. (Q3 R2): anche rc 2, la cartella assente, cadeva nella salute.
        log "REPO $REPO: caccia: ⚠ LENTE MUTA (rc $CACCIA_RC: modello o strumento muto, o cartella assente) — NON e' 'sistema sano'"
        git -C "$DIR" checkout "$DB" -q 2>/dev/null || true
        git -C "$DIR" branch -D "$CACCIA_BRANCH" -q 2>/dev/null || true
      elif [ "$CACCIA_RC" -eq 1 ] && [ "$MIGLIORIA_TENTATA" -eq 0 ]; then
        # (2026-09-25, settimo ventaglio, V2 R2): sana ma con l'albero sporco la miglioria non parte — era «nessuna
        # miglioria trovata, repository in salute» con 30 minuti di cooldown. Si dice, e il ciclo dopo riprova.
        log "REPO $REPO: caccia: la lente dice sano, ma miglioria NON tentata: albero sporco — niente cooldown della salute"
        git -C "$DIR" checkout "$DB" -q 2>/dev/null || true
        git -C "$DIR" branch -D "$CACCIA_BRANCH" -q 2>/dev/null || true
      elif [ "$CACCIA_RC" -ne 1 ]; then
        # (2026-09-25, settimo ventaglio, V2 R2): «sana» era il ramo di default. Un rc non dichiarato (127: lo script
        # assente durante un riallineo; 143: un kill) scriveva salute e cooldown. Ora non e' né sano né malato.
        log "REPO $REPO: caccia: ⚠ rc $CACCIA_RC non dichiarato (0 problemi · 1 sana · 2 cartella assente · 3 muta) — né sana né malata, niente cooldown"
        git -C "$DIR" checkout "$DB" -q 2>/dev/null || true
        git -C "$DIR" branch -D "$CACCIA_BRANCH" -q 2>/dev/null || true
      else
        # (2026-09-19, Ollama wedged): «nessuna trovata» e «agente morto» NON sono
        # la stessa cosa — la finestra con lo strumento rotto va detta per quello che e'
        if grep -aq "agente rc=\|NESSUN rianimamento" <<<"$MIGLIORIA_OUT"; then
          log "REPO $REPO: caccia: ⚠ AGENTE FALLITO (Ollama?) — NON e' 'niente trovato': $(echo "$MIGLIORIA_OUT" | grep -a "rc=\|rianimamento" | head -1 | cut -c1-90)"
        else
          log "REPO $REPO: caccia: sana e nessuna miglioria trovata — repository in salute"
        fi
        # (2026-09-18, domanda di Luca: «come fa a essere sempre tutto in salute?»).
        # La salute si dichiara CON i debiti o non e' onesta: ogni volta che il
        # turno dice 'in salute', allega il censimento delle famiglie di bug del
        # registro (dove i bug DAVVERO si nascondono: E-002 pipe, E-032 fixture).
        # marker: sana E niente da migliorare — cooldown 30 min
        touch "$CACCIA_MARKER"
        git -C "$DIR" checkout "$DB" -q 2>/dev/null || true
        git -C "$DIR" branch -D "$CACCIA_BRANCH" -q 2>/dev/null || true
        # (2026-09-24, quinto ventaglio, R4 R1): il censimento scrive la storia solo da main — girava qui sopra,
        # sul ramo night/caccia-*, e dal 23/9 la storia (e il trend della dashboard) era congelata
        if [ -f "$HERE/../tools/caccia-registro.sh" ]; then
          CENSUS=$(bash "$HERE/../tools/caccia-registro.sh" "$DIR" 2>/dev/null | head -1)
          [ -n "$CENSUS" ] && log "REPO $REPO: $CENSUS"
        fi
      fi
    fi
    # (revisione 10 giri, 2026-09-23): il ramo della caccia usciva PRIMA dell'aggregazione in
    # fondo a shift_repo — una PR di caccia non contava mai: il SAL del turno diceva 0 PR e il
    # ciclo, creduto a vuoto, dormiva la sua pausa.
    TOT_PR_CREATED=$((TOT_PR_CREATED+PR_CREATED))
    return 0
  fi

  local PR_CREATED=0 PROPOSTE=0 FAILED=0 IDX=0
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
    # (2026-09-23, notte dei giri): la sequenza del cancello vive in lib.sh cancello_design (provata
    # da tests/test-night-shift-design-gate.sh sulla funzione VERA, non su una copia); qui restano
    # il log e il commento di ciascun motivo. (Q11): il commento passa da commenta_una_volta —
    # uno per motivo, non uno per ciclo.
    MOTIVO=$(cancello_design "$BODY")
    if [ -n "$MOTIVO" ]; then
      case "$MOTIVO" in
        territorio-assente)
          LOG_M="SENZA sezione ## Territorio — il processo la richiede, skip con commento"
          CORPO_M="🌙 Saltata: manca la sezione \`## Territorio\` (quanto codice serve leggere). La lezione dell'11 ore: la notte converge solo su territori piccoli e indicati — dichiara il territorio, o se è grande assegnala al giorno." ;;
        design-assente)
          LOG_M="SENZA sezione ## Design — il processo la richiede, skip con commento"
          CORPO_M="🌙 Il turno di notte salta questa issue: manca la sezione \`## Design\` (anche solo un link o tre righe di ratio). Il processo di AI_Programmer richiede che ogni commessa dichiari il suo design prima del lavoro — aggiungila e la prossima notte riparte." ;;
        design-povero*)
          LOG_M="sezione ## Design troppo povera (${MOTIVO#design-povero } char < 80) — serve il DA DOVE (SAL, analisi, riferimento)"
          CORPO_M="🌙 Saltata: la sezione \`## Design\` è troppo povera (${MOTIVO#design-povero } caratteri utili). Il design dichiara da dove nasce la commessa (link al SAL, all'analisi, o tre righe di ratio sostanziale)." ;;
        design-senza-fonte)
          LOG_M="## Design senza un riferimento reale (link/SAL/issue/file) — solo prosa di riempimento"
          CORPO_M="🌙 Saltata: la sezione \`## Design\` è lunga ma non cita nulla di verificabile (un link, \`SAL.md\`, un'issue \`#N\`, o un file). Il DA-DOVE deve poter essere controllato da chi legge, non solo affermato." ;;
        *)
          LOG_M="## Territorio senza file/righe nominate — il territorio si dichiara con precisione"
          CORPO_M="🌙 Saltata: la sezione \`## Territorio\` non nomina file, righe né documenti. Il territorio si dichiara con precisione (file e dimensione) — altrimenti il lavoro va al giorno." ;;
      esac
      log "Issue #$NUM: $LOG_M"
      commenta_una_volta "$NUM" "$REPO" "${MOTIVO%% *}" "$CORPO_M" || true
      SKIPPED_DESIGN=$((SKIPPED_DESIGN+1)); continue
    fi

    # Idempotenza: PR aperta → skip; PR fusa → chiude l'issue e skip
    local PR_STATE
    # (2026-09-25, ottavo ventaglio, O2 R1): gh in errore non e' «nessuna PR» — si salta l'issue in questo ciclo, invece di
    # rifarla e forzare il ramo di una PR che forse e' aperta
    if ! PR_STATE=$(stato_pr_ramo "$REPO" "night/issue-$NUM"); then
      log "Issue #$NUM: ⚠ gh non ha detto lo stato della PR di night/issue-$NUM — salto l'issue in questo ciclo (non la rifaccio al buio)"
      continue
    fi
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
      # l'issue scaricata in un file locale: la leggono il check «gia' implementata» qui
      # sotto E il solver. (D6, test del sistema completo 2026-09-20: il file veniva
      # scritto DOPO il check, che sotto set -u leggeva una variabile vuota e non girava
      # mai — la lezione del caso #10 era scritta e inattiva.)
      ISSUE_FILE="/tmp/night-issue-$NUM.md"
      # (studio dsh goal, 2026-09-23): l'obiettivo dura quanto la issue, non un ciclo
      if [ -f "$HERE/../tools/goal-issue.sh" ]; then
        bash "$HERE/../tools/goal-issue.sh" "$DIR" create "$NUM" "$(gh issue view "$NUM" -R "$REPO" --json title -q .title 2>/dev/null || echo "issue #$NUM")" >/dev/null 2>&1 || true
        log "REPO $REPO: goal aperto per issue #$NUM (durable: sopravvive ai cicli)"
      fi
      printf '%s\n' "$BODY" > "$ISSUE_FILE"
      # (2026-09-08, dal caso #10): la notte inseguiva una commessa che il giorno aveva
      # gia' consegnato (funzione presente E cablata, commit a72213d) — quattro notti a
      # proporre cio' che esisteva. Il tracker e il codice divergono in silenzio: questo
      # check li riavvicina PRIMA di spendere il modello. Se la funzione esiste ed e'
      # chiamata, il turno NON decide: lo dice e aspetta il giorno.
      FN_NOMINATA=$(sed -n '/^## Commessa/,/^## /p' "$ISSUE_FILE" 2>/dev/null | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*\(' | sort -u | head -3 | tr -d '(')
      TERR_FILE=$(sed -n '/^## Territorio/,/^## /p' "$ISSUE_FILE" 2>/dev/null | grep -oE '[a-zA-Z0-9_./-]+\.(gs|js|html|py)' | head -1)
      if [ -n "$TERR_FILE" ] && [ -n "$FN_NOMINATA" ]; then
        TF="$DIR/$TERR_FILE"; [ -f "$TF" ] || TF="$TERR_FILE"
        if [ -f "$TF" ]; then
          GIA_FATTO=""
          for FN in $FN_NOMINATA; do
            if funzione_definita_e_chiamata "$TF" "$FN"; then   # V1#3: la definizione non e' una chiamata
              GIA_FATTO="$FN ($(grep -n "function $FN" "$TF" | head -1 | cut -d: -f1))"
              break
            fi
          done
          if [ -n "$GIA_FATTO" ]; then
            log "Issue #$NUM: $GIA_FATTO esiste ed e' chiamata in $TERR_FILE — GIA' IMPLEMENTATA? Il turno non decide: lo chiede al giorno"
            CORPO_GIA="/tmp/night-giafatto-$NUM.md"
            { echo "🌙 Il turno legge nel codice che \`$GIA_FATTO\` esiste ed è chiamata in \`$TERR_FILE\` — la commessa sembra GIA' IMPLEMENTATA (il tracker e il codice divergevano). Se manca qualcosa di specifico, riscrivi l'issue col difetto preciso; se è tutto lì, questa nota basta a chiuderla."; } > "$CORPO_GIA"
            COMMENTI_GIA=$(gh issue view "$NUM" -R "$REPO" --json comments -q '.comments[].body' 2>/dev/null || true)
            grep -q "GIA' IMPLEMENTATA" <<<"$COMMENTI_GIA" || gh issue comment "$NUM" -R "$REPO" --body-file "$CORPO_GIA" >/dev/null 2>&1
            rm -f "$CORPO_GIA"
            ASPETTA_GIORNO="$ASPETTA_GIORNO"$'\n'"  $REPO #$NUM: gia' implementata? (chiede il giorno)"
            rm -f "$ISSUE_FILE"
            continue
          fi
        fi
      fi
      # (E-023, 2026-09-08): il check pre-solver sulla proposta ESISTENTE e' RITIRATO.
      #  Nato per risparmiare GPU (la notte del 6/9 rigenerava 262s per nulla), ha bloccato
      #  la PRIMA inserzione vera: col solver che ora INSERISCE funzioni nuove, un commento
      #  di proposta non e' piu' lo stato finale — e' lo stato di una CAPACITA' VECCHIA.
      #  La stratificazione giusta: PR aperta -> skip (gia' sopra, prima di tutto); proposta
      #  effettiva di STANOTTE (RC=3) -> niente duplicati (check nel ramo). Il ritento con
      #  capacita' migliore non e' spam: e' il lavoro che riparte.
      log "Issue #$NUM: risolutore senza agente (risolvi-issue.sh)"
      # (revisione 10 giri): il default e' MODEL_TAG — con MODELLO cambiato, sonda e solver
      # usavano due modelli diversi
      OUT=$(NIGHT_MODEL="${NIGHT_MODEL:-$MODEL_TAG}" bash "$NIGHT_SOLVER" "$DIR" "$ISSUE_FILE" 2>&1)
      RC=$?
      log "Issue #$NUM: $OUT"
      # (studio dsh goal): il progresso si accumula nel goal — il prossimo ciclo
      # vede DOVE eravamo rimasti, non riparte da zero
      [ -f "$HERE/../tools/goal-issue.sh" ] && bash "$HERE/../tools/goal-issue.sh" "$DIR" update "$NUM" "solver rc=$RC: $(echo "$OUT" | tail -1 | cut -c1-80)" >/dev/null 2>&1 || true

      # CASCATA solver → agente (2026-09-17, intuizione di Luca): se il solver non
      # converge, l'agente multi-turno prova strade che il solver non vede.
      # Previene 33 cicli di retry su qualcosa che non può matchare il pattern.
      AUTORE_FIX="risolvi-issue.sh, modello locale"   # chi ha scritto il fix: lo dice il commit (V1#6)
      # (2026-09-25, settimo ventaglio, V2 R3): rc 2 (uso errato, o node assente) non va all'agente: non saprebbe
      # verificare nemmeno lui, e il motivo vero si perderebbe dietro un «agente fallito».
      if [ "$RC" -ne 0 ] && [ "$RC" -ne 3 ] && [ "$RC" -ne 2 ] && [ -f "$HERE/agente.sh" ]; then
        log "Issue #$NUM: solver rc=$RC — provo l'AGENTE (cascade)"
        AGENTE_OUT=$(bash "$HERE/agente.sh" "$DIR" \
          "Fix this GitHub issue. Read the relevant files, understand the problem, fix it.

=== ISSUE ===
$(cat "$ISSUE_FILE" | head -60)
=== END ===

Fix the code in the current directory. When done, respond with FINISH." 2>&1)
        AGENTE_RC=$?
        # (audit 2026-09-23): l'esito della cascade finiva in una variabile e
        # moriva — ora almeno la coda dell'output si vede nel log del turno.
        log "Issue #$NUM: cascade-agente rc=$AGENTE_RC — $(echo "$AGENTE_OUT" | tail -2 | head -1 | cut -c1-110)"
        if [ "$AGENTE_RC" -eq 0 ] && ! git -C "$DIR" diff --quiet 2>/dev/null; then
          log "Issue #$NUM: ✅ AGENTE ha converto (dove il solver non poteva)"
          RC=0; AUTORE_FIX="agente.sh, cascata dopo il solver"
          OUT="AGENTE: completato"
          [ -f "$HERE/../tools/goal-issue.sh" ] && bash "$HERE/../tools/goal-issue.sh" "$DIR" update "$NUM" "AGENTE ha converto (cascade)" >/dev/null 2>&1 || true
        else
          log "Issue #$NUM: anche l'agente non ha converto (rc=$AGENTE_RC)"
        fi
      fi

      if [ $RC -eq 3 ]; then
        # PROPOSTA (funzione nuova o bersaglio assente): il codice va nell'issue come
        # commento, NON come PR — la notte del 4/9 ha aperto la PR #16 con dentro solo
        # il file proposto e il .night-bak: +739 righe di rumore, zero fix applicati.
        PATCH_LATEST=$(ls -t "$DIR"/.night-patch-*.js 2>/dev/null | head -1)
        # (notte 5/9: due commenti con lo stesso codice sulla stessa issue — la proposta
        # non era idempotente. Il flusso PR ha la sua guardia, questa e' quella della
        # proposta: una per issue finche' il giorno non decide. E-002: cattura prima,
        # MAI pipe in grep -q sotto pipefail)
        COMMENTI=$(gh issue view "$NUM" -R "$REPO" --json comments -q '.comments[].body' 2>/dev/null || true)
        if grep -q "Proposta notturna" <<<"$COMMENTI"; then
          log "Issue #$NUM: proposta gia pubblicata in un turno precedente — niente duplicati, aspetta il giorno"
          PROPOSTE=$((PROPOSTE+1))
          rm -f "$ISSUE_FILE"
          continue
        fi
        if [ -n "$PATCH_LATEST" ]; then
          COMMENTO="/tmp/night-commento-$NUM.md"
          { echo "🌙 Proposta notturna (NON applicata: funzione nuova o bersaglio non trovato in automatico). Il codice generato dal modello locale:"; echo '```javascript'; cat "$PATCH_LATEST"; echo '```'; echo ""; echo "Da verificare e collegare a mano (il giorno dispone): la funzione è proposta, manca l'inserimento nel file e l'attivazione (botone/menu/chiamata)."; } > "$COMMENTO"
          if gh issue comment "$NUM" -R "$REPO" --body-file "$COMMENTO" >/dev/null 2>&1; then
            log "Issue #$NUM: proposta pubblicata come commento (niente PR di scarto)"
            # (ottavo ventaglio, O2 R5): a capo veri, non «\n» per echo -e — il titolo e' testo di GitHub, e un «\c» chiudeva
            # l'uscita perdendo le voci dopo
            ASPETTA_GIORNO="$ASPETTA_GIORNO"$'\n'"  $REPO #$NUM: $TITLE"  # globale: la legge il SAL di fine turno
          else
            log "⚠ Issue #$NUM: commento della proposta fallito — il codice resta in $PATCH_LATEST"
          fi
          rm -f "$COMMENTO"
        fi
        PROPOSTE=$((PROPOSTE+1))
        rm -f "$ISSUE_FILE"
        continue
      fi
      if [ $RC -eq 0 ]; then
        # il fix è applicato: commit e push. Prova dal vivo 2026-09-04 (repo sandbox):
        # la variabile si chiama CTYPE, non TIPO — set -u uccideva il commit E il log
        # diceva comunque "committato e pushato": il log mentiva. Ora l'esito lo dice
        # il comando, non l'ottimismo.
        # night/* sono tentativi usa-e-getta: un nuovo tentativo sostituisce il branch
        # stantio di una prova precedente (mai main: il push punta esplicito a $BRANCH).
        # Il lease va passato COL VALORE ATTESO: il clone --depth=50 è single-branch e
        # il branch eredita l'upstream da origin/main (checkout -B) — il lease nudo
        # leggerebbe quello e rifiuterebbe sempre con "stale info" (giri 3-5 della
        # prova dal vivo 2026-09-04). Refspec esplicito + lease deterministico.
        git -C "$DIR" fetch origin "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH" -q 2>/dev/null || true
        LEASE_ARGS=()
        if EXPECTED=$(git -C "$DIR" rev-parse -q --verify "refs/remotes/origin/$BRANCH"); then
          # (2026-09-24, R5 R3): il ramo remoto con commit del GIORNO (autore diverso dal turno) non si forza —
          # senza lease il push viene rifiutato, il lavoro del giorno resta, e il log dice perche'
          ALTRUI=$(commit_altrui "$DIR" "origin/$DB" "refs/remotes/origin/$BRANCH")
          if [ "${ALTRUI:-0}" -gt 0 ]; then
            log "⚠ Issue #$NUM: $BRANCH sul remoto ha $ALTRUI commit non del turno: non lo sovrascrivo (push senza forzatura, verra' rifiutato)"
          else
            LEASE_ARGS=(--force-with-lease="$BRANCH:$EXPECTED")
          fi
        fi
        # (fase B adattiva): la nota da portare nel commit — una funzione NUOVA inserita
        # e' codice morto dichiarato: il diff reviewer cerca il collegamento che manca
        NOTA_INS=""
        if grep -q "ESITO: INSERITO" <<<"$OUT"; then
          NOTA_INS="

Funzione NUOVA inserita dal turno: nessuno la chiama ancora — il collegamento (bottone/menu/chiamata) resta da fare. Verificare il diff."
        fi
        # (fase B adattiva): la ## Verifica dell'issue si ESEGUE, se e' un comando che
        # sappiamo eseguire al sicuro (denylist: mai clasp/rm/push/deploy/curl/git da
        # un issue body — input esterno). L'esito si riporta nel commit, non fa gate:
        # un rosso dichiarato vale piu' di un silenzio.
        # (2026-09-23, giro A5): la scelta del comando vive in lib.sh verifica_issue_comando (testata):
        # solo `npm test` o un file del progetto eseguito — mai un install, un exec, un -e/-c
        VERIFICA_CMD=$(verifica_issue_comando "$ISSUE_FILE")
        VERIFICA_OUT="non dichiarata o non eseguibile al sicuro"
        if [ -n "$VERIFICA_CMD" ]; then
          # timeout(1) non esiste su macOS: ai_timeout e' il wrapper portabile dell'hub
          # (llm/_timeout.sh, nato per questo). D2 2026-09-07: la verifica diceva ROTTA
          # per command-not-found scambiato per esito — un finto rosso insegna a ignorare i rossi.
          # (2026-09-23, giro A5): il file eseguito puo' averlo scritto il modello — sul Mac dentro la
          # sandbox del turno (niente rete, scritture solo nella copia e in /tmp)
          SANDBOX_PRE=()
          if command -v sandbox-exec >/dev/null 2>&1 && [ -f "$HERE/sandbox.sb" ]; then
            SANDBOX_PROF=$(mktemp /tmp/verifica-sandbox.XXXXXX)
            sed -e "s|__WORKDIR__|$DIR|g" -e "s|__HOME__|$HOME|g" "$HERE/sandbox.sb" > "$SANDBOX_PROF"
            SANDBOX_PRE=(sandbox-exec -f "$SANDBOX_PROF")
          fi
          # shellcheck disable=SC2086  # VERIFICA_CMD va diviso in parole: e' un comando validato
          VERIFICA_RC=0; (cd "$DIR" && ai_timeout 60 ${SANDBOX_PRE[@]+"${SANDBOX_PRE[@]}"} $VERIFICA_CMD >/dev/null 2>&1) || VERIFICA_RC=$?
          VERIFICA_OUT=$(verdetto_verifica "$VERIFICA_RC" "$VERIFICA_CMD")
          [ -n "${SANDBOX_PROF:-}" ] && rm -f "$SANDBOX_PROF"
          log "Issue #$NUM: verifica dell'issue eseguita: $VERIFICA_OUT"
        fi
        # AUTO-REVIEW (2026-09-17): il modello rivede il proprio fix con una
        # domanda diversa. Se dice WRONG, il fix viene degradato: PR con warning.
        # Il verdetto arriva nella riga «REVIEW: ...» dell'output del solver (D5: prima
        # qui c'era anche una chiamata `risolvi-issue.sh --review` a una modalita' mai
        # esistita — usciva 2 «dir inesistente» a ogni fix, in silenzio).
        # (revisione 10 giri, 2026-09-23): si legge la sola riga REVIEW — prima «WRONG»/«CORRECT»
        # si cercavano in TUTTO l'output del solver (log e codice compresi: una variabile
        # `wrongCount` bastava), e con una pipe verso grep -q (famiglia E-002)
        REVIEW_RIGA=$(grep -m1 '^REVIEW: ' <<<"$OUT" || true)
        if [ "$RC" -eq 0 ]; then
          if [ "$REVIEW_RIGA" = "REVIEW: WRONG" ]; then
            NOTA_INS="

⚠ AUTO-REVIEW: il modello ha dubbi sul proprio fix — verificare con attenzione."
            log "Issue #$NUM: auto-review DUBBIA — PR con warning"
          elif [ "$REVIEW_RIGA" = "REVIEW: CORRECT" ]; then
            log "Issue #$NUM: auto-review CORRECT"
          fi
        fi
        # GENERATORE DI TEST (2026-09-17): il fix arriva col test che lo presidia.
        # Terza chiamata Ollama, stesso patto: prompt → codice → applicazione.
        if [ "$RC" -eq 0 ] && [ "$REVIEW_RIGA" != "REVIEW: WRONG" ]; then
          TEST_FILE="$DIR/tests/night/test_$(date +%s)_issue_$NUM.js"
          mkdir -p "$DIR/tests/night"
          # chiediamo al modello (tramite il solver) di scrivere il test
          # (revisione 10 giri): il test intero fra i marcatori del solver (prima: la sola
          # prima riga di un test multi-riga finiva nel file e nel commit)
          TEST_GEN=$(sed -n '/^TEST-GENERATO-INIZIO$/,/^TEST-GENERATO-FINE$/p' <<<"$OUT" | sed '1d;$d')
          if [ -n "$TEST_GEN" ] && [ "${#TEST_GEN}" -gt 20 ]; then
            echo "$TEST_GEN" > "$TEST_FILE"
            log "Issue #$NUM: test generato → tests/night/$(basename "$TEST_FILE")"
          fi
        fi
        # push -u: a fine corsa l'upstream del branch diventa il suo (non più main)
        # T5#2b: nel commit le modifiche, il test generato e i file nuovi dichiarati da agente.sh
        if ( cd "$DIR" && aggiungi_consegna "$DIR" "${TEST_FILE:+${TEST_FILE#"$DIR"/}}" | while IFS= read -r l; do log "Issue #$NUM: $l"; done \
             && git commit -qm "$(messaggio_fix "$CTYPE" "$NUM" "$TITLE" "$AUTORE_FIX" "$NOTA_INS" "$VERIFICA_OUT")" && { F=$(forme_prima_del_push "$DIR" "origin/$DB") || { log "Issue #$NUM: $F"; false; }; } \
             && git push -q -u origin ${LEASE_ARGS[@]+"${LEASE_ARGS[@]}"} "$BRANCH" ); then
          log "Issue #$NUM: fix committato e pushato"
          # il patto del turno è la PR BOZZA (mai pronta, mai su main): --draft.
          # --head e --base espliciti: niente inferenze su shallow clone e upstream strani
          PR_URL=$(cd "$DIR" && gh pr create --fill --draft --head "$BRANCH" --base "$DB" 2>&1 | tail -1)
          log "Issue #$NUM: PR $PR_URL"
          log "Issue #$NUM: $(lente_pr "$DIR" "origin/$DB" "$BRANCH" "$PR_URL")"  # D2: lente sicurezza automatica
          case "$PR_URL" in
            https*) PR_CREATED=$((PR_CREATED+1)) ;;
            *) log "⚠ Issue #$NUM: PR NON creata ($PR_URL)"; FAILED=$((FAILED+1)) ;;
          esac
        else
          log "⚠ Issue #$NUM: commit/push FALLITO — fix applicato in $DIR ma non consegnato"
          FAILED=$((FAILED+1))
        fi
      else
        log "Issue #$NUM: risolutore non ha converto (rc=$RC) — si passa oltre"
        FAILED=$((FAILED+1))
        # (2026-09-16): CATEGORIZZA il fallimento — i pattern ricorrenti diventano
        # categorie di fix nuove. La notte non corregge qui, ma il mattino trova
        # la statistica pronta.
        MOTIVO_FALL=$(echo "$OUT" | grep -oE "⛔.*" | head -1 | cut -c1-80)
        [ -n "$MOTIVO_FALL" ] && log "Issue #$NUM: motivo: $MOTIVO_FALL"
        echo "  $REPO #$NUM: rc=$RC — $MOTIVO_FALL" >> "$HERE/.sal-turni-fallimenti.md" 2>/dev/null || true
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
    # (R5 R6): `exec` — il PID e' quello di opencode stesso, e si scrive: la pulizia ferma solo lui
    ( cd "$DIR" && exec opencode run --model "$OCPROVIDER" "$PROMPT" ) >> "$LOG" 2>&1 &
    AGENTE_PID=$!
    echo "$AGENTE_PID" > "$OPENCODE_PID_FILE"
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
    # (revisione 10 giri, 2026-09-23): era `local OP_RC=$?` — l'esito dell'`if` appena chiuso,
    # sempre 0: il ramo «OpenCode fallito» (commento sull'issue, regola dell'A/B) era MORTO.
    # L'esito dell'agente e' RC, letto dal `wait` qui sopra.
    local OP_RC=$RC
    ferma_opencode_del_turno "$OPENCODE_PID_FILE" || true

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

    # (T5#2b, 2026-09-24): qui resta `add -A` — i file nuovi di opencode (un test, un modulo) sono il suo
    # lavoro e opencode non li dichiara. Se debbano passare da una dichiarazione e' una domanda (DEBITI).
    git -C "$DIR" add -A
    git -C "$DIR" commit -q -m "$CTYPE: night issue #$NUM — $TITLE" || { log "Issue #$NUM: commit fallito"; FAILED=$((FAILED+1)); continue; }
    F=$(forme_prima_del_push "$DIR" "origin/$DB") || { log "Issue #$NUM: $F"; FAILED=$((FAILED+1)); continue; }  # T5#3: prima del push
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

    log "Issue #$NUM: $(lente_pr "$DIR" "origin/$DB" "$BRANCH" "$PR_URL")"  # D2: lente sicurezza automatica
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
  TOT_PROPOSTE=$((TOT_PROPOSTE+PROPOSTE))
  TOT_FAILED=$((TOT_FAILED+FAILED))
  TOT_SKIPPED_DESIGN=$((TOT_SKIPPED_DESIGN+SKIPPED_DESIGN))
  log "REPO $REPO FINITA: $PR_CREATED PR bozza, $PROPOSTE proposte in issue, $FAILED fallite, $SKIPPED_DESIGN saltate per Design/Territorio"
}

# --- Esecuzione -----------------------------------------------------------------
# (il lock globale del turno si prende in testa allo script: vedi prendi_lock_turno)

# il SECONDO CERVELLO (2026-09-21): una domanda al giorno, la prima del giorno.
# Compila gli sospesi (note tipo:sospeso + PR aperte) in modo DETERMINISTICO e
# lascia il risultato in $WORK/.cervello-<data> per il mattino. Il grafo si
# interroga; il diario resta alla SAL. Fallita = niente marker = riprova al
# prossimo ciclo (dichiarato nel log, non taciuto).
CERVELLO_MARKER="$WORK/.cervello-$(date +%F)"
if [ ! -f "$CERVELLO_MARKER" ] && [ -f "$HERE/../tools/cervello-domanda.sh" ]; then
  if bash "$HERE/../tools/cervello-domanda.sh" in-sospeso > "$CERVELLO_MARKER.tmp" 2>/dev/null; then
    mv "$CERVELLO_MARKER.tmp" "$CERVELLO_MARKER"
    log "cervello: domanda del giorno fatta ($(grep -c '^  -' "$CERVELLO_MARKER" || true) voci in sospeso) — il mattino la legge in $CERVELLO_MARKER"
  else
    rm -f "$CERVELLO_MARKER.tmp"
    log "cervello: domanda del giorno fallita — riprovo al prossimo ciclo"
  fi
fi

# il /learn del sistema (rubato a everything-claude-code, 2026-09-22): una volta
# al giorno, dalle 22 in poi, il turno distilla UNA lezione dal log del giorno e
# la propone come nota del cervello DA APPROVARE al mattino — mai auto-salvata
# (il loro auto_approve:false e' il nostro ASPETTA IL GIORNO). Fallita = niente
# marker = riprova al prossimo ciclo.
# (2026-09-25, settimo ventaglio, V3 R6): se nessun ciclo e' PARTITO fra le 22 e mezzanotte (un'issue dura fino a 240
# minuti), la lezione di ieri non si faceva piu', e nessuna riga lo diceva. Al primo ciclo di oggi si recupera, sul log
# intero di ieri — solo se ieri il turno ha scritto qualcosa.
IMPRA_IERI=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F 2>/dev/null)
if [ -n "$IMPRA_IERI" ] && [ ! -f "$WORK/.impara-$IMPRA_IERI" ] && [ -f "$HERE/../tools/cervello-impara.sh" ] \
   && grep -ac "^\[$IMPRA_IERI" "${NIGHT_LOG:-$HOME/night-shift-console.log}" >/dev/null 2>&1; then
  log "impara: la lezione di ieri ($IMPRA_IERI) manca — nessun ciclo e' partito dopo le ${IMPARA_ORA:-22}: la faccio ora, sul log di ieri"
  if IMP_OUT=$(IMPARA_DATA="$IMPRA_IERI" bash "$HERE/../tools/cervello-impara.sh" 2>&1); then
    printf '%s\n' "$IMP_OUT" > "$WORK/.impara-$IMPRA_IERI"
    log "impara (ieri): $(echo "$IMP_OUT" | head -1)"
  else
    log "impara (ieri): fallito (dichiarato) — riprovo al prossimo ciclo"
  fi
fi
IMPRA_MARKER="$WORK/.impara-$(date +%F)"
if [ ! -f "$IMPRA_MARKER" ] && [ "$(date +%H)" -ge "${IMPARA_ORA:-22}" ] && [ -f "$HERE/../tools/cervello-impara.sh" ]; then
  if IMP_OUT=$(bash "$HERE/../tools/cervello-impara.sh" 2>&1); then
    printf '%s\n' "$IMP_OUT" > "$IMPRA_MARKER"
    log "impara: $(echo "$IMP_OUT" | head -1)"
  else
    log "impara: fallito (dichiarato) — riprovo al prossimo ciclo"
  fi
fi

# il GRAFO SEMANTICO (D1, Luca 2026-09-23: «la notte, Ollama»): una volta al giorno, in
# BACKGROUND — un pass sui documenti a ~4 tok/s dura ore e il ciclo non lo aspetta. Hub + ogni
# repo del turno; ogni grafo cambiato diventa una PR in bozza (tools/grafo-semantico.sh). Il lock
# evita due pass insieme; un lock oltre le 24h e' un pass morto: si toglie e si dichiara.
# (settimo ventaglio, V3 R2): la data si calcola una volta e va al pass, che la usa per ramo, commit e titolo.
GRAFO_DATA=$(date +%F); GRAFO_MARKER="$WORK/.grafo-$GRAFO_DATA"; GRAFO_LOCK="$WORK/.lock-grafo"
# (2026-09-24, sesto ventaglio, S4 R6): il segno del giorno si scriveva PRIMA del pass, e il lock non aveva il PID —
# un turno ucciso a meta' pass lasciava segno e lock, e il pass mancava in silenzio fino a 24 ore. Ora il lock porta
# il PID del pass (la regola di lock_turno_orfano: PID morto = lock orfano), e il segno si scrive a pass finito.
# (2026-09-25, settimo ventaglio, V3 R3): col PID nel lock decide solo il PID — vivo, il lock resta a qualunque eta'
# (prima oltre le 24 ore si toglieva anche col pass vivo: due extract sulla stessa copia). Le 24 ore valgono per i lock
# senza PID (versione vecchia). Il PID si legge prima di cancellare: il messaggio diceva sempre «PID ?».
if [ -d "$GRAFO_LOCK" ]; then
  GRAFO_PID=$(cat "$GRAFO_LOCK/pid" 2>/dev/null); GRAFO_ETA=$(( $(date +%s) - $(mtime "$GRAFO_LOCK") ))
  if { [ -n "$GRAFO_PID" ] && lock_turno_orfano "$GRAFO_LOCK" night-shift; } || { [ -z "$GRAFO_PID" ] && [ "$GRAFO_ETA" -ge 86400 ]; }; then
    rm -rf "$GRAFO_LOCK" && log "grafo semantico: lock di un pass morto (PID ${GRAFO_PID:-assente, oltre 24h}) rimosso — il pass riparte"
  elif [ -n "$GRAFO_PID" ] && [ "$GRAFO_ETA" -ge 86400 ]; then
    log "grafo semantico: ⚠ pass VIVO da oltre 24 ore (PID $GRAFO_PID) — non si tocca e non se ne avvia un secondo"
  fi
fi
if [ ! -f "$GRAFO_MARKER" ] && [ -f "$HERE/../tools/grafo-semantico.sh" ] && command -v graphify >/dev/null 2>&1 \
   && mkdir "$GRAFO_LOCK" 2>/dev/null; then
  GRAFO_REPO=("obi2kenobi/AI_Programmer"); for E in "${REPO_LIST[@]}"; do [ "${E%% *}" = "${GRAFO_REPO[0]}" ] || GRAFO_REPO+=("${E%% *}"); done
  ( for R in "${GRAFO_REPO[@]}"; do GRAFO_DATA="$GRAFO_DATA" MODELLO="$MODEL_TAG" bash "$HERE/../tools/grafo-semantico.sh" "$R" "$WORK"; done \
      >> "$WORK/grafo-semantico.log" 2>&1; touch "$GRAFO_MARKER"; rm -rf "$GRAFO_LOCK" ) &
  echo $! > "$GRAFO_LOCK/pid"
  log "grafo semantico: avviato in background su ${#GRAFO_REPO[@]} repo (PID $!, log: $WORK/grafo-semantico.log)"
elif [ ! -f "$GRAFO_MARKER" ] && ! command -v graphify >/dev/null 2>&1; then
  log "grafo semantico: graphify ASSENTE — pass saltato (DEGRADATO; pip install graphifyy)"
fi

log "=== TURNO INIZIATO (${#REPO_LIST[@]} repo in coda) ==="
T_CICLO_INIZIO=$(date +%s)   # per la pausa dei cicli a vuoto (D17)

# (2026-09-20): il WATCHDOG di Ollama. Il server (0.32.14) si inceppa sotto
# carico: resta su (tags risponde) ma le generazioni muoiono. L'agente si
# rianima da solo DENTRO le sue finestre, ma fra le finestre nessuno guardava:
# un wedge alle 14:45 ha ucciso agenti per 18 minuti e rosso la suite. Da qui:
# a OGNI inizio ciclo, un ping di GENERAZIONE (non tags: quello risponde anche
# da wedged); muto = kill del serve, launchd lo riporta, si aspetta. Il turno
# non parte mai con un cervello morto accanto.
# (revisione 10 giri, 2026-09-23): il modello del ping era scritto a mano — con MODELLO cambiato
# il ping chiedeva un modello assente, tornava vuoto e il watchdog uccideva Ollama a ogni ciclo
PING_JSON=$(jq -cn --arg m "$MODEL_TAG" '{model:$m, messages:[{role:"user",content:"Say OK"}], stream:false, think:false, keep_alive:-1}')
OLLM_PING=$(curl -s --max-time 25 http://localhost:11434/api/chat -d "$PING_JSON" 2>/dev/null | jq -r '.message.content // empty' 2>/dev/null)
if [ -z "$OLLM_PING" ]; then
  log "⚠ Ollama wedged al via del turno (ping di generazione muto): lo rianimo (custode se c'e', istanza propria se no)"
  rianima_ollama 2>&1 | while IFS= read -r l; do log "$l"; done
  OLLM_PING=$(curl -s --max-time 60 http://localhost:11434/api/chat -d "$PING_JSON" 2>/dev/null | jq -r '.message.content // empty' 2>/dev/null)
  if [ -n "$OLLM_PING" ]; then
    log "✓ Ollama rianimato dal watchdog del turno"
  else
    log "⚠⚠ Ollama NON risponde nemmeno dopo il rilancio: il turno gira senza cervello (le lenti dichiareranno)"
  fi
fi

# PULIZIA RAMI NOTTE STANTI (2026-09-16): i rami notte/auto-* piu' vecchi di 24h
# sul remoto sono scarti (PR fusa o mai create). Con 53 cicli a notte, i rami si
# accumulano se nessuno li pulisce.
# (revisione 10 giri, 2026-09-23): le 24h erano solo nel commento (nessun controllo d'eta') e
# la PR si cercava per SOTTOSTRINGA (notte/auto-1 «trovava» la PR di notte/auto-12). La
# decisione ora vive in lib.sh rami_da_scopare (testata), con le date dal clone dell'hub.
RAMI_TSV=$(mktemp); PR_TSV=$(mktemp)
if git -C "$HERE" fetch -q --prune origin 2>/dev/null \
   && git -C "$HERE" for-each-ref refs/remotes/origin --format='%(refname:lstrip=3)%09%(committerdate:unix)' 2>/dev/null | grep -v '^HEAD' > "$RAMI_TSV" \
   && gh pr list -R obi2kenobi/AI_Programmer --state all --limit 1000 --json headRefName,state -q '.[] | [.headRefName, .state] | @tsv' > "$PR_TSV" 2>/dev/null; then
  SCOPA_OK=1
else
  SCOPA_OK=0
  log "pulizia rami: fetch o lista PR falliti — non cancello niente (senza date o PR la scopa e' cieca)"
fi
if [ "$SCOPA_OK" -eq 1 ]; then
  for B in $(rami_da_scopare "$(date +%s)" 24 "$RAMI_TSV" "$PR_TSV" | grep "^notte/auto-" | head -10); do
    gh api -X DELETE "repos/obi2kenobi/AI_Programmer/git/refs/heads/${B//\//%2F}" >/dev/null 2>&1 \
      && log "pulizia: ramo notte stante '$B' cancellato (PR fusa/chiusa, o nessuna PR da oltre 24h)"
  done
fi
GLOBAL_RC=0
TOT_PR_CREATED=0
TOT_PROPOSTE=0
TOT_FAILED=0
# globale perche' l'heredoc del SAL la legge fuori da shift_repo (D2: unbound al primo giro)
ASPETTA_GIORNO=""
TOT_SKIPPED_DESIGN=0
for ENTRY in "${REPO_LIST[@]}"; do
  shift_repo "$ENTRY" || GLOBAL_RC=1
done
log "=== TURNO FINITO ==="

# Giro 9/10: il turno scrive la propria memoria (non dipende da chi ricorda).
# MAI nella SAL.md del repo: un file tracciato modificato romperebbe il self-pull
# --ff-only della notte dopo (la SAL cambia quasi ogni giorno: conflitto garantito,
# turno fermo sul metodo di ieri). Prima puntava a night-shift/SAL.md, che non è mai
# esistito: no-op silenzioso colpevole di giri interi (giri 3/5, 2026-09-06).
# File locale GITIGNORED: la memoria del turno sopravvive, il pull non si accorge.
HUB_SAL="$HERE/.sal-turni.md"
# (D26, test del sistema completo 2026-09-20): una voce per ciclo, 24/7, e il digest la
# svuota SOLO se DIGEST_EMAIL e' configurata — altrimenti il file cresceva per sempre.
# Rotazione a 1 MB (una generazione, come i log): la memoria resta, il disco no.
rotate_log_if_big "$HUB_SAL" 1
if true; then
  DT=$(date '+%Y-%m-%d')
  # (2026-09-24, quinto ventaglio, R4 R4): il digest contava i fix nelle 20 righe di coda qui sotto, finestre
  # che si sovrappongono fra cicli. Il numero si scrive nell'intestazione, come le PR: i fix riusciti
  # («auto-fix — …») dall'ultimo «TURNO INIZIATO» del log.
  TOT_AUTOFIX=$(awk '/TURNO INIZIATO/{n=0} /auto-fix — /{n++} END{print n+0}' "$LOG" 2>/dev/null); TOT_AUTOFIX=${TOT_AUTOFIX:-0}
  cat >> "$HUB_SAL" <<SALEOF

### $DT, turno automatico — $TOT_PR_CREATED PR bozza, $TOT_PROPOSTE proposte in issue, $TOT_FAILED fallite, $TOT_SKIPPED_DESIGN saltate per Design/Territorio, $TOT_AUTOFIX auto-fix

$(grep -aE "^\[|^--- Issue|^===== REPO" "$LOG" | tail -20 | sed 's/^/  /')

**ASPETTA IL GIORNO** (proposta pubblicata, decisione diurna pendente):$(printf '%s' "$ASPETTA_GIORNO")
SALEOF
  log "memoria del turno scritta in night-shift/.sal-turni.md (locale: il mattino la porta nella SAL)"
fi

# (dominio, Luca 2026-09-23 — l'incidente dei dati insegnava): UN RAMO FUSO NON
# SERVE A NIENTE — il lavoro vive in main, la PR resta nella storia, e un ramo
# lasciato li' e' solo un posto dove i dati vecchi sopravvivono. Scopa: ogni
# ramo remoto con PR fusa/chiusa si cancella; ogni ramo SENZA PR piu' vecchio
# di 48h e' orfano e si cancella pure. Il revisore gia' usa --delete-branch.
# (revisione 10 giri, 2026-09-23): la soglia delle 48h era solo in questo commento — il
# codice cancellava OGNI ramo senza PR, anche uno spinto un minuto prima di aprirla; e un
# ramo con una PR fusa veniva cancellato anche se una PR APERTA riusava lo stesso nome,
# chiudendola. Le regole vivono in lib.sh rami_da_scopare (testata in tests/test-lib.sh).
if command -v gh >/dev/null 2>&1 && [ "${SCOPA_OK:-0}" -eq 1 ]; then
  N_SCOPA=0
  # (2026-09-24, quinto ventaglio, R5 R2): solo i rami DEL TURNO. Prima si cancellavano anche claude/* e glm/*
  # senza PR (il ramo di una sessione web chiusa, di cui non resta copia): scelta provvisoria dichiarata, la
  # domanda (quali prefissi) e' in DEBITI.md
  for B in $(rami_da_scopare "$(date +%s)" 48 "$RAMI_TSV" "$PR_TSV" | grep -E '^(night|notte)/'); do
    gh api -X DELETE "repos/obi2kenobi/AI_Programmer/git/refs/heads/${B//\//%2F}" >/dev/null 2>&1 \
      && N_SCOPA=$((N_SCOPA+1)) && log "scopa-rami: '$B' cancellato (PR fusa/chiusa, o orfano oltre 48h)"
  done
  [ "$N_SCOPA" -gt 0 ] && log "scopa-rami: $N_SCOPA rami cancellati in tutto (un ramo fuso non serve a niente)"
fi
rm -f "$RAMI_TSV" "$PR_TSV"

# NESSUNA finestra, NESSUN sonno (Luca 2026-09-18: gira sempre, riparte subito)
# (D17, test del sistema completo 2026-09-20): con una copia rotta o la caccia in cooldown
# il turno ha fatto 390 cicli in 4,5 minuti (~8 chiamate gh per ciclo): il freno era il
# rate limit di GitHub, non il sistema. Un ciclo che NON ha prodotto nulla e chiude sotto
# il minuto dorme il resto del minuto (NIGHT_CICLO_MIN_SEC, default 60): al massimo un
# giro a vuoto al minuto, e chi lavora riparte subito come prima.
CICLO_SEC=$(( $(date +%s) - T_CICLO_INIZIO ))
if [ "$TOT_PR_CREATED" -eq 0 ] && [ "$TOT_PROPOSTE" -eq 0 ] && [ "$CICLO_SEC" -lt "${NIGHT_CICLO_MIN_SEC:-${CICLO_MIN_SEC:-60}}" ]; then
  PAUSA=$(( ${NIGHT_CICLO_MIN_SEC:-${CICLO_MIN_SEC:-60}} - CICLO_SEC ))
  log "=== TURNO FINITO — ciclo a vuoto in ${CICLO_SEC}s: pausa ${PAUSA}s prima di ripartire (niente giri a vuoto sotto il minuto) ==="
  sleep "$PAUSA"
else
  log "=== TURNO FINITO — riparto SUBITO ==="
fi
# il lock NON si rilascia: il ciclo dopo l'exec ha lo stesso PID e lo ritrova suo (Q10).
# (Q12): ripartiva da $0 — lanciato come `bash night-shift.sh` da dentro night-shift/, $0 e'
# relativo e dopo il `cd` alla radice non esiste: il turno moriva al primo giro. E voleva +x.
exec bash "$HERE/night-shift.sh" "$@"

exit $GLOBAL_RC
