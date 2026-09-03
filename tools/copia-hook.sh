#!/bin/bash
# copia-hook.sh — dal campo (REPO-V, progetto GAS nuovo, 2026-09-03).
#
# La causa, non il sintomo. La lista degli hook viveva scritta A MANO in tre posti —
# .claude/settings.json (chi li ESEGUE), tools/bootstrap-app.sh e tools/sync-repo.sh
# (chi li COPIA) — e i tre erano divergiti in silenzio: settings.json ne dichiarava tre,
# gli script ne copiavano due. Mancava tools/clasp-block-hook.sh, cioè l'unico cancello
# TECNICO del metodo: una repo portata a standard riceveva un settings.json che punta a
# uno script inesistente e restava senza blocco sul deploy in produzione.
#
# Qui la lista si DERIVA da settings.json — l'unica fonte che non può divergere da sé
# stessa, perché è la stessa che l'agente esegue. Aggiungere un hook a settings.json ora
# BASTA: nessun secondo posto da ricordare.
#
# Uso:   copia-hook.sh <dir-destinazione>
# Stampa un percorso relativo per riga (il chiamante ci fa il suo `git add`).
# Esiti: 0 tutti copiati · 1 errore DETTO (jq assente, settings illeggibile, hook
#        dichiarato e assente dall'hub, copia fallita). Mai un successo silenzioso su
#        una copia parziale: è esattamente così che il buco è passato inosservato.
set -uo pipefail
DEST="${1:?uso: copia-hook.sh <dir-destinazione>}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$HERE/.claude/settings.json"

command -v jq >/dev/null 2>&1 || { echo "copia-hook: jq assente, impossibile leggere gli hook dichiarati" >&2; exit 1; }
[ -f "$SETTINGS" ] || { echo "copia-hook: $SETTINGS assente" >&2; exit 1; }
[ -d "$DEST" ] || { echo "copia-hook: destinazione inesistente: $DEST" >&2; exit 1; }

# `awk '{print $1}'`: il comando di un hook può portare argomenti, il percorso è il primo
# campo. Il filtro su tools/*.sh tiene fuori gli hook che non sono script del repo.
DICHIARATI=$(jq -r '.hooks | to_entries[] | .value[]? | .hooks[]? | .command' "$SETTINGS" \
  | awk '{print $1}' | grep -E '^tools/.*\.sh$' | sort -u)

[ -n "$DICHIARATI" ] || { echo "copia-hook: nessun hook dichiarato in $SETTINGS — sospetto, non copio niente" >&2; exit 1; }

N=0
while IFS= read -r H; do
  [ -n "$H" ] || continue
  [ -f "$HERE/$H" ] || { echo "copia-hook: $H è dichiarato in settings.json ma non esiste nell'hub" >&2; exit 1; }
  mkdir -p "$DEST/$(dirname "$H")" || exit 1
  cp "$HERE/$H" "$DEST/$H" || { echo "copia-hook: copia fallita: $H" >&2; exit 1; }
  chmod +x "$DEST/$H"
  echo "$H"
  N=$((N+1))
done <<< "$DICHIARATI"

[ "$N" -gt 0 ] || { echo "copia-hook: zero hook copiati" >&2; exit 1; }
