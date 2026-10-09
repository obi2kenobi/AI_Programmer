#!/bin/bash
# giorno.sh — l'HARNESS di chi programma di giorno (2026-10-09).
#
# Luca: «AI_Programmer deve essere un harness piu' per il giorno che per la
# notte: lenti, agenti e tutti i sistemi anche di giorno, per chi programma».
# Fino a ieri le armi (lente sicurezza, cancello dei segreti, dichiarazione dei
# file nuovi, trailer, censore) erano cablate SOLO nel turno notturno: chi
# consegnava alle 11 di mattina passava accanto ai cancelli. Questo tool e' il
# turno del giorno: riusa le STESSE funzioni della notte (night-shift/lib.sh —
# niente copie, la pipeline non vive in due posti), con due differenze dichia-
# rate: il reset in caso di gate bocciato e' SOFT (il lavoro di una persona non
# si distrugge: quello della notte e' rigenerabile dal modello, questo no) e il
# censore si consulta a comando (parere, MAI fusione: D10 vale anche di giorno).
#
# Uso:
#   giorno.sh consegna <dir> "<messaggio>"   working tree → ramo giorno/* → gate → push → PR → lente
#   giorno.sh lente <dir> [base]             il rapporto della lente sicurezza sul diff (base...HEAD)
#   giorno.sh parere <dir> <n-pr>            il censore giudica la PR #n (parere, mai fusione)
#   giorno.sh handoff <dir> "<titolo>" "[corpo]"  il passamano giorno->notte: issue [handoff]
#   giorno.sh bilancino [data]               il conto del giorno: consegne/lenti/pareri per repo
#
# Il log del giorno: $GIORNO_LOG (default ~/giorno.log), una riga per azione —
# e' la controparte del night-shift.log: domani «cosa ha prodotto il giorno?»
# ha una risposta letta dal log vero (stessa filosofia del bilancino).
# Tutto LLM-agnostic: bash + il modello che gia' gira (LENTE_STUB passa attraverso).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"   # default_branch, aggiungi_consegna, forme_prima_del_push, lente_pr
GIORNO_LOG="${GIORNO_LOG:-$HOME/giorno.log}"
CMD="${1:-}"
[ -n "$CMD" ] || { echo "uso: giorno.sh consegna <dir> <msg> | lente <dir> [base] | parere <dir> <n> | handoff <dir> <titolo> [corpo] | annota <dir> <n-pr> | osserva <dir> [cmd] | bilancino [data]" >&2; exit 2; }
log() { echo "[giorno $(date '+%H:%M:%S')] $*" >&2; }
riga_giorno() { echo "[GIORNO $(date '+%F %T')] REPO ${1##*/}: $2" >> "$GIORNO_LOG"; }

# corpo_da_destinazioni <pr-body|issue-comment> — il testo su stdin esce senza le
# righe colpevoli. Il cancello le elenca INDENTATE dopo la sua intestazione: si
# tolgono TUTTE, esatte. (Il primo giro filtrava l'uscita grella del tool: non
# matchava niente e l'email restava nel corpo — banco del 2026-10-09.)
corpo_da_destinazioni() {
  local dest="$1" testo out sporche f
  testo=$(cat)
  out=$(printf '%s' "$testo" | bash "$HERE/tools/destinazioni-pulite.sh" "$dest" 2>/dev/null) || true
  sporche=$(sed -n 's/^  //p' <<<"$out")
  if [ -n "$sporche" ]; then
    log "cancello destinazioni ($dest): righe con dati personali rimosse"
    f=$(mktemp "${TMPDIR:-/tmp}/giorno-dest.XXXXXX")
    printf '%s\n' "$sporche" > "$f"
    grep -vxF -f "$f" <<<"$testo" || true
    rm -f "$f"
  else
    printf '%s' "$testo"
  fi
}

case "$CMD" in

# ── consegna: la pipeline della notte, con la mano del giorno ────────────────────
consegna)
  # (dal flusso reale della Vetrina, 2026-10-09): la prima consegna di un
  # progetto nuovo e' TUTTI file nuovi — senza dichiarazione li sposta tutti
  # in .git/consegna-fuori (disciplina giusta per la notte, che dichiara via
  # dichiara_file_nuovo; per il giorno servono gli argomenti, o --tutto quando
  # e' la persona a prendersi la responsabilita' dell'albero intero).
  TUTTO=0
  ARGS=()
  for a in "${@:3}"; do
    case "$a" in
      --tutto) TUTTO=1 ;;
      *) ARGS+=("$a") ;;
    esac
  done
  [ ${#ARGS[@]} -ge 1 ] || { echo "uso: giorno.sh consegna <dir> \"<messaggio>\" <file...|--tutto>" >&2; exit 2; }
  DIR="$2"; MSG="${ARGS[0]}"
  DICHIARATI=("${ARGS[@]:1}")
  [ -d "$DIR/.git" ] || { echo "⛔ non è un repo git: $DIR" >&2; exit 2; }
  cd "$DIR"
  DB=$(default_branch "$DIR")
  git rev-parse -q --verify "origin/$DB" >/dev/null 2>&1 || { log "⛔ niente origin/$DB: senza remoto non c'e' consegna"; exit 2; }
  [ -n "$(git status --porcelain 2>/dev/null)" ] || { log "niente da consegnare: working tree pulito"; exit 2; }
  # ramo del giorno: mai si committa sul ramo di partenza; piu' consegne della
  # stessa sessione viaggiano sullo stesso ramo giorno/*
  BR=$(git branch --show-current)
  case "$BR" in
    giorno/*) ;;
    # (edge dichiarato, dal banco del flusso reale): due consegne nello STESSO
    # secondo generano lo stesso nome ramo — la seconda va a monte sul push
    *) BR="giorno/$(date +%Y%m%d-%H%M%S)"; git checkout -b "$BR" -q ;;
  esac
  GD_CONSEGNA=$(git -C "$DIR" rev-parse --absolute-git-dir 2>/dev/null)
  if [ "$TUTTO" -eq 1 ]; then
    # --tutto: dichiara ogni non-tracciato (idioma del flusso reale: git ls-files
    # --others, ricorsivo — le sottodirectory non si perdono come con ls */*)
    { cd "$DIR" && git ls-files --others --exclude-standard; } > "$GD_CONSEGNA/agente-file-nuovi"
    log "dichiaro TUTTO il non-tracciato ($(grep -c . "$GD_CONSEGNA/agente-file-nuovi") file): la responsabilita' e' di chi ha detto --tutto"
  elif [ ${#DICHIARATI[@]} -gt 0 ]; then
    printf '%s\n' "${DICHIARATI[@]}" >> "$GD_CONSEGNA/agente-file-nuovi"
  fi
  aggiungi_consegna "$DIR" ${DICHIARATI[@]+"${DICHIARATI[@]}"}   # i file nuovi NON dichiarati restano fuori (e si dice)
  git commit -qm "$MSG" -m "Turno: giorno" || { log "⛔ commit fallito — niente consegna"; exit 1; }
  if ! forme_prima_del_push "$DIR" "origin/$DB"; then
    git reset -q --soft HEAD~1   # SOFT, non hard: il lavoro di una persona non si distrugge (dichiarato)
    log "⛔ consegna fermata dal cancello dei segreti: commit sciolto (soft), lavoro in albero, ramo $BR"
    riga_giorno "$DIR" "consegna BLOCCATA dal cancello (forme di segreto)"
    exit 1
  fi
  PUSH_OUT=$(git push -u origin "$BR" 2>&1); PUSH_RC=$?
  tail -2 <<<"$PUSH_OUT" >&2
  [ "$PUSH_RC" -eq 0 ] || { log "⛔ push fallito"; exit 1; }
  BODY_PR="Consegna del turno di GIORNO attraverso il cancello condiviso: lente sicurezza automatica, forme di segreto verificate prima del push, file nuovi solo se dichiarati. Il censore lascia il parere a comando (giorno.sh parere) — la fusione resta umana."
  # il corpo passa dal cancello delle destinazioni (come i corpi PR della notte)
  BODY_PR=$(printf '%s' "$BODY_PR" | corpo_da_destinazioni pr-body)
  PR_URL=$(gh pr create --draft --head "$BR" --title "giorno: $MSG" --body "$BODY_PR" 2>&1 | tail -1)
  case "$PR_URL" in
    https://*)
      VERDETTO=$(lente_pr "$DIR" "origin/$DB" "$BR" "$PR_URL")
      log "$VERDETTO"
      riga_giorno "$DIR" "consegna → $PR_URL · $(tail -1 <<<"$VERDETTO" | grep -oE 'LENTE SICUREZZA: .*' || echo lente?)"
      echo "$PR_URL"
      ;;
    *) log "⚠ ramo $BR spinto ma PR NON creata: $PR_URL"; riga_giorno "$DIR" "consegna spinta senza PR ($BR)"; exit 1 ;;
  esac
  ;;

# ── lente: il rapporto, senza consegnare ─────────────────────────────────────────
lente)
  [ $# -ge 2 ] || { echo "uso: giorno.sh lente <dir> [base]" >&2; exit 2; }
  DIR="$2"
  BASE="${3:-origin/$(default_branch "$DIR")}"
  cd "$DIR" || exit 2
  bash "$HERE/tools/lente-sicurezza.sh" "$DIR" "$BASE" HEAD
  RC=$?
  riga_giorno "$DIR" "lente ($BASE...HEAD): rc=$RC"
  exit "$RC"
  ;;

# ── parere: il censore a comando — parere, MAI fusione (D10 anche di giorno) ────
parere)
  [ $# -ge 3 ] || { echo "uso: giorno.sh parere <dir> <n-pr>" >&2; exit 2; }
  DIR="$2"; N="$3"
  [ -f "$HERE/night-shift/revisore.sh" ] || { echo "⛔ revisore.sh assente" >&2; exit 2; }
  log "censore in parere sulla PR #$N di ${DIR##*/} — parere, mai fusione"
  OUT=$(bash "$HERE/night-shift/revisore.sh" "$DIR" "$N" 2>&1); RC=$?
  grep -aE "DELIBERA|PARERE:|canone|rigett" <<<"$OUT" | sed 's/^\[revisore [^]]*\] //' | head -6
  riga_giorno "$DIR" "parere PR #$N (rc=$RC)"
  exit "$RC"
  ;;

# ── handoff: il passamano giorno→notte (il terzo pezzo dell'harness) ────────────
# La notte lavora le ISSUE per prime: la coda e' gia' il suo canale. Un handoff
# e' un'issue etichettata che dice cosa il giorno lascia — decisioni prese,
# lavoro a metà, cosa verificare sul vivo. Nessuna nuova strada da cablare nel
# turno: la issue VIENE lavorata, e si chiude quando e' consumata.
handoff)
  [ $# -ge 3 ] || { echo "uso: giorno.sh handoff <dir> \"<titolo>\" \"[corpo]\"" >&2; exit 2; }
  DIR="$2"; TITOLO="$3"; CORPO="${4:-}"
  cd "$DIR" || exit 2
  # il corpo passa dal cancello delle destinazioni (l'issue e' pubblica come le PR)
  CORPO_PULITO=$(printf '%s' "$CORPO" | corpo_da_destinazioni issue-comment)
  gh label create handoff --color 5319e7 --description "passamano giorno→notte" >/dev/null 2>&1 || true   # esiste gia' o niente permessi: si va avanti senza etichetta
  BODY_H="Handoff del turno di GIORNO ($(date '+%F %H:%M')).

$CORPO_PULITO

---
Lasciato dal giorno per la notte: il turno lavora le issue per prime — questa
e' la sua coda. Va chiusa quando il contenuto e' stato consumato (fatto, o
tradotto in lavoro vero), non prima."
  URL_H=$(cd "$DIR" && gh issue create --label handoff --title "[handoff] $TITOLO" --body "$BODY_H" 2>&1 | tail -1)
  case "$URL_H" in
    https://*) log "handoff aperto: $URL_H"; riga_giorno "$DIR" "handoff → $URL_H"; echo "$URL_H" ;;
    *) log "⚠ handoff NON aperto: $URL_H"; riga_giorno "$DIR" "handoff NON aperto ($TITOLO)"; exit 1 ;;
  esac
  ;;

# ── annota: righe errorformat → annotazioni SULLA RIGA della PR (furto reviewdog)
annota)
  [ $# -ge 3 ] || { echo "uso: giorno.sh annota <dir> <n-pr> (errorformat su stdin)" >&2; exit 2; }
  DIR="$2"; N="$3"
  REPO_URL=$(git -C "$DIR" remote get-url origin 2>/dev/null) || { echo "⛔ niente origin in $DIR" >&2; exit 2; }
  REPO_SLUG=$(sed -n 's#.*github.com[:/]\([^/]*/[^.]*\)\(\.git\)\?$#\1#p' <<<"$REPO_URL" | head -1)
  [ -n "$REPO_SLUG" ] || { echo "⛔ origin non GitHub: $REPO_URL" >&2; exit 2; }
  bash "$HERE/tools/annota.sh" "$REPO_SLUG" "$N"
  RC=$?
  riga_giorno "$DIR" "annota PR #$N (rc=$RC)"
  exit "$RC"
  ;;

# ── osserva: il ciclo stretto del giorno (salvi, il banco riparte) ─────────────
# (furto da watchexec/entr: il feedback loop Change→Verify in un comando; qui
# girano il .night-verify del repo o il comando che dici). Ctrl-C per uscire.
osserva)
  [ $# -ge 2 ] || { echo "uso: giorno.sh osserva <dir> [comando]" >&2; exit 2; }
  DIR="$2"; CMD_O="${3:-}"
  if [ -z "$CMD_O" ]; then
    if [ -f "$DIR/.night-verify" ]; then
      CMD_O="bash .night-verify"
    else
      log "niente da osservare: senza .night-verify serve il comando come terzo argomento (es.: \"bash tests/test-giorno.sh\")"
      exit 2
    fi
  fi
  WATCHEXEC="${WATCHEXEC_BIN:-watchexec}"
  if ! command -v "$WATCHEXEC" >/dev/null 2>&1; then
    log "⚠ watchexec assente — osserva SALTATO (dichiarato: brew install watchexec)"
    exit 0
  fi
  log "osservo ${DIR##*/}: a ogni modifica gira \"$CMD_O\" (Ctrl-C per uscire; .gitignore rispettato)"
  riga_giorno "$DIR" "osserva avviato ($CMD_O)"
  cd "$DIR" || exit 2
  exec "$WATCHEXEC" -w . -- $CMD_O
  ;;

# ── bilancino: il conto del giorno, letto dal log vero ───────────────────────────
bilancino)
  DATA="${2:-$(date +%F)}"
  [ -f "$GIORNO_LOG" ] || { echo "giorno.sh bilancino: nessun log ($GIORNO_LOG) — il giorno non ha ancora consegnato niente"; exit 0; }
  RIGHE=$(grep "^\[GIORNO $DATA " "$GIORNO_LOG" 2>/dev/null || true)
  [ -n "$RIGHE" ] || { echo "GIORNO $DATA: nessuna azione registrata"; exit 0; }
  printf '%s\n' "$RIGHE" | sed 's/^\[GIORNO [^]]*\] REPO //' | awk '{
    repo=$1; sub(/:.*$/, "", repo)
    azione="altro"
    if ($0 ~ /consegna →/) azione="consegna"
    else if ($0 ~ / BLOCCATA /) azione="bloccate"
    else if ($0 ~ /[^a-z]lente([^a-z]|$)/) azione="lenti"
    else if ($0 ~ /parere/) azione="pareri"
    else if ($0 ~ /handoff →/) azione="handoff"
    conta[repo"|"azione]++
    repos[repo]=1
  } END {
    for (r in repos)
      printf "%s: %d consegne, %d bloccate, %d lenti, %d pareri, %d handoff\n", r,
        conta[r"|consegna"]+0, conta[r"|bloccate"]+0, conta[r"|lenti"]+0, conta[r"|pareri"]+0, conta[r"|handoff"]+0
  }'
  ;;

*)
  echo "uso: giorno.sh consegna <dir> <msg> | lente <dir> [base] | parere <dir> <n> | handoff <dir> <titolo> [corpo] | annota <dir> <n-pr> | osserva <dir> [cmd] | bilancino [data]" >&2
  exit 2
  ;;
esac
