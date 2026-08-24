#!/bin/bash
# test-design-set2-sesto-ciclo.sh — 6° ciclo, set 2 (2026-08-24): le quattro aggiunte
# di progettazione devono restare e non scavalcarsi a vicenda: (1) design-doc dichiara
# VINCOLI DI SQUALIFICA (§1bis) PRIMA dei criteri di confronto (§2) — un'opzione morta
# non corre; (2) ogni opzione dichiara gli EFFETTI DI SECONDO ORDINE (cosa tocca
# altrove); (3) brainstorming DIVERGE (riformulazioni del problema) prima di convergere
# e seleziona il contesto con budget prima della prima domanda; (4) la skill
# selezione-contesto esiste e dichiara budget ED esclusioni. Stessa guardia delle
# regressioni design-doc precedenti: la prosa che sparisce è un metodo che regredisce.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
BS="$HERE/.claude/skills/brainstorming/SKILL.md"
SC="$HERE/.claude/skills/selezione-contesto/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# --- design-doc: squalifica prima del confronto ---
RIGA_SQ=$(grep -n "VINCOLI DI SQUALIFICA" "$DD" | head -1 | cut -d: -f1)
RIGA_CR=$(grep -n "criteri di confronto PRIMA delle opzioni" "$DD" | head -1 | cut -d: -f1)
[ -n "$RIGA_SQ" ] && [ -n "$RIGA_CR" ] && [ "$RIGA_SQ" -lt "$RIGA_CR" ] \
  && ok "design-doc: vincoli di squalifica (riga $RIGA_SQ) dichiarati prima dei criteri (riga $RIGA_CR)" \
  || ko "design-doc: squalifica assente o DOPO i criteri"
grep -qi "opzione che viola un vincolo non entra nella tabella" "$DD" \
  && ok "design-doc: l'opzione squalificata non corre (o entra solo come registrata)" \
  || ko "design-doc: la gara fra opzioni morte è ancora possibile"

# --- design-doc: effetti di secondo ordine ---
grep -q "effetti di secondo ordine" "$DD" && grep -q "cosa tocca ALTrove" "$DD" \
  && ok "design-doc: ogni opzione dichiara gli effetti di secondo ordine" \
  || ko "design-doc: effetti di secondo ordine mancanti"

# --- brainstorming: divergenza + contesto ---
grep -q "Divergere PRIMA di convergere" "$BS" \
  && ok "brainstorming: fase di divergenza (riformulazioni del problema) presente" \
  || ko "brainstorming: divergenza mancante"
grep -q "RIFORMULAZIONI" "$BS" && grep -q "non soluzioni" "$BS" \
  && ok "brainstorming: le riformulazioni sono del PROBLEMA, non soluzioni travestite" \
  || ko "brainstorming: riformulazioni non distinte dalle soluzioni"
grep -q "selezione-contesto" "$BS" \
  && ok "brainstorming: cita selezione-contesto per il giro di contesto preliminare" \
  || ko "brainstorming: nessun aggancio a selezione-contesto"

# --- selezione-contesto: esiste, con budget e esclusioni ---
[ -f "$SC" ] && ok "la skill selezione-contesto esiste" || { echo "FAIL skill assente"; exit 1; }
grep -q "budget" "$SC" | head -1 >/dev/null && grep -qi "esclusioni si scrivono" "$SC" \
  && ok "selezione-contesto: budget esplicito e esclusioni dichiarate" \
  || ko "selezione-contesto: budget o esclusioni mancanti"
grep -qi "esclusione silenziosa è un buco travestito da scelta" "$SC" \
  && ok "selezione-contesto: l'esclusione silenziosa è vietata" \
  || ko "selezione-contesto: la regola delle esclusioni non c'è"

# --- coerenza della pipeline: selezione-contesto cita le fonti nell'ordine ---
grep -q "SAL del dominio" "$SC" && grep -q "mappa dei domini" "$SC" && grep -q "oracoli" "$SC" \
  && ok "selezione-contesto: ordine fonti (SAL → pattern → mappa → oracoli → grafo)" \
  || ko "selezione-contesto: l'ordine delle fonti è incompleto"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
