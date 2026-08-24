#!/bin/bash
# test-flusso-artefatti.sh — 6° ciclo, set 3 giro 5 (2026-08-24). Il flusso delle idee
# è una catena di artefatti che si citano per percorso: selezione-contesto →
# brainstorming → design-doc → commessa (## Design + ## Forma dei dati) → notte →
# gate → SAL. Questo test verifica che OGNI anello dichiari la consegna al successivo
# — non che il lavoro sia buono, ma che la catena non si spezza in silenzio dove un
# giro precedente l'aveva saldata. Se una delle citazioni sparisce, il flusso "esiste
# solo se qualcuno se ne ricorda" — esattamente il filo comune dei gap del 5° ciclo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SC="$HERE/.claude/skills/selezione-contesto/SKILL.md"
BS="$HERE/.claude/skills/brainstorming/SKILL.md"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
AC="$HERE/.claude/skills/audit-commessa/SKILL.md"
TMPL="$HERE/.github/ISSUE_TEMPLATE/night-shift.md"
NS="$HERE/night-shift/night-shift.sh"
MG="$HERE/night-shift/morning-gate.sh"
AG="$HERE/AGENTS.md"

# 1. selezione-contesto → brainstorming/design-doc (il contesto che chiude, sennò)
grep -q "/brainstorming" "$SC" \
  && ok "selezione-contesto → rimanda a /brainstorming quando il quadro manca" \
  || ko "selezione-contesto: nessuna consegna dichiarata a valle"

# 2. brainstorming → design-doc (il problema chiaro passa alle opzioni)
grep -q "/design-doc" "$BS" \
  && ok "brainstorming → /design-doc (il problema chiaro passa alle opzioni)" \
  || ko "brainstorming: non consegna a /design-doc"

# 3. design-doc → commessa (## Design cita il PERCORSO, non riassume)
grep -q "## Design" "$DD" && grep -qi "PERCORSO del documento" "$DD" \
  && ok "design-doc → commessa: la ## Design cita il percorso del documento" \
  || ko "design-doc: la consegna alla commessa non è un percorso citabile"

# 4. il template dichiara gli slot che la notte e l'audit presidianp
grep -q "^## Design" "$TMPL" \
  && ok "template commessa: sezione ## Design presente" \
  || ko "template: manca ## Design"
grep -q "^## Forma dei dati" "$TMPL" \
  && ok "template commessa: sezione ## Forma dei dati presente (slot del censitore)" \
  || ko "template: manca ## Forma dei dati"

# 5. la notte presidia il gate del Design (l'anello meccanico)
grep -q 'grep -q "\^## Design"' "$NS" \
  && ok "night-shift: la issue senza ## Design viene saltata col commento (il presidio esiste)" \
  || ko "night-shift: il controllo ## Design non trovato"

# 6. audit-commessa guarda il riferimento Design (il pre-flight del flusso)
grep -q "## Design" "$AC" \
  && ok "audit-commessa: verifica il riferimento in ## Design" \
  || ko "audit-commessa: non guarda ## Design"

# 7. il gate scrive nel SAL (l'ultimo anello torna alla memoria)
grep -q "SAL" "$MG" \
  && ok "morning-gate: chiude nel SAL (l'anello che torna alla memoria)" \
  || ko "morning-gate: nessun riferimento al SAL"

# 8. AGENTS.md dichiara la catena intera all'agente che atterra
grep -q "selezione-contesto" "$AG" && grep -q "brainstorming" "$AG" && grep -q "design-doc" "$AG" \
  && grep -q "audit-commesse" "$AG" && grep -q "gate" "$AG" \
  && ok "AGENTS.md: la pipeline completa è dichiarata all'agente in arrivo" \
  || ko "AGENTS.md: la pipeline dichiarata è incompleta"

# 9. la catena è CIRCOLARE: il SAL torna a selezione-contesto (fonte #1)
grep -q "SAL del dominio" "$SC" \
  && ok "circolarità: il SAL che il gate scrive è la fonte #1 di selezione-contesto" \
  || ko "la catena non è circolare: il SAL non è in testa alle fonti"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
