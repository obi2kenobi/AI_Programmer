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
# (2026-11-10): era `git rev-parse --abbrev-ref origin/HEAD | sed …` — senza origin/HEAD stampa «origin/HEAD» (non
# fallisce): BASE diventava «HEAD», il fallback su main non scattava e il worktree non nasceva. Ora default_branch()
# di lib.sh (origin/HEAD, poi ls-remote, poi gh, poi main dichiarato).
# shellcheck source=../night-shift/lib.sh
. "$(cd "$(dirname "$0")/.." && pwd)/night-shift/lib.sh"
BASE=$(default_branch .)
WT=$(mktemp -d "${TMPDIR:-/tmp}/verify-standalone.XXXXXX")
rmdir "$WT" 2>/dev/null
if ! git worktree add --detach "$WT" "origin/$BASE" >/dev/null 2>&1; then
  echo "verify-standalone: worktree non creato su origin/$BASE" >&2; exit 2
fi
trap 'git worktree remove --force "$WT" 2>/dev/null' EXIT
echo "verify-standalone: giro su origin/$BASE in $WT (la copia del turno non si tocca)"
# (2026-10-01): ai_timeout vive nell'HUB (i satelliti non ce l'hanno); dal 2026-11-10 arriva con lib.sh, caricata
# accanto a questo script — non piu' dal percorso fisso ~/night-shift-work/AI_Programmer
cd "$WT" || exit 2
verifica_righe .; RC=$?   # (2026-11-10): la stessa logica, ora una sola in lib.sh (la usano anche fondi, deploy-gas, giorno)
[ $RC -eq 0 ] && echo "verify-standalone: VERDE" || echo "verify-standalone: ROSSO"
exit $RC
