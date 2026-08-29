#!/bin/bash
# morning-gate.sh — il giudizio del mattino: REPO-A come giudice, censore, correttore.
#
# Per ogni PR night/* O claude/* aperta su ogni repo della coda (il giudice ha due occhi:
# anche il lavoro del giorno passa verifiche e banco — 2026-08-21):
#   1. VERIFICHE DICHIARATE: esegue i comandi nel file .night-verify della repo
#      (se assente, lo dice invece di tacere — regola "un silenzio non è un verdetto")
#   2. BANCO AVVERSARIALE: chiede al modello locale di provare a SMENTERE la PR
#      (il metodo del Supervisore: il test che la bozza deve superare)
#   3. REPORT: ~/morning-gate-report.md — diff stat, verdetti, proposte di commesse
#      correttive PRONTE DA INCOLLARE (nessuna azione automatica: il sì è di Luca)
#   4. MEMORIA: appende una riga per PR in metrics/gate.csv
#
# Uso: morning-gate.sh          (legge night-shift/repos.conf)
#      morning-gate.sh owner/repo ...
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib.sh"
CONF="$HERE/repos.conf"
HUB_METRICS="$(cd "$HERE/.." && pwd)/metrics/gate.csv"
WORK="$HOME/night-shift-work"
REPORT="$HOME/morning-gate-report.md"
GATE_LOG="$HOME/morning-gate.log"
rotate_log_if_big "$GATE_LOG"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$GATE_LOG"; }

REPO_LIST=()
if [ $# -gt 0 ]; then
  for a in "$@"; do REPO_LIST+=("$a"); done
else
  [ -f "$CONF" ] || { echo "crea $CONF (vedi repos.conf.example)" >&2; exit 1; }
  while IFS= read -r line; do
    line="${line%%#*}"; [ -z "$(echo "$line" | tr -d '[:space:]')" ] && continue
    REPO_LIST+=("${line%% *}")
  done < "$CONF"
fi

[ -f "$HUB_METRICS" ] || echo "data,repo,pr,issue,verifiche,banco,esito" > "$HUB_METRICS"

echo "# Morning Gate — $(date '+%Y-%m-%d %H:%M')" > "$REPORT"
echo "" >> "$REPORT"
TOTAL=0 PASS=0 FAIL=0

# 2026-08-29 (E-015): con conf vuoto (o solo commenti) "${REPO_LIST[@]}" sotto
# set -u su bash 3.2 CRASHA "unbound variable" invece di dirlo — il gate del
# mattino mancato dal 25/8 per questo. Lista vuota = messaggio pulito, non crash.
if [ "${#REPO_LIST[@]}" -eq 0 ]; then
  echo "il gate non ha repo da giudicare: repos.conf vuoto (o solo commenti) e nessun argomento." >&2
  echo "riempi $CONF (una riga per repo: owner/repo [tipo]) oppure passa le repo come argomenti." >&2
  exit 1
fi
for REPO in ${REPO_LIST[@]+"${REPO_LIST[@]}"}; do
  DIR="$WORK/${REPO##*/}"
  gh pr list -R "$REPO" --state open --json number,headRefName,title,mergeable --limit 50 2>/dev/null \
    | jq -c '.[] | select(.headRefName | test("^night/|^claude/|^glm/"))' > /tmp/gate-prs.json
  # -s (slurp): conta gli elementi dello stream — senza, jq conta le CHIAVI dell'oggetto
  N=$(jq -s 'length' < /tmp/gate-prs.json); N="${N:-0}"
  echo "## $REPO — $N PR notturne aperte" >> "$REPORT"
  [ "$N" -eq 0 ] && { echo "_Nessuna. Il sistema ha lavorato o non aveva coda._" >> "$REPORT"; echo "" >> "$REPORT"; continue; }

  [ -d "$DIR/.git" ] || { gh repo clone "$REPO" "$DIR" -- --depth=50 -q; }
  git -C "$DIR" fetch origin --prune -q
  DB=$(default_branch "$DIR") || log "ATTENZIONE: default branch non rilevato in $REPO, assumo main"
  # review §4.2: drift-check del CLAUDE.md (informativo, non bloccante)
  if ! diff -q <(git -C "$DIR" show "origin/$DB:CLAUDE.md" 2>/dev/null) "$HERE/../CLAUDE.md" >/dev/null 2>&1; then
    echo "_⚠ Drift: il CLAUDE.md della repo $REPO differisce da quello del hub (regole ereditate non allineate — valutare l'aggiornamento)._" >> "$REPORT"
  fi

  while IFS= read -r row; do
    NUM=$(echo "$row" | jq -r '.number')
    BRANCH=$(echo "$row" | jq -r '.headRefName')
    TITLE=$(echo "$row" | jq -r '.title')
    MERGEABLE=$(echo "$row" | jq -r '.mergeable')
    # bug reale (dogfooding, set 3 "flusso delle idee", 2026-08-22): "${BRANCH#night/issue-}"
    # non rimuove nulla se il branch non inizia per "night/issue-" — esattamente il caso
    # dei branch claude/* e glm/* che questo stesso gate giudica "con due occhi" (riga 4).
    # Verificato dal vivo: per un branch claude/qualcosa, ISSUE_NUM diventava l'INTERO nome
    # del branch, finendo così com'è nella colonna "issue" di metrics/gate.csv — corrompe
    # la memoria condivisa (principio L4 di docs/system.md) con stringhe invece di numeri.
    case "$BRANCH" in
      night/issue-*) ISSUE_NUM="${BRANCH#night/issue-}" ;;
      *) ISSUE_NUM="—" ;;  # lavoro di giorno non legato a un'issue night-shift: onesto, non un dato finto
    esac
    TOTAL=$((TOTAL+1))
    echo "" >> "$REPORT"
    echo "### PR #$NUM — $TITLE (\`$BRANCH\`)" >> "$REPORT"
    # Giro 8 dei test 2026-08-21 (night-shift-pilot): due PR gemelle passavano le verifiche
    # ciascuna sul proprio branch mentre erano in conflitto reale tra loro — il gate non lo
    # segnalava mai, lo scopriva solo chi provava a mergere. Il silenzio non è un verdetto qui
    # come altrove in questo script: se GitHub la segna CONFLICTING, lo diciamo prima del resto.
    [ "$MERGEABLE" = "CONFLICTING" ] && echo "⛔ **Non mergeable: conflitto con \`$DB\` — risolvere prima di leggere il resto di questa sezione.**" >> "$REPORT"
    echo "**Diff:**" >> "$REPORT"
    git -C "$DIR" diff --stat "origin/$DB...$BRANCH" >> "$REPORT" 2>/dev/null

    # bug reale, GRAVISSIMO (revisione 14 lenti, 2026-08-28): fino a qui il working tree di
    # $DIR non viene mai toccato (diff/show sopra usano ref espliciti) — ma le verifiche
    # dichiarate e il banco avversariale SOTTO girano con `cd "$DIR" && ...`: senza un
    # checkout esplicito del branch della PR, eseguivano sul contenuto lasciato lì
    # dall'ultima operazione (tipicamente il branch di default), MAI sul codice reale della
    # PR. Riprodotto dal vivo: un branch con un bug reale iniettato (marker rilevato da
    # .night-verify) dava comunque "verifiche-ok". Da qui in poi il gate ha davvero bisogno
    # del branch giusto nel working tree.
    if ! git -C "$DIR" checkout -q -B "$BRANCH" "origin/$BRANCH" 2>/dev/null; then
      echo "⛔ **Checkout di \`$BRANCH\` fallito — verifiche e banco avversariale NON eseguiti per questa PR.**" >> "$REPORT"
      echo "$(date '+%Y-%m-%d'),$(repo_code "$REPO"),#$NUM,#$ISSUE_NUM,checkout-fallito,—," >> "$HUB_METRICS"
      FAIL=$((FAIL+1))
      continue
    fi

    # 1. Verifiche dichiarate — lette da origin/main: la dichiarazione è della REPO,
    #    non del branch della PR (che può essere nato prima della dichiarazione)
    VERDICT="—"
    NIGHT_VERIFY=$(git -C "$DIR" show "origin/$DB:.night-verify" 2>/dev/null || true)
    FAIL_DETAIL=""  # Giro 6 dei test 2026-08-21: l'estratto del fallimento, per la issue correttiva
    # giro 10/10 (set 2 "capacità di progettare"): proposta #2 di
    # docs/test-processo-2026-08-21.md, mai implementata — "il gate dichiara la categoria
    # repo non-verificabile, non il generico non-dichiarate" (repo GAS-only dove la
    # verifica di livello 1-2 passa dal deploy umano). Distinta da "verifiche-vuote" (giro
    # 9: il file c'è ma sembra dimenticato) — qui la repo DICHIARA esplicitamente, col
    # motivo, di non poter verificare in automatico. Marcatore: una riga
    # "# NON-VERIFICABILE: <motivo>" in .night-verify.
    NV_MOTIVO=$(printf '%s' "$NIGHT_VERIFY" | grep -iE '^#\s*NON-VERIFICABILE\s*:' | head -1 | sed -E 's/^#\s*NON-VERIFICABILE\s*:\s*//I')
    if [ -n "$NV_MOTIVO" ]; then
      echo "**Verifiche dichiarate:** repo marcata \`NON-VERIFICABILE\` — $NV_MOTIVO. La verifica di livello 1-2 passa da un controllo umano/deploy, non dal gate automatico." >> "$REPORT"
      VERDICT="non-verificabile"
    elif [ -n "$NIGHT_VERIFY" ]; then
      echo "**Verifiche dichiarate (.night-verify, da main):**" >> "$REPORT"
      V_RC=0
      # bug reale, alta severità (dogfooding, set 2 "capacità di progettare", 2026-08-22):
      # un .night-verify con SOLO righe di commento — ESATTAMENTE il default generato da
      # tools/bootstrap-app.sh per ogni repo nuova — fa collassare ogni riga nel `continue`
      # sotto, zero comandi eseguiti, V_RC resta 0 invariato → VERDICT="verifiche-ok".
      # Falso verde: verificato dal vivo con un file identico al template reale. CMD_ESEGUITI
      # distingue "ho verificato e va tutto bene" da "non ho verificato nulla".
      CMD_ESEGUITI=0
      while IFS= read -r cmd; do
        cmd="${cmd%%#*}"; [ -z "$(echo "$cmd" | tr -d '[:space:]')" ] && continue
        CMD_ESEGUITI=$((CMD_ESEGUITI+1))
        echo "- \`$cmd\`:" >> "$REPORT"
        if OUT=$( cd "$DIR" && run_guarded 120 bash -c "$cmd" 2>&1 ); then
          echo "  ✅ — $(echo "$OUT" | tail -2 | tr '\n' ' ')" >> "$REPORT"
        else
          echo "  ❌ — $(echo "$OUT" | tail -3 | tr '\n' ' ')" >> "$REPORT"; V_RC=1
          FAIL_DETAIL="$FAIL_DETAIL"$'\n'"- \`$cmd\`:"$'\n'"$(echo "$OUT" | tail -8)"
        fi
      done <<< "$NIGHT_VERIFY"
      if [ "$CMD_ESEGUITI" -eq 0 ]; then
        echo "**Verifiche dichiarate:** \`.night-verify\` esiste ma non contiene nessun comando eseguibile (solo commenti/righe vuote) — non è lo stesso di 'tutto ok', è lo stesso di 'niente verificato'." >> "$REPORT"
        VERDICT="verifiche-vuote"
      elif [ "$V_RC" -eq 0 ]; then
        VERDICT="verifiche-ok"
      else
        VERDICT="verifiche-fallite"
      fi
    else
      echo "**Verifiche dichiarate:** nessun file \`.night-verify\` su main — il silenzio non è un verdetto: dichiarale." >> "$REPORT"
      VERDICT="non-dichiarate"
    fi

    # 2. Banco avversariale ESECUTORE: genera la smentita e LA ESEGUE sul branch
    #    (livello 4 → livello 1-2: la proposta diventa verdetto. 2026-08-21)
    BANCO="—"
    ADVERSARY="${ADVERSARY:-qwen}"
    ASK="$HERE/../llm/ask-qwen.sh"
    [ "$ADVERSARY" = "opus" ] && ASK="$HERE/../llm/ask-opus.sh"
    # gap reale (set 1 "armonizza gli agenti"): GLM è un cervello di giorno pienamente
    # documentato (llm/README.md, llm/ask-glm.sh) ma non era mai selezionabile per il
    # banco avversariale — solo qwen/opus erano cablati. Asimmetria diretta col mandato
    # di armonizzare notte+giorno "code e glm": ora ADVERSARY=glm è una via reale.
    [ "$ADVERSARY" = "glm" ] && ASK="$HERE/../llm/ask-glm.sh"
    if [ -x "$ASK" ]; then
      DIFF_TXT=$(git -C "$DIR" diff "origin/$DB...$BRANCH" 2>/dev/null | head -300)
      if [ -n "$DIFF_TXT" ]; then
        # bug reale (dogfooding, set 3 "flusso delle idee", 2026-08-22): il prompt diceva
        # "sono ammessi node/python/..." ma gate_allowlist_ok() in lib.sh non li ammette
        # affatto (rimossi per sicurezza, opzione (c) di Luca — bypassabili con bash -c/
        # python3 -c/node -e) — verificato dal vivo: ogni comando node/python viene SEMPRE
        # scartato. L'avversario, invitato dal prompt a usarli, sprecava l'intero turno di
        # giudizio su un comando garantito allo scarto. Prompt corretto per riflettere
        # l'allowlist VERA, non quella immaginata prima della stretta di sicurezza.
        BANCO_PROMPT="Sei l'avversario in una code review. Ecco il diff di una pull request. Scrivi UN solo comando shell, eseguibile dalla root della repo, che SMASCHERA un difetto della PR se esiste: deve riuscire (exit 0) se la PR è solida, fallire (exit != 0) se è difettosa. Vincoli rigidissimi: niente rete, niente operazioni distruttive (rm/mv/chmod/git push), nessuna modifica permanente, NESSUN interprete general-purpose (node/python/bash -c/sh -c vengono scartati automaticamente, qualunque cosa contengano). Sono ammessi SOLO: grep, cat, diff, wc, head, tail, ls, test, jq, echo, e git in sola lettura (diff/log/show/grep/status/rev-parse/ls-files/blame). Rispondi con UN SOLO blocco di codice contenente il comando, senza spiegazioni.

$DIFF_TXT"
        BANCO_OUT=$(printf '%s' "$BANCO_PROMPT" | "$ASK" "Fai quanto chiesto sopra." 2>/dev/null || true)
        CMD=$(printf '%s' "$BANCO_OUT" | awk '/^```/{f=!f; next} f' | head -1 | sed 's/^[a-z]*://; s/^ *//; s/ *$//')
        if [ -z "$CMD" ]; then
          echo "**Banco avversariale:** nessun comando estratto dalla risposta del cervello ($ADVERSARY)" >> "$REPORT"
          BANCO="vuoto"
        elif ! gate_allowlist_ok "$CMD"; then
          echo "**Banco avversariale:** comando SCARTATO dall'allowlist (solo strumenti di lettura/verifica, git readonly): \`$CMD\`" >> "$REPORT"
          BANCO="scartato-allowlist"
        else
          # Difesa in profondità (review §3): allowlist ✓ + sandbox seatbelt (no rete, scritture
          # solo nella copia disposabile) + watchdog 120s
          sed -e "s|__WORKDIR__|$DIR|g" -e "s|__HOME__|$HOME|g" "$HERE/sandbox.sb" > /tmp/gate-sandbox.sb
          ( cd "$DIR" && run_guarded 120 sandbox-exec -f /tmp/gate-sandbox.sb bash -c "$CMD" ) > /tmp/gate-banco.out 2>&1
          BRC=$?
          OUT_TAIL=$(tail -5 /tmp/gate-banco.out | tr '\n' ' ' | head -c 200 | mask_secrets)
          echo "**Banco avversariale ESEGUITO** (cervello: $ADVERSARY):" >> "$REPORT"
          echo "- comando: \`$CMD\`" >> "$REPORT"
          if [ "$BRC" -eq 0 ]; then
            echo "- esito: **la bozza SOPRAVVIVE alla smentita** (exit 0) — ${OUT_TAIL:-(nessun output)}" >> "$REPORT"
            BANCO="eseguito:sopravvissuta"
          else
            echo "- esito: **SMENTITA** (exit $BRC) — ${OUT_TAIL:-(nessun output)}" >> "$REPORT"
            BANCO="eseguito:smentita"
            FAIL_DETAIL="$FAIL_DETAIL"$'\n'"- banco avversariale, comando \`$CMD\`:"$'\n'"$OUT_TAIL"
          fi
          # l'avversario non lascia tracce nella copia di lavoro
          git -C "$DIR" checkout -q -- . 2>/dev/null; git -C "$DIR" clean -fdq 2>/dev/null
        fi
      fi
    fi

    # 2-bis. Verifica di MINIMITÀ (livello 4, consultiva — da /ponytail-review, 2026-08-21):
    # delete-list proposta sul diff; informa la review, in v1 non cambia il verdetto.
    if [ -n "${DIFF_TXT:-}" ] && [ -x "$HERE/../llm/ask-qwen.sh" ]; then
      MIN_PROMPT="Sei il revisore anti-over-engineering. Ecco il diff di una pull request. Indica SOLO le parti in eccesso rispetto a ciò che serviva: codice che si può eliminare o ridurre senza perdere funzione, dipendenze non necessarie, astrazioni superflue. Se il diff è già minimale, scrivi ESATTAMENTE: già minimale. Massimo 8 righe.

${DIFF_TXT}"
      MIN_OUT=$(printf '%s' "$MIN_PROMPT" | "$HERE/../llm/ask-qwen.sh" "Fai quanto chiesto sopra." 2>/dev/null || true)
      echo "**Minimità (delete-list proposta, consultiva):**" >> "$REPORT"
      echo '```' >> "$REPORT"; echo "${MIN_OUT:-(non disponibile)}" >> "$REPORT"; echo '```' >> "$REPORT"
    fi

    # 3-4. memoria + verdetto
    case "$VERDICT" in verifiche-ok) PASS=$((PASS+1));; *) FAIL=$((FAIL+1));; esac
    echo "$(date '+%Y-%m-%d'),$(repo_code "$REPO"),#$NUM,#$ISSUE_NUM,$VERDICT,$BANCO," >> "$HUB_METRICS"

    if [ "$VERDICT" = "verifiche-fallite" ] || [ "$BANCO" = "eseguito:smentita" ]; then
      # Giro 6 dei test 2026-08-21: prima diceva solo "Dettagli nel report locale del
      # gate" — irraggiungibile da chi lavora la issue correttiva altrove. Ora l'estratto
      # vero del fallimento entra nel body, via heredoc quotato ('GATE_EOF'): al riparo da
      # backtick/virgolette/$ che l'output di un comando qualunque potrebbe contenere.
      echo "" >> "$REPORT"
      echo "> ⛔ **Proposta correttiva** (il correttore — da approvare):" >> "$REPORT"
      echo "> \`\`\`bash" >> "$REPORT"
      echo "gh issue create -R $REPO --label night-shift --title \"correzione: PR #$NUM — verifiche o banco avversario falliti\" --body \"\$(cat <<'GATE_EOF'" >> "$REPORT"
      echo "La PR #$NUM non supera il gate del mattino (verifiche: $VERDICT, banco: $BANCO)." >> "$REPORT"
      if [ -n "$FAIL_DETAIL" ]; then
        echo "" >> "$REPORT"
        echo "Dettaglio del fallimento:" >> "$REPORT"
        echo "$FAIL_DETAIL" >> "$REPORT"
      fi
      echo "" >> "$REPORT"
      echo "Correggere quanto serve senza ampliare lo scope." >> "$REPORT"
      echo "GATE_EOF" >> "$REPORT"
      echo ")\"" >> "$REPORT"
      echo "\`\`\`" >> "$REPORT"
    fi
  done < <(jq -c '.' /tmp/gate-prs.json)
  # lascia $DIR sul branch di default prima di passare alla repo successiva (o al prossimo giro)
  git -C "$DIR" checkout -q "$DB" 2>/dev/null || true
  echo "" >> "$REPORT"
done

echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "**Totale: $TOTAL PR · $PASS con verifiche ok · $FAIL da giudizio/correzione. Report: \`$REPORT\`. Metriche: \`metrics/gate.csv\`. Le proposte correttive si incollano a mano: nessun sì, nessuna commessa.**" >> "$REPORT"

# 6° ciclo, set 3 giro 5 (2026-08-24): l'anello SAL della memoria esisteva solo nei
# documenti (system.md L4 "SAL.md + metrics/gate.csv") — il gate scriveva le metriche
# ma nulla RIORDAVA la lezione in SAL.md: il ciclo dichiarato ("la notte insegna, il
# gate registra, il SAL ricorda") si fermava a metà. La PROSA resta umana (giudizio,
# livello 4-5): qui entra solo il richiamo meccanico, con la soglia per non riempire
# il report di rumore quando tutto è passato pulito.
if [ "$FAIL" -gt 0 ] || [ "$TOTAL" -eq 0 ]; then
  echo "" >> "$REPORT"
  echo "**Memoria:** gli esiti sono già in \`metrics/gate.csv\`; la lezione di questo gate (il PERCHÉ di un fallimento, o una notte a coda vuota) va scritta in \`SAL.md\` del hub prima del prossimo giro — è ciò che rende il ciclo circolare, non solo una coda." >> "$REPORT"
fi
log "Gate completato: $TOTAL PR esaminate ($PASS ok, $FAIL da correggere). Report: $REPORT"
echo "Report pronto: $REPORT"
