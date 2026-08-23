#!/bin/bash
# test-design-doc-goal-o-commessa.sh — 4° ciclo, SET 2 giro 10 (chiude il set). §3 di
# /design-doc citava SOLO /nuova-commessa come passo successivo dopo la scelta — ma
# docs/system.md e goal/SKILL.md distinguono esplicitamente giorno (/goal, sempre un
# tetto di tentativi) da notte (commessa unica, mai un tetto): un'opzione scelta con
# territorio piccolo e verificabile in poche iterazioni non ha motivo di passare dalla
# coda notturna. Verifica che §3 offra entrambi i percorsi, non solo quello notturno, e
# che l'obiettivo del /goal sia derivato dal criterio di successo del metodo (§1), non
# inventato lì.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SEZ3=$(awk '/^## 3\./{f=1} /^## 4\./{f=0} f' "$DD")

echo "$SEZ3" | grep -q "nuova-commessa" \
  && ok "§3 cita ancora /nuova-commessa per il territorio grande/notturno" \
  || ko "§3 non cita più /nuova-commessa"

echo "$SEZ3" | grep -q "/goal" \
  && ok "§3 offre anche /goal per il territorio piccolo/diurno" \
  || ko "§3 non offre /goal come alternativa — solo il percorso notturno"

echo "$SEZ3" | grep -q "criterio di successo del punto 1" \
  && ok "l'obiettivo del /goal è derivato dal criterio di successo dichiarato al punto 1, non inventato" \
  || ko "manca il vincolo che l'obiettivo del /goal derivi dal punto 1"

[ -f "$HERE/.claude/skills/goal/SKILL.md" ] \
  && ok "la skill /goal citata esiste davvero" \
  || ko "/goal citato ma la skill non esiste"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
