#!/bin/bash
# test-pattern-reminder-hook.sh — feedback utente esterno (2026-08-24): la consultazione di
# patterns/ prima di certe modifiche dipendeva dalla memoria dell'agente, non da un
# meccanismo del sistema. Verifica il hook PreToolUse (Edit|Write, tools/pattern-reminder-
# hook.sh) simulando lo stdin JSON che Claude Code gli passerebbe davvero: deve segnalare i
# path sensibili citando patterns/README.md, ignorare i path non sensibili, e non bloccare
# mai l'operazione (permissionDecision sempre "allow").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/pattern-reminder-hook.sh"
SETTINGS="$HERE/.claude/settings.json"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$HOOK" ] && ok "il hook è eseguibile" || ko "tools/pattern-reminder-hook.sh non è eseguibile"

command -v jq >/dev/null 2>&1 && ok "jq disponibile (richiesto dal hook)" || ko "jq non disponibile: il hook non può funzionare"

OUT_SENSIBILE=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"credenziali BC.rtf"}}' | bash "$HOOK")
echo "$OUT_SENSIBILE" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && ok "path sensibile: produce additionalContext" \
  || ko "path sensibile: nessun additionalContext prodotto"
echo "$OUT_SENSIBILE" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null 2>&1 \
  && ok "path sensibile: permissionDecision è 'allow' (non blocca mai)" \
  || ko "path sensibile: permissionDecision non è 'allow'"
echo "$OUT_SENSIBILE" | grep -qi 'segreto-come-impronta' \
  && ok "cita il pattern segreto-come-impronta nel reminder" \
  || ko "non cita il pattern segreto-come-impronta"

OUT_NON_SENSIBILE=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | bash "$HOOK")
[ -z "$OUT_NON_SENSIBILE" ] && ok "path non sensibile: nessun output (no-op silenzioso)" \
  || ko "path non sensibile: ha prodotto output inatteso"

OUT_TOKEN=$(echo '{"tool_name":"Write","tool_input":{"file_path":"tools/oauth_token_refresh.py"}}' | bash "$HOOK")
echo "$OUT_TOKEN" | jq -e '.hookSpecificOutput' >/dev/null 2>&1 \
  && ok "riconosce anche la categoria 'token' in inglese" \
  || ko "non riconosce 'token' come categoria sensibile"

[ -f "$SETTINGS" ] && ok ".claude/settings.json esiste" || ko ".claude/settings.json assente"
jq -e '.hooks.PreToolUse[] | select(.matcher == "Edit|Write|Bash")' "$SETTINGS" >/dev/null 2>&1 \
  && ok "settings.json registra il hook su Edit|Write|Bash" \
  || ko "settings.json non registra il hook correttamente"

# --- 6° ciclo, set 3: il ramo Bash (il varco documentato nel SAL del 5° ciclo) ---
OUT_B_SENS=$(echo '{"tool_name":"Bash","tool_input":{"command":"printenv | grep -i token"}}' | bash "$HOOK")
echo "$OUT_B_SENS" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && ok "Bash sensibile (printenv): produce additionalContext" \
  || ko "Bash sensibile: nessun additionalContext"
echo "$OUT_B_SENS" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null 2>&1 \
  && ok "Bash sensibile: permissionDecision resta 'allow' (reminder, non cancello)" \
  || ko "Bash sensibile: permissionDecision non è 'allow'"
OUT_B_ENV=$(echo '{"tool_name":"Bash","tool_input":{"command":"cat .env.production"}}' | bash "$HOOK")
echo "$OUT_B_ENV" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && ok "Bash che legge .env: reminder prodotto" || ko "Bash .env: nessun reminder"
OUT_B_CHIAVE=$(echo '{"tool_name":"Bash","tool_input":{"command":"curl -H \"Authorization: Bearer xyz\" https://x"}}' | bash "$HOOK")
echo "$OUT_B_CHIAVE" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && ok "Bash con Bearer token nel comando: reminder prodotto" || ko "Bash Bearer: nessun reminder"
OUT_B_OK=$(echo '{"tool_name":"Bash","tool_input":{"command":"git status && ls -la"}}' | bash "$HOOK")
[ -z "$OUT_B_OK" ] && ok "Bash ordinario: nessun output (no-op silenzioso)" \
  || ko "Bash ordinario: output inatteso"
OUT_B_DEPLOY=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp deploy"}}' | bash "$HOOK")
[ -z "$OUT_B_DEPLOY" ] \
  && ok "clasp deploy: NON è più materia per reminder sensibile (falso positivo evitato: deploy non tocca segreti da solo)" \
  || ko "clasp deploy produce un reminder non richiesto: $(echo "$OUT_B_DEPLOY" | head -2)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
