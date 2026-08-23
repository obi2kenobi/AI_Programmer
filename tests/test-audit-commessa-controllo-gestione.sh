#!/bin/bash
# test-audit-commessa-controllo-gestione.sh — 4° ciclo, SET 1 giro 9. audit-commessa fa
# il pre-flight serale sulle commesse in coda (verifica assunzioni sul codice PRIMA che
# la notte le incontri) e già aveva una lente dedicata per Business Central (§2) — ma
# nessuna per le commesse che calcolano una cifra contabile/gestionale, esattamente il
# tipo di commessa che la nuova skill controllo-gestione (giro 1) rende possibile. Senza
# questa lente, una commessa potrebbe citare una formula "plausibile" mai verificata sul
# codice e l'audit non se ne accorgerebbe. Verifica che la lente §2bis esista e sia
# raggiunta dal passo numerato in §1.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
AC="$HERE/.claude/skills/audit-commessa/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q '## 2bis. Lente controllo-gestione' "$AC" \
  && ok "esiste la lente §2bis controllo-gestione" \
  || ko "la lente §2bis non esiste"

grep -q '(§2bis)' "$AC" \
  && ok "il passo numerato in §1 rimanda alla lente §2bis (non solo prosa isolata)" \
  || ko "nessun passo numerato rimanda a §2bis — citazione senza presidio"

grep -q 'oracolo' "$AC" \
  && ok "la lente ricorda la regola centrale (oracolo, non formula a memoria)" \
  || ko "la lente non ricorda la regola dell'oracolo"

grep -q 'controllo-gestione' "$AC" \
  && ok "audit-commessa cita esplicitamente la skill controllo-gestione" \
  || ko "audit-commessa non cita controllo-gestione"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
