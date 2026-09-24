#!/bin/bash
# test-messaggio-fix.sh — il messaggio del commit di un fix d'issue del turno (2026-09-24, terzo ventaglio,
# V1#6). Prima: il commit diceva sempre «(risolvi-issue.sh, modello locale)», anche quando l'issue l'aveva
# risolta l'agente della cascata; e il corpo della PR (`gh pr create --fill`, preso dal commit) non portava
# `Closes #N`: lo faceva solo il ramo opencode, che il turno non raggiunge mai. La keyword resta INGLESE
# (CLAUDE.md §4): GitHub non auto-chiude con la traduzione.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
type messaggio_fix >/dev/null 2>&1 && ok "messaggio_fix e' definita in night-shift/lib.sh" \
  || { ko "messaggio_fix non esiste in night-shift/lib.sh"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }

M=$(messaggio_fix fix 7 "totale sbagliato" "agente.sh, cascata dopo il solver" "" "PASSA")
[ "$(head -1 <<<"$M")" = "fix: issue #7 — totale sbagliato (agente.sh, cascata dopo il solver)" ] \
  && ok "la prima riga dice chi ha risolto davvero" || ko "prima riga: $(head -1 <<<"$M")"
grep -cx 'Closes #7' <<<"$M" >/dev/null && ok "il corpo porta «Closes #7» (inglese, su una riga sua)" || ko "manca Closes #7: $M"
grep -cx "Verifica dell'issue: PASSA" <<<"$M" >/dev/null && ok "l'esito della verifica resta nel corpo" || ko "verifica persa: $M"
M2=$(messaggio_fix fix 8 "t" "risolvi-issue.sh, modello locale" "

⚠ AUTO-REVIEW: dubbi" "non dichiarata")
grep -cx '⚠ AUTO-REVIEW: dubbi' <<<"$M2" >/dev/null && ok "la nota (auto-review, funzione nuova) resta nel messaggio" || ko "nota persa: $M2"

NS="$HERE/night-shift/night-shift.sh"
N_USI=$(grep -c 'messaggio_fix ' "$NS")
[ "$N_USI" -ge 1 ] && ! grep -c 'risolvi-issue.sh, modello locale)\${NOTA_INS}' "$NS" >/dev/null \
  && ok "il turno compone il commit con messaggio_fix" || ko "il turno scrive ancora il messaggio a mano"
grep -c 'AUTORE_FIX="agente.sh' "$NS" >/dev/null && ok "la cascata che converge cambia la provenienza in agente.sh" \
  || ko "la provenienza non segue la cascata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
