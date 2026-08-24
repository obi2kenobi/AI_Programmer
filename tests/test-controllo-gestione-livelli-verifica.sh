#!/bin/bash
# test-controllo-gestione-livelli-verifica.sh — 5° ciclo, set 3 giro 7. La tassonomia
# condivisa a 5 livelli (docs/system.md) è già richiesta esplicitamente da /goal e dal
# wizard /nuova-commessa (5° ciclo, set 2 giro 4) — ma il passo 6 di controllo-gestione
# (verifica con un riscontro) non la citava, restando nel proprio vocabolario isolato
# mentre il resto del sistema ne condivide uno. Verifica il collegamento.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CG="$HERE/.claude/skills/controllo-gestione/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SEZ=$(awk '/^6\. \*\*Verifica con un riscontro/{f=1} /^## 2\./{f=0} f' "$CG")
echo "$SEZ" | grep -q "livelli di verifica" \
  && ok "il passo 6 (riscontro) cita la tassonomia condivisa dei 5 livelli" \
  || ko "il passo 6 non cita la tassonomia — vocabolario isolato dal resto del sistema"

echo "$SEZ" | grep -q "docs/system.md" \
  && ok "cita la fonte di verità reale (docs/system.md), non a memoria" \
  || ko "non cita la fonte della tassonomia"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
