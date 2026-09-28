#!/bin/bash
# backup-config.sh — il sistema vive su un Mac: la config critica va salvata (giro 4/10).
# repos.conf, metrics/gate.csv, DEBITI.md: file che non esistono da nessun'altra parte.
# Backup: gist segreto (GitHub, già autenticato) — nessuna dipendenza nuova.
# (2026-09-25, D36, risposta delegata): repos.key NON va nel gist — chi ha l'URL di un gist segreto lo legge, e la
# chiave dei nomi privati e' accesso. La custodisce Luca fuori da GitHub. E il gist di prima si toglie, ma solo dopo
# aver verificato che il nuovo ha tutti i file: un gist per volta, non uno in piu' ogni settimana.
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

FILES=("night-shift/repos.conf" "metrics/gate.csv" "DEBITI.md")
# (2026-09-25, ottavo ventaglio, O4 R1): il backup non e' mai stato fatto. `gh gist create --secret` e' rifiutato dal gh
# vero (un gist e' segreto per default), la forma di `gist edit` pure, e sotto set -e lo script usciva 1 muto. E i file
# arrivavano al gist coi nomi casuali di mktemp. Ora: una cartella coi nomi veri, un gist nuovo a ogni backup, e ogni
# fallimento detto con il suo motivo.
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
[ -f "$HERE/night-shift/repos.key" ] && echo "  repos.key non e' nel gist (D36): la sua copia la custodisci tu, fuori da GitHub"
NUOVO=$(echo "$URL" | grep -oE '[a-f0-9]{32,}')
echo "$NUOVO" > "$GIST_ID_FILE"
echo "✓ nuovo gist segreto con $N file: $URL"
# la verifica: il gist nuovo elenca tanti file quanti ne ho mandati. Solo allora il vecchio si toglie.
VISTI=$(gh gist view "$NUOVO" --files 2>/dev/null | grep -c . || true)
if [ "${VISTI:-0}" -lt "$N" ]; then
  [ -n "$GIST_ID" ] && echo "$GIST_ID" > "$GIST_ID_FILE.prima"
  echo "⛔ gist nuovo NON verificato: ne leggo ${VISTI:-0} file su $N. Il vecchio resta (ID in .gist-backup-id.prima)" >&2
  exit 1
fi
[ -n "$GIST_ID" ] && [ "$GIST_ID" != "$NUOVO" ] || exit 0
# `--yes` c'e' solo nei gh recenti, che senza terminale lo pretendono; il 2.45 lo rifiuta: si chiede all'aiuto
AIUTO=$(gh gist delete --help 2>&1 || true); SI=(); grep -q -- '--yes' <<<"$AIUTO" && SI=(--yes)
if gh gist delete "$GIST_ID" ${SI[@]+"${SI[@]}"} >/dev/null 2>"$TD/.err"; then
  rm -f "$GIST_ID_FILE.prima"; echo "  il gist di prima e' tolto (verificato il nuovo: $VISTI file)"
else
  echo "$GIST_ID" > "$GIST_ID_FILE.prima"
  echo "⚠ il gist di prima NON si e' tolto ($(tail -1 "$TD/.err")): il suo ID e' in .gist-backup-id.prima" >&2
fi
