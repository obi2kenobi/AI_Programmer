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
# sessione stessa — una run di questa suite è arrivata a superare 2 minuti.
# CORREZIONE (set 1 "armonizza gli agenti", 2026-08-22): attribuito allora a "claude -p
# lento", causa vera trovata dopo — la lettura di stdin in ask-opus.sh (`$(cat)` senza
# limite) può bloccarsi a tempo indefinito, non la chiamata al cervello. Corretto in
# ask-opus.sh (timeout 5s sulla lettura di stdin, vedi tests/test-stdin-timeout.sh).
# Il timeout qui resta comunque una buona guardia: un limite duro evita che UN test
# blocchi tutta la suite all'infinito, qualunque sia la causa di un futuro rallentamento.
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

# --- bug reale (set 1, giro 3): ASK_TIMEOUT ignorato, --max-time fisso a 1800 ---
QWENTMP=$(mktemp -d)
cat > "$QWENTMP/curl" <<'EOF'
#!/bin/bash
echo "$*" >> /tmp/qwen-curl-args.log
[[ "$*" == *"api/version"* ]] && exit 0
echo '{"message":{"content":"ok"}}'
EOF
chmod +x "$QWENTMP/curl"
rm -f /tmp/qwen-curl-args.log
PATH="$QWENTMP:$PATH" ASK_TIMEOUT=42 bash "$HERE/llm/ask-qwen.sh" "test" </dev/null >/dev/null 2>&1
grep -q -- "--max-time 42 " /tmp/qwen-curl-args.log 2>/dev/null \
  && ok "ask-qwen: ASK_TIMEOUT=42 arriva davvero a curl --max-time (bug corretto)" \
  || ko "ask-qwen: ASK_TIMEOUT non propagato: $(cat /tmp/qwen-curl-args.log 2>/dev/null)"
rm -rf "$QWENTMP" /tmp/qwen-curl-args.log

# --- bug reale (set 1, giro 4): ASK_MODEL ignorato da ask-glm.sh/ask-qwen.sh ---
MODELTMP=$(mktemp -d)
cat > "$MODELTMP/curl" <<'EOF'
#!/bin/bash
echo "$*" >> /tmp/model-curl.log
[[ "$*" == *"api/version"* ]] && exit 0
echo '{"choices":[{"message":{"content":"ok"}}],"message":{"content":"ok"}}'
EOF
chmod +x "$MODELTMP/curl"

rm -f /tmp/model-curl.log
( unset GLM_MODEL; PATH="$MODELTMP:$PATH" ZHIPUAI_API_KEY=x ASK_MODEL=modello-custom bash "$HERE/llm/ask-glm.sh" "test" </dev/null >/dev/null 2>&1 )
grep -q '"model": "modello-custom"' /tmp/model-curl.log 2>/dev/null \
  && ok "ask-glm: ASK_MODEL usato quando GLM_MODEL è assente (bug corretto)" \
  || ko "ask-glm: ASK_MODEL ignorato: $(cat /tmp/model-curl.log 2>/dev/null)"

rm -f /tmp/model-curl.log
( unset QWEN_MODEL; PATH="$MODELTMP:$PATH" ASK_MODEL=modello-custom-qwen bash "$HERE/llm/ask-qwen.sh" "test" </dev/null >/dev/null 2>&1 )
grep -q '"model": "modello-custom-qwen"' /tmp/model-curl.log 2>/dev/null \
  && ok "ask-qwen: ASK_MODEL usato quando QWEN_MODEL è assente (bug corretto)" \
  || ko "ask-qwen: ASK_MODEL ignorato: $(cat /tmp/model-curl.log 2>/dev/null)"
rm -rf "$MODELTMP" /tmp/model-curl.log

# --- set 1, giro 5: ask-opus.sh armonizza exit 2 per auth assente (come ask-glm.sh) ---
OPUSTMP=$(mktemp -d)
cat > "$OPUSTMP/claude" <<'EOF'
#!/bin/bash
echo "Error: not logged in. Please run 'claude login' first." >&2
exit 1
EOF
chmod +x "$OPUSTMP/claude"
OUT_AUTH=$(PATH="$OPUSTMP:$PATH" bash "$HERE/llm/ask-opus.sh" "test" </dev/null 2>&1); RC_AUTH=$?
[ "$RC_AUTH" -eq 2 ] && ok "ask-opus: auth assente → exit 2 (armonizzato con ask-glm)" \
  || ko "ask-opus: auth assente ha dato rc=$RC_AUTH invece di 2: $OUT_AUTH"

cat > "$OPUSTMP/claude" <<'EOF'
#!/bin/bash
echo "Error: internal server error, code 500" >&2
exit 1
EOF
chmod +x "$OPUSTMP/claude"
OUT_ERR=$(PATH="$OPUSTMP:$PATH" bash "$HERE/llm/ask-opus.sh" "test" </dev/null 2>&1); RC_ERR=$?
[ "$RC_ERR" -eq 1 ] && ok "ask-opus: errore generico resta exit 1 (distinto da auth assente)" \
  || ko "ask-opus: errore generico ha dato rc=$RC_ERR invece di 1: $OUT_ERR"
rm -rf "$OPUSTMP"

# --- set 1, giro 7: ask-glm.sh non deve mai dare un traceback Python grezzo ---
GLMTMP=$(mktemp -d)
check_glm_response() {
  local nome="$1" body="$2" atteso_grep="$3"
  cat > "$GLMTMP/curl" <<EOF
#!/bin/bash
printf '%s' '$body'
EOF
  chmod +x "$GLMTMP/curl"
  local OUT RC
  OUT=$(PATH="$GLMTMP:$PATH" ZHIPUAI_API_KEY=x bash "$HERE/llm/ask-glm.sh" "test" </dev/null 2>&1); RC=$?
  ! grep -q "Traceback" <<<"$OUT" && grep -q "$atteso_grep" <<<"$OUT" \
    && ok "ask-glm risposta $nome: diagnosi pulita, niente traceback (rc=$RC)" \
    || ko "ask-glm risposta $nome: $OUT (rc=$RC)"
}
check_glm_response "vuota"             ""                       "ERRORE glm"
check_glm_response "HTML non-JSON"     "<html>errore</html>"    "ERRORE glm"
check_glm_response "JSON forma errata" '{"unexpected": true}'   "ERRORE glm"
rm -rf "$GLMTMP"

# --- set 1, giro 8: stesso bug in ask-qwen.sh (traceback su risposta malformata) ---
QWENRESPTMP=$(mktemp -d)
check_qwen_response() {
  local nome="$1" body="$2" atteso_grep="$3"
  cat > "$QWENRESPTMP/curl" <<EOF
#!/bin/bash
[[ "\$*" == *"api/version"* ]] && exit 0
printf '%s' '$body'
EOF
  chmod +x "$QWENRESPTMP/curl"
  local OUT RC
  OUT=$(PATH="$QWENRESPTMP:$PATH" bash "$HERE/llm/ask-qwen.sh" "test" </dev/null 2>&1); RC=$?
  ! grep -q "Traceback" <<<"$OUT" && grep -q "$atteso_grep" <<<"$OUT" \
    && ok "ask-qwen risposta $nome: diagnosi pulita, niente traceback (rc=$RC)" \
    || ko "ask-qwen risposta $nome: $OUT (rc=$RC)"
}
check_qwen_response "vuota"             ""                       "ERRORE ollama"
check_qwen_response "HTML non-JSON"     "<html>errore</html>"    "ERRORE ollama"
check_qwen_response "JSON forma errata" '{"unexpected": true}'   "ERRORE ollama"
rm -rf "$QWENRESPTMP"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
