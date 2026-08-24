#!/bin/bash
# test-design-set2-settimo-ciclo.sh — 7° ciclo, set 2 (2026-08-24): le due
# aggiunte nate dal DOGFOOD reale (design-doc DTE-vs-intrastat in SAL):
# (1) selezione-contesto ha la RICETTA DELLA DENSITÀ (quanto pesa la formula in
# un dominio — decide oracolo vs progetto, e chiude la famiglia dei pettini);
# (2) brainstorming ha la DOMANDA DI DOMINIO del corpus, prima del criterio di
# successo, col divieto del silenzio. E il design-doc reale nel SAL rispetta il
# formato (vincoli di squalifica + criteri prima + tabella + secondo ordine).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SC="$HERE/.claude/skills/selezione-contesto/SKILL.md"
BS="$HERE/.claude/skills/brainstorming/SKILL.md"
SAL="$HERE/SAL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "ricetta della densità" "$SC" && grep -qi "un oracolo per un dominio a densità" "$SC" \
  && ok "selezione-contesto: la ricetta della densità distingue oracolo da progetto" \
  || ko "selezione-contesto: ricetta di densità mancante"
grep -q "ORACOLO-DATI" "$SC" \
  && ok "selezione-contesto: senza tabella di verità la formula non nasce (diventa domanda di dominio)" \
  || ko "selezione-contesto: il punto dell'oracolo-dati manca"

grep -q "DOMANDA DI DOMINIO" "$BS" && grep -q "nessuna domanda di dominio" "$BS" \
  && ok "brainstorming: domanda di dominio prima del criterio, silenzio vietato" \
  || ko "brainstorming: domanda di dominio mancante"

grep -q "7° ciclo, Set 2/3: il flusso di progettazione dogfooddato" "$SAL" \
  && ok "il design-doc reale DTE-vs-intrastat è nel SAL" || ko "design-doc assente"
grep -q "Vincoli di squalifica: (1) nessuna formula indovinata" "$SAL" \
  && ok "il design-doc reale esercita i vincoli di squalifica" \
  || ko "squalifiche assenti nel design-doc reale"
grep -q "Effetti di secondo ordine: A senza listino" "$SAL" \
  && ok "il design-doc reale dichiara gli effetti di secondo ordine" \
  || ko "secondo ordine assente"
grep -q "Scelta: resta a Luca" "$SAL" \
  && ok "la scelta resta al proprietario (il metodo non si prevarica)" \
  || ko "scelta prevaricata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
