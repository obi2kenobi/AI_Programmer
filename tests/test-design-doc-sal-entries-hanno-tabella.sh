#!/bin/bash
# test-design-doc-sal-entries-hanno-tabella.sh — 5° ciclo, set 2 giro 1. La skill
# /design-doc §2 RICHIEDE che il documento persistito includa la tabella opzioni×criteri
# (già verificato in test-design-doc-tabella-persistita.sh, ma solo sulla PROSA della
# skill, non sulla realtà) — nessuna verifica controllava se le voci di design REALMENTE
# scritte in SAL.md rispettassero quella regola. Le due voci esistenti oggi la
# rispettano entrambe (verificato leggendole), ma senza questo test una terza voce futura
# senza tabella passerebbe inosservata — lo stesso principio delle guardie di
# regressione già scritte per i limiti dichiarati in docs/system.md.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SAL="$HERE/SAL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# estrae ogni voce "### <qualsiasi> — design: <titolo>" fino alla prossima intestazione
mapfile -t TITOLI < <(grep -n '^### .*— design:' "$SAL" | cut -d: -f1)

if [ "${#TITOLI[@]}" -eq 0 ]; then
  ko "nessuna voce di design trovata in SAL.md (nulla da verificare — controllare il pattern)"
else
  ok "trovate ${#TITOLI[@]} voci di design in SAL.md"
fi

for START in "${TITOLI[@]}"; do
  TITOLO=$(sed -n "${START}p" "$SAL")
  END=$(awk -v s="$START" 'NR>s && /^## /{print NR; exit}' "$SAL")
  [ -z "$END" ] && END=$(wc -l < "$SAL")
  BODY=$(sed -n "$((START+1)),${END}p" "$SAL")

  echo "$BODY" | grep -qi 'criteri dichiarat' \
    && ok "\"$TITOLO\": dichiara i criteri prima delle opzioni" \
    || ko "\"$TITOLO\": nessun criterio dichiarato trovato nel corpo"

  echo "$BODY" | grep -qE '^\| ?Opzione' \
    && ok "\"$TITOLO\": contiene la tabella opzioni×criteri richiesta da §2" \
    || ko "\"$TITOLO\": NESSUNA tabella opzioni×criteri — §2 di design-doc violato nella pratica"

  N_OPZIONI=$(echo "$BODY" | grep -cE '^\| [A-Z]\. ')
  [ "$N_OPZIONI" -ge 2 ] \
    && ok "\"$TITOLO\": almeno 2 opzioni reali confrontate ($N_OPZIONI trovate)" \
    || ko "\"$TITOLO\": meno di 2 opzioni trovate ($N_OPZIONI) — non è un confronto reale"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
