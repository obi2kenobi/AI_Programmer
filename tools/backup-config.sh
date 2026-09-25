#!/bin/bash
# backup-config.sh — il sistema vive su un Mac: la config critica va salvata (giro 4/10).
# repos.conf, repos.key, metrics/gate.csv: tre file che non esistono da nessun'altra parte.
# Backup: gist privato (GitHub, già autenticato) — nessuna dipendenza nuova.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# mutation-testing 2026-08-28: senza gh lo script moriva 127 in SILENZIO (set -e
# uccideva al primo comando mancante, nessun messaggio). Il contratto dichiarato
# dal suo test era "errore pulito": ora lo è davvero.
command -v gh >/dev/null 2>&1 || { echo "backup-config: serve gh (CLI GitHub autenticata) — non trovato nel PATH" >&2; exit 1; }
GIST_DESC="AI_Programmer config backup $(date '+%Y-%m-%d %H:%M')"
GIST_ID_FILE="$HERE/.gist-backup-id"

# trova o crea il gist
GIST_ID=""
[ -f "$GIST_ID_FILE" ] && GIST_ID=$(cat "$GIST_ID_FILE")

FILES=("night-shift/repos.conf" "night-shift/repos.key" "metrics/gate.csv" "DEBITI.md")
# (2026-09-25, ottavo ventaglio, O4 R1): il backup non e' mai stato fatto. `gh gist create --secret` e' rifiutato dal gh
# vero (un gist e' segreto per default), la forma di `gist edit` pure, e sotto set -e lo script usciva 1 muto. E i file
# arrivavano al gist coi nomi casuali di mktemp. Ora: una cartella coi nomi veri, un gist nuovo a ogni backup (l'ID del
# precedente resta in .gist-backup-id.prima, da togliere a mano: cosa farne e' una domanda in DEBITI), e ogni fallimento
# detto con il suo motivo.
TD=$(mktemp -d)
trap 'rm -rf "$TD"' EXIT
N=0
for f in "${FILES[@]}"; do
  [ -f "$HERE/$f" ] && { cp "$HERE/$f" "$TD/$(basename "$f")"; N=$((N+1)); }
done
[ "$N" -gt 0 ] || { echo "⛔ backup fallito: nessuno dei file da salvare c'e' (${FILES[*]})" >&2; exit 1; }
URL=""
if ! URL=$(gh gist create --desc "$GIST_DESC" "$TD"/* 2>"$TD/.err" | tail -1) || [ -z "$URL" ]; then
  echo "⛔ backup fallito (gh gist create): $(tail -1 "$TD/.err" 2>/dev/null)" >&2
  exit 1
fi
[ -n "$GIST_ID" ] && cp "$GIST_ID_FILE" "$GIST_ID_FILE.prima" \
  && echo "  il gist del backup di prima resta: il suo ID e' in .gist-backup-id.prima (toglilo quando il nuovo e' verificato)"
echo "$URL" | grep -oE '[a-f0-9]{32,}' > "$GIST_ID_FILE"
echo "✓ nuovo gist segreto con $N file: $URL"
