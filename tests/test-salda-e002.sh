#!/bin/bash
# test-salda-e002.sh — il trasformatore deterministico della famiglia E-002
# («chiudi ora», 2026-09-20): cattura-prima e' meccanica, il modello non serve.
# Prova: forma A (if PROD | grep), forma B (cond composta), forma ignota rifiutata
# con codice giusto, sintassi rotta ripristinata, il filo per il tubo del
# censimento NON si abbocca (i pezzi a pezzetti restano pezzi).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SALDA="$HERE/tools/salda-e002.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$SALDA" && ok "sintassi" || { ko "sintassi"; exit 1; }

# (revisione 10 giri): la pulizia finale cancellava /tmp/test-salda.* — anche le cartelle di
# un'altra esecuzione in corso (il banco notturno si sovrappone). Si puliscono solo le proprie.
MIE=()
nuova() { SB=$(mktemp -d /tmp/test-salda.XXXXXX); MIE+=("$SB"); cd "$SB"; git init -q -b main; }

# 1. forma A
nuova
PDQ="| gre""p -q"
printf '#!/bin/bash\nif echo "$PROMPT" %s PAT; then\n  echo si\nfi\n' "$PDQ" > a.sh
git add -A && git -c user.name=t -c user.email=t@t commit -qm i
bash "$SALDA" a.sh 2 2>/dev/null; RC=$?
[ "$RC" -eq 0 ] && grep -q '_cp=$(echo "$PROMPT")' a.sh && grep -q '<<<"$_cp"' a.sh \
  && ok "forma A: cattura-prima esatta" || ko "forma A: rc=$RC, $(cat a.sh | tr '\n' ' ' | head -c 80)"
bash -n a.sh && ok "forma A: sintassi" || ko "forma A: sintassi rotta"

# 2. forma B: la condizione resta nell'if, la cattura e' SOLO il produttore
nuova
printf '#!/bin/bash\n  if [ -f "$f.x" ] || head -5 "$f" %s -i "pippo:"; then\n    echo si\n  fi\n' "$PDQ" > b.sh
git add -A && git -c user.name=t -c user.email=t@t commit -qm i
bash "$SALDA" b.sh 2 2>/dev/null; RC=$?
grep -q '_cp=$(head -5 "\$f")' b.sh && grep -q '\[ -f "\$f.x" \] || grep -q -i "pippo:" <<<"\$_cp"' b.sh \
  && ok "forma B: condizione in if, cattura pulita" || ko "forma B: $(grep -n '_cp' b.sh | head -2 | tr '\n' ' ')"
bash -n b.sh && ok "forma B: sintassi" || ko "forma B: sintassi rotta"

# 3. forma ignota: rc 1, file INTATTO
nuova
printf '#!/bin/bash\nzzz_ignota_comando | %q altro\n' "$PDQ" > c.sh
git add -A && git -c user.name=t -c user.email=t@t commit -qm i
PRIMA=$(cat c.sh)
bash "$SALDA" c.sh 1 2>/dev/null; RC=$?
[ "$RC" -eq 1 ] && [ "$(cat c.sh)" = "$PRIMA" ] && ok "forma ignota: rc 1, file intatto (all'agente)" || ko "forma ignota: rc=$RC, file cambiato"

# 4. la variabile non collide
nuova
printf '#!/bin/bash\n_cp=9\nif echo "$X" %s Y; then\n  echo si\nfi\n' "$PDQ" > d.sh
git add -A && git -c user.name=t -c user.email=t@t commit -qm i
bash "$SALDA" d.sh 3 2>/dev/null
grep -q '_cp2=' d.sh && ok "collisione variabile: usa _cp2" || ko "collisione non gestita: $(grep -c '_cp2' d.sh)"

# 5. (revisione 10 giri, 2026-09-23): la NEGAZIONE — `if ! PROD | grep` diventava
# `_cp=$(! PROD)` + `if grep`: logica ROVESCIATA, e bash -n passava. Prova di COMPORTAMENTO:
# prima e dopo la trasformazione lo script deve rispondere uguale, per ogni ingresso.
for FORMA in A B; do
  nuova
  if [ "$FORMA" = A ]; then
    printf '#!/bin/bash
X="$1"
if ! echo "$X" %s PAT; then
  echo manca
else
  echo trovato
fi
' "$PDQ" > n.sh
  else
    printf '#!/bin/bash
X="$1"
if [ -z "$X" ] || ! echo "$X" %s PAT; then
  echo manca
else
  echo trovato
fi
' "$PDQ" > n.sh
  fi
  git add -A && git -c user.name=t -c user.email=t@t commit -qm i
  PRIMA_SI=$(bash n.sh "c'e' PAT"); PRIMA_NO=$(bash n.sh "niente")
  bash "$SALDA" n.sh 3 >/dev/null 2>&1
  DOPO_SI=$(bash n.sh "c'e' PAT"); DOPO_NO=$(bash n.sh "niente")
  [ "$PRIMA_SI|$PRIMA_NO" = "$DOPO_SI|$DOPO_NO" ] && ok "negazione (forma $FORMA): stesso comportamento prima e dopo ($DOPO_SI/$DOPO_NO)" \
    || ko "negazione (forma $FORMA) ROVESCIATA: prima $PRIMA_SI/$PRIMA_NO, dopo $DOPO_SI/$DOPO_NO"
done

cd "$HERE"; rm -rf "${MIE[@]}"
# Q16 (2026-09-23, giro A7 della notte): la trasformazione deve dare lo STESSO esito eseguendo, non
# solo compilare. Due vie per cui non lo dava, con bash -n verde (e la caccia la applica da sola):
#  (a) sotto `set -e`, `_cp=$(PROD)` fuori dall'if fa MORIRE lo script quando PROD fallisce — dentro
#      l'if il fallimento era solo un «falso»;
#  (b) `grep -v` su un output vuoto: il here-string porta una riga vuota che -v accetta, e la
#      condizione si ribalta. Queste forme vanno all'agente, non al trasformatore.
nuova
PDQ="| gre""p -q"
printf '#!/bin/bash\nset -euo pipefail\nif false %s x; then\n  echo si\nfi\necho dopo\n' "$PDQ" > e.sh
PRIMA=$(bash e.sh 2>/dev/null)
bash "$SALDA" e.sh 3 >/dev/null 2>&1
DOPO=$(bash e.sh 2>/dev/null)
[ "$PRIMA" = "$DOPO" ] && ok "Q16a: sotto set -e un produttore che fallisce non uccide lo script trasformato" \
  || ko "Q16a: esito cambiato dopo la trasformazione: prima «${PRIMA}», dopo «${DOPO}»"
PDV="| gre""p -qv"
printf '#!/bin/bash\nif true %s ok; then\n  echo PROBLEMA\nelse\n  echo tutto-ok\nfi\n' "$PDV" > v.sh
PRIMA=$(bash v.sh 2>/dev/null)
bash "$SALDA" v.sh 2 >/dev/null 2>&1; RC=$?
DOPO=$(bash v.sh 2>/dev/null)
[ "$RC" -eq 1 ] && [ "$PRIMA" = "$DOPO" ] && ok "Q16b: grep -v rifiutato (all'agente): la logica non si ribalta" \
  || ko "Q16b: grep -v trasformato (rc=$RC): prima «${PRIMA}», dopo «${DOPO}»"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
