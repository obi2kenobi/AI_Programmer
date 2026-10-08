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
# (2026-09-24, Q3 R4): `${1:?}` usciva 1, che qui significa «fallito»: l'uso sbagliato esce 2, come dichiarato
[ $# -ge 2 ] || { echo "uso: agente.sh <dir> <prompt>" >&2; exit 2; }
DIR="$1"; PROMPT="$2"
MODEL="${NIGHT_MODEL:-${MODELLO:-qwen3.8-27b:iq3s}}"   # MODELLO: il profilo del turno (D11)
# shellcheck source=lib.sh
source "$HERE/night-shift/lib.sh"   # gate_allowlist_ok: l'allowlist di sola lettura del censore
# NIGHT_API_URL: solo per i test (server mock, stesso contratto del solver) — di norma non si tocca
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"
MAX_TURNI="${AGENTE_MAX_TURNI:-8}"
PENSA=$( [ "${THINK:-false}" = "true" ] && echo true || echo false )   # THINK del profilo (D11): solo true|false arrivano a jq
TIMEOUT_TOTALE="${AGENTE_TIMEOUT:-600}"  # (2026-09-21: 300 non bastano al 27B quando paga un ricarico in coda)

[ -d "$DIR" ] || { echo "⛔ dir inesistente: $DIR" >&2; exit 2; }
# (Q2 R2): senza jq il corpo della richiesta restava vuoto e l'agente accusava Ollama (e lo rianimava)
MANCANO=$(dipendenze_mancanti jq curl) || { echo "⛔ MANCA $MANCANO: l'agente non parte — ogni diagnosi del modello sarebbe falsa" >&2; exit 2; }
cd "$DIR"

# percorso_ammesso <realpath> <realpath-progetto>: 0 se il percorso sta dentro il progetto e NON dentro un `.git`.
# (2026-09-25, ottavo ventaglio, O1 R1): `.git/` sta dentro il progetto, e il confine lo ammetteva. Una voce di
# .git/config (o un hook) puo' essere un comando che git esegue: lo scriveva il modello con un edit, e lo eseguivano
# poi tutti i git del turno — fuori dalla sandbox, e a ogni notte, perche' reset --hard non tocca .git/config.
percorso_ammesso() {
  case "$1" in */.git|*/.git/*) return 1 ;; esac
  case "$1" in "$2"|"$2"/*) return 0 ;; esac
  return 1
}

log() { echo "[agente $(date '+%H:%M:%S')] $*" >&2; }
T_INIZIO=$(date +%s)

# il system prompt: di default è il generico, ma se AGENTE_SYSTEM_FILE punta a un file
# (agente o skill dell'hub), quel file DIVENTA l'intelligenza del turno.
# (2026-09-18, intuizione di Luca: usiamo le lenti e gli agenti che già esistono)
AGENTE_INTELLIGENZA=""
if [ -z "${AGENTE_SYSTEM_FILE:-}" ] && [ -f "$HERE/night-shift/cervello-notturno.md" ]; then
  # (2026-09-20): ogni cervello NUOVO parte col briefing del turno notturno —
  # chi e', di che catena e' l'ingranaggio, le regole d'onore. Non serve piu'
  # spiegare al modello cosa fare: lo spieghiamo una volta, qui.
  AGENTE_SYSTEM_FILE="$HERE/night-shift/cervello-notturno.md"
fi
if [ -n "${AGENTE_SYSTEM_FILE:-}" ] && [ -f "$AGENTE_SYSTEM_FILE" ]; then
  AGENTE_INTELLIGENZA=$(head -c 4000 "$AGENTE_SYSTEM_FILE")
  log "intelligenza: $(basename "$AGENTE_SYSTEM_FILE") ($(wc -c < "$AGENTE_SYSTEM_FILE" | tr -d ' ') bytes)"
fi

SYSTEM="You are a coding agent working in a project directory. You can:
1. READ a file: respond with JSON {\"action\":\"read\",\"path\":\"filename\"}
2. EDIT a file (PREFERRED for any change): respond with JSON {\"action\":\"edit\",\"path\":\"filename\",\"old\":\"the EXACT current text copied byte for byte from what you read\",\"new\":\"the replacement text\"}. The edit FAILS if old is not found or appears more than once: read first, copy exactly, include surrounding lines when needed.
3. WRITE a full file: ONLY to create a NEW file — never to modify an existing one.
4. RUN a command: respond with JSON {\"action\":\"run\",\"command\":\"the command\"}
5. FINISH: respond with your final answer as plain text (no JSON).

Rules: always READ before EDIT. One action per response. Minimal diffs: edit only the lines that must change, keep everything else byte-identical. When done, respond with your final answer as text.

${AGENTE_INTELLIGENZA:+
YOUR SPECIALIST EXPERTISE (from AI_Programmer):
$AGENTE_INTELLIGENZA

Apply this expertise to the task. Cite specific patterns or rules from your specialty when relevant.}"

# la conversazione: parte con system + user
# (2026-09-23, notte dei giri, T5#6): prompt e conversazione viaggiano su STDIN verso jq e curl, mai
# negli argomenti — leggibili da `ps`, e oltre 128 KB per argomento (Linux) il comando non parte:
# la conversazione arriva a MAX_TURNI × 24 KB di file letti.
CONV=$(printf '%s' "$PROMPT" | jq -Rs --arg sys "$SYSTEM" \
  '. as $p | [{"role":"system","content":$sys},{"role":"user","content":$p}]')

TURNO=0; RIPETIZIONI=0; PREV_STRIPPED=""
# (furto giro 4, little-coder «cold-start ~7k token dichiarati»): il contesto
# iniziale si MISURA all'ingresso — prompt + contesto del progetto. La pressione
# del num_ctx (lezione #172) diventa un numero nel log, non un'ipotesi a posteriori.
log "contesto iniziale: ~$(token_stimati "$(printf '%s' "${2:-}" | wc -c | tr -d ' ')") token stimati (prompt $(printf '%s' "${2:-}" | wc -c | tr -d ' ') byte) — num_ctx 12240: la pressione si vede subito"
ANON_DIZ=$(mktemp /tmp/anon-diz-XXXXXX.json)  # diz PII: locale, attivo solo con AGENTE_ANONIMIZZA=1
while [ "$TURNO" -lt "$MAX_TURNI" ]; do
  TURNO=$((TURNO+1))
  ELAPSED=$(( $(date +%s) - T_INIZIO ))
  [ "$ELAPSED" -gt "$TIMEOUT_TOTALE" ] && { log "⛔ timeout ${TIMEOUT_TOTALE}s"; rm -f "$ANON_DIZ" 2>/dev/null
exit 3; }

  RESPONSE=$(jq -c \
    --arg m "$MODEL" \
    --argjson th "$PENSA" \
    '. as $msgs | {model:$m, messages:$msgs, stream:false, think:$th, options:{temperature:0, num_ctx:12288}}' <<<"$CONV" \
    | curl -sf --max-time 120 "$API" --data-binary @- 2>/dev/null)

  if [ -z "$RESPONSE" ]; then
    # (2026-09-19, Ollama wedged alle 17:29): il server a volte smette di
    # rispondere alle GENERAZIONI pur stando su (tags/ps rispondono) — un pkill
    # e launchd lo riportano in 15s. Prima di arrendersi: ping di generazione,
    # rianimazione, UN secondo tentativo. Meglio un riavvio che una finestra
    # morta che il turno registra come «nessuna miglioria trovata».
    PING=$(curl -s --max-time 20 "$API" -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Say OK\"}],\"stream\":false}" 2>/dev/null | jq -r '.message.content // empty' 2>/dev/null)
    if [ -z "$PING" ]; then
      log "⚠ server muto anche al ping: rianimo Ollama (lib.sh rianima_ollama: custode se c'e', istanza propria se no)"
      rianima_ollama 2>&1 | while IFS= read -r l; do log "$l"; done
    fi
    # (07:22 di stamattina): una generazione puo' morire ANCHE col server sano al
    # ping — il rianimamento non basta, serve il RIENTO. Un tentativo in piu'
    # costa secondi; la finestra morta costa mezz'ora di cooldown.
    log "generazione vuota (ping: $([ -n "$PING" ] && echo sano || echo muto)) — ritento il turno"
    RESPONSE=$(jq -c \
      --arg m "$MODEL" \
      --argjson th "$PENSA" \
      '. as $msgs | {model:$m, messages:$msgs, stream:false, think:$th, options:{temperature:0, num_ctx:12288}}' <<<"$CONV" \
      | curl -sf --max-time 120 "$API" --data-binary @- 2>/dev/null)
  fi

  [ -z "$RESPONSE" ] && { log "⛔ Ollama non ha risposto (turno $TURNO) — NESSUN rianimamento ha funzionato"; rm -f "$ANON_DIZ" 2>/dev/null
exit 1; }

  CONTENT=$(printf '%s' "$RESPONSE" | jq -r '.message.content // empty' 2>/dev/null)
  # (2026-09-24, quarto ventaglio, Q3 R1): 200 con il contenuto vuoto (un modello che pensa soltanto, un
  # contesto saturo) usciva 0 «completato», e a valle la caccia dichiarava il file pulito per 6 ore.
  # Muto non e' finito: rc 1, e il chiamante lo legge come agente fallito.
  [ -z "$CONTENT" ] && { log "⛔ risposta vuota del modello (turno $TURNO) — muto, NON completato: agente rc=1"; exit 1; }
  log "turno $TURNO (${ELAPSED}s): il modello risponde"
  # (furto giro 7, context-monitor di cc-safe-setup): pressione a soglie GRADUATE —
  # il turno accumula; quando il num_ctx si riempie la qualita' precipita prima
  # dell'errore. A 75% si chiude: meglio una consegna parziale che un gargarismo.
  STORICO_BYTE=$(( ${#STORICO_BYTE:-0} + ${#CONTENT} ))
  SOGLIA=$(( 12240 * 7 / 2 ))   # ~75% di num_ctx, in caratteri (3.5 byte/token stimati)
  if [ "$STORICO_BYTE" -gt "$(( SOGLIA * 45 / 100 ))" ] && [ "$STORICO_BYTE" -le "$SOGLIA" ]; then
    log "⚠ contesto: ~$(( STORICO_BYTE / 350 ))0 token — oltre il 45%: si chiude presto"
  elif [ "$STORICO_BYTE" -gt "$SOGLIA" ]; then
    log "⛔ contesto saturo (~$(( STORICO_BYTE / 350 ))0 token oltre il 75% del num_ctx): chiudo con quello che c'e', meglio una consegna onesta che il gargarismo"
    exit 1
  fi
  # B) (furto giro 7, no-ask-human): la notte che CHIEDE e' un turno bruciato —
  # il promemoria torna al modello nella risposta stessa
  if grep -qaE 'Should I|dovrei chiedere|posso procedere|dimmi tu' <<<"$CONTENT"; then
    RESULT="REMINDER: you run unattended at night — nobody answers. Decide autonomously with the canon you have, act, and declare assumptions."
    log "⚠ il modello ha chiesto all'umano: promemoria di autonomia rimandato"
  fi

  # prova a parsare come JSON action (spogliando i fence markdown)
  STRIPPED=$(printf '%s' "$CONTENT" | sed 's/^```[a-z]*//; s/```$//' | tr -d '\n' | sed 's/^ *//; s/ *$//')
  # (studio dsh guard, audit-4): conteggio qui, applicazione DOPO il case —
  # prima RESULT="" a meta' giro azzerava il reminder (era un no-op)
  if [ "$STRIPPED" = "${PREV_STRIPPED:-}" ] && [ -n "$STRIPPED" ]; then
    RIPETIZIONI=$((RIPETIZIONI+1))
  else
    RIPETIZIONI=0
  fi
  PREV_STRIPPED="$STRIPPED"
  # (furto giro 2, RiskKernel «runaway halted at its loop budget»): il rilevatore
  # dei RIPETUTI identici non vede il ciclo A-B-A-B (mai due risposte uguali di
  # fila, ma otto turni persi a ronzare). Firma = azione+bersaglio; periodo 2 per
  # due cicli completi = loop dichiarato, si esce.
  SIGLA=$(echo "$STRIPPED" | jq -r '"\(.action // "?") \(.path // .target // "")"' 2>/dev/null || echo "?")
  STORICO_SIGLE="${STORICO_SIGLE:-}|${SIGLA}"
  ULTIME4=$(printf '%s' "$STORICO_SIGLE" | awk -F'|' '{if (NF>=5) print $(NF-3)"|"$(NF-2)"|"$(NF-1)"|"$NF}')
  A=$(printf '%s' "$ULTIME4" | cut -d'|' -f2)
  B=$(printf '%s' "$ULTIME4" | cut -d'|' -f3)
  C4=$(printf '%s' "$ULTIME4" | cut -d'|' -f4)
  D4=$(printf '%s' "$ULTIME4" | cut -d'|' -f5)
  if [ -n "$A" ] && [ "$A" = "$C4" ] && [ "$B" = "$D4" ] && [ "$A" != "$B" ]; then
    log "⛔ ciclo A-B rilevato (\"$A\" ↔ \"$B\" per due giri): loop dichiarato, esco al budget"
    exit 1
  fi

ACTION=$(echo "$STRIPPED" | jq -r '.action // empty' 2>/dev/null)

  # (2026-09-25, ottavo ventaglio, O1 R4): una frase prima del JSON («Leggo prima il file: {…}») perdeva l'azione. Si
  # cerca il primo oggetto con "action" dentro il testo.
  if [ -z "$ACTION" ] && grep -c '"action"' <<<"$STRIPPED" >/dev/null; then
    ESTRATTO=$(python3 -c '
import json, sys
t = sys.argv[1]; d = json.JSONDecoder(); i = t.find("{")
while i != -1:
    try:
        o, _ = d.raw_decode(t[i:])
        if isinstance(o, dict) and "action" in o:
            print(json.dumps(o)); break
    except ValueError:
        pass
    i = t.find("{", i + 1)' "$STRIPPED" 2>/dev/null)
    if [ -n "$ESTRATTO" ]; then STRIPPED="$ESTRATTO"; ACTION=$(echo "$STRIPPED" | jq -r '.action // empty' 2>/dev/null); fi
  fi
  # (ottavo ventaglio, O1 R4): un'azione che non si legge (JSON troncato da un tetto sui token) NON e' la risposta finale:
  # era «completato», rc 0, e la caccia dichiarava il file pulito per 6 ore. Torna al modello come errore di formato;
  # due di fila sono rc 1.
  if [ -z "$ACTION" ] && grep -c '"action"' <<<"$STRIPPED" >/dev/null; then
    FORMATO_ROTTO=$(( ${FORMATO_ROTTO:-0} + 1 ))
    [ "$FORMATO_ROTTO" -ge 2 ] && { log "⛔ azione illeggibile per $FORMATO_ROTTO turni di fila (JSON troncato o rotto) — NON completato: agente rc=1"; exit 1; }
    ACTION="__formato__"
  else
    FORMATO_ROTTO=0
  fi

  if [ -z "$ACTION" ]; then
    # non è un'action: il modello ha finito
    log "✅ completato in $TURNO turni (${ELAPSED}s)"
    echo "$CONTENT"
    rm -f "$ANON_DIZ" 2>/dev/null
exit 0
  fi

  RESULT=""
  case "$ACTION" in
    edit)
      # (2026-09-20, «portare in fondo»): la primitive che mancava. Con solo
      # write_file il modello RISCRIVE il file intero anche quando ha capito
      # (516 righe per un tubo). edit = sostituzione ESATTA vecchio→nuovo:
      # fallisce se la stringa non c'e', quindi il modello DEVE leggere prima,
      # e il diff minimale non e' una preghiera nel prompt — e' strutturale.
      FPATH=$(echo "$STRIPPED" | jq -r '.path // empty')
      FOLD=$(echo "$STRIPPED" | jq -r '.old')
      FNEW=$(echo "$STRIPPED" | jq -r '.new')
      # (rizzo-pii): l'agente scrive [FULLNAME_1], il file ha Mario Rossi
      if [ -f "$ANON_DIZ" ] && [ -s "$ANON_DIZ" ]; then
        FOLD=$(printf '%s' "$FOLD" | python3 "$HERE/tools/anonimizza.py" --ripristina --diz "$ANON_DIZ" 2>/dev/null)
        FNEW=$(printf '%s' "$FNEW" | python3 "$HERE/tools/anonimizza.py" --ripristina --diz "$ANON_DIZ" 2>/dev/null)
      fi
      REAL=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FPATH" 2>/dev/null)
      REAL_DIR=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$DIR")
      case "$(percorso_ammesso "$REAL" "$REAL_DIR" && echo dentro)" in dentro)
        if [ -f "$REAL" ]; then
          EDIT_OUT=$(python3 -c "
import sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
if old not in s:
    print('NOT_FOUND'); sys.exit(0)
if s.count(old) > 1:
    print('AMBIGUOUS'); sys.exit(0)
open(p, 'w').write(s.replace(old, new))
print('OK')" "$REAL" "$FOLD" "$FNEW" 2>/dev/null)
          case "$EDIT_OUT" in
            OK)
              # (2026-10-08, furto #3 da SWE-agent: «l'edit non passa se non compila,
              # rifiutato sul posto»). Un edit rotto tornava silenzioso al cancello,
              # sprecando il turno: ora si REVOCA e l'errore torna al modello, che
              # corregge al turno dopo. Ignoti passano (dichiarato in lib.sh).
              if ! edit_sintassi_ok "$REAL"; then
                python3 -c "
import sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
open(p, 'w').write(s.replace(new, old, 1))" "$REAL" "$FOLD" "$FNEW" 2>/dev/null || true
                PRIMO_ERR=$( { bash -n "$REAL" 2>&1 || node --check "$REAL" 2>&1 || python3 -m py_compile "$REAL" 2>&1 || true; } | head -1 | cut -c1-120)
                RESULT="ERROR: edit REJECTED — syntax error after edit (${PRIMO_ERR:-file non sano}). Fix the code and re-apply the edit."
                log "  edit: $FPATH REVOCATO (sintassi rotta: si corregge al turno dopo)"
              else
                RESULT="Edit applied to $FPATH (exact replacement done)"; log "  edit: $FPATH (sostituzione esatta)"
              fi ;;
            NOT_FOUND) RESULT="ERROR: old string not found in $FPATH — read the file first, use the EXACT current text as old"; log "  edit: $FPATH vecchio non trovato" ;;
            AMBIGUOUS) RESULT="ERROR: old string appears more than once in $FPATH — include more surrounding lines to make it unique"; log "  edit: $FPATH ambiguo" ;;
            *) RESULT="ERROR: edit failed"; log "  edit: $FPATH fallito" ;;
          esac
        else
          RESULT="ERROR: file not found: $FPATH"
        fi ;;
        *)
        RESULT="ERROR: path outside project (or inside .git, which is off limits)"
        log "  edit: $FPATH FUORI (rifiutato)" ;;
      esac ;;

    read)
      FPATH=$(echo "$STRIPPED" | jq -r '.path // empty')
      REAL=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FPATH" 2>/dev/null)
      REAL_DIR=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$DIR")
      case "$(percorso_ammesso "$REAL" "$REAL_DIR" && echo dentro)" in dentro)
        if [ -f "$REAL" ]; then
          RAW_CONTENT=$(head -c 24000 "$REAL")
          # (audit-5): GDPR gate fail-closed — il server PII DEVE esserci quando
          # l'anonimizzazione e' attiva; se manca, il read si blocca (non passthrough)
          if [ "${AGENTE_ANONIMIZZA:-0}" = "1" ]; then
            if ! curl -sf --max-time 3 http://127.0.0.1:5005/health >/dev/null 2>&1; then
              RESULT="ERROR: PII server down — read blocked for GDPR. Retry later or declare finish."
              log "  read: $FPATH BLOCCATO (server PII spento — fail-closed)"
            elif [ -f "$HERE/tools/anonimizza.py" ]; then
              ANON_OUT=$(printf '%s' "$RAW_CONTENT" | python3 "$HERE/tools/anonimizza.py" --diz "$ANON_DIZ" 2>/dev/null)
              if [ -n "$ANON_OUT" ] && ! grep -q "passthrough" <<<"$ANON_OUT"; then
                RESULT="File $FPATH content:\n$ANON_OUT"
                log "  read: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes, PII anonimizzato)"
              else
                RESULT="File $FPATH content:\n$RAW_CONTENT"
                log "  read: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes, passthrough dichiarato)"
              fi
            else
              RESULT="File $FPATH content:\n$RAW_CONTENT"
              log "  read: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes, tool assente)"
            fi
          else
            RESULT="File $FPATH content:\n$RAW_CONTENT"
            log "  read: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes)"
          fi
        else
          RESULT="ERROR: file not found: $FPATH"
          log "  read: $FPATH NON TROVATO"
        fi ;;
        *)
        RESULT="ERROR: path outside project (or inside .git, which is off limits)"
        log "  read: $FPATH FUORI (rifiutato)" ;;
      esac ;;

    write)
      FPATH=$(echo "$STRIPPED" | jq -r '.path // empty')
      FCONTENT=$(echo "$STRIPPED" | jq -r '.content')
      REAL=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FPATH" 2>/dev/null)
      REAL_DIR=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$DIR")
      case "$(percorso_ammesso "$REAL" "$REAL_DIR" && echo dentro)" in dentro)
        # (giro 11, 2026-09-20): il system prompt dice «WRITE solo per file NUOVI» ma nulla
        # lo faceva rispettare — la riscrittura intera (516 righe per un tubo) passava di qui.
        # La regola diventa strutturale: un file che esiste si cambia SOLO con edit.
        if [ -e "$REAL" ]; then
          RESULT="ERROR: $FPATH already exists — use the edit action (exact old→new replacement); write is only for NEW files"
          log "  write: $FPATH esiste — RIFIUTATO (solo edit sui file esistenti)"
        else
          mkdir -p "$(dirname "$REAL")"
          echo "$FCONTENT" > "$REAL"
          # T5#2b: il file nuovo si dichiara — nella consegna del turno entrano solo i file dichiarati
          dichiara_file_nuovo "$DIR" "${REAL#"$REAL_DIR"/}" || log "  write: $DIR non e' una repo git — nessuna consegna a cui dichiarare il file"
          RESULT="OK: wrote to $FPATH"
          log "  write: $FPATH ($(wc -c < "$REAL" | tr -d ' ') bytes)"
        fi ;;
        *)
        RESULT="ERROR: path outside project (or inside .git, which is off limits)"
        log "  write: $FPATH FUORI (rifiutato)" ;;
      esac ;;

    run)
      CMD=$(echo "$STRIPPED" | jq -r '.command')
      # (2026-09-23, giro A6 della notte): qui c'era una denylist a SOTTOSTRINGHE e poi eval, fuori
      # sandbox — `git p""ush`, wget, un interprete o un touch passavano (riprodotto: 0 rifiuti su 4,
      # file scritti). Ora il run passa dalla stessa allowlist di SOLA LETTURA del censore: le
      # scritture restano a edit/write, confinate al progetto. Sul Mac il comando gira in piu' dentro
      # sandbox-exec col profilo del turno (niente rete, scritture solo qui e in /tmp).
      if ! gate_allowlist_ok "$CMD"; then
        RESULT="ERROR: command not allowed. run accepts only read-only tools: grep, cat, diff, wc, head, tail, ls, test, jq, echo, and git diff/log/show/grep/status/rev-parse/ls-files/blame. To change files use edit or write."
        log "  run: RIFIUTATO (fuori dall'allowlist di sola lettura): $CMD"
      elif command -v sandbox-exec >/dev/null 2>&1 && [ -f "$HERE/night-shift/sandbox.sb" ]; then
        PROFILO=$(mktemp /tmp/agente-sandbox.XXXXXX)
        sed -e "s|__WORKDIR__|$PWD|g" -e "s|__HOME__|$HOME|g" "$HERE/night-shift/sandbox.sb" > "$PROFILO"
        RESULT="Command: $CMD\nOutput:\n$(sandbox-exec -f "$PROFILO" bash -c "$CMD" 2>&1 | head -30)"
        rm -f "$PROFILO"
        log "  run (sandbox): $CMD"
      else
        RUN_RAW=$(eval "$CMD" 2>&1 | head -30)
        # GDPR: anche il run legge dati — se l'anonimizzazione e' attiva, filtra
        if [ "${AGENTE_ANONIMIZZA:-0}" = "1" ] && curl -sf --max-time 3 http://127.0.0.1:5005/health >/dev/null 2>&1 && [ -f "$HERE/tools/anonimizza.py" ]; then
          RUN_ANON=$(printf '%s' "$RUN_RAW" | python3 "$HERE/tools/anonimizza.py" --diz "$ANON_DIZ" 2>/dev/null)
          if [ -n "$RUN_ANON" ] && ! grep -q "passthrough" <<<"$RUN_ANON"; then RUN_RAW="$RUN_ANON"; log "  run: output PII anonimizzato"; fi
        fi
        RESULT="Command: $CMD\nOutput:\n$RUN_RAW"
        log "  run: $CMD"
      fi ;;

    __formato__)
      RESULT="ERROR: your action is not valid JSON (truncated or malformed). Send ONE complete JSON object on one line, or your final answer as plain text."
      log "  azione illeggibile (JSON troncato o rotto): errore di formato rimandato al modello" ;;
    *)
      RESULT="ERROR: unknown action: $ACTION"
      log "  azione sconosciuta: $ACTION" ;;
  esac

  # il reminder vive DOPO il case: RESULT e' pieno, il NOTE arriva al modello
  if [ "$RIPETIZIONI" -ge 1 ]; then
    RESULT="$RESULT

NOTE: you have repeated the EXACT same action for $((RIPETIZIONI+1)) consecutive turns. Same input, same result. Change your approach (read more context, try a different old/new pair) or declare finish with an honest result."
    log "  repeat-reminder: azione identica per $((RIPETIZIONI+1)) turni di fila"
  fi

  # aggiorna la conversazione: risposta del modello + risultato dell'azione
  CONV=$(echo "$CONV" | jq \
    --arg content "$CONTENT" \
    --arg result "$RESULT" \
    '. + [{"role":"assistant","content":$content},{"role":"user","content":$result}]')

done

log "⛔ max turni ($MAX_TURNI) senza completamento"
exit 1
