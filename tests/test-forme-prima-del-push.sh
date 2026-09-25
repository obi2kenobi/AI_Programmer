#!/bin/bash
# test-forme-prima-del-push.sh — le forme di segreto si guardano PRIMA del push, non dopo (2026-09-23,
# notte dei giri, T5#3). La lente sicurezza (lente_pr) girava dopo `git push` + `gh pr create` in tutti
# e quattro i punti di consegna di night-shift.sh: sull'hub PUBBLICO il segreto era gia' su GitHub
# quando la lente lo vedeva. Ora lo strato 1 della lente (deterministico, nessun cervello) sta fra il
# commit e il push: con una forma di segreto nel diff il push non parte.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null "$@"; }
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"

repo() { # repo <nome> <contenuto aggiunto sul ramo>
  local R="$T/$1"; mkdir -p "$R"; g -C "$R" init -q -b main
  echo base > "$R/LEGGIMI.md"; g -C "$R" add -A; g -C "$R" commit -qm base; g -C "$R" branch -q base
  g -C "$R" checkout -q -b night/prova; printf '%s\n' "$2" > "$R/nuovo.js"; g -C "$R" add -A; g -C "$R" commit -qm pr
}
F20=ABCDEFGHIJKLMNOPQRST
repo pulito 'const n = 1;'
repo sporco "const refresh = '1/""/0$F20';"

command -v forme_prima_del_push >/dev/null || { ko "forme_prima_del_push non esiste in night-shift/lib.sh"; echo; echo "$PASS OK, $FAIL FAIL"; exit 1; }
OUT=$(forme_prima_del_push "$T/pulito" base 2>&1); RC=$?
[ $RC -eq 0 ] && ok "diff pulito: il push puo' partire" || ko "diff pulito bloccato (rc $RC): $OUT"
OUT=$(forme_prima_del_push "$T/sporco" base 2>&1); RC=$?
[ $RC -ne 0 ] && ok "forma di segreto nel diff: il push NON parte (rc $RC)" || ko "forma di segreto nel diff e push libero: $OUT"
grep -cF "$F20" <<<"$OUT" >/dev/null && ko "il motivo porta il segreto in chiaro" || ok "il motivo non porta il segreto in chiaro"
LENTE_STUB=/bin/false OUT=$(LENTE_STUB=/bin/false forme_prima_del_push "$T/pulito" base 2>&1); RC=$?
[ $RC -eq 0 ] && ok "il cancello non consulta il cervello (uno stub muto non lo rende DEGRADATO)" || ko "il cancello dipende dal cervello (rc $RC): $OUT"

# ogni `git push` del turno ha il cancello nelle 4 righe prima (stesso && o riga sopra).
# (2026-09-25, settimo ventaglio, V1 R3): guardava solo night-shift.sh — il pass del grafo (tools/grafo-semantico.sh,
# lanciato dal turno) spingeva senza cancello. Ora ogni script di night-shift/ e il pass del grafo; `git push`
# dentro un testo (il prompt del morning-gate lo nomina fra i vietati) non conta: si cerca `push -`.
SENZA=$(awk 'FNR==1{u=0} /forme_prima_del_push/{u=FNR} /git( -C "\$[A-Z_]+")? push -/ && !/^[[:space:]]*#/{ if (!u || FNR-u>4) print FILENAME":"FNR }' \
  "$HERE"/night-shift/*.sh "$HERE/tools/grafo-semantico.sh")
[ -z "$SENZA" ] && ok "ogni git push della notte (night-shift/ e il pass del grafo) passa dal cancello delle forme" || ko "git push senza cancello: $SENZA"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
