#!/bin/bash
# test-mutation-tests.sh — il banco delle mutazioni sotto prova (esso stesso è
# «codice appena scritto»: questo test lo presidia). Il run COMPLETO (23 tool
# neutralizzati, ~2 min) è roba del banco di fine passaggio, non della suite:
# qui si prova il contratto — sintassi e la GUARDIA dell'albero sporco (mutare
# un repo con lavoro non committato è la lezione degli avversari: i checkout
# di ripristino hanno cancellato fix veri). La guardia l'ha fermato davvero,
# perfino mentre la scrivevo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MUTA="$HERE/tools/mutation-tests.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$MUTA" ] && ok "il banco mutazioni è eseguibile" || ko "non eseguibile"
bash -n "$MUTA" && ok "sintassi" || ko "sintassi rotta"

# su albero pulito: completa e dichiara il verdetto (run pieno: è il contratto
# del banco, e in suite costa quanto due test lenti — accettato)
if git -C "$HERE" diff --quiet 2>/dev/null && git -C "$HERE" diff --cached --quiet 2>/dev/null; then
  OUT=$(bash "$MUTA" 2>&1); RC=$?
  [ $RC -eq 0 ] && grep -qE "[0-9]+ test reagiscono alla mutazione, 0 teatri verdi" <<<"$OUT" \
    && ok "run completo: tutti i test reagiscono, nessun teatro" \
    || { echo "$OUT" | tail -3 | sed 's/^/    /'; ko "run completo non pulito (rc=$RC)"; }
else
  # albero sporco: la guardia deve FERMARE (exit 2) — mai mutare lavoro vivo
  OUT=$(bash "$MUTA" 2>&1); RC=$?
  [ $RC -eq 2 ] && grep -q "albero sporco" <<<"$OUT" \
    && ok "albero sporco: il banco si ferma prima di mutare (exit 2)" \
    || ko "la guardia non scatta (rc=$RC): muterebbe lavoro non committato"
fi

# (Q32, 2026-09-23, notte dei giri): un banco GIA' rosso prima della mutazione fallisce anche dopo,
# e veniva contato «reagisce alla mutazione» — un TIENE regalato da un banco rotto. Si prova in una
# repo di prova: tool sano, banco che fallisce sempre.
MT=$(mktemp -d)
git -C "$MT" init -q; mkdir -p "$MT/tools" "$MT/tests"
cp "$HERE/tools/mutation-tests.sh" "$MT/tools/"
printf '#!/bin/bash\necho sano\n' > "$MT/tools/soggetto.sh"
printf '#!/bin/bash\nexit 1\n' > "$MT/tests/test-soggetto.sh"
git -C "$MT" add -A; git -C "$MT" -c user.name=t -c user.email=t@t commit -qm base
OUT=$(cd "$MT" && bash tools/mutation-tests.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -qi "rosso gia' prima" <<<"$OUT" && ! grep -q "^VERDETTO: 1 test reagiscono" <<<"$OUT" \
  && ok "banco gia' rosso prima della mutazione: detto, e non contato fra quelli che reagiscono" \
  || ko "banco rotto promosso a «reagisce alla mutazione» (rc=$RC): $(tail -1 <<<"$OUT")"
rm -rf "$MT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
