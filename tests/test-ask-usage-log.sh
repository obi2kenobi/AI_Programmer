#!/bin/bash
# test-ask-usage-log.sh — set 1 giro 10: simmetria di memoria notte/giorno. Il turno
# notturno lascia traccia in SAL.md + metrics/gate.csv; i cervelli di giorno
# (ask-opus/ask-glm/ask-qwen) non lasciavano nulla. llm/_usage.sh aggiunge un log
# locale minimale (mai versionato, best-effort) via trap EXIT su ogni wrapper.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/claude" <<'EOF'
#!/bin/bash
echo "risposta finta opus"
EOF
cat > "$TMP/curl" <<'EOF'
#!/bin/bash
[[ "$*" == *"api/version"* ]] && exit 0
if [[ "$*" == *"chat/completions"* ]]; then echo '{"choices":[{"message":{"content":"ok"}}]}'; exit 0; fi
echo '{"message":{"content":"ok"}}'
EOF
chmod +x "$TMP/claude" "$TMP/curl"

USAGELOG="$TMP/usage.log"
export ASK_USAGE_LOG="$USAGELOG"
export PATH="$TMP:$PATH"

ZHIPUAI_API_KEY=x bash "$HERE/llm/ask-opus.sh" "prova opus" </dev/null >/dev/null 2>&1
ZHIPUAI_API_KEY=x bash "$HERE/llm/ask-glm.sh"  "prova glm"  </dev/null >/dev/null 2>&1
bash "$HERE/llm/ask-qwen.sh" "prova qwen" </dev/null >/dev/null 2>&1

[ -f "$USAGELOG" ] && ok "il file di traccia locale viene creato" || ko "nessun file di traccia creato"

for brain in ask-opus ask-glm ask-qwen; do
  grep -q "^[0-9T:Z-]* $brain rc=0 dur=[0-9]*s prompt_chars=[0-9]*$" "$USAGELOG" \
    && ok "$brain: registrato con rc/durata/lunghezza prompt" \
    || ko "$brain: riga di traccia mancante o malformata: $(grep "$brain" "$USAGELOG" || echo assente)"
done

# il fallimento (auth/config assente) deve tracciare comunque, con l'rc reale
: > "$USAGELOG"
bash "$HERE/llm/ask-glm.sh" "senza chiave" </dev/null >/dev/null 2>&1
grep -q "ask-glm rc=2 " "$USAGELOG" && ok "ask-glm: anche l'esito 'non configurato' (rc=2) viene tracciato" \
  || ko "ask-glm: fallimento non tracciato: $(cat "$USAGELOG")"

# il contenuto del prompt non deve MAI finire nel log (solo la lunghezza)
grep -q "senza chiave" "$USAGELOG" && ko "il testo del prompt è finito nel log (privacy)" \
  || ok "il testo del prompt non finisce nel log, solo la sua lunghezza"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
