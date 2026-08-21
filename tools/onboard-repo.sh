#!/bin/bash
# onboard-repo.sh — porta una repo ESISTENTE dentro il sistema:
# label night-shift, .night-verify, iscrizione alla coda locale.
# Uso: onboard-repo.sh owner/repo [tipo_commit]
set -euo pipefail

REPO="${1:?uso: onboard-repo.sh owner/repo [tipo_commit]}"
TYPE="${2:-chore}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

gh auth status >/dev/null 2>&1 || { echo "gh non autenticato"; exit 1; }
gh repo view "$REPO" >/dev/null 2>&1 || { echo "repo non trovata: $REPO"; exit 1; }

gh label create night-shift --description "Lavorata dal turno di notte (modello locale)" --color 5D3FD3 -R "$REPO" >/dev/null 2>&1 \
  && echo "label night-shift creata" || echo "label già presente"

# .night-verify: lo crea solo se assente (mai sovrascrivere ciò che la repo dichiara)
WORK="$HOME/night-shift-work/${REPO##*/}"
[ -d "$WORK/.git" ] || gh repo clone "$REPO" "$WORK" -- --depth=50 -q
if [ ! -f "$WORK/.night-verify" ]; then
  cat > "$WORK/.night-verify" <<'EOF'
# Verifiche dichiarate del turno di notte (una riga per comando, eseguite dal morning-gate).
# Esempi: node tools/test.js · pnpm test
EOF
  git -C "$WORK" add .night-verify
  git -C "$WORK" commit -q -m "chore: .night-verify per il gate del mattino (onboarding sistema)"
  git -C "$WORK" push -q
  echo ".night-verify creato e spinto"
else
  echo ".night-verify già presente, intoccato"
fi

CONF="$HERE/night-shift/repos.conf"
[ -f "$CONF" ] || cp "$HERE/night-shift/repos.conf.example" "$CONF"
grep -q "^$REPO\b" "$CONF" || { echo "$REPO $TYPE" >> "$CONF"; echo "aggiunta a repos.conf"; }

echo ""
echo "Fatto: $REPO è nel sistema. Prima issue con label night-shift e la notte lavora."
