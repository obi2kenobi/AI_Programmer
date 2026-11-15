#!/bin/bash
# test-verifica-diff.sh — la guardia delle affermazioni sul diff non puo'
# morire su input vuoti o cercare regex quando il contratto parla di SIMBOLI.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/verifica-diff.sh"
T=$(mktemp -d /tmp/test-verifica-diff.XXXXXX); trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
printf 'alpha beta\na.b\n' > "$T/f.txt"

OUT=$(bash "$TOOL" "$T/f.txt" 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q 'almeno un criterio' <<<"$OUT" \
  && ok "nessun criterio = errore d'uso, mai guardia verde a vuoto" \
  || ko "nessun criterio: rc=$RC, $OUT"

OUT=$(bash "$TOOL" "$T/f.txt" --assenti '' 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! grep -q 'unbound variable' <<<"$OUT" \
  && ok "criterio vuoto = errore dichiarato, niente array non inizializzato" \
  || ko "criterio vuoto: rc=$RC, $OUT"

OUT=$(bash "$TOOL" "$T/f.txt" --presenti alpha,beta --assenti gamma 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "presenti/assenti sullo stesso file: verdetto corretto" || ko "caso verde: rc=$RC, $OUT"

OUT=$(bash "$TOOL" "$T/f.txt" --presenti delta 2>&1); RC=$?
[ "$RC" -eq 1 ] && grep -q 'PRESENTE-MA-ASSENTE' <<<"$OUT" && ok "simbolo mancante = rosso" || ko "mancante: rc=$RC, $OUT"

printf 'axb\n' > "$T/regex.txt"
OUT=$(bash "$TOOL" "$T/regex.txt" --presenti 'a.b' 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "il punto nel simbolo e' letterale: a.b non trova axb" || ko "regex non escaped: rc=$RC, $OUT"
OUT=$(bash "$TOOL" "$T/regex.txt" --assenti 'a.b' 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "assenti col punto letterale: axb resta un simbolo diverso" || ko "assenti regex: rc=$RC, $OUT"

OUT=$(bash "$TOOL" "$T/f.txt" --presenti 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q 'manca il valore' <<<"$OUT" && ok "flag senza valore = errore d'uso" || ko "flag senza valore: rc=$RC, $OUT"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
