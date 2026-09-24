#!/bin/bash
# test-contratti-uscita.sh — i codici d'uscita che le intestazioni dichiarano sono quelli che gli script
# emettono (2026-09-24, quarto ventaglio, Q3 R4-R5). Prima:
#   - `${1:?uso}` esce 1, e per cinque strumenti 1 ha gia' un altro significato (revisore: «rigettata»;
#     lente-sicurezza: «RILIEVI»; agente, risolvi-issue, goal-issue: «fallito» o non dichiarato). Un
#     chiamante nuovo che legge 1 crede a un rigetto o a un rilievo di sicurezza;
#   - sei intestazioni dichiaravano codici diversi da quelli emessi («0 sempre» ed esce 1 o 2).
# Il banco lancia ogni strumento nel caso d'uso sbagliato e confronta col codice DICHIARATO.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
NO="$T/non-esiste"

caso() { # caso <rc atteso> <descrizione> <comando…>
  local atteso="$1" desc="$2"; shift 2
  ( cd "$T" && "$@" ) </dev/null >/dev/null 2>&1; local rc=$?
  [ "$rc" -eq "$atteso" ] && ok "$desc → rc $rc (dichiarato)" || ko "$desc → rc $rc, l'intestazione dichiara $atteso"
}
# Q3 R4: senza argomenti, il codice d'USO dichiarato
caso 2 "agente.sh senza argomenti (2 = uso)"            bash "$HERE/night-shift/agente.sh"
caso 2 "risolvi-issue.sh senza argomenti (2 = uso)"     bash "$HERE/night-shift/risolvi-issue.sh"
caso 3 "revisore.sh senza argomenti (3 = errore)"       bash "$HERE/night-shift/revisore.sh"
caso 2 "lente-sicurezza.sh senza argomenti (2 = non giudicabile)" bash "$HERE/tools/lente-sicurezza.sh"
caso 2 "goal-issue.sh senza argomenti (2 = uso)"        bash "$HERE/tools/goal-issue.sh"
# Q3 R5: la cartella o il file inesistenti, col codice che l'intestazione dichiara
caso 2 "py-gate.sh su una cartella inesistente (2 = non giudicabile)" bash "$HERE/tools/py-gate.sh" "$NO"
caso 2 "salda-e002.sh su un file inesistente (2 = uso)"  bash "$HERE/tools/salda-e002.sh" "$NO" 3
for s in caccia-registro debiti-riapertura polilivello test-modelli-notturni; do
  DICH=$(sed -n '1,30p' "$HERE/tools/$s.sh" | grep -m1 -E '^# *Esce' || true)
  grep -c 'sempre' <<<"$DICH" >/dev/null && ko "$s.sh dichiara «0 sempre» ma esce anche con altri codici" || ok "$s.sh non dichiara piu' «0 sempre»"
done
caso 2 "caccia-registro.sh su una cartella inesistente"  bash "$HERE/tools/caccia-registro.sh" "$NO"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
