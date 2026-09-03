#!/bin/bash
# garante-standard.sh — rende l'installazione di AI_Programmer OBBLIGATORIA:
# gira a OGNI sessione su QUALSIASI repo (via ~/.claude/settings.json, livello utente)
# e se il repo non ha lo standard, LO INSTALLA senza chiedere. Il metodo diventa
# un fatto, non una scelta: non dipende da chi se lo ricorda.
#
# Come funziona:
#   1. individua l'hub AI_Programmer più vicino (env AI_PROGRAMMER_HUB o percorso fisso)
#   2. verifica se il repo corrente ha .claude/settings.json con i nostri hook
#   3. se NON li ha: copia CLAUDE.md, .claude/settings.json, .claude/skills, .claude/agents,
#      .opencode, patterns, tools hook — come sync-repo.sh --standard ma in un comando
#      silenzioso che gira da hook, senza che nessuno debba ricordarsi di invocarlo
#   4. se LI HA già: silenzio (nessun costo, nessun output)
#
# Installazione (una volta, a livello UTENTE):
#   bash tools/install-garante.sh
set -uo pipefail
HUB="${AI_PROGRAMMER_HUB:-$HOME/.zcode/workspace/default/AI_Programmer}"
CWD="${CLAUDE_PROJECT_DIR:-$PWD}"

# l'hub deve esistere: se no, silenzio (non possiamo installare da dove non c'è)
[ -d "$HUB/.claude/skills" ] || exit 0

# il repo corrente È l'hub? non installare su se stesso
[ "$(cd "$CWD" 2>/dev/null && pwd)" = "$(cd "$HUB" 2>/dev/null && pwd)" ] && exit 0

# già installato? (settings.json con il nostro SessionStart hook)
if [ -f "$CWD/.claude/settings.json" ]; then
  jq -e '.hooks.SessionStart // empty | length > 0' "$CWD/.claude/settings.json" >/dev/null 2>&1 && exit 0
fi

# NON installato → INSTALLA
echo "STANDARD AI_PROGRAMMER INSTALLATO automaticamente su $CWD" >&2

mkdir -p "$CWD/.claude" "$CWD/.opencode" "$CWD/patterns"

# CLAUDE.md (se non esiste già un CLAUDE.md proprio)
[ -f "$CWD/CLAUDE.md" ] || cp "$HUB/CLAUDE.md" "$CWD/CLAUDE.md"

# settings.json (gli hook:SessionStart/UserPromptSubmit/PreToolUse)
cp "$HUB/.claude/settings.json" "$CWD/.claude/settings.json"

# skill e agenti
cp -R "$HUB/.claude/skills" "$CWD/.claude/skills"
cp -R "$HUB/.claude/agents" "$CWD/.claude/agents"

# mirror opencode
cp -R "$HUB/.opencode/agent" "$CWD/.opencode/agent" 2>/dev/null || true
cp -R "$HUB/.opencode/skills" "$CWD/.opencode/skills" 2>/dev/null || true

# patterns
cp -R "$HUB/patterns" "$CWD/patterns" 2>/dev/null || true

# hook scripts (deriva da settings.json)
for H in $(jq -r '.hooks.PreToolUse[]?.hooks[]?.command' "$HUB/.claude/settings.json" 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u); do
  mkdir -p "$CWD/tools"
  cp "$HUB/tools/$H" "$CWD/tools/$H" 2>/dev/null || true
done

# .night-verify minimo se assente
if [ ! -f "$CWD/.night-verify" ]; then
  echo "# Verifiche del turno di notte (VUOTO = il gate lo dice)" > "$CWD/.night-verify"
fi

echo "Installato: CLAUDE.md, skill, agenti, hook, patterns. Il metodo è ora STRUTTURALE in questo repo." >&2
