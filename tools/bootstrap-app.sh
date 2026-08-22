#!/bin/bash
# bootstrap-app.sh — crea una repo nuova DENTRO il sistema: regole ereditate,
# PROJECT.md stub, label night-shift, .night-verify dichiarato.
# Uso: bootstrap-app.sh <nome-repo> [--private]
set -euo pipefail

NAME="${1:?uso: bootstrap-app.sh <nome-repo> [--private] [--dry-run]}"
DRY_RUN=0
for a in "$@"; do [ "$a" = "--dry-run" ] && DRY_RUN=1; done
if [ $DRY_RUN -eq 1 ]; then echo "== DRY RUN: tutto what-if, nessuna scrittura =="; fi
VIS="--public"
[ "${2:-}" = "--private" ] && VIS="--private"

HERE="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/night-shift-work/$NAME"

[ -d "$DEST" ] && { echo "esiste già: $DEST"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh non autenticato"; exit 1; }

mkdir -p "$DEST" && cd "$DEST"
git init -q -b main

# Le regole universali si EREDITANO dal hub: un solo luogo dove vivono.
cp "$HERE/CLAUDE.md" CLAUDE.md
cat > PROJECT.md <<EOF
# PROJECT.md — contesto specifico di $NAME

Sezione per progetto: comandi, validation artifact (regola "Done means proven"),
convenzioni locali. Le regole universali stanno in CLAUDE.md (ereditate dal hub
AI_Programmer: aggiornale LÌ, non qui).
EOF

# Le verifiche dichiarate per il gate del mattino: una riga per comando.
cat > .night-verify <<EOF
# Verifiche dichiarate del turno di notte (una riga per comando, eseguite dal morning-gate).
# Esempi: node tools/test.js · pnpm test · python3 -m pytest
# VUOTO = il gate lo dice ("il silenzio non è un verdetto"): dichiarale appena puoi.
EOF

# Vocabolario di dominio (aggiunta 2026-08-21): si riempie coi fatti confermati dal business,
# non si scrive vuoto per sempre — ma il posto per scriverlo c'è dal primo commit.
mkdir -p docs
cp "$HERE/docs/GRAMMATICA_DOMINIO_TEMPLATE.md" docs/GRAMMATICA_DOMINIO.md

echo "# $NAME" > README.md
# SECRET-SCAN (review §4.3): gitleaks PRIMA del primo push — la disciplina da sola non basta
command -v gitleaks >/dev/null 2>&1 && { gitleaks detect --source . --no-banner >/dev/null 2>&1 || { echo "⛔ gitleaks ha trovato segreti — risolvere PRIMA del push"; exit 1; }; } || echo "⚠ gitleaks assente (brew install gitleaks): secret-scan saltato"
if [ $DRY_RUN -eq 1 ]; then
  echo "(dry: creerebbe la repo)"
else
  # bug reale (dogfooding, nuovo ciclo 10 giri): la vecchia catena
  # "[ dry ] || git add -A && [ dry ] || git commit" non si fermava se git add
  # falliva — set -e non intercetta un fallimento intermedio dentro una catena
  # &&/||, e git commit veniva eseguito comunque (verificato con simulazione).
  git add -A
  git commit -q -m "feat: repo generata dal sistema AI_Programmer (bootstrap-app)"
  gh repo create "$NAME" $VIS --source . --push -q
fi
gh label create night-shift --description "Lavorata dal turno di notte (modello locale)" --color 5D3FD3 -R "$NAME" >/dev/null 2>&1 || true

# La iscrive alla coda locale (se esiste repos.conf)
CONF="$HERE/night-shift/repos.conf"
if [ -f "$CONF" ] && ! grep -q "^$(gh api user --jq .login)/$NAME\$" "$CONF"; then
  echo "$(gh api user --jq .login)/$NAME feat" >> "$CONF"
  echo "aggiunta a $CONF"
fi

echo ""
echo "Fatto: $NAME è nel sistema."
echo "  prossimo passi: riempi PROJECT.md e .night-verify, poi la prima issue night-shift."
