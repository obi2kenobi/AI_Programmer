#!/bin/bash
# auditoria-conoscenza.sh — la conoscenza che INVECCHIA si audita (furto giro 8
# da Osmani «audit your agent files»: l'auto-memoria va in stantio; e da skillmem:
# learn, recall, REINFORCE, DECAY). Il nostro registro ha 59 voci e 66 pattern:
# una lezione mai piu' toccata da mesi e' ancora VERA? Nessuno lo chiedeva.
#
# Deterministico: per patterns/*.md conta i giorni dall'ultima modifica (mtime);
# una lezione vecchia NON e' colpevole (le regole buone non cambiano) — viene
# LISTATA come da rafforzare: o qualcuno la cita/ancora, o si dichiara storica.
# Uso: auditoria-conoscenza.sh [giorni-soglia=90]
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SOGLIA="${1:-90}"
ORA=$(date +%s)
VECCHIE=0; TOTALI=0
OUT=""
for f in "$HERE"/patterns/*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in README.md) continue ;; esac
  TOTALI=$((TOTALI+1))
  M=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo "$ORA")
  GIORNI=$(( (ORA - M) / 86400 ))
  if [ "$GIORNI" -ge "$SOGLIA" ]; then
    VECCHIE=$((VECCHIE+1))
    OUT="$OUT
- $(basename "$f" .md) — ferma da ${GIORNI}g"
  fi
done
echo "## L'audit della conoscenza (furto Osmani/skillmem: reinforce o decay)"
echo "Pattern censiti: $TOTALI · non toccati da almeno ${SOGLIA}g: $VECCHIE"
if [ "$VECCHIE" -gt 0 ]; then
  echo "$OUT" | head -9
  [ "$VECCHIE" -gt 9 ] && echo "- … (altre $((VECCHIE-9)) nel report completo)"
  echo "Domanda per il giorno: ognuna o e' ancora il vero (si RAFFORZA: un hook, un banco,"
  echo "una citazione nel canone) o diventa STORICA dichiarata — mai fossile silenzioso."
fi
exit 0
