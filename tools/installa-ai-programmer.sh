#!/bin/bash
# installa-ai-programmer.sh — UN comando per installare il cervello AI_Programmer in un repo.
#
# (2026-10-04, Luca: «voglio migliorare il metodo di installazione»).
# Con il cervello centrale, l'installazione è MINIMA: niente fotocopie di skills,
# pattern, CLAUDE.md. Solo il puntatore, gli hook, il grafo, e la registrazione.
#
# USO (da Claude Code o da terminale):
#   bash ~/.night-shift-work/AI_Programmer/tools/installa-ai-programmer.sh <dir-repo>
#
# oppure su un repo GitHub:
#   bash ~/.night-shift-work/AI_Programmer/tools/installa-ai-programmer.sh --clone owner/repo
#
# FA (in ordine):
#   1. CLAUDE.md sottile (puntatore al cervello — 19 righe, non 177)
#   2. Hook (5 file in tools/ + registrazione in .claude/settings.json)
#   3. Grafo (graphify update — la prima volta, poi il pre-commit lo aggiorna)
#   4. .night-verify (se non c'e', un minimo: bash -n sui .sh)
#   5. repos.conf (il turno lo processa dal prossimo ciclo)
#   6. Issue abilitate su GitHub
#
# NON FA (perche' non serve col cervello centrale):
#   - Copiare skills (lette dall'hub)
#   - Copiare pattern (letti dall'hub)
#   - Copiare agenti (letti dall'hub)
#   - Copiare CLAUDE.md completo (il puntatore basta)
#
# Esce: 0 installato · 1 errore · 2 gia' installato
set -uo pipefail
HUB="${INSTALLA_HUB:-$(cd "$(dirname "$0")/.." && pwd)}"

# ── argomenti ──────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--clone" ] && [ -n "${2:-}" ]; then
  REPO="$2"
  DIR="$HOME/night-shift-work/${REPO##*/}"
  if [ ! -d "$DIR" ]; then
    echo "── clono $REPO in $DIR..."
    gh repo clone "$REPO" "$DIR" -q || { echo "⛔ clone fallito"; exit 1; }
  fi
  shift 2
else
  DIR="${1:?uso: installa-ai-programmer.sh <dir-repo> (o --clone owner/repo)}"
fi

[ -d "$DIR/.git" ] || { echo "⛔ $DIR non e' un repo git"; exit 1; }
cd "$DIR" || exit 1
REPO="$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')"
[ -n "$REPO" ] || REPO="locale/$(basename "$DIR")"   # fallback: nome directory
NOME="${REPO##*/}"
echo "═══ installazione AI_Programmer (cervello centrale) su $REPO ═══"

# ── 0. gia' installato? ───────────────────────────────────────────────────────
if grep -q 'metodo AI_Programmer' CLAUDE.md 2>/dev/null && \
   grep -q 'night-shift-work/AI_Programmer/CLAUDE.md' CLAUDE.md 2>/dev/null; then
  echo "── gia' installato (CLAUDE.md e' un puntatore al cervello)"
  echo "   per aggiornare: bash $0 $DIR --aggiorna"
  exit 2
fi

# ── 1. CLAUDE.md sottile ──────────────────────────────────────────────────────
echo "── 1/6 CLAUDE.md (puntatore al cervello)..."
if [ -f "$HUB/tools/claude-md-cervello.sh" ]; then
  bash "$HUB/tools/claude-md-cervello.sh" "$PWD" "$HUB" >/dev/null 2>&1
else
  # fallback: scrivilo inline
  cat > CLAUDE.md << 'CLAUDE'
# Questo repo lavora col metodo AI_Programmer

## REGOLE COMPLETE (leggile PRIMA di fare qualsiasi cosa)

Le regole vincolanti NON sono in questo file: vivono nel cervello centrale.

**PRIMA di iniziare qualsiasi lavoro, leggi:**
→ `~/.night-shift-work/AI_Programmer/CLAUDE.md` (le regole complete)

**Durante il lavoro, consulta:**
→ Skills: `~/.night-shift-work/AI_Programmer/.claude/skills/`
→ Patterns (lezioni apprese): `~/.night-shift-work/AI_Programmer/patterns/`
→ Registro errori: `~/.night-shift-work/AI_Programmer/docs/errori/REGISTRO.md`

**Perché così:** le regole cambiano ogni giorno. Una fotocopia invecchia. Il cervello è sempre corrente.

## Regole LOCALI di questo repo

Ogni repo può avere regole aggiuntive in `PROJECT.md` e `.night-verify`.
CLAUDE
fi
echo "   ✓ $(wc -l < CLAUDE.md | tr -d ' ') righe (puntatore)"

# ── 2. Hook (5 file + registrazione) ─────────────────────────────────────────
echo "── 2/6 hook..."
mkdir -p tools
HOOK_COPIATI=0
for H in pattern-reminder-hook.sh clasp-block-hook.sh metodo-reminder-hook.sh skill-reminder-hook.sh graphify-spina.sh gas-gate.sh; do
  if [ -f "$HUB/tools/$H" ]; then
    cp "$HUB/tools/$H" "tools/$H" && chmod +x "tools/$H" && HOOK_COPIATI=$((HOOK_COPIATI+1))
  fi
done
# registrazione in settings.json: CREALO se non c'e' (repo nuovo), aggiornalo se c'e'
mkdir -p .claude
if [ ! -f .claude/settings.json ]; then
  # repo nuovo: settings completo con tutti e 5 gli hook
  cat > .claude/settings.json << 'SETTINGS'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/tools/pattern-reminder-hook.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/tools/skill-reminder-hook.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/tools/clasp-block-hook.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/tools/metodo-reminder-hook.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/tools/metodo-reminder-hook.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/tools/graphify-spina.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
SETTINGS
  echo "   ✓ settings.json creato (5 hook registrati)"
elif [ -f "$HUB/tools/copia-hook.sh" ]; then
  # repo esistente: usa copia-hook dell'hub
  bash "$HUB/tools/copia-hook.sh" "$PWD" >/dev/null 2>&1 && echo "   ✓ hook registrati" || echo "   ⚠ copia-hook non riuscito"
fi
echo "   ✓ $HOOK_COPIATI hook copiati in tools/"

# ── 3. Grafo ──────────────────────────────────────────────────────────────────
echo "── 3/6 grafo strutturale..."
if command -v graphify >/dev/null 2>&1; then
  if [ ! -d graphify-out ]; then
    PYTHONHASHSEED=0 graphify update . >/dev/null 2>&1
    [ -d graphify-out ] && echo "   ✓ creato ($(jq '.nodes | length' graphify-out/graph.json 2>/dev/null || echo '?') nodi)" || echo "   ⚠ graphify non ha creato il grafo"
  else
    echo "   ✓ gia' esistente"
  fi
else
  echo "   ⚠ graphify non installato — il grafo si creera' al primo pre-commit"
fi

# ── 4. .night-verify minimo ──────────────────────────────────────────────────
echo "── 4/6 .night-verify..."
if [ ! -f .night-verify ]; then
  echo "bash tools/gas-gate.sh" > .night-verify
  echo "   ✓ minimo scritto (gas-gate: sintassi GAS)"
else
  echo "   ✓ gia' presente (lo definisce il progetto)"
fi

# ── 5. repos.conf ────────────────────────────────────────────────────────────
echo "── 5/6 registrazione nel turno..."
CONF="$HUB/night-shift/repos.conf"
if ! grep -q "$REPO" "$CONF" 2>/dev/null; then
  echo "" >> "$CONF"
  echo "# (installato da installa-ai-programmer.sh, $(date '+%Y-%m-%d'))" >> "$CONF"
  echo "$REPO feat" >> "$CONF"
  echo "   ✓ aggiunto a repos.conf (tipo feat)"
else
  echo "   ✓ gia' registrato"
fi

# ── 6. Issue abilitate ───────────────────────────────────────────────────────
echo "── 6/6 issue su GitHub..."
gh repo edit "$REPO" --enable-issues >/dev/null 2>&1 && echo "   ✓ abilitate" || echo "   ⚠ non riuscito (o gia' abilitate)"

# ── commit ────────────────────────────────────────────────────────────────────
git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -qm "chore: installazione AI_Programmer (cervello centrale)

CLAUDE.md sottile (puntatore all'hub), $HOOK_COPIATI hook in tools/,
grafo strutturale, .night-verify minimo. Le skills, i pattern e gli
agenti si leggono dall'hub: sempre correnti, niente drift." >/dev/null 2>&1
  echo ""
  echo "── committato (su main: primo giro)"
  echo "   dal prossimo ciclo il turno lo processera'"
fi

echo ""
echo "═══ INSTALLATO ═══"
echo "  CLAUDE.md: puntatore al cervello (19 righe)"
echo "  Hook: $HOOK_COPIATI in tools/"
echo "  Grafo: $([ -d graphify-out ] && echo 'SI' || echo 'no')"
echo "  Turno: registrato ($REPO)"
echo "  Le regole vivono in: $HUB"
