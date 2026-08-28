#!/bin/bash
# test-project-md-percorsi-citati.sh — 2026-08-24, report dal campo (F4): PROJECT.md
# citava CATALOGO_ENDPOINT_BC.md che non esiste da nessuna parte dell'hub — pattern
# citazione-non-presidio dentro il documento che OGNI progetto eredita. Ogni percorso
# citato in PROJECT.md deve esistere nell'hub OPPURE la riga che lo cita dichiara che
# vive altrove ("vive nel" / "repo del cliente" / "non vive in questo hub").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PM="$HERE/PROJECT.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# due bug reali (revisione 14 lenti, 2026-08-28), non uno solo:
# 1) la regex copriva solo percorsi con un'estensione da una lista fissa
#    (.md/.sh/.py/.js/.json/.csv) — un'intera sezione di PROJECT.md (§Motore) citava
#    percorsi SENZA estensione (`app/engine`, `docs/47`) o con estensioni non in lista
#    (`.php`, `last_dump.txt`) e passava indisturbata. Due passate ora: 1) percorsi con
#    estensione nota (più estensioni), 2) percorsi senza estensione ma con almeno una
#    "/" (directory-like, es. `app/engine`).
# 2) PIÙ GRAVE, preesistente dalla nascita del test (2026-08-24): `sed 's/://;...'`
#    rimuoveva il PRIMO due-punti — esattamente quello che `grep -n` inserisce fra
#    numero di riga e match — lasciando "55docs/bc/README.md" senza separatore.
#    `awk -F: '{print $1":"$2}'` su una stringa senza due-punti stampa tutto in $1 e un
#    due-punti finale vuoto ("55docs/bc/README.md:"): `riga_num_percorso` finiva sempre
#    con `percorso=""` (vuoto) per OGNI riga — `[ -e "$HERE/" ]` è sempre vero (la
#    directory radice esiste), quindi il test non ha MAI controllato un percorso vero
#    dalla sua creazione. Verificato dal vivo isolando la pipeline originale: produce
#    "3CLAUDE.md:" invece di "3:CLAUDE.md" per ogni riga. Il fix rimuove solo i
#    backtick, non tocca il due-punti che grep -n ha già messo al posto giusto.
MANCANTI=0
while IFS= read -r riga_num_percorso; do
  riga="${riga_num_percorso%%:*}"
  percorso="${riga_num_percorso#*:}"
  [ -e "$HERE/$percorso" ] && continue
  riga_testo=$(sed -n "${riga}p" "$PM")
  echo "$riga_testo" | grep -qiE "vive nel|repo del cliente|non vive in questo hub|vive in .*repo" \
    || { echo "   citato ma assente e non dichiarato esterno: $percorso (riga $riga)"; MANCANTI=$((MANCANTI+1)); }
done < <( { grep -noE '`[A-Za-z0-9_./-]+\.(md|sh|py|js|json|csv|php|txt)`' "$PM"
            grep -noE '`[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+/?`' "$PM"
          } | sed 's/`//g' | sort -u -t: -k2 )

[ "$MANCANTI" -eq 0 ] \
  && ok "ogni percorso citato in PROJECT.md esiste o dichiara di vivere altrove" \
  || ko "$MANCANTI percorso/i citato/i senza presidio in PROJECT.md"

[ -f "$HERE/docs/bc/CATALOGO_ENDPOINT_BC.md" ] \
  && ok "il catalogo endpoint vive ORA nell'hub (F4 chiuso davvero: il riferimento risolve)" \
  || ko "il catalogo è tornato assente dall'hub"
grep -q "CATALOGO_ENDPOINT_BC.md" "$PM" \
  && ok "PROJECT.md cita il catalogo col percorso hub" \
  || ko "il riferimento al catalogo è sparito da PROJECT.md"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
