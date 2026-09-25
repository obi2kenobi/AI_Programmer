#!/bin/bash
# test-payload-da-stdin.sh — i prompt verso i modelli viaggiano su stdin, mai negli argomenti (2026-09-23,
# notte dei giri, T5#6; la stessa cura di Q8 per llm/ask-*). `curl -d "$(jq --arg p "$PROMPT" …)"`
# mette conversazione e sorgenti in argv: leggibili da `ps`, e oltre 128 KB per argomento (Linux)
# il comando non parte («Argument list too long»). La conversazione di night-shift/agente.sh arriva a
# 8 turni × 24 KB di file letti.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# la ragione, misurata: un argomento oltre 128 KB non parte su Linux (su macOS il tetto e' ARG_MAX, 1 MB)
if [ "$(uname)" = Linux ]; then
  GRANDE=$(head -c 200000 /dev/zero | tr '\0' a)
  /bin/echo "$GRANDE" >/dev/null 2>&1 && ko "un argomento da 200 KB e' partito: la premessa del banco non regge" \
    || ok "un argomento da 200 KB non parte (E2BIG): il payload in argv e' un limite vero"
fi

# il cricchetto: nessun payload costruito in argv verso un modello
SITI=$(cd "$HERE" && grep -nE -- '-d "\$\(jq|--argjson msgs "\$CONV"|--arg p "\$(PROMPT|1)"' night-shift/*.sh tools/*.sh 2>/dev/null)
[ -z "$SITI" ] && ok "nessun prompt verso un modello passa per gli argomenti di curl o jq" \
  || ko "prompt in argv: $(cut -d: -f1,2 <<<"$SITI" | tr '\n' ' ')"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
