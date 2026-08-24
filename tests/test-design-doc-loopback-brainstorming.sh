#!/bin/bash
# test-design-doc-loopback-brainstorming.sh — 5° ciclo, set 2 giro 7. design-doc
# strutturava il caso "un'opzione vince" ma non diceva cosa fare quando NESSUNA
# opzione è accettabile sui criteri critici — rischio di forzare una scelta scadente
# solo perché la tabella esiste. Verifica che §4bis esista e rimandi indietro a
# /brainstorming invece di presentare comunque tre opzioni deboli come "risolte".
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q '4bis\. \*\*Se NESSUNA opzione' "$DD" \
  && ok "esiste il passo §4bis sul caso 'nessuna opzione è buona'" \
  || ko "il passo §4bis non esiste"

SEZ=$(awk '/^4bis\./{f=1} /^5\./{f=0} f' "$DD")
echo "$SEZ" | grep -q "brainstorming" \
  && ok "§4bis rimanda a /brainstorming invece di forzare una scelta scadente" \
  || ko "§4bis non rimanda a /brainstorming"

echo "$SEZ" | grep -qi "non forzare" \
  && ok "§4bis dice esplicitamente di non forzare la scelta" \
  || ko "§4bis non è esplicito sul non forzare"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
