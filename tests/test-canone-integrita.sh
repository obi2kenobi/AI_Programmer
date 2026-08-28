#!/bin/bash
# test-canone-integrita.sh — scoperto il 2026-08-28: uno script di manutenzione ha
# svuotato metodo.md (314 righe → 9) con open(path,'w') prima di un errore, e la
# suite intera è rimasta verde: nessun test guardava il CONTENUTO del canone, solo
# la sua esistenza. Un canone svuotato è il danno peggiore che questo repo può
# subire in silenzio, perché tutto il resto (agenti, hook, propagazione) continua
# a puntare a un file vuoto. Questo test fallisce se una delle sezioni portanti
# sparisce o se il file si accorcia oltre soglia.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
METODO="$HERE/.claude/skills/gas-sviluppo/references/metodo.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$METODO" ] && ok "metodo.md esiste" || { ko "metodo.md assente"; echo "0 0"; exit 1; }

# Sezioni portanti: se una sparisce, il canone è stato svuotato o degradato
SEZIONI=("Cosa sei" "I quattro verbi" "L'ordine (ogni riga da una volta invertita)" \
  "Vincoli trasversali" "L'onore del NON VERIFICATO" "Il ripasso finale" \
  "Misura la deriva" "Le assunzioni implicite si verificano" \
  "Il catalogo pattern è parte del canone" "Indice rapido dei pattern")
for s in "${SEZIONI[@]}"; do
  grep -q "$s" "$METODO" && ok "sezione presente: $s" || ko "sezione MANCANTE: $s"
done

# Soglia di dimensione: il canone integro è ~19KB; sotto 10KB è svuotato o decapitato
SIZE=$(wc -c < "$METODO" | tr -d ' ')
[ "$SIZE" -ge 10000 ] && ok "dimensione $SIZE bytes (sopra soglia 10000)" \
  || ko "dimensione $SIZE bytes: sotto soglia, canone svuotato?"

# Ogni pattern citato nell'indice deve esistere come file: un indice che punta
# nel vuoto è peggio di nessun indice
grep -o '`[a-z0-9-]*`' "$METODO" | tr -d '`' | sort -u | while read -r p; do
  case "$p" in
    gas-sviluppo|patterns) continue ;;
  esac
  [ -f "$HERE/patterns/$p.md" ] || echo "INDICE-ROTTO: $p"
done | grep -q "INDICE-ROTTO" && ko "l'indice cita pattern senza file" || ok "tutti i pattern dell'indice esistono"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
