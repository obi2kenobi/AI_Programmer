#!/bin/bash
# pattern-reminder-hook.sh — hook PreToolUse (Edit|Write|Bash), 2026-08-24.
# Feedback di un utente esterno: la consultazione di patterns/ prima di certe modifiche
# dipendeva dalla memoria dell'agente in quel turno, non da un meccanismo del sistema.
# Quando il file_path toccato matcha una categoria sensibile (auth/secret/credential/
# token/login/password, incluse le varianti italiane), stampa un reminder con le righe
# pertinenti del registro patterns/README.md — non blocca mai l'operazione (allow sempre).
# 6° ciclo, set 3 (2026-08-24): esteso a Bash — il varco documentato nella voce SAL del
# 5° ciclo: l'hook copriva Edit|Write ma "non copre il modo in cui si è lavorato oggi
# (clasp deploy, probe su BC)". Un COMANDO che stampa/legge segreti (printenv, cat di
# .env/chiavi, curl con token in chiaro) ora riceve lo stesso reminder. Resta un
# reminder, non un cancello; l'estensione a UserPromptSubmit (confronto compito↔skill)
# resta decisione di Luca, come dichiarato nel SAL.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRO="$HERE/patterns/README.md"

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"

# ramo Bash: comandi che toccano/printano materiale sensibile
if [ -n "$COMMAND" ] && [ -z "$FILE_PATH" ]; then
  echo "$COMMAND" | grep -qiE '\.env|id_rsa|id_ed25519|\.pem|\.key|printenv|/usr/bin/security|keychain|repos\.key|Authorization:|Bearer |api[_-]?key|ZHIPUAI_API_KEY|GH_TOKEN' || exit 0
  HITS_B=""
  [ -f "$REGISTRO" ] && HITS_B="$(grep -E '^\| \[' "$REGISTRO" | grep -iE 'segreto|credenzial|token' | head -5)"
  if [ -n "$HITS_B" ]; then
    CTX_B="Il comando tocca materiale sensibile — pattern pertinenti in patterns/README.md prima di procedere:
$HITS_B"
  else
    CTX_B="Il comando tocca materiale sensibile — vale comunque CLAUDE.md \"Never expose secrets\" / \"Mask, don't omit\" / \"One-shot secret handoff\"."
  fi
  jq -n --arg ctx "$CTX_B" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",additionalContext:$ctx}}'
  exit 0
fi

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
