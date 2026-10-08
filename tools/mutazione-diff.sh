#!/bin/bash
# mutazione-diff.sh — le SENTINELLE DEL DIFF (furto da DeployProof, giro 2:
# «AST mutation testing on your git diff before any commit reaches CI»).
#
# La loro osservazione vale per noi: copertura alta con mutation score vicino a
# zero = test che non verificano niente. La mossa: mutare SOLO le righe cambiate
# dal diff e vedere se QUALCHE verifica diventa rossa. Zero rosse = il diff non
# ha sentinelle: nessun test morde le righe appena scritte.
#
# Noi (casa bash, dichiarato): mutazione per sostituzione di operatore nelle
# righe cambiate dei file .py del diff (== ↔ !=), UNA mutazione per sito, tetto
# 3 siti (il costo resta quello di un banco). AST completo = futuro dichiarato.
#
# Uso: mutazione-diff.sh <dir-repo> <base> <comando-verifica>
#   esce 0 e stampa "sentinelle: K/N" (K = mutazioni viste da una verifica rossa)
set -uo pipefail
DIR="${1:?dir}" BASE="${2:?base}" VERIFICA="${3:?comando}"
cd "$DIR" || exit 2

SITI=$(git diff "$BASE"...HEAD --unified=0 -- '*.py' 2>/dev/null | grep -aE '^\+' | grep -avE '^\+\+\+' | grep -a ' == ' | head -3 || true)
N=0; K=0
while IFS= read -r RIGA; do
  [ -z "$RIGA" ] && continue
  N=$((N+1))
  # trova IL file che contiene la riga cambiata (senza il +)
  RIGA_SENZA=$(printf '%s' "$RIGA" | sed 's/^+//')
  FILE=$(grep -rlF "$RIGA_SENZA" --include='*.py' . 2>/dev/null | head -1 || true)
  [ -z "$FILE" ] && continue
  cp "$FILE" "$FILE.mutbak"
  python3 - "$FILE" "$RIGA_SENZA" <<'PYMUT'
import sys
p, riga = sys.argv[1], sys.argv[2]
s = open(p).read()
if riga in s and ' == ' in riga:
    s = s.replace(riga, riga.replace(' == ', ' != '), 1)
    open(p, 'w').write(s)
PYMUT
  if bash -c "$VERIFICA" >/dev/null 2>&1; then
    :
  else
    K=$((K+1))
  fi
  mv "$FILE.mutbak" "$FILE"
done <<<"$SITI"
echo "sentinelle: $K/$N"
[ "$N" -eq 0 ] && exit 0
exit 0
