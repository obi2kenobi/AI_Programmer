#!/bin/bash
# morning-gate.sh — il giudizio del mattino: AI_Develop come giudice, censore, correttore.
#
# Per ogni PR night/* aperta su ogni repo della coda:
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
  gh pr list -R "$REPO" --state open --json number,headRefName,title --limit 50 2>/dev/null \
    | jq -c '.[] | select(.headRefName | startswith("night/"))' > /tmp/gate-prs.json
  # -s (slurp): conta gli elementi dello stream — senza, jq conta le CHIAVI dell'oggetto
  N=$(jq -s 'length' < /tmp/gate-prs.json); N="${N:-0}"
  echo "## $REPO — $N PR notturne aperte" >> "$REPORT"
  [ "$N" -eq 0 ] && { echo "_Nessuna. Il sistema ha lavorato o non aveva coda._" >> "$REPORT"; echo "" >> "$REPORT"; continue; }

  [ -d "$DIR/.git" ] || { gh repo clone "$REPO" "$DIR" -- --depth=50 -q; }
  git -C "$DIR" fetch origin --prune -q

  while IFS= read -r row; do
    NUM=$(echo "$row" | jq -r '.number')
    BRANCH=$(echo "$row" | jq -r '.headRefName')
    TITLE=$(echo "$row" | jq -r '.title')
    ISSUE_NUM="${BRANCH#night/issue-}"
    TOTAL=$((TOTAL+1))
    echo "" >> "$REPORT"
    echo "### PR #$NUM — $TITLE (\`$BRANCH\`)" >> "$REPORT"
    git -C "$DIR" checkout -q "$BRANCH" 2>/dev/null || git -C "$DIR" checkout -q -b "$BRANCH" "origin/$BRANCH"
    echo "**Diff:**" >> "$REPORT"
    git -C "$DIR" diff --stat "origin/main...$BRANCH" >> "$REPORT" 2>/dev/null

    # 1. Verifiche dichiarate — lette da origin/main: la dichiarazione è della REPO,
    #    non del branch della PR (che può essere nato prima della dichiarazione)
    VERDICT="—"
    NIGHT_VERIFY=$(git -C "$DIR" show origin/main:.night-verify 2>/dev/null || true)
    if [ -n "$NIGHT_VERIFY" ]; then
      echo "**Verifiche dichiarate (.night-verify, da main):**" >> "$REPORT"
      V_RC=0
      while IFS= read -r cmd; do
        cmd="${cmd%%#*}"; [ -z "$(echo "$cmd" | tr -d '[:space:]')" ] && continue
        echo "- \`$cmd\`:" >> "$REPORT"
        if OUT=$( cd "$DIR" && eval "$cmd" 2>&1 ); then
          echo "  ✅ — $(echo "$OUT" | tail -2 | tr '\n' ' ')" >> "$REPORT"
        else
          echo "  ❌ — $(echo "$OUT" | tail -3 | tr '\n' ' ')" >> "$REPORT"; V_RC=1
        fi
      done <<< "$NIGHT_VERIFY"
      [ "$V_RC" -eq 0 ] && VERDICT="verifiche-ok" || VERDICT="verifiche-fallite"
    else
      echo "**Verifiche dichiarate:** nessun file \`.night-verify\` su main — il silenzio non è un verdetto: dichiarale." >> "$REPORT"
      VERDICT="non-dichiarate"
    fi

    # 2. Banco avversariale: il modello locale prova a smentire
    BANCO="—"
    ASK_QWEN="$HERE/../llm/ask-qwen.sh"
    if [ -x "$ASK_QWEN" ]; then
      DIFF_TXT=$(git -C "$DIR" diff "origin/main...$BRANCH" 2>/dev/null | head -300)
      if [ -n "$DIFF_TXT" ]; then
        BANCO_PROMPT="Ecco il diff di una pull request. Il tuo compito: PROVA A SMENERLA. Scrivi UNA verifica concreta (test, comando o controllo manuale) che questa bozza NON supererebbe se contiene un difetto — concentra il ragionamento sui punti deboli reali: valori attesi, effetti collaterali, casi limite non gestiti. Se il diff non ha punti deboli evidenti, dillo onestamente. Massimo 10 righe.

$DIFF_TXT"
        BANCO_OUT=$(printf '%s' "$BANCO_PROMPT" | QWEN_THINK=true "$ASK_QWEN" "Fai quanto chiesto sopra." 2>/dev/null || true)
        echo "**Banco avversariale (proposta di smentita da eseguire in review):**" >> "$REPORT"
        echo '```' >> "$REPORT"; echo "${BANCO_OUT:-(modello non disponibile)}" >> "$REPORT"; echo '```' >> "$REPORT"
        BANCO="proposto"
      fi
    fi

    # 3-4. memoria + verdetto
    case "$VERDICT" in verifiche-ok) PASS=$((PASS+1));; *) FAIL=$((FAIL+1));; esac
    echo "$(date '+%Y-%m-%d'),$REPO,#$NUM,#$ISSUE_NUM,$VERDICT,$BANCO" >> "$HUB_METRICS"

    if [ "$VERDICT" = "verifiche-fallite" ]; then
      echo "" >> "$REPORT"
      echo "> ⛔ **Proposta correttiva** (il correttore — da approvare):" >> "$REPORT"
      echo "> \`\`\`bash" >> "$REPORT"
      echo "gh issue create -R $REPO --label night-shift --title \"correzione: PR #$NUM non passa le verifiche\" --body \"La PR #$NUM fallisce le verifiche dichiarate. Correggere quanto serve per farle passare, senza ampliare lo scope.\"" >> "$REPORT"
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
