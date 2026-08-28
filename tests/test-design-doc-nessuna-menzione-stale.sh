#!/bin/bash
# test-design-doc-nessuna-menzione-stale.sh — 4° ciclo, SET 2 giro 8. Dopo aver corretto
# la staleness "opzioni+trade-off" in METHOD.md/docs/system.md (giro 5) e nel wizard
# (giro 6), un grep più ampio ha trovato la STESSA staleness in un terzo posto mai
# controllato: .claude/skills/brainstorming/SKILL.md, in tre punti (description + due
# righe del metodo) — descriveva ancora /design-doc come "opzioni con trade-off" dopo
# che i giri 1-4 ne avevano cambiato il meccanismo. Corretto anche lì. Questo test
# previene la stessa classe di staleness in futuro, su tutto il repo, non file per file.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# "struttura ... con trade-off" o "opzioni ... con trade-off" descrivono il VECCHIO
# meccanismo di design-doc (narrativa libera, prima dei giri 1-4). SAL.md è un diario
# storico: le voci passate descrivono correttamente cosa era vero ALLORA, non si toccano.
TROVATI=$(grep -rlE "(struttura|opzioni).{0,30}con trade-off" --include="*.md" "$HERE" 2>/dev/null \
  | grep -v SAL.md | grep -v campo | grep -v ARCHIVIO || true)
[ -z "$TROVATI" ] && ok "nessuna menzione stale di design-doc 'con trade-off' fuori da SAL.md" \
  || ko "menzioni stale trovate: $TROVATI"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
