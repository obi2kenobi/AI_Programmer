#!/bin/bash
# claude-md-satellite.sh — il CLAUDE.md che si installa in una repo satellite: quello dell'hub
# SENZA i blocchi del solo hub (decisione di Luca, D8 2026-09-23: «a» — un file solo, sezioni del
# solo hub marcate, tolte da chi copia). Nato dal report BusinessPlan: la regola «repo pubblico»
# copiata in una repo privata era dannosa, e il 77% dei riferimenti pendenti nel cliente veniva
# da regole che puntavano a file del solo hub (night-shift/, llm/, docs/system.md, loops/).
#
# Uso: tools/claude-md-satellite.sh [CLAUDE.md dell'hub]   → stdout
# Blocchi: dalla riga `<!-- solo-hub -->` alla riga `<!-- /solo-hub -->` (commenti HTML: il
# modello non li vede — anche nell'hub i marcatori non costano contesto).
# Marcatori sbilanciati o annidati: esce 1 e NON stampa niente — mai un CLAUDE.md a meta'.
# Usato da: tools/sync-repo.sh, tools/bootstrap-app.sh, tools/garante-standard.sh,
# night-shift/morning-gate.sh (il confronto di deriva si fa con la versione satellite).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$HERE/CLAUDE.md}"
[ -f "$SRC" ] || { echo "claude-md-satellite: $SRC assente" >&2; exit 1; }
# (2026-09-23, notte dei giri): con uno spazio finale o un CRLF sulla riga del marcatore la regex non
# combaciava e il blocco solo-hub arrivava ai satelliti, rc 0. Ora la riga si confronta ripulita, e
# un commento che nomina solo-hub senza essere un marcatore esatto e' un errore, non un testo.
OUT=$(awk '
  { l = $0; sub(/[ \t\r]+$/, "", l) }
  l == "<!-- solo-hub -->"  { if (dentro) { print "annidato alla riga " NR > "/dev/stderr"; exit 3 } dentro=1; n++; next }
  l == "<!-- /solo-hub -->" { if (!dentro) { print "chiusura senza apertura alla riga " NR > "/dev/stderr"; exit 3 } dentro=0; next }
  l ~ /<!--.*solo-hub/      { print "marcatore solo-hub non esatto alla riga " NR ": " l > "/dev/stderr"; exit 3 }
  !dentro { print }
  END { if (dentro) { print "blocco aperto e mai chiuso" > "/dev/stderr"; exit 3 } }
' "$SRC") || { echo "claude-md-satellite: marcatori solo-hub sbilanciati in $SRC — nessuna uscita" >&2; exit 1; }
printf '%s\n' "$OUT"
