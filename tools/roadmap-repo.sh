#!/bin/bash
# roadmap-repo.sh — il passo corrente della repo (studio GSD Pi: auto-mode
# deriva il lavoro da uno STATO autorevole, non dall'emergenza). Il nostro
# adattamento bash: un file .git/roadmap per repo che dice il passo corrente.
#
# La caccia onora la roadmap: se c'e' un passo corrente, la caccia lo guarda
# PRIMA di vagare per categorie. Se la roadmap dice "saldare il debito E-002
# su tools/", la caccia cerca li'.
#
# Uso:
#   roadmap-repo.sh <dir> set <passo>     → imposta il passo corrente
#   roadmap-repo.sh <dir> get             → stampa il passo corrente
#   roadmap-repo.sh <dir> advance         → segna il passo come fatto, prossimo
#   roadmap-repo.sh <dir> list            → tutti i passi
# Esce: 0 · 2 uso · 3 nessuna roadmap
set -uo pipefail
DIR="${1:?uso: roadmap-repo.sh <dir> <set|get|advance|list> ...}"; shift
CMD="${1:-}"; shift || true
cd "$DIR" 2>/dev/null || { echo "⛔ dir: $DIR" >&2; exit 2; }
F=".git/roadmap"

case "$CMD" in
  set)
    PASSO="${1:?passo}"
    echo "$PASSO" > "$F"
    echo "roadmap: passo corrente = $PASSO" ;;
  get)
    [ -f "$F" ] && cat "$F" || { echo "(nessuna roadmap)"; exit 3; } ;;
  advance)
    [ -f "$F" ] || { echo "(nessuna roadmap)"; exit 3; }
    PASSO=$(cat "$F")
    echo "$PASSO DONE $(date '+%F %H:%M')" >> "$F.done"
    echo "(prossimo passo da impostare)" > "$F"
    echo "roadmap: '$PASSO' segnato fatto" ;;
  list)
    [ -f "$F.done" ] && cat "$F.done" || echo "(nessun passo completato)"
    [ -f "$F" ] && echo "→ corrente: $(cat "$F")" ;;
  *) echo "uso: roadmap-repo.sh <dir> <set|get|advance|list>" >&2; exit 2 ;;
esac
