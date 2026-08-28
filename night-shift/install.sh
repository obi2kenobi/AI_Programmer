#!/bin/bash
# install.sh — porta il sistema sul Mac: symlink, LaunchAgent, prerequisiti.
# Idempotente: rieseguire non rompe nulla, aggiorna i puntamenti.
# Il repo dove gira questo script diventa la fonte di verità (HUB).
set -uo pipefail

HUB="$(cd "$(dirname "$0")/.." && pwd)"
USER_NAME="$(id -un)"
# mutation-testing 2026-08-28: prima risolveva con `eval echo ~user`, IGNORANDO
# $HOME — nei test scriveva nella home VERA dell'utente e negli ambienti con HOME
# non standard installava nel posto sbagliato. $HOME è la fonte di verità.
HOME_DIR="${HOME:-$(eval echo ~$USER_NAME)}"
BIN="$HOME_DIR/.local/bin"
AGENTS="$HOME_DIR/Library/LaunchAgents"
MISSING=0

echo "== Installazione sistema AI_Programmer =="
echo "HUB: $HUB"

step() { echo "→ $*"; }

# --- Prerequisiti (li segnala, non li installa: scelta tua) --------------------
command -v ollama >/dev/null 2>&1 || { echo "⚠ MANCA ollama (brew install --cask ollama-app)"; MISSING=1; }
ollama list 2>/dev/null | grep -q "qwen3.8:27b-mtp-q4_K_M" || echo "⚠ modello qwen3.8:27b-mtp-q4_K_M assente (ollama pull qwen3.8:27b-mtp-q4_K_M — 17 GB)"
command -v gh >/dev/null 2>&1 || { echo "⚠ MANCA gh (brew install gh) + gh auth login"; MISSING=1; }
command -v opencode >/dev/null 2>&1 || { echo "⚠ MANCA opencode (brew install opencode)"; MISSING=1; }
command -v jq >/dev/null 2>&1 || { echo "⚠ MANCA jq"; MISSING=1; }
[ "$MISSING" -eq 1 ] && echo "(sistema comunque installato: completa i prerequisiti per il turno)"

# --- Symlink dei comandi -------------------------------------------------------
step "symlink in $BIN"
mkdir -p "$BIN"
for cmd in llm/ask-qwen.sh llm/ask-opus.sh llm/ask-glm.sh night-shift/night-shift.sh night-shift/morning-gate.sh; do
  name=$(basename "$cmd" .sh)
  ln -sf "$HUB/$cmd" "$BIN/$name"
done
echo "  comandi: ask-qwen ask-opus ask-glm night-shift morning-gate"

# --- Config locale della coda --------------------------------------------------
step "repos.conf (coda locale, gitignored)"
if [ ! -f "$HUB/night-shift/repos.conf" ]; then
  cp "$HUB/night-shift/repos.conf.example" "$HUB/night-shift/repos.conf"
  echo "  creato da example — RIEMPILO con le tue repo (owner/repo tipo_commit)"
else
  echo "  già presente, intoccato"
fi

# --- LaunchAgent ----------------------------------------------------------------
step "LaunchAgent: Ollama always-on + turno 23:00"
mkdir -p "$AGENTS"
for tpl in ollama nightshift; do
  SRC="$HUB/night-shift/plist/com.luca.$tpl.plist"
  DST="$AGENTS/com.$USER_NAME.$tpl.plist"
  sed -e "s|__USER__|$USER_NAME|g" -e "s|__HOME__|$HOME_DIR|g" -e "s|__HUB__|$HUB|g" "$SRC" > "$DST"
  launchctl bootout "gui/$(id -u)/com.$USER_NAME.$tpl" 2>/dev/null
  launchctl bootstrap "gui/$(id -u)" "$DST" 2>/dev/null || echo "  ⚠ $DST non caricato (già attivo con altro nome?)"
done
echo "  attivi: com.$USER_NAME.ollama com.$USER_NAME.nightshift"

echo ""
echo "== Fatto. Verifiche: =="
echo "  ask-qwen \"ping\"                     → cervello locale"
echo "  curl -s localhost:11434/api/health   → server always-on"
echo "  launchctl list | grep $USER_NAME     → i due agent"
echo "  notte: il turno parte da solo alle 23:00 (o: night-shift owner/repo)"
echo "  mattina: morning-gate                → il giudizio con banco avversariale"
