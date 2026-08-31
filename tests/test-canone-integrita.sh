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
  "Il catalogo pattern è parte del canone" "Indice rapido dei pattern" \
  "Graphify")
# giri avversari 2026-08-28 (G1): la sezione Graphify poteva sparire dal canone
# senza che nessun test diventasse rosso
for s in "${SEZIONI[@]}"; do
  grep -q "$s" "$METODO" && ok "sezione presente: $s" || ko "sezione MANCANTE: $s"
done

# Soglia di dimensione: il canone integro è ~19KB; sotto 10KB è svuotato o decapitato
SIZE=$(wc -c < "$METODO" | tr -d ' ')
[ "$SIZE" -ge 10000 ] && ok "dimensione $SIZE bytes (sopra soglia 10000)" \
  || ko "dimensione $SIZE bytes: sotto soglia, canone svuotato?"

# Ogni pattern citato nell'INDICE deve esistere come file: un indice che punta
# nel vuoto è peggio di nessun indice. (giri avversari 2026-08-28, A3: la versione
# precedente finiva con `done | grep -q` sotto pipefail — grep -q usciva alla prima
# corrispondenza, il while prendeva SIGPIPE, la pipeline dava 141 e il ramo `|| ok`
# scattava SEMPRE: il controllo non ha mai controllato. È il pattern
# pipefail-grep-sigpipe applicato al mio stesso test. Inoltre si greppa SOLO la
# sezione indice: il resto del canone contiene token di codice in backtick —
# `--`, `node`, `vm` — che non sono pattern.)
SEZ_INDICE=$(sed -n '/## Indice rapido dei pattern/,$p' "$METODO")
RE_TOKEN='`[a-z0-9-]*`'
ROTTI=$(grep -o "$RE_TOKEN" <<<"$SEZ_INDICE" | tr -d '`' | sort -u | while read -r p; do
  [ -z "$p" ] && continue
  [ "$p" = "gas-sviluppo" ] || [ "$p" = "patterns" ] && continue
  [ -f "$HERE/patterns/$p.md" ] || echo "$p"
done)
[ -z "$ROTTI" ] && ok "tutti i pattern dell'indice esistono" || ko "l'indice cita pattern senza file: $ROTTI"

# le famiglie di difetti misurate restano popolate (G10: cancellare famiglie
# intere non faceva diventare rosso niente — il catalogo è presidiato dal numero)
FAM="$HERE/.claude/skills/gas-sviluppo/references/famiglie-difetti.md"
NFAM=$(grep -c '^- \*\*' "$FAM" 2>/dev/null || echo 0)
# il pavimento SEGUE il catalogo reale: 50 voci al 2026-08-31, pavimento 47
# (togliere 4 famiglie deve arrossire — scoperto che con 50 il vecchio 45 non prendeva)
[ "$NFAM" -ge 47 ] && ok "famiglie di difetti popolate: $NFAM voci" \
  || ko "famiglie di difetti degradate: $NFAM voci (attese >= 47)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
