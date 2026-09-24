#!/bin/bash
# test-ask-wrappers.sh — i percorsi di fallimento dei wrapper llm/ (giro 3/10).
# ask-qwen è rodato daily; ask-glm e ask-opus MAI eseguiti: si testano i percorsi
# graziosi (niente chiave, niente argomenti) senza chiamare cervelli veri.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# ai_timeout: portabile anche su macOS senza GNU timeout (vedi llm/_timeout.sh)
source "$HERE/llm/_timeout.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# (2026-09-24, terzo ventaglio, V4#5): ogni suite faceva una chiamata `claude -p` VERA (10 s qui, fino a
# 90 s di tetto) dentro un budget fisso, mentre il gate dell'auto-fix esclude proprio test-ask-* per l'auth
# sotto launchd. Una sentinella in testa al PATH registra ogni chiamata a claude che nessun finto intercetta:
# senza ASK_VIVO=1 non ce ne deve essere nessuna.
SENT=$(mktemp -d)
printf '#!/bin/bash\necho "$*" >> "%s/vere.log"\necho "sentinella: chiamata vera a claude senza ASK_VIVO=1" >&2\nexit 1\n' "$SENT" > "$SENT/claude"
chmod +x "$SENT/claude"
[ "${ASK_VIVO:-0}" = 1 ] || export PATH="$SENT:$PATH"

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
# (V4#5): la chiamata vera solo con ASK_VIVO=1; di norma il ramo «auth presente» si prova con un claude
# finto che risponde, come i rami «auth assente» ed «errore» qui sotto.
if [ "${ASK_VIVO:-0}" = 1 ]; then
  OUT4=$(ai_timeout 90 bash "$HERE/llm/ask-opus.sh" "test" 2>&1); RC4=$?
  if [ "$RC4" -eq 124 ]; then
    ko "ask-opus: timeout dopo 90s (chiamata ricorsiva a claude -p lenta o bloccata)"
  elif [ "$RC4" -eq 0 ]; then
    [ -n "$OUT4" ] && ok "ask-opus con auth presente: risposta non vuota (rc=0)" || ko "ask-opus rc=0 ma output vuoto"
  else
    grep -qiE "gateway|Keychain|ask-opus:|login" <<<"$OUT4" && ok "ask-opus con auth assente: diagnosi leggibile (rc=$RC4)" || ko "opus diag: $OUT4"
  fi
else
  echo "SALTO la chiamata vera a claude -p: ASK_VIVO=1 per provarla (fuori dal budget della suite)"
  VIVOTMP=$(mktemp -d)
  printf '#!/bin/bash\necho "OK dalla risposta finta"\n' > "$VIVOTMP/claude"; chmod +x "$VIVOTMP/claude"
  OUT4=$(PATH="$VIVOTMP:$PATH" ai_timeout 30 bash "$HERE/llm/ask-opus.sh" "test" </dev/null 2>&1); RC4=$?
  [ "$RC4" -eq 0 ] && grep -c "OK dalla risposta finta" <<<"$OUT4" >/dev/null \
    && ok "ask-opus con auth presente (claude finto): la risposta arriva, rc 0" || ko "ask-opus con auth presente (finto): rc=$RC4, $OUT4"
  rm -rf "$VIVOTMP"
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
echo "$*" >> "$(dirname "$0")/args.log"
[[ "$*" == *"api/version"* ]] && exit 0
echo '{"message":{"content":"ok"}}'
EOF
chmod +x "$QWENTMP/curl"
rm -f "$QWENTMP/args.log"
PATH="$QWENTMP:$PATH" ASK_TIMEOUT=42 bash "$HERE/llm/ask-qwen.sh" "test" </dev/null >/dev/null 2>&1
grep -q -- "--max-time 42 " "$QWENTMP/args.log" 2>/dev/null \
  && ok "ask-qwen: ASK_TIMEOUT=42 arriva davvero a curl --max-time (bug corretto)" \
  || ko "ask-qwen: ASK_TIMEOUT non propagato: $(cat "$QWENTMP/args.log" 2>/dev/null)"
rm -rf "$QWENTMP"

# --- bug reale (set 1, giro 4): ASK_MODEL ignorato da ask-glm.sh/ask-qwen.sh ---
MODELTMP=$(mktemp -d)
cat > "$MODELTMP/curl" <<'EOF'
#!/bin/bash
echo "$*" >> "$(dirname "$0")/args.log"
[[ "$*" == *"@-"* ]] && cat >> "$(dirname "$0")/args.log"
[[ "$*" == *"api/version"* ]] && exit 0
echo '{"choices":[{"message":{"content":"ok"}}],"message":{"content":"ok"}}'
EOF
chmod +x "$MODELTMP/curl"

rm -f "$MODELTMP/args.log"
( unset GLM_MODEL; PATH="$MODELTMP:$PATH" ZHIPUAI_API_KEY=x ASK_MODEL=modello-custom bash "$HERE/llm/ask-glm.sh" "test" </dev/null >/dev/null 2>&1 )
grep -q '"model": "modello-custom"' "$MODELTMP/args.log" 2>/dev/null \
  && ok "ask-glm: ASK_MODEL usato quando GLM_MODEL è assente (bug corretto)" \
  || ko "ask-glm: ASK_MODEL ignorato: $(cat "$MODELTMP/args.log" 2>/dev/null)"

rm -f "$MODELTMP/args.log"
( unset QWEN_MODEL; PATH="$MODELTMP:$PATH" ASK_MODEL=modello-custom-qwen bash "$HERE/llm/ask-qwen.sh" "test" </dev/null >/dev/null 2>&1 )
grep -q '"model": "modello-custom-qwen"' "$MODELTMP/args.log" 2>/dev/null \
  && ok "ask-qwen: ASK_MODEL usato quando QWEN_MODEL è assente (bug corretto)" \
  || ko "ask-qwen: ASK_MODEL ignorato: $(cat "$MODELTMP/args.log" 2>/dev/null)"
rm -rf "$MODELTMP"

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

# --- revisione 14 lenti, 2026-08-28: curl che fallisce interamente (rete assente) non
# deve far uscire lo script sotto `set -e` senza alcuna diagnosi ---
CURLFAILTMP=$(mktemp -d)
cat > "$CURLFAILTMP/curl" <<'EOF'
#!/bin/bash
echo "curl: (7) Failed to connect" >&2
exit 7
EOF
chmod +x "$CURLFAILTMP/curl"
OUT_GLM_CF=$(PATH="$CURLFAILTMP:$PATH" ZHIPUAI_API_KEY=x bash "$HERE/llm/ask-glm.sh" "test" </dev/null 2>&1); RC_GLM_CF=$?
[ "$RC_GLM_CF" -eq 1 ] && grep -q "ERRORE glm: curl fallito" <<<"$OUT_GLM_CF" \
  && ok "ask-glm: curl fallito (rete assente) dà una diagnosi, non un'uscita muta" \
  || ko "ask-glm: curl fallito non diagnosticato — rc=$RC_GLM_CF out=$OUT_GLM_CF"

cat > "$CURLFAILTMP/curl" <<'EOF'
#!/bin/bash
[[ "$*" == *"api/version"* ]] && exit 0
echo "curl: (7) Failed to connect" >&2
exit 7
EOF
chmod +x "$CURLFAILTMP/curl"
OUT_QWEN_CF=$(PATH="$CURLFAILTMP:$PATH" bash "$HERE/llm/ask-qwen.sh" "test" </dev/null 2>&1); RC_QWEN_CF=$?
[ "$RC_QWEN_CF" -eq 1 ] && grep -q "ERRORE qwen: curl fallito" <<<"$OUT_QWEN_CF" \
  && ok "ask-qwen: curl fallito (rete assente) dà una diagnosi, non un'uscita muta" \
  || ko "ask-qwen: curl fallito non diagnosticato — rc=$RC_QWEN_CF out=$OUT_QWEN_CF"
rm -rf "$CURLFAILTMP"

# --- revisione 14 lenti, 2026-08-28: uno stdin lento (troncato dal timeout di 5s) deve
# avvisare, non corrompere il contesto in silenzio ---
STDINTMP=$(mktemp -d)
cat > "$STDINTMP/curl" <<'EOF'
#!/bin/bash
printf '{"choices":[{"message":{"content":"ok"}}]}'
EOF
chmod +x "$STDINTMP/curl"
OUT_STDIN=$( { for i in 1 2 3; do echo "riga$i"; sleep 2; done; } \
  | PATH="$STDINTMP:$PATH" ZHIPUAI_API_KEY=x bash "$HERE/llm/ask-glm.sh" "test" 2>&1 )
grep -q "ATTENZIONE.*TRONCATO" <<<"$OUT_STDIN" \
  && ok "ask-glm: stdin lento avvisa del troncamento invece di corrompere in silenzio" \
  || ko "ask-glm: stdin lento senza avviso — output: $OUT_STDIN"
rm -rf "$STDINTMP"

# --- 2026-09-23, giro A1 della notte: la chiave di ask-glm stava negli ARGOMENTI di curl
# (`-H "Authorization: Bearer $KEY"`), leggibile da `ps` per tutta la durata della chiamata
# (fino a 600s); e il prompt con lo stdin passava come argomento a python3 e a curl: oltre
# 128 KB (MAX_ARG_STRLEN) il wrapper moriva con «Argument list too long» (rc=126) — proprio
# il «contesto lungo via stdin» che CLAUDE.md §7 promette. Ora la chiave passa da un file
# descrittore, prompt e payload da stdin. La chiave non si stampa mai: si CONTA.
ARGVTMP=$(mktemp -d)
cat > "$ARGVTMP/curl" <<'EOF'
#!/bin/bash
D=$(dirname "$0"); printf '%s\n' "$@" >> "$D/argv"
prec=""; for a in "$@"; do [ "$prec" = "-H" ] && [ "${a#@}" != "$a" ] && cat "${a#@}" >> "$D/header"; prec="$a"; done
[[ "$*" == *"@-"* ]] && cat >> "$D/corpo"
[[ "$*" == *"api/version"* ]] && exit 0
printf '{"choices":[{"message":{"content":"ok"}}],"message":{"content":"ok"}}'
EOF
chmod +x "$ARGVTMP/curl"
CHIAVE_FINTA="chiave-finta-$$-xyz"
PATH="$ARGVTMP:$PATH" ZHIPUAI_API_KEY="$CHIAVE_FINTA" bash "$HERE/llm/ask-glm.sh" "ciao" </dev/null >/dev/null 2>&1
[ "$(grep -c -- "$CHIAVE_FINTA" "$ARGVTMP/argv" 2>/dev/null)" = "0" ] \
  && ok "ask-glm: la chiave NON compare negli argomenti di curl (invisibile a ps)" \
  || ko "ask-glm: la chiave e' negli argomenti di curl ($(grep -c -- "$CHIAVE_FINTA" "$ARGVTMP/argv") righe)"
[ "$(grep -c -- "Authorization: Bearer $CHIAVE_FINTA" "$ARGVTMP/header" 2>/dev/null)" = "1" ] \
  && ok "ask-glm: l'header di autorizzazione arriva comunque a curl (da file descrittore)" \
  || ko "ask-glm: l'header di autorizzazione non arriva a curl"
head -c 200000 /dev/zero | tr '\0' q > "$ARGVTMP/grande"
for W in glm qwen; do
  rm -f "$ARGVTMP/argv" "$ARGVTMP/corpo"
  PATH="$ARGVTMP:$PATH" ZHIPUAI_API_KEY="$CHIAVE_FINTA" bash "$HERE/llm/ask-$W.sh" "riassumi" <"$ARGVTMP/grande" >"$ARGVTMP/out" 2>&1; RC=$?
  N=$(cat "$ARGVTMP/argv" "$ARGVTMP/corpo" 2>/dev/null | tr -cd q | wc -c | tr -d ' ')
  [ "$RC" -eq 0 ] && [ "$N" -ge 200000 ] \
    && ok "ask-$W: un contesto di 200 KB via stdin arriva intero al modello (niente E2BIG)" \
    || ko "ask-$W: contesto di 200 KB perso — rc=$RC, $N byte arrivati: $(head -c 200 "$ARGVTMP/out")"
done
rm -rf "$ARGVTMP"

# --- Q29 (2026-09-23, notte dei giri): ask-opus. (a) `2>&1` metteva nello STDOUT anche gli avvisi che
# claude stampa su stderr: sul successo la risposta arrivava sporca a chi la legge (pipeline, turno).
# (b) il contesto dallo stdin viaggiava nell'argomento: oltre 128 KB, «Argument list too long».
OPTMP=$(mktemp -d)
cat > "$OPTMP/claude" <<'EOF'
#!/bin/bash
D=$(dirname "$0")
printf '%s' "$*" | wc -c > "$D/argv-len"
[ -t 0 ] || cat > "$D/stdin"
echo "Warning: una nuova versione e' disponibile" >&2
echo "RISPOSTA DEL MODELLO"
EOF
chmod +x "$OPTMP/claude"
OUT=$(PATH="$OPTMP:$PATH" bash "$HERE/llm/ask-opus.sh" "domanda" </dev/null 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && [ "$OUT" = "RISPOSTA DEL MODELLO" ] && ok "ask-opus: sul successo lo stdout e' la sola risposta (gli avvisi di claude restano su stderr)" \
  || ko "ask-opus: risposta sporca o rc=$RC: $(head -c 120 <<<"$OUT")"
head -c 200000 /dev/zero | tr '\0' q > "$OPTMP/grande"
OUT=$(PATH="$OPTMP:$PATH" bash "$HERE/llm/ask-opus.sh" "riassumi" <"$OPTMP/grande" 2>&1); RC=$?
N=$(tr -cd q < "$OPTMP/stdin" 2>/dev/null | wc -c | tr -d ' ')
[ "$RC" -eq 0 ] && [ "${N:-0}" -ge 200000 ] && [ "$(cat "$OPTMP/argv-len")" -lt 1000 ] \
  && ok "ask-opus: un contesto di 200 KB arriva a claude su stdin, non nell'argomento (niente E2BIG)" \
  || ko "ask-opus: contesto di 200 KB — rc=$RC, su stdin ${N:-0} byte: $(head -c 150 <<<"$OUT")"
rm -rf "$OPTMP"

# --- (2026-09-23, notte dei giri, T5#5): verso i cervelli CLOUD il contesto parte mascherato. Il
# morning-gate con ADVERSARY=glm|opus manda il diff delle repo private: un token o una password nel
# diff arrivavano interi nel payload. Il cervello locale (ask-qwen) resta com'e': i dati non escono.
MSKTMP=$(mktemp -d)
cat > "$MSKTMP/curl" <<EOF
#!/bin/bash
cat > "$MSKTMP/payload"; echo '{"choices":[{"message":{"content":"ok"}}]}'
EOF
cat > "$MSKTMP/claude" <<EOF
#!/bin/bash
printf '%s\n' "\$2" > "$MSKTMP/domanda"; cat > "$MSKTMP/contesto"; echo ok
EOF
chmod +x "$MSKTMP/curl" "$MSKTMP/claude"
FINTO="gh""p_ABCDEFGHIJKLMNOPQRSTUVWX"
PATH="$MSKTMP:$PATH" ZHIPUAI_API_KEY=x bash "$HERE/llm/ask-glm.sh" "rivedi GH_TOKEN=$FINTO" <<<"password=$FINTO nel diff" >/dev/null 2>&1
grep -cF "$FINTO" "$MSKTMP/payload" >/dev/null 2>&1 && ko "ask-glm: il segreto parte intero verso il cloud" \
  || { grep -cE "segreto [0-9a-f]{8}" "$MSKTMP/payload" >/dev/null && ok "ask-glm: domanda e contesto partono mascherati" || ko "ask-glm: payload senza maschera ne' segreto: $(head -c 200 "$MSKTMP/payload")"; }
PATH="$MSKTMP:$PATH" bash "$HERE/llm/ask-opus.sh" "rivedi GH_TOKEN=$FINTO" <<<"password=$FINTO nel diff" >/dev/null 2>&1
cat "$MSKTMP/domanda" "$MSKTMP/contesto" 2>/dev/null | grep -cF "$FINTO" >/dev/null && ko "ask-opus: il segreto parte intero verso il cloud" \
  || { grep -c "«segreto" "$MSKTMP/contesto" >/dev/null 2>&1 && ok "ask-opus: domanda e contesto partono mascherati" || ko "ask-opus: claude finto mai chiamato o contesto vuoto"; }
rm -rf "$MSKTMP"

[ ! -s "$SENT/vere.log" ] && ok "nessuna chiamata vera a claude senza ASK_VIVO=1 (il budget della suite non paga la rete)" \
  || ko "chiamata vera a claude senza ASK_VIVO=1: $(cat "$SENT/vere.log")"
rm -rf "$SENT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
