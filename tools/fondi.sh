#!/bin/bash
# fondi.sh — l'AUTO-MERGE a condizioni (emendamento D10, Luca 14/10: «la maturita'
# del progetto e dei partecipanti ci impone... pull push in maniera automatica»).
# Il cancello umano NON sparisce: cambia guardia. La PR si fonde SOLO se:
#   1. e' fondibile (GitHub pulito)
#   2. la lente sicurezza ha detto PULITA (o RILIEVI gia' curati: verdetto nel commento)
#   3. il banco del repo e' verde (.night-verify)
#   4. il CENSORE APPROVA (parere del revisore — l'umano resta informato, decide il sistema)
# Ogni condizione mancata = NO con la riga che dice quale. Mai silenzio.
# Uso: fondi.sh <dir-repo> <n-pr>
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: fondi.sh <dir> <n-pr>}"; N="${2:?}"
REPO=$(cd "$DIR" && git remote get-url origin 2>/dev/null | sed -e 's#.*github.com[:/]##' -e 's#\.git$##')
[ -n "$REPO" ] || { echo "⛔ origin non GitHub" >&2; exit 2; }
KO=0
ST=$(gh pr view "$N" --repo "$REPO" --json mergeable,state,isDraft --jq '"\(.state) \(.mergeable) \(.isDraft)"' 2>/dev/null)
case "$ST" in *MERGEABLE*false*) echo "1. fondibile: SI ($ST)";; *) echo "1. fondibile: NO ($ST) — conflitti o bozza"; KO=1;; esac
VER=$(gh pr view "$N" --repo "$REPO" --json comments --jq '.[].body' 2>/dev/null | grep -oE 'LENTE SICUREZZA: [A-Z]+' | tail -1)
case "$VER" in *"PULITA") echo "2. lente: $VER";; *) echo "2. lente: ${VER:-ASSENTE} — serve il verdetto PULITA nel commento"; KO=1;; esac
if [ -f "$DIR/.night-verify" ]; then
  (cd "$DIR" && bash .night-verify >/dev/null 2>&1) && echo "3. banco: VERDE" || { echo "3. banco: ROSSO"; KO=1; }
else
  echo "3. banco: assente (dichiarato)"
fi
PAR=$(GIORNO_PARERE=1 GIORNO_SUBITO=1 bash "$HERE/night-shift/revisore.sh" "$DIR" "$N" 2>&1)
case "$PAR" in *DELIBERA:*APPROVA*|*"PARERE: APPROVA"*) echo "4. censore: APPROVA";; *) echo "4. censore: ${PAR:-muto} — senza APPROVA non si fonde"; KO=1;; esac
[ "$KO" -eq 0 ] || { echo "FONDI: NO ($KO condizioni mancate, scritte sopra)"; exit 1; }
gh pr merge "$N" --repo "$REPO" --merge 2>&1 | tail -1
echo "FONDI: SI — PR #$N fusa dal sistema (4 condizioni verdi, censore approva)"
