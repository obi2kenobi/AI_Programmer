#!/bin/bash
# verify-standalone.sh — il .night-verify di un repo SENZA toccare la copia del turno
# (2026-10-01, giro 3): lanciato a mano nella copia viva, il verify (con la suite da
# 25 minuti) collide coi checkout del turno che cicla nello stesso clone: banchi che
# muoiono a caso. Qui il verify gira in un WORKTREE staccato di origin/main, che il
# turno non tocca mai — e a fine corsa il worktree sparisce.
#
# Uso: verify-standalone.sh <dir-repo>   (il repo deve essere pulito per fare il fetch)
set -uo pipefail
DIR="${1:?uso: verify-standalone.sh <dir-repo>}"
cd "$DIR" || exit 2
git fetch -q origin 2>/dev/null || true
BASE=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||'); BASE="${BASE:-main}"
WT=$(mktemp -d "${TMPDIR:-/tmp}/verify-standalone.XXXXXX")
rmdir "$WT" 2>/dev/null
if ! git worktree add --detach "$WT" "origin/$BASE" >/dev/null 2>&1; then
  echo "verify-standalone: worktree non creato su origin/$BASE" >&2; exit 2
fi
trap 'git worktree remove --force "$WT" 2>/dev/null' EXIT
echo "verify-standalone: giro su origin/$BASE in $WT (la copia del turno non si tocca)"
# (2026-10-01): il _timeout.sh vive nell'HUB (i satelliti non ce l'hanno) — senza di
# lui ogni riga moriva di «command not found» e il verify diceva rosso fantasma
source "$HOME/night-shift-work/AI_Programmer/llm/_timeout.sh" 2>/dev/null || true
command -v ai_timeout >/dev/null 2>&1 || { echo "verify-standalone: ai_timeout assente (llm/_timeout.sh dell'hub) — righe @N senza tetto" >&2; }
cd "$WT" || exit 2
_cp=$(head -10 .night-verify 2>/dev/null) || true
if grep -q '^# FORMATO: script' <<<"$_cp"; then
  ai_timeout 1800 bash .night-verify; RC=$?
else
  RC=0
  while IFS= read -r riga; do
    case "$riga" in ''|'#'*) continue ;; esac
    sec=120
    case "$riga" in @*' '*) sec="${riga%% *}"; sec="${sec#@}"; riga="${riga#* }" ;; esac
    if ai_timeout "$sec" bash -c "$riga" >/dev/null 2>&1; then :; else
      RC=1; echo "ROSSA: $(printf '%s' "$riga" | cut -c1-110)"
    fi
  done < .night-verify
fi
[ $RC -eq 0 ] && echo "verify-standalone: VERDE" || echo "verify-standalone: ROSSO"
exit $RC
