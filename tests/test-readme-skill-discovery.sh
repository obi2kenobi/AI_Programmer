#!/bin/bash
# test-readme-skill-discovery.sh — feedback utente esterno (2026-08-24): il meccanismo di
# scoperta delle skill/agenti andava dedotto dal codice, nessun punto d'ingresso per un
# umano che apre il repo (verificato: nessun README.md in radice prima di questo giro).
# Verifica che il README esista e spieghi il meccanismo reale (frontmatter + matching
# automatico sull'intento, non un elenco statico) e i due percorsi (skills/agents).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
README="$HERE/README.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$README" ] && ok "README.md esiste in radice" || ko "README.md assente in radice"

grep -q '.claude/skills' "$README" && ok "cita il percorso reale delle skill" \
  || ko "non cita .claude/skills"
grep -q '.claude/agents' "$README" && ok "cita il percorso reale degli agenti" \
  || ko "non cita .claude/agents"
grep -qi 'description' "$README" && ok "spiega il ruolo del campo description nel frontmatter" \
  || ko "non spiega description come meccanismo di attivazione"
grep -qi 'automatic\|scattano\|attiva' "$README" && ok "chiarisce che l'attivazione è automatica, non un elenco manuale" \
  || ko "non chiarisce il meccanismo di attivazione automatica"
grep -q 'docs/system.md' "$README" && ok "rimanda alla mappa completa" \
  || ko "non rimanda a docs/system.md"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
