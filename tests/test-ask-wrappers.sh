#!/bin/bash
# test-ask-wrappers.sh — i percorsi di fallimento dei wrapper llm/ (giro 3/10).
# ask-qwen è rodato daily; ask-glm e ask-opus MAI eseguiti: si testano i percorsi
# graziosi (niente chiave, niente argomenti) senza chiamare cervelli veri.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# --- ask-glm senza API key: exit 2 col messaggio chiaro (mai fallire in silenzio) ---
unset ZHIPUAI_API_KEY
OUT=$(bash "$HERE/llm/ask-glm.sh" "ping" 2>&1); RC=$?
[ $RC -eq 2 ] && ok "ask-glm senza chiave: exit 2 (via non configurata, distinta dall'errore)" || ko "exit $RC"
grep -q "non configurata" <<<"$OUT" && ok "ask-glm: messaggio dice COME si sistema (opzioni, non solo errore)" || ko "msg: $OUT"
grep -q "ZCode" <<<"$OUT" && ok "ask-glm: suggerisce la via naturale (sessione ZCode)" || ko "manca via naturale"

# --- senza argomento: usage, exit 1 ---
OUT2=$(bash "$HERE/llm/ask-glm.sh" 2>&1); RC2=$?
[ $RC2 -eq 1 ] && grep -q "uso:" <<<"$OUT2" && ok "ask-glm senza prompt: usage + exit 1" || ko "usage: RC=$RC2"
OUT3=$(bash "$HERE/llm/ask-opus.sh" 2>&1); RC3=$?
[ $RC3 -eq 1 ] && grep -q "uso:" <<<"$OUT3" && ok "ask-opus senza prompt: usage + exit 1" || ko "opus usage: RC=$RC3"

# --- ask-opus: contratto rispettato in ENTRAMBI i mondi possibili ---
# Scoperta (nuovo ciclo 10 giri, 2026-08-22): il test assumeva SEMPRE auth assente
# ("funziona da terminale/launchd, NON da shell sandboxed" — nota nell'header di
# ask-opus.sh). Falso in una sessione cloud come questa: qui il binario `claude` È
# già autenticato (è la sessione stessa), e "test" ottiene una risposta vera, exit 0.
# Non è un difetto di ask-opus.sh (fa esattamente il suo contratto in entrambi i
# casi) — era un'assunzione del TEST, non del sistema: annotato qui, non come
# difetto del wrapper.
# timeout: quando l'auth è presente, questo invoca un vero claude -p ricorsivo dalla
# sessione stessa — osservato variabile in latenza (una run di questa stessa suite
# è arrivata a superare 2 minuti). Un limite duro evita che UN test blocchi tutta la
# suite all'infinito; un timeout qui è un FAIL leggibile, non un mistero.
OUT4=$(timeout 90 bash "$HERE/llm/ask-opus.sh" "test" 2>&1); RC4=$?
if [ "$RC4" -eq 124 ]; then
  ko "ask-opus: timeout dopo 90s (chiamata ricorsiva a claude -p lenta o bloccata)"
elif [ "$RC4" -eq 0 ]; then
  [ -n "$OUT4" ] && ok "ask-opus con auth presente: risposta non vuota (rc=0)" || ko "ask-opus rc=0 ma output vuoto"
else
  grep -qiE "gateway|Keychain|ask-opus:|login" <<<"$OUT4" && ok "ask-opus con auth assente: diagnosi leggibile (rc=$RC4)" || ko "opus diag: $OUT4"
fi

# --- contratto uniforme: usage anche con stdin in arrivo ---
OUT5=$(echo "contenuto" | bash "$HERE/llm/ask-qwen.sh" 2>&1); RC5=$?
grep -q "uso:" <<<"$OUT5" && ok "ask-qwen senza prompt: usage anche con stdin in arrivo" || ko "qwen usage: $OUT5"

# --- bug reale (set 1, giro 1): senza prompt NON deve tentare di avviare Ollama.
# Prima validava il prompt DOPO il tentativo (fino a 30s sprecati + processo in
# background su una chiamata invalida) — verificato con `time`: 30.4s reali.
T0=$(date +%s)
bash "$HERE/llm/ask-qwen.sh" >/dev/null 2>&1 || true
T1=$(date +%s)
DUR=$((T1-T0))
[ "$DUR" -le 3 ] && ok "ask-qwen senza prompt: fallisce subito, non tenta Ollama (${DUR}s)" \
  || ko "ask-qwen senza prompt: ${DUR}s — tenta ancora di avviare Ollama prima di validare"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
