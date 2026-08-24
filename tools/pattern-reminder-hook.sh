#!/bin/bash
# pattern-reminder-hook.sh — hook PreToolUse (Edit|Write), 2026-08-24.
# Feedback di un utente esterno: la consultazione di patterns/ prima di certe modifiche
# dipendeva dalla memoria dell'agente in quel turno, non da un meccanismo del sistema.
# Quando il file_path toccato matcha una categoria sensibile (auth/secret/credential/
# token/login/password, incluse le varianti italiane), stampa un reminder con le righe
# pertinenti del registro patterns/README.md — non blocca mai l'operazione (allow sempre).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRO="$HERE/patterns/README.md"

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -z "$FILE_PATH" ] && exit 0

echo "$FILE_PATH" | grep -qiE 'auth|secret|credential|credenzial|token|login|password|segret' || exit 0

HITS=""
if [ -f "$REGISTRO" ]; then
  HITS="$(grep -E '^\| \[' "$REGISTRO" | grep -iE 'segreto|credenzial|token' | head -5)"
fi

if [ -n "$HITS" ]; then
  CTX="File sensibile ($FILE_PATH) — pattern pertinenti in patterns/README.md prima di procedere:
$HITS"
else
  CTX="File sensibile ($FILE_PATH) — nessun pattern specifico trovato nel registro patterns/README.md, ma vale comunque CLAUDE.md \"Never expose secrets\" / \"Mask, don't omit\" / \"One-shot secret handoff\"."
fi

jq -n --arg ctx "$CTX" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",additionalContext:$ctx}}'
