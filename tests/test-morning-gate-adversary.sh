#!/bin/bash
# test-morning-gate-adversary.sh — set 1 giro 6: GLM diventa selezionabile come
# ADVERSARY nel banco avversariale (prima solo qwen/opus erano cablati, nonostante
# GLM sia un cervello di giorno pienamente documentato in llm/README.md).
# Estrae la logica di selezione REALE da morning-gate.sh (non una copia che potrebbe
# disallinearsi) e la esegue con i tre valori possibili.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SNIPPET=$(sed -n '/ADVERSARY="\${ADVERSARY:-qwen}"/,/ASK="\$HERE\/\.\.\/llm\/ask-glm\.sh"/p' \
  "$HERE/night-shift/morning-gate.sh")

[ -n "$SNIPPET" ] && ok "trovata la logica di selezione ADVERSARY in morning-gate.sh" \
  || { ko "logica di selezione non trovata (rinominata? test da aggiornare)"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

check_adversary() {
  local valore="$1" atteso="$2"
  local ASK
  ASK=$(bash -c "HERE='$HERE/night-shift'; ADVERSARY='$valore'; $SNIPPET; echo \"\$ASK\"")
  [[ "$ASK" == *"$atteso" ]] && ok "ADVERSARY=$valore → $atteso" \
    || ko "ADVERSARY=$valore → atteso *$atteso, ottenuto $ASK"
}

check_adversary "qwen" "ask-qwen.sh"
check_adversary ""     "ask-qwen.sh"   # default
check_adversary "opus" "ask-opus.sh"
check_adversary "glm"  "ask-glm.sh"    # bug corretto: prima non esisteva questo branch

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
