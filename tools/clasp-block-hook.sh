#!/bin/bash
# clasp-block-hook.sh — il DENTE della regola «clasp push MAI» (giri avversari
# 2026-08-28, attacco B8/F1: la regola viveva solo nei promemoria — nessun
# blocco tecnico, un agente confuso poteva deployare in produzione).
# PreToolUse su Bash: `clasp push` e `clasp deploy` vengono NEGATI davvero
# (permissionDecision: deny). I comandi che toccano credenziali ricevono un
# CONTESTO di avviso (advisory: leggere le proprie credenziali a volte è
# legittimo — dipende da cosa se ne fa). Tutto il resto: silenzio.
#
# Il deploy è dell'umano: questa è l'unica regola del sistema che da oggi
# non dipende dalla memoria dell'agente.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0
TOOL="$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
[ "$TOOL" = "Bash" ] || exit 0

# NEGATO davvero: scrittura in produzione senza staging e senza rollback
# (dal campo REPO-E 2026-09-01: il grep libero negava git commit il cui MESSAGGIO
# citava "clasp push" — falso positivo 2 volte in una sessione. Ora si matcha solo
# se il comando È un'invocazione clasp: a inizio stringa o dopo un separatore shell)
if echo "$CMD" | grep -qE '(^|[;&|][[:space:]]*)clasp[[:space:]]+(push|deploy)'; then
  jq -n --arg r "NEGATO (clasp-block-hook): clasp push/deploy scrive in PRODUZIONE senza staging né rollback. La regola è del metodo AI_Programmer: il deploy è dell'umano, che prima confronta col vivo (clasp clone + diff). Se il push è davvero giusto, lo fa Luca a mano." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

# (dal campo REPO-Q 2026-09-02: l'agente ha GENERATO un loop di clasp push
# che includeva directory dichiarate clone-di-sola-lettura nel CLAUDE.md del
# repo — Luca l'ha eseguito e ha sovrascritto 2 progetti sviluppati altrove.
# La guardia ora verifica anche il caso GENERAZIONE)
if echo "$CMD" | grep -qE '(^|[;&|][[:space:]]*)clasp[[:space:]]+(push|deploy)'; then
  MB="$PWD/.mirror-boundaries"
  if [ -f "$MB" ]; then
    jq -n --arg c "ATTENZIONE: questa directory ha .mirror-boundaries (cloni di sola lettura). Un clasp push qui sovrascriverebbe progetti sviluppati altrove. Verifica PRIMA di eseguire." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
    exit 0
  fi
fi

# ADVISORY: comandi che leggono/passano credenziali — possibili e a volte
# legittimi, ma chi li lancia deve sapere cosa sta toccando
if echo "$CMD" | grep -qE 'clasp\.json|credenziali|\.env|printenv|secret|token[_ =]|refresh_token'; then
  jq -n --arg c "Questo comando tocca credenziali: mai nel diff, mai nei log, mai in chat (pattern segreto-come-impronta). Se stai solo LEGGENDO per verificare un'impronta, ok — ma l'output resta locale." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
  exit 0
fi

exit 0
