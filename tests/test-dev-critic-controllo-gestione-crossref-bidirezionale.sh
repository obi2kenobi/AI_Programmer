#!/bin/bash
# test-dev-critic-controllo-gestione-crossref-bidirezionale.sh — 5° ciclo, set 3 giro 1.
# controllo-gestione/SKILL.md §6 cita già i tre agenti (5° ciclo, set 1 giri 1-3) — ma
# dev-critic §2ter (la lente che revisore-calcoli-critici incarna esattamente) non citava
# ancora quell'agente: la direzione mancava in un solo senso. Verifica che ora sia
# bidirezionale, e che il limite di invocabilità sia ricordato anche qui (non solo dove
# l'agente è stato creato) — coerenza dell'avviso ovunque l'agente è citato.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DC="$HERE/.claude/skills/dev-critic/SKILL.md"
CG="$HERE/.claude/skills/controllo-gestione/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'controllo-gestione' "$CG" >/dev/null # sanity: il file esiste ed è leggibile
grep -q 'revisore-calcoli-critici' "$CG" \
  && ok "controllo-gestione cita già revisore-calcoli-critici (direzione 1, dal Set 1)" \
  || ko "controllo-gestione non cita più revisore-calcoli-critici"

grep -q 'revisore-calcoli-critici' "$DC" \
  && ok "dev-critic ora cita revisore-calcoli-critici (direzione 2, chiusa in questo giro)" \
  || ko "dev-critic non cita revisore-calcoli-critici — cross-reference ancora mono-direzionale"

SEZ_2TER=$(awk '/^## 2ter\./{f=1} /^## 3\./{f=0} f' "$DC")
echo "$SEZ_2TER" | grep -qi "refresh del roster" \
  && ok "§2ter ricorda la nota sull'invocabilità dell'agente, non solo il nome" \
  || ko "§2ter cita l'agente senza ricordare il limite noto"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
