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
# Esce: 0 = fix applicato/verificato o funzione NUOVA inserita (wiring dichiarato mancante) · 1 = fallito · 2 = uso errato · 3 = proposta
#   (3 = codice pronto ma NON applicato: funzione nuova o bersaglio assente. La notte
#    del 4/9 l'ha trattato come successo e ha aperto una PR di soli scarti: un .js
#    proposto + il .night-bak dell'App.html intero, +739 righe di rumore.)
set -uo pipefail
# (2026-09-24, Q3 R4): `${1:?}` usciva 1, che qui significa «fallito»: l'uso sbagliato esce 2, come dichiarato
[ $# -ge 2 ] || { echo "uso: risolvi-issue.sh <dir-progetto> <issue-md>" >&2; exit 2; }
DIR="$1"; ISSUE="$2"
MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
# NIGHT_API_URL: solo per i test (server mock) — di norma non si tocca
# (T5#6, 2026-09-23): i prompt (con i sorgenti) viaggiano su stdin verso jq e curl, mai negli argomenti
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"
[ -d "$DIR" ] || { echo "⛔ dir inesistente: $DIR" >&2; exit 2; }
[ -f "$ISSUE" ] || { echo "⛔ issue inesistente: $ISSUE" >&2; exit 2; }
# (2026-09-25, settimo ventaglio, V2 R3): node e' il verificatore di ogni fix (node --check). Senza, l'rc 127 si leggeva
# «il codice non passa»: un fix giusto buttato con due diagnosi false. Il plist del turno ha un PATH fisso, e un node
# di nvm non c'e'. Si dice prima di chiamare il modello: niente GPU spesa per un fix che non si potrebbe verificare.
command -v node >/dev/null 2>&1 || { echo "⛔ MANCA node sul PATH: il fix non si puo' verificare (node --check) — non e' codice rotto, nessun tentativo" >&2; exit 2; }

log() { echo "[$(date '+%H:%M:%S')] $*" >&2; }

# --- 8. AUTO-REVIEW: il modello rivede il proprio lavoro (2026-09-17) ---
# Una seconda chiamata con una domanda DIVERSA («e' corretto?») invece della
# stessa («correggi»). Il patto resta: niente agent, niente tool — solo
# prompt → verdetto. Se la review dice WRONG, il turno apre la PR con un warning (non piu'
# «degradato a proposta»: il comportamento vero e' in night-shift.sh, riga REVIEW).
# (D5, test del sistema completo 2026-09-20): queste due funzioni vivevano in CODA al
# file, DOPO l'`exit 3` — bash le definisce quando le legge, quindi al momento della
# chiamata non esistevano: «auto_review: command not found» a ogni fix applicato, REVIEW
# vuota, nessun test generato, e il turno leggeva esiti che non arrivavano mai. Le
# definizioni stanno PRIMA dell'uso, e parlano allo stesso $API del solver (il mock dei
# test le raggiunge: prima puntavano a localhost fisso).
# classifica_verdetto <prima riga della risposta>: CORRECT | WRONG | UNCLEAR.
# (revisione 10 giri, 2026-09-23): prima un `case` provava *correct* PRIMA di *wrong* —
# «incorrect», «not correct», «scorretto» contengono «correct»/«corretto» e diventavano
# CORRECT. Ora si cercano prima le forme NEGATIVE, poi le positive come parola intera.
classifica_verdetto() {
  local V
  V=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  if grep -qE '(^|[^a-z])(wrong|incorrect|not correct|sbagliat[oa]|scorrett[oa]|non corrett[oa]|errat[oa]|errore)([^a-z]|$)' <<<"$V"; then
    echo "WRONG"
  elif grep -qE '(^|[^a-z])(correct|corrett[oa]|giust[oa])([^a-z]|$)' <<<"$V"; then
    echo "CORRECT"
  else
    echo "UNCLEAR"
  fi
}

auto_review() {
  local CODE="$1" COMMESSA="$2"
  local PROMPT="You are a code reviewer. Given this issue and this code fix, answer with exactly one word: CORRECT or WRONG. If WRONG, add one line explaining why.

=== ISSUE ===
$COMMESSA
=== END ISSUE ===

=== CODE FIX ===
$CODE
=== END CODE ===

Is this fix correct? Answer CORRECT or WRONG:"
  local RESPONSE VERDETTO
  RESPONSE=$(printf '%s' "$PROMPT" | jq -Rs --arg m "$MODEL" '. as $p | {model:$m, messages:[{role:"user",content:$p}], stream:false, think:false, options:{temperature:0, num_ctx:2048}}' | curl -sf --max-time 120 "$API" --data-binary @- 2>/dev/null)
  VERDETTO=$(echo "$RESPONSE" | jq -r '.message.content // empty' 2>/dev/null | head -1)
  classifica_verdetto "$VERDETTO"
}

# --- 9. GENERATORE DI TEST: il fix arriva col suo test (2026-09-17) ---
# Terza chiamata Ollama: «scrivi un test che fallisce senza questo fix».
# Il test viene salvato e aggiunto al PR. Il patto resta lo stesso.
genera_test() {
  local CODE="$2" COMMESSA="$3"  # (audit: $1 non serve piu', si tiene il posto)
  local PROMPT="Write a minimal Node.js test function that verifies this fix is correct. The test should FAIL if the old buggy code is restored. Output ONLY the test function, no explanation.

=== ISSUE ===
$COMMESSA
=== FIX ===
$CODE
=== END ===

Write the test:"
  local RESPONSE TEST
  RESPONSE=$(printf '%s' "$PROMPT" | jq -Rs --arg m "$MODEL" '. as $p | {model:$m, messages:[{role:"user",content:$p}], stream:false, think:false, options:{temperature:0}}' | curl -sf --max-time 120 "$API" --data-binary @- 2>/dev/null)
  TEST=$(echo "$RESPONSE" | jq -r '.message.content // empty' 2>/dev/null | sed -n '/^```/,/^```/p' | sed '/^```/d')
  [ -n "$TEST" ] && echo "$TEST" || return 1
}

# --- 1. individua i file da leggere (dal Territorio dell'issue, o tutti i .gs/.js) ---
# (2026-09-24, sesto ventaglio, S3 R3): l'estrazione non ammetteva lo spazio — «Codice Principale.gs» diventava
# «Principale.gs», che non esiste, e si saltava in silenzio. Un percorso fra backtick si prende intero; se non ce ne
# sono, la forma senza spazi di prima.
SEZ_TERR=$(sed -n '/^## Territorio/,/^## /p' "$ISSUE")
TERRitorio=$(grep -oE '`[^`]+\.(gs|js|html|py)`' <<<"$SEZ_TERR" | tr -d '`' | sort -u | head -5)
[ -n "$TERRitorio" ] || TERRitorio=$(grep -oE '[a-zA-Z0-9_/.-]+\.(gs|js|html|py)' <<<"$SEZ_TERR" | sort -u | head -5)
if [ -z "$TERRitorio" ]; then
  # fallback: i file più piccoli del progetto (il territorio piccolo è quello fattibile)
  TERRitorio=$(find "$DIR" -type f \( -name '*.gs' -o -name '*.js' \) -size -50k | sort | head -3)
fi
log "File da leggere: $TERRitorio"

# --- 2. legge i file e costruisce il prompt ---
# (set sicurezza 2026-09-07, G1): il Territorio di un issue e' INPUT ESTERNO. Un path
#  assoluto o con ../ faceva leggere al turno file FUORI dal progetto e mandarli al
#  modello (provato: /tmp/segreto-finto.py letto e incollato nel prompt). Regola del
#  canone: un dato esterno che arriva fino a una lettura va confinato. Ogni path
#  risolto deve stare DENTRO $DIR, realpath contro realpath — niente prefissi fidati.
dentro_il_progetto() {
  RP_F=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null)
  RP_D=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$2" 2>/dev/null)
  # (2026-09-25, ottavo ventaglio, O1 R1): mai dentro un .git — una voce di .git/config puo' essere un comando che git esegue
  case "$RP_F" in */.git|*/.git/*) return 1;; esac
  case "$RP_F" in "$RP_D"|"$RP_D"/*) return 0;; *) return 1;; esac
}

FILES_CONTENT=""
N_LETTI=0
# (S3 R3): era `for F in $TERRitorio` — un percorso con lo spazio (anche quelli del ripiego find) si spezzava
while IFS= read -r F; do
  [ -n "$F" ] || continue
  # il chiamante (night-shift.sh) NON cd-a dentro $DIR: i percorsi del Territorio
  # vanno risolti contro $DIR, non contro la CWD di chi lancia (bug colto dal test
  # di suite 2026-09-04: i 20 test manuali giravano da dentro la dir e non lo vedevano)
  [ -f "$F" ] || F="$DIR/$F"
  [ -f "$F" ] || continue
  if ! dentro_il_progetto "$F" "$DIR"; then
    log "⛔ $F e' FUORI dal progetto: il Territorio di un issue non legge fuori da $DIR (salto)"
    continue
  fi
  # (revisione 10 giri, 2026-09-23): `realpath --relative-to` e' GNU — sul Mac del turno
  # falliva e il prompt riceveva il path ASSOLUTO. os.path.relpath e' ovunque.
  REL_PATH=$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$F" "$DIR" 2>/dev/null || echo "$F")
  # (fase A efficienza, 2026-09-07): App.html intera = 41KB = 262s di inferenza.
  #  Limite per file 24000 byte (~6-8K token; head -c conta byte, settimo ventaglio V4 R6), TRONCATO DICHIARATO nel prompt —
  #  mai taglio silenzioso: il modello sa che non vede tutto e lavora da quello che
  #  l'issue nomina. I file piccoli (il caso normale: 9s) non cambiano di una virgola.
  CORPO=$(head -c 24000 "$F")
  N_CHAR=$(wc -c < "$F" | tr -d ' ')
  if [ "$N_CHAR" -gt 24000 ]; then
    CORPO="$CORPO"$'\n'"[... TRONCATO: mostrati i primi 24000 byte su $N_CHAR. Le funzioni NON mostrate vanno ricostruite dal contesto dell'issue e dichiarate.]"
    log "⚠ $REL_PATH troncato a 24000/$N_CHAR byte (dichiarato nel prompt)"
  fi
  # (S3 R3): gli a capo erano «\n» letterali fra virgolette doppie: il modello leggeva una barra e una n
  FILES_CONTENT+="=== FILE: $REL_PATH ==="$'\n'"$CORPO"$'\n\n'
  N_LETTI=$((N_LETTI+1))
done <<<"$TERRitorio"
# (S3 R3): nessun file letto = nessun codice da mostrare. Prima il modello riceveva un SOURCE vuoto, alla cieca.
if [ "$N_LETTI" -eq 0 ]; then
  log "⛔ nessun file del Territorio letto (${TERRitorio:-nessuno trovato}): il modello non si chiama senza il codice"
  exit 1
fi
log "letti $N_LETTI file (${#FILES_CONTENT} caratteri) per il prompt"

# (set sicurezza G3, 2026-09-07): il limite da 24k valeva per i FILE, non per il corpo
#  dell'issue: un body gigante gonfiava il prompt senza limite. Stesso patto: troncato
#  DICHIARATO, mai taglio silenzioso.
COMMESSA=$(head -c 24000 "$ISSUE")
if [ "$(wc -c < "$ISSUE" | tr -d ' ')" -gt 24000 ]; then
  log "⚠ issue troncata a 24000 byte (dichiarato nel prompt)"
  COMMESSA="$COMMESSA
[... ISSUE TRONCATA: mostrati i primi 24000 byte su $(wc -c < "$ISSUE" | tr -d ' ').]"
fi

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
RESPONSE=$(printf '%s' "$PROMPT" | jq -Rs --arg m "$MODEL" '. as $p | {model:$m, messages:[{role:"user",content:$p}], stream:false, options:{temperature:0}}' | curl -sf --max-time 300 "$API" --data-binary @- 2>&1)
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
log "Codice salvato in $(basename "$PATCH_FILE") ($(echo "$CODE" | wc -l | tr -d ' ') righe)"

# --- 7. se c'è UN solo file e UN solo blocco di codice: applica direttamente ---
N_FILES=$(echo "$TERRitorio" | wc -w | tr -d ' ')
N_BLOCKS=$(echo "$CODE" | grep -c "^function \|^  function " || true)
if [ "$N_FILES" -eq 1 ] && grep -q "^function " <<<"$CODE"; then
  TARGET_FILE=$(echo "$TERRitorio" | head -1)
  [ -f "$TARGET_FILE" ] || TARGET_FILE="$DIR/$TARGET_FILE"
  # stesso confine in SCRITTURA: mai sostituire/inserire fuori da $DIR
  if ! dentro_il_progetto "$TARGET_FILE" "$DIR"; then
    log "⛔ TARGET $TARGET_FILE fuori dal progetto: rifiuto (il Territorio di un issue non scrive fuori)"
    TARGET_FILE=""
  fi
  [ -n "$TARGET_FILE" ] && [ -f "$TARGET_FILE" ] || TARGET_FILE=""
  TARGET_FN=$(echo "$CODE" | grep -oE '^function [a-zA-Z_]+' | head -1 | sed 's/function //')
  # (D2 2026-09-07): se il modello restituisce PIU' funzioni (il blocco intero dello script),
  #  la prima puo' essere una GIA' ESISTENTE e la via della sostituzione parte col piede
  #  sbagliato. Se fra le funzioni del blocco ce n'e' una ASSENTE dal file, si isola QUELLA:
  #  e' la funzione nuova che l'issue chiede — la sostituzione riguarderebbe codice che il
  #  modello ha solo ricopiato.
  for FN_CAND in $(echo "$CODE" | grep -oE '^function [a-zA-Z_]+' | sed 's/function //'); do
    if ! grep -q "function $FN_CAND" "$TARGET_FILE"; then
      if [ "$FN_CAND" != "$TARGET_FN" ]; then
        log "blocco multi-funzione: isolo $FN_CAND (nuova) — le altre gia' esistono nel file"
      fi
      TARGET_FN="$FN_CAND"
      CODE=$(echo "$CODE" | awk -v fn="function $FN_CAND" '$0 ~ "^"fn {p=1} p {print} p && /^}$/ {exit}')
      # il PATCH FILE e' cio' che viene APPLICATO: deve essere la funzione isolata,
      # non il blocco intero del modello — D2 secondo giro ha inserito <script> e una
      # copia di una funzione esistente perche' CODE (verificato) e PATCH (applicato)
      # erano due cose diverse. Verificato = applicato, o non e' una verifica.
      printf '%s\n' "$CODE" > "$PATCH_FILE"
      break
    fi
  done
  # (fase B adattiva, 2026-09-07 — chiude il DEBITI "inserzione funzioni nuove": le issue
  #  "Feature:" chiedono funzioni che NON esistono ancora; degradare a proposta teneva
  #  l'issue #10 ferma da tre notti. L'inserzione ha REGOLE dal campo: in un .html si va
  #  PRIMA dell'ultimo </script> (mai dopo </html>); senza un punto dichiarato si rifiuta
  #  con la ragione; e la funzione inserita senza chiamante e' CODICE MORTO DICHIARATO.)
  if [ -n "$TARGET_FN" ] && ! grep -q "function $TARGET_FN" "$TARGET_FILE"; then
    INS_OK=0
    case "$TARGET_FILE" in
      *.html)
        if grep -q "</script>" "$TARGET_FILE"; then
          cp "$TARGET_FILE" "$TARGET_FILE.night-bak"
          python3 - "$TARGET_FILE" "$PATCH_FILE" <<'PYINS'
import sys
target, patch = sys.argv[1], sys.argv[2]
src = open(target).read()
fn = open(patch).read().strip()
i = src.rfind("</script>")
src = src[:i] + "\n" + fn + "\n" + src[i:]
open(target, "w").write(src)
print("FUNZIONE-INSERITA-HTML")
PYINS
          INS_OK=$?
        else
          log "⛔ $TARGET_FILE non ha </script>: nessun punto di inserimento dichiarato — proposta, non inserzione alla cieca"
        fi
        ;;
      *.js|*.gs)
        cp "$TARGET_FILE" "$TARGET_FILE.night-bak"
        printf '\n%s\n' "$(cat "$PATCH_FILE")" >> "$TARGET_FILE"
        INS_OK=$?
        ;;
    esac
    if [ "$INS_OK" -eq 0 ] && echo "$CODE" | node --check - 2>/dev/null; then
      # doppia verifica: la funzione adesso c'e', ed E UNA sola
      N_FN=$(grep -c "^function $TARGET_FN" "$TARGET_FILE" || true)
      if [ "$N_FN" -eq 1 ]; then
        log "✅ Funzione NUOVA $TARGET_FN inserita in $(basename "$TARGET_FILE") e verificata (node --check)"
        log "⚠ CODICE MORTO DICHIARATO: la funzione e' inserita ma nessuno la chiama — il collegamento (bottone/menu/chiamata) sta al giorno"
        rm -f "$TARGET_FILE.night-bak"
        rm -f "$PATCH_FILE"
        echo "ESITO: INSERITO $(basename "$TARGET_FILE") $TARGET_FN ${ELAPSED}s (wiring mancante, dichiarato)"
        exit 0
      fi
    fi
    # inserzione fallita o non verificata: rollback pulito, si degrada a proposta
    [ -f "$TARGET_FILE.night-bak" ] && { cp "$TARGET_FILE.night-bak" "$TARGET_FILE"; rm -f "$TARGET_FILE.night-bak"; }
    log "⚠ inserzione non verificata: rollback, resta la proposta"
  fi
  if [ -n "$TARGET_FN" ] && grep -q "function $TARGET_FN" "$TARGET_FILE"; then
    log "Applicando: sostituisco $TARGET_FN in $(basename "$TARGET_FILE")"
    # backup
    cp "$TARGET_FILE" "$TARGET_FILE.night-bak"
    # sostituzione: rimuovi la vecchia funzione, inserisci la nuova
    python3 - "$TARGET_FILE" "$PATCH_FILE" "$TARGET_FN" <<'PYEOF'
import sys, re
target, patch, fn = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(target).read()
new_fn = open(patch).read().strip()
# trova la funzione vecchia (dalla dichiarazione alla chiusura con indentazione coerente)
# (^\s*function: il caso #10 del Bilancio — funzione a 2 spazi di indentazione,
#  grep la trovava, la regex a colonna zero no: FUNZIONE-NON-TROVATA su codice esistente)
pattern = re.compile(r'(^\s*function ' + re.escape(fn) + r'\([^)]*\)\s*\{.*?^\s*\})', re.M | re.S)
match = pattern.search(src)
if match:
    src = src[:match.start()] + new_fn + src[match.end():]
    open(target, 'w').write(src)
    print(f"FUNZIONE-SOSTITUITA {fn}")
else:
    print(f"FUNZIONE-NON-TROVATA {fn}")
    sys.exit(1)
PYEOF
    RC_PY=$?
    if [ $RC_PY -ne 0 ]; then
      # sostituzione fallita: il file NON è stato toccato, il backup è scarto puro
      # (notte 4/9: il bak finiva commitato dalla PR — git add -A non perdona)
      rm -f "$TARGET_FILE.night-bak"
    fi
    if [ $RC_PY -eq 0 ]; then
      # verifica: node --check sulla PATCH (il file .html/.gs contiene HTML misto,
      # node --check sull'intero fallirebbe sempre — si verifica il codice JS puro)
      if echo "$CODE" | node --check - 2>/dev/null; then
        log "✅ Fix applicato e verificato (node --check passa)"
        # AUTO-REVIEW: seconda domanda allo stesso modello (2026-09-17)
        RV=$(auto_review "$CODE" "$(cat "$ISSUE" | head -30)")
        log "auto-review: $RV"
        echo "REVIEW: $RV"
        # GENERATORE DI TEST: terza domanda (il fix arriva presidiato)
        TG=$(genera_test "$TARGET_FN" "$CODE" "$(cat "$ISSUE" | head -30)")
        # (revisione 10 giri, 2026-09-23): il test ha PIU' righe e il protocollo era una riga
        # («TEST-GENERATO: $TG»): il turno ne salvava solo la prima (`function test_fix() {`) e
        # la committava come test. Ora il test sta fra due marcatori, intero.
        if [ -n "$TG" ]; then
          echo "TEST-GENERATO-INIZIO"
          printf '%s\n' "$TG"
          echo "TEST-GENERATO-FINE"
        fi
        rm -f "$TARGET_FILE.night-bak"
        rm -f "$PATCH_FILE"
        echo "ESITO: APPLICATO $(basename "$TARGET_FILE") $TARGET_FN ${ELAPSED}s"
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

# se non può applicare direttamente: il codice è una PROPOSTA (funzione nuova o
# bersaglio assente) — non un fix consegnato. Exit 3: il turno la pubblica come
# commento all'issue, NON come PR (la notte del 4/9 ha aperto la PR #16 di scarti)
log "Codice pronto in $(basename "$PATCH_FILE") — proposta, applicazione a carico del giorno"
echo "ESITO: PATCH $(basename "$PATCH_FILE") ${ELAPSED}s"
exit 3
