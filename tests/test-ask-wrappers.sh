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

# --- ask-opus col gateway/auth assente: diagnosi leggibile, non mistero ---
OUT4=$(bash "$HERE/llm/ask-opus.sh" "test" 2>&1); RC4=$?
grep -qiE "gateway|Keychain|ask-opus:|login" <<<"$OUT4" && ok "ask-opus col auth assente: diagnosi leggibile (rc=$RC4)" || ko "opus diag: $OUT4"

# --- contratto uniforme: usage anche con stdin in arrivo ---
OUT5=$(echo "contenuto" | bash "$HERE/llm/ask-qwen.sh" 2>&1); RC5=$?
grep -q "uso:" <<<"$OUT5" && ok "ask-qwen senza prompt: usage anche con stdin in arrivo" || ko "qwen usage: $OUT5"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
