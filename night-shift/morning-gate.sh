#!/bin/bash
# morning-gate.sh — il giudizio del mattino: AI_Develop come giudice, censore, correttore.
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

for REPO in "${REPO_LIST[@]}"; do
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
    ISSUE_NUM="${BRANCH#night/issue-}"
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

    # 1. Verifiche dichiarate — lette da origin/main: la dichiarazione è della REPO,
    #    non del branch della PR (che può essere nato prima della dichiarazione)
    VERDICT="—"
    NIGHT_VERIFY=$(git -C "$DIR" show "origin/$DB:.night-verify" 2>/dev/null || true)
    FAIL_DETAIL=""  # Giro 6 dei test 2026-08-21: l'estratto del fallimento, per la issue correttiva
    if [ -n "$NIGHT_VERIFY" ]; then
      echo "**Verifiche dichiarate (.night-verify, da main):**" >> "$REPORT"
      V_RC=0
      while IFS= read -r cmd; do
        cmd="${cmd%%#*}"; [ -z "$(echo "$cmd" | tr -d '[:space:]')" ] && continue
        echo "- \`$cmd\`:" >> "$REPORT"
        if OUT=$( cd "$DIR" && run_guarded 120 bash -c "$cmd" 2>&1 ); then
          echo "  ✅ — $(echo "$OUT" | tail -2 | tr '\n' ' ')" >> "$REPORT"
        else
          echo "  ❌ — $(echo "$OUT" | tail -3 | tr '\n' ' ')" >> "$REPORT"; V_RC=1
          FAIL_DETAIL="$FAIL_DETAIL"$'\n'"- \`$cmd\`:"$'\n'"$(echo "$OUT" | tail -8)"
        fi
      done <<< "$NIGHT_VERIFY"
      [ "$V_RC" -eq 0 ] && VERDICT="verifiche-ok" || VERDICT="verifiche-fallite"
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
    if [ -x "$ASK" ]; then
      DIFF_TXT=$(git -C "$DIR" diff "origin/$DB...$BRANCH" 2>/dev/null | head -300)
      if [ -n "$DIFF_TXT" ]; then
        BANCO_PROMPT="Sei l'avversario in una code review. Ecco il diff di una pull request. Scrivi UN solo comando shell, eseguibile dalla root della repo, che SMASCHERA un difetto della PR se esiste: deve riuscire (exit 0) se la PR è solida, fallire (exit != 0) se è difettosa. Vincoli rigidissimi: niente rete, niente operazioni distruttive (rm/mv/chmod/git push), nessuna modifica permanente. Sono ammessi node/python/grep/git/cat e simili. Rispondi con UN SOLO blocco di codice contenente il comando, senza spiegazioni.

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
          OUT_TAIL=$(tail -5 /tmp/gate-banco.out | tr '\n' ' ' | head -c 200 | sed -E 's/(secret|token|password|key)[a-z_]*[=: ][^ ,"]+/\1=***MASCHERATO***/gi')
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
    echo "$(date '+%Y-%m-%d'),$REPO,#$NUM,#$ISSUE_NUM,$VERDICT,$BANCO," >> "$HUB_METRICS"

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
  echo "" >> "$REPORT"
done

echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "**Totale: $TOTAL PR · $PASS con verifiche ok · $FAIL da giudizio/correzione. Report: \`$REPORT\`. Metriche: \`metrics/gate.csv\`. Le proposte correttive si incollano a mano: nessun sì, nessuna commessa.**" >> "$REPORT"
log "Gate completato: $TOTAL PR esaminate ($PASS ok, $FAIL da correggere). Report: $REPORT"
echo "Report pronto: $REPORT"
