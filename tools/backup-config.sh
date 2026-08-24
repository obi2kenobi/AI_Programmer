#!/bin/bash
# backup-config.sh — il sistema vive su un Mac: la config critica va salvata (giro 4/10).
# repos.conf, repos.key, metrics/gate.csv: tre file che non esistono da nessun'altra parte.
# Backup: gist privato (GitHub, già autenticato) — nessuna dipendenza nuova.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GIST_DESC="AI_Programmer config backup $(date '+%Y-%m-%d %H:%M')"
GIST_ID_FILE="$HERE/.gist-backup-id"

# trova o crea il gist
GIST_ID=""
[ -f "$GIST_ID_FILE" ] && GIST_ID=$(cat "$GIST_ID_FILE")

FILES=("night-shift/repos.conf" "night-shift/repos.key" "metrics/gate.csv" "DEBITI.md")
ARGS=()
TMPFILES=()
for f in "${FILES[@]}"; do
  if [ -f "$HERE/$f" ]; then
    T=$(mktemp); cp "$HERE/$f" "$T"; TMPFILES+=("$T")
    ARGS+=("--filename" "$(basename "$f")" "$T")
  fi
done
trap 'rm -f ${TMPFILES[@]+"${TMPFILES[@]}"}' EXIT

if [ -n "$GIST_ID" ]; then
  # aggiorna il gist esistente
  gh gist edit "$GIST_ID" --desc "$GIST_DESC" ${ARGS[@]+"${ARGS[@]}"} 2>/dev/null \
    && echo "✓ backup aggiornato: $GIST_ID" \
    || { echo "⚠ aggiornamento fallito, provo a creare"; GIST_ID=""; }
fi

if [ -z "$GIST_ID" ]; then
  URL=$(gh gist create --secret --desc "$GIST_DESC" ${ARGS[@]+"${ARGS[@]}"} 2>/dev/null | tail -1)
  if [ -n "$URL" ]; then
    echo "$URL" | grep -oE '[a-f0-9]{32,}' > "$GIST_ID_FILE"
    echo "✓ nuovo gist segreto: $URL"
  else
    echo "⛔ backup fallito (gh gist create)"
    exit 1
  fi
fi
