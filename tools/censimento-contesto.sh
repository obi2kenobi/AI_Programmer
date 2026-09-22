#!/bin/bash
# censimento-contesto.sh — quanto pesa il nostro arredamento a ogni prompt?
#
# (Ispirazione dichiarata: everything-claude-code misura la "tassa MCP" — 200k
# di contesto che scendono a 70k con troppi tool attivi. La lezione non e' il
# numero: e' MISURARE quanto costa il proprio stesso contesto. Nessuno qui
# aveva mai pesato briefing, patti e reminder.)
#
# Misura i file che entrano (direttamente o tagliati) nel contesto di un prompt
# del turno o di una sessione, e li dichiara in byte e ~token (byte/4, ordine
# di grandezza onesto). Un file che pesa senza guadagnare si vede.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

pezzo() { # $1=etichetta $2=file $3=nota-taglio
  local bytes=0
  if [ -n "$2" ] && [ -f "$2" ]; then
    bytes=$(wc -c < "$2" | tr -d ' ')
  fi
  printf '%-38s %8s byte  ~%6s tok  %s\n' "$1" "$bytes" "$((bytes / 4))" "${3:-}"
}

echo "CENSIMENTO DEL CONTESTO — cosa entra in ogni prompt ($(date '+%F %H:%M'))"
echo "═══════════════════════════════════════════════════════════════════════"
echo "── il briefing dell'agente (caricato come system, tagliato a 4000 byte):"
pezzo "cervello-notturno.md (intero)" "$HERE/night-shift/cervello-notturno.md" "il taglio head -c 4000 scarta il resto"
pezzo "  → quello che NE PASSA" "$HERE/night-shift/cervello-notturno.md" "vedi colonna byte: se >4000, si perde coda"
echo "── il canone e i patti (reminder a ogni prompt di sessione):"
pezzo "metodo.md (canone GAS)" "$HERE/.claude/skills/gas-sviluppo/references/metodo.md"
pezzo "CLAUDE.md" "$HERE/CLAUDE.md"
echo "── il contesto fisso delle chiamate (num_ctx 4096 = ~16384 byte di soffitto):"
pezzo "  → soffitto per chiamata" "" "4096 token"
echo "── la memoria interrogabile (entra SOLO su domanda, non a ogni giro):"
pezzo "cervello/ (tutte le note)" "" "$(cat "$HERE"/cervello/*.md 2>/dev/null | wc -c | tr -d ' ') byte totali, caricati a cibarsi"
echo
echo "lettura: il briefing vive sotto i 4000 byte e sotto il ~20% del num_ctx;"
echo "il canone pesa come pesa ma entra una volta per sessione, non per prompt."
