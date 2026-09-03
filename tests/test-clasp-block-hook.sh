#!/bin/bash
# test-clasp-block-hook.sh — il dento della regola «clasp push MAI» (giri
# avversari 2026-08-28, attacco B8/F1): fino a oggi la regola era advisory.
# Verifica che l'hook NEGI davvero clasp push/deploy (permissionDecision deny),
# lasci passare clasp pull/version (lettura), avverta sui comandi con
# credenziali (additionalContext) e taccia su comandi innocui.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/clasp-block-hook.sh"
SETTINGS="$HERE/.claude/settings.json"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$HOOK" ] && ok "l'hook è eseguibile" || ko "tools/clasp-block-hook.sh non è eseguibile"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cd repo && clasp push"}}' | bash "$HOOK")
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && ok "clasp push → permissionDecision deny" || ko "clasp push NON negato"
echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -qi "produzione\|NEGATO" \
  && ok "il deny dice perché" || ko "il deny non spiega"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp deploy -P xxx"}}' | bash "$HOOK")
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && ok "clasp deploy → deny" || ko "clasp deploy NON negato"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp pull"}}' | bash "$HOOK")
[ -z "$OUT" ] && ok "clasp pull (lettura): silenzio, non blocca" || ko "clasp pull disturbato inutilmente"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cat ~/.clasp.json | head -1"}}' | bash "$HOOK")
echo "$OUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && ok "comando con credenziali → contesto di avviso" || ko "comando con credenziali ignorato"
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && ko "leggere credenziali NEGATO (troppo: deve solo avvisare)" \
  || ok "leggere credenziali non è negato (advisory giusto)"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | bash "$HOOK")
[ -z "$OUT" ] && ok "comando innocuo: silenzio" || ko "comando innocuo produce rumore"

OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"x.md","command":"clasp push"}}' | bash "$HOOK")
[ -z "$OUT" ] && ok "tool non-Bash ignorato" || ko "si intromette su tool sbagliati"

# --- CORREZIONE (dal campo, REPO-V, progetto GAS nuovo, 2026-09-03) -----------
# Buco reale trovato installando lo standard su una repo nuova: l'ancora
# `(^|[;&|][[:space:]]*)clasp` accetta clasp solo a inizio comando o dopo un
# separatore shell. `npx ` è uno spazio, non un separatore — e su una macchina
# senza clasp installato globalmente `npx clasp push` è LA forma normale di
# invocarlo. Il cancello passava tutte le attese qui sopra ed era comunque
# scavalcabile: nessuna di esse copriva un runner davanti al comando.
for FORMA in \
  "npx clasp push" \
  "npx clasp deploy" \
  "npx @google/clasp push" \
  "npx --yes clasp push" \
  "bunx clasp push" \
  "pnpm dlx clasp push" \
  "yarn dlx clasp deploy" \
  "./node_modules/.bin/clasp push" \
  "cd progetto && npx clasp push"; do
  OUT=$(jq -n --arg c "$FORMA" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK")
  echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
    && ok ""$FORMA" -> deny" || ko ""$FORMA" NON negato: il cancello si scavalca"
done

# --- PARITÀ della correzione ------------------------------------------------
# La difesa contro il falso positivo già pagata (campo REPO-E 2026-09-01: un
# `git commit` il cui MESSAGGIO citava la forma vietata veniva negato, due volte
# in una sessione) deve restare in piedi DOPO l'allargamento della regex: è
# esattamente l'attesa che un allargamento sciatto romperebbe per prima.
for INNOCUO in \
  'git commit -m "vieta clasp push"' \
  'git log --grep="clasp deploy"' \
  'echo "il deploy è di Luca: clasp push mai"' \
  "npx clasp pull" \
  "npx clasp versions" \
  "grep -rn clasp tools/"; do
  OUT=$(jq -n --arg c "$INNOCUO" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK")
  echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
    && ko "«$INNOCUO» negato — falso positivo, non scrive in produzione" \
    || ok "«$INNOCUO» non negato (giusto)"
done

# --- LIMITE DICHIARATO (scarto mai silenzioso) ------------------------------
# Forme NON coperte, per scelta e non per dimenticanza: prefissi di ambiente
# (`env FOO=1 clasp push`), `sudo`, alias di shell, e un percorso assoluto
# arbitrario verso il binario. Coprirle richiederebbe di riconoscere un comando
# arbitrario invece di un runner noto, e ogni allargamento in più riapre il
# falso positivo appena difeso qui sopra. Il cancello è una difesa contro
# l'errore, non contro un aggressore: chi vuole aggirarlo ci riesce comunque,
# e la regola resta scritta in CLAUDE.md per quel caso.

jq -e '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.command | contains("clasp-block"))' "$SETTINGS" >/dev/null 2>&1 \
  && ok "settings.json registra l'hook su Bash" || ko "settings.json non registra clasp-block-hook"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
