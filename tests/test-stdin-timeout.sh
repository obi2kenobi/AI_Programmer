#!/bin/bash
# test-stdin-timeout.sh — bug reale, riprodotto dal vivo (set 1 "armonizza gli agenti",
# 2026-08-22): i tre wrapper llm/ask-*.sh usavano `[ ! -t 0 ] && STDIN_DATA=$(cat)` per
# leggere un contesto opzionale da stdin. In un contesto non interattivo dove stdin non
# è un terminale ma NON emette EOF a breve (un pipe aperto senza scrittore che chiude),
# `cat` blocca a tempo indefinito. Il ciclo precedente aveva attribuito un hang osservato
# di 2+ minuti a "claude -p lento" — CORREZIONE: la causa vera è questa, riprodotta qui
# con `< <(sleep 100)` (un file descriptor che resta aperto 100s senza mai scrivere né
# chiudere, esattamente il caso non-tty-senza-EOF).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# finti cervelli: rispondono all'istante, per isolare SOLO il tempo di lettura di stdin
cat > "$TMP/claude" <<'EOF'
#!/bin/bash
echo "risposta finta opus"
EOF
cat > "$TMP/curl" <<'EOF'
#!/bin/bash
# risponde a QUALSIASI chiamata (versione ollama, chat GLM, chat qwen) con qualcosa di
# innocuo: gli script che lo usano per una probe si accontentano di un exit 0/output vuoto,
# quelli che lo usano per il payload ricevono un JSON minimo valido.
if [[ "$*" == *"api/version"* ]]; then echo '{"version":"0.0.0-finto"}'; exit 0; fi
if [[ "$*" == *"chat/completions"* ]]; then echo '{"choices":[{"message":{"content":"risposta finta glm"}}]}'; exit 0; fi
echo '{"message":{"content":"risposta finta qwen"}}'
EOF
chmod +x "$TMP/claude" "$TMP/curl"
export PATH="$TMP:$PATH"
export ZHIPUAI_API_KEY="finta-per-test"

check_bounded() {
  local nome="$1" script="$2"; shift 2
  local T0 T1 DUR RC FIFO SLEEP_PID
  # bug reale (5° ciclo, set 1 giro 10, scoperto rieseguendo l'intera suite più volte di
  # fila — esattamente cosa fa questo stesso ciclo): `< <(sleep 100)` (process substitution)
  # lascia il `sleep 100` orfano quando `timeout` uccide solo il comando che legge da esso,
  # non il processo che scrive — verificato dal vivo con `ps aux` dopo una run: gli orfani
  # si accumulano a ogni esecuzione del test (3 per run, uno per wrapper) e restano vivi
  # fino alla loro scadenza naturale di 100s. Con una FIFO esplicita si ottiene lo stesso
  # comportamento (stdin apribile senza EOF) ma il PID del sleep resta noto e viene ucciso
  # subito dopo, non lasciato scadere da solo.
  FIFO="$TMP/fifo_${nome//[^A-Za-z0-9]/_}"
  mkfifo "$FIFO"
  sleep 100 > "$FIFO" &
  SLEEP_PID=$!
  T0=$(date +%s)
  timeout 20 bash "$HERE/llm/$script" "$@" < "$FIFO" >/tmp/stdintest.out 2>&1
  RC=$?
  T1=$(date +%s); DUR=$((T1-T0))
  kill "$SLEEP_PID" 2>/dev/null
  wait "$SLEEP_PID" 2>/dev/null
  rm -f "$FIFO"
  if [ "$RC" -eq 124 ]; then
    ko "$nome: bloccato oltre 20s con stdin aperto senza EOF (bug NON corretto)"
  elif [ "$DUR" -le 10 ]; then
    ok "$nome: completa in ${DUR}s con stdin aperto senza EOF (limite rispettato)"
  else
    ko "$nome: ${DUR}s — troppo lento, il timeout sullo stdin non sta limitando l'attesa"
  fi

  # guardia di regressione: il sleep ausiliario deve essere morto qui, non orfano
  if kill -0 "$SLEEP_PID" 2>/dev/null; then
    ko "$nome: il processo sleep ausiliario (pid $SLEEP_PID) è ancora vivo — orfano non riaperto"
  else
    ok "$nome: nessun processo orfano lasciato dal banco di test"
  fi
}

check_bounded "ask-opus.sh" "ask-opus.sh" "test"
check_bounded "ask-glm.sh"  "ask-glm.sh"  "test"
# ask-qwen.sh: puntare a un Ollama "già su" evitando i 30s del probe di avvio —
# il finto curl risponde subito a /api/version, quindi il probe passa al primo colpo.
check_bounded "ask-qwen.sh" "ask-qwen.sh" "test"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
