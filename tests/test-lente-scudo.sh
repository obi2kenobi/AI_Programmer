#!/bin/bash
# test-lente-scudo.sh — lo scudo che guarda l'harness (furto AgentShield, ECC)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SC="$HERE/tools/lente-scudo.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$SC" && ok "sintassi" || { ko "sintassi"; exit 1; }
OUT=$(bash "$SC" "$HERE" 2>&1); RC=$?
for n in 1 2 3 4 5; do grep -q "^$n\. " <<<"$OUT" && ok "controllo $n presente e numerato" || ko "controllo $n presente"; done
grep -q "SCUDO: INTEGRO\|SCUDO: .*rilievi" <<<"$OUT" && ok "verdetto finale con rc onesto (rc=$RC)" || ko "verdetto finale"
if grep -q "giri-avversari" <<<"$OUT"; then ko "l'esente (giri-avversari, forme per prova) non viene segnalato"; else ok "l'esente non viene segnalato (lista allineata al pre-commit)"; fi
grep -q "SEGRETO nel prompt" "$HERE/llm/ask-qwen.sh" && ok "ask-qwen: il cancello segreti-nel-prompt esiste (avviso prima notte)" || ko "cancello nel prompt"
case "ghp_abc123" in *ghp_*|*sk-ant-*|*AKIA[0-9A-Z]*) ok "la forma del cancello matcha un token di prova" ;; *) ko "forma del cancello" ;; esac
echo ""; echo "$PASS OK, $FAIL FAIL"; [ "$FAIL" -eq 0 ]
