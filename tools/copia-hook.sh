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
#        copia-hook.sh --residui <dir-destinazione>  solo le righe «residuo» nella .gitignore (R2 R6)
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

# --residui <dir> (2026-09-24, quinto ventaglio, R2 R6): solo la seconda meta' — le righe «residuo» nella
# .gitignore, senza toccare gli hook. Per l'onboard, che copia gli hook da se' (quelli gia' presenti nel
# progetto restano suoi) e perdeva le righe: il primo Stop lasciava l'albero sporco.
SOLO_RESIDUI=0
[ "${1:-}" = "--residui" ] && { SOLO_RESIDUI=1; shift; }
DEST="${1:?uso: copia-hook.sh <dir-destinazione> | --residui <dir-destinazione> | --elenco [settings.json]}"
SETTINGS="$HERE/.claude/settings.json"
[ -f "$SETTINGS" ] || { echo "copia-hook: $SETTINGS assente" >&2; exit 1; }
# (sesto ventaglio, rinviati di S3 R6): una cartella relativa che comincia col trattino e' un percorso, non un'opzione.
case "$DEST" in -*) DEST="./$DEST" ;; esac
[ -d "$DEST" ] || { echo "copia-hook: destinazione inesistente: $DEST" >&2; exit 1; }

DICHIARATI=$(hook_dichiarati "$SETTINGS")

[ -n "$DICHIARATI" ] || { echo "copia-hook: nessun hook dichiarato in $SETTINGS — sospetto, non copio niente" >&2; exit 1; }

if [ "$SOLO_RESIDUI" -eq 0 ]; then
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
fi

# (report REPO-I 2026-09-19, H1): l'hook copiato ma non la riga che ne nasconde il
# residuo — ogni repo portata a standard restava con l'albero sporco per sempre.
# Le righe si DERIVANO dagli hook stessi: stessa disciplina della lista hook, estesa al residuo.
# (2026-09-24, notte dei giri, T6#3): prima si prendeva ogni `$PWD/.x` nominato — anche
# .mirror-boundaries, che e' una DICHIARAZIONE letta dall'hook clasp: ignorata, non si versionava e chi
# clona perdeva il cancello. E i sorgenti si cercavano relativi alla cartella CORRENTE: da un'altra
# cartella, nessun residuo, in silenzio. Ora un hook dichiara cio' che SCRIVE con una riga
# `# residuo: <file>`, e i sorgenti si leggono dall'hub.
RESIDUI=$(while IFS= read -r H; do sed -n 's/^[[:space:]]*# residuo: \([A-Za-z0-9_.-]*\)[[:space:]]*$/\1/p' "$HERE/$H"; done <<< "$DICHIARATI" | sort -u)
if [ -n "$RESIDUI" ]; then
  touch "$DEST/.gitignore"
  # (2026-09-24, sesto ventaglio, S2 R2): senza a capo finale la riga nuova si incollava all'ultima
  [ -s "$DEST/.gitignore" ] && [ -n "$(tail -c1 "$DEST/.gitignore")" ] && echo >> "$DEST/.gitignore"
  while IFS= read -r R; do
    [ -n "$R" ] || continue
    grep -qxF "$R" "$DEST/.gitignore" || echo "$R" >> "$DEST/.gitignore"
  done <<< "$RESIDUI"
  # (T6#3): i satelliti nati prima hanno la riga .mirror-boundaries, messa dal metodo per errore — la
  # dichiarazione dei cloni di sola lettura va versionata. Si toglie la sola riga esatta, e lo si dice.
  if grep -qxF '.mirror-boundaries' "$DEST/.gitignore"; then
    grep -vxF '.mirror-boundaries' "$DEST/.gitignore" > "$DEST/.gitignore.copia-hook" && cat "$DEST/.gitignore.copia-hook" > "$DEST/.gitignore"
    rm -f "$DEST/.gitignore.copia-hook"
    echo "copia-hook: tolta la riga .mirror-boundaries dalla .gitignore — e' una dichiarazione da versionare, non un residuo (T6#3)" >&2
  fi
  echo ".gitignore"
fi
