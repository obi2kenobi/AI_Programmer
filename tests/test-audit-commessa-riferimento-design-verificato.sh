#!/bin/bash
# test-audit-commessa-riferimento-design-verificato.sh — 5° ciclo, set 2 giro 5. Il gate
# meccanico del turno notturno (night-shift.sh, verificato in
# test-night-shift-design-gate.sh) accetta qualunque testo che SOMIGLI a un riferimento
# (regex: link, "SAL.md", "issue #N", un'estensione file) — non verifica che il
# riferimento esista davvero né che un design-doc citato contenga la tabella richiesta.
# audit-commessa (pre-flight di giorno) deve chiudere quel buco: verifica che §1bis
# esista e citi sia l'apertura del riferimento sia il controllo della tabella.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
AC="$HERE/.claude/skills/audit-commessa/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q '1bis\. \*\*Il riferimento in `## Design` esiste davvero' "$AC" \
  && ok "esiste il passo §1bis sul riferimento verificato" \
  || ko "il passo §1bis non esiste"

grep -qi 'regex, non verifica\|SOMIGLI a un riferimento' "$AC" \
  && ok "§1bis spiega il limite reale del gate meccanico (regex, non verifica)" \
  || ko "§1bis non spiega perché il gate meccanico non basta"

grep -q 'tabella opzioni×criteri' "$AC" \
  && ok "§1bis richiede di verificare la tabella opzioni×criteri di un design-doc citato" \
  || ko "§1bis non verifica la tabella del design-doc citato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
