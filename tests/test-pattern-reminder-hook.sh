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
jq -e '.hooks.PreToolUse[] | select(.matcher == "Edit|Write")' "$SETTINGS" >/dev/null 2>&1 \
  && ok "settings.json registra il hook su Edit|Write" \
  || ko "settings.json non registra il hook correttamente"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
