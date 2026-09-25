#!/bin/bash
# goal-issue.sh — l'obiettivo DURABLE di una issue, che sopravvive ai cicli del
# turno (studio deepseek-harness packages/goal, 2026-09-23: un objective per
# sessione con restart e resume; il nostro adattamento bash: un file per issue).
#
# Vive in .git/goal-issue-N (stato locale, come caccia-registro): il turno lo
# crea quando prende una issue, lo aggiorna con cio' che e' gia' fatto, lo
# pulisce quando la issue chiude. L'agente lo vede nel prompt (obiettivo +
# progressi), il censore lo consulta ("questa PR serve al goal?").
#
# Uso:
#   goal-issue.sh <repo-dir> create <N> <titolo>    → crea il goal
#   goal-issue.sh <repo-dir> update <N> <progresso> → aggiunge una riga di progresso
#   goal-issue.sh <repo-dir> show <N>               → stampa il goal (per prompt/censore)
#   goal-issue.sh <repo-dir> close <N> [esito]      → chiude (ok|rinvia|abbandona)
#   goal-issue.sh <repo-dir> list                   → goal aperti
# Esce: 0 ok · 2 uso · 3 conflitto (create su esistente)
set -uo pipefail
# (2026-09-24, Q3 R4): `${1:?}` usciva 1, che qui significa niente di dichiarato: l'uso sbagliato esce 2
[ $# -ge 1 ] || { echo "uso: goal-issue.sh <dir> <create|update|show|close|list> ..." >&2; exit 2; }
DIR="$1"; shift
CMD="${1:-}"; shift || true
cd "$DIR" 2>/dev/null || { echo "⛔ dir: $DIR" >&2; exit 2; }
GOAL_DIR=".git/goals"
mkdir -p "$GOAL_DIR"

case "$CMD" in
  create)
    N="${1:?issue N}"; TITOLO="${2:?titolo}"
    F="$GOAL_DIR/issue-$N"
    [ -f "$F" ] && { echo "⛔ goal per issue #$N gia' esistente: $(head -1 "$F")" >&2; exit 3; }
    printf 'APERTO %s | issue #%s | %s\n' "$(date '+%F %H:%M')" "$N" "$TITOLO" > "$F"
    echo "goal creato: issue #$N — $TITOLO" ;;
  update)
    N="${1:?issue N}"; PROG="${2:?progresso}"
    F="$GOAL_DIR/issue-$N"
    [ -f "$F" ] || { echo "⛔ nessun goal per issue #$N" >&2; exit 3; }
    printf '+ %s %s\n' "$(date '+%H:%M')" "$PROG" >> "$F" ;;
  show)
    N="${1:?issue N}"
    cat "$GOAL_DIR/issue-$N" 2>/dev/null || exit 3 ;;
  close)
    N="${1:?issue N}"; ESITO="${2:-ok}"
    F="$GOAL_DIR/issue-$N"
    [ -f "$F" ] || exit 3
    printf 'CHIUSO %s | esito: %s\n' "$(date '+%F %H:%M')" "$ESITO" >> "$F"
    mv "$F" "$GOAL_DIR/done-$N"
    echo "goal #$N chiuso ($ESITO)" ;;
  list)
    for F in "$GOAL_DIR"/issue-*; do
      [ -f "$F" ] || continue
      head -1 "$F"
    done
    ls "$GOAL_DIR"/issue-* >/dev/null 2>&1 || echo "(nessun goal aperto)" ;;
  *) echo "uso: goal-issue.sh <dir> <create|update|show|close|list>" >&2; exit 2 ;;
esac
