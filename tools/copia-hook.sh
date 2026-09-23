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
#        copia-hook.sh --elenco [settings.json]  stampa soltanto gli hook dichiarati (un
#        percorso relativo per riga) — l'UNICA derivazione: sync-repo, onboard-repo e i banchi
#        la chiamano invece di rifarla (erano sette copie della stessa pipeline).
# Stampa un percorso relativo per riga (il chiamante ci fa il suo `git add`).
# Esiti: 0 tutti copiati · 1 errore DETTO (jq assente, settings illeggibile, hook
#        dichiarato e assente dall'hub, copia fallita). Mai un successo silenzioso su
#        una copia parziale: è esattamente così che il buco è passato inosservato.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

command -v jq >/dev/null 2>&1 || { echo "copia-hook: jq assente, impossibile leggere gli hook dichiarati" >&2; exit 1; }

# hook_dichiarati <settings.json>: gli script del repo nominati dai comandi degli hook.
# `awk '{print $1}'`: il comando di un hook può portare argomenti, il percorso è il primo
# campo. (Revisione 10 giri, 2026-09-23 — decisione di Luca): i comandi partono ora da
# "$CLAUDE_PROJECT_DIR"/ (con path relativi, da una sottocartella l'hook usciva 127 e il
# cancello clasp falliva APERTO): il prefisso si toglie qui, e la forma relativa di una repo
# satellite resta leggibile. Il filtro su tools/*.sh tiene fuori gli hook che non sono script.
hook_dichiarati() {
  jq -r '.hooks | to_entries[] | .value[]? | .hooks[]? | .command' "$1" \
    | awk '{print $1}' | sed -E 's#^"?\$(\{CLAUDE_PROJECT_DIR\}|CLAUDE_PROJECT_DIR)"?/##' \
    | grep -E '^tools/.*\.sh$' | sort -u
}

if [ "${1:-}" = "--elenco" ]; then
  S="${2:-$HERE/.claude/settings.json}"
  [ -f "$S" ] || { echo "copia-hook: $S assente" >&2; exit 1; }
  hook_dichiarati "$S"
  exit 0
fi

DEST="${1:?uso: copia-hook.sh <dir-destinazione> | --elenco [settings.json]}"
SETTINGS="$HERE/.claude/settings.json"
[ -f "$SETTINGS" ] || { echo "copia-hook: $SETTINGS assente" >&2; exit 1; }
[ -d "$DEST" ] || { echo "copia-hook: destinazione inesistente: $DEST" >&2; exit 1; }

DICHIARATI=$(hook_dichiarati "$SETTINGS")

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

# (report REPO-I 2026-09-19, H1): l'hook copiato ma non la riga che ne nasconde il
# residuo — ogni repo portata a standard restava con l'albero sporco per sempre.
# Le righe si DERIVANO dai path che gli hook scrivono ($PWD/.qualcosa nei sorgenti):
# stessa disciplina della lista hook, estesa al residuo.
RESIDUI=$(grep -ohE '\$PWD/\.[A-Za-z0-9_.-]+' $DICHIARATI 2>/dev/null | sed 's|^\$PWD/||' | sort -u)
if [ -n "$RESIDUI" ]; then
  touch "$DEST/.gitignore"
  while IFS= read -r R; do
    [ -n "$R" ] || continue
    grep -qxF "$R" "$DEST/.gitignore" || echo "$R" >> "$DEST/.gitignore"
  done <<< "$RESIDUI"
  echo ".gitignore"
fi
