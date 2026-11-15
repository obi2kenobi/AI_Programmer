#!/bin/bash
# verifica-diff.sh — la guardia "le note non sono il diff" (incidente 13/11:
# l'agente dichiarava rimosso un loop che il diff teneva ancora, e referenziava
# un simbolo non più dichiarato). Da lanciare DOPO aver applicato un diff,
# PRIMA di dichiarare la fine: la prova viene dal file, non dalle intenzioni.
#
# Uso: tools/verifica-diff.sh <file> --assenti SIMB1,SIMB2 --presenti SIMB3
#   --assenti  : simboli che NON devono più esistere nel file (es. vecchie
#                funzioni rimosse, costabili eliminate)
#   --presenti : simboli che DEVONO esistere (le nuove cure)
# Esce 0 se tutto vero, 1 con l'elenco delle menzogne altrimenti.
set -uo pipefail
FILE="${1:?uso: verifica-diff.sh <file> --assenti A,B --presenti C}"
shift
ASSENTI="" PRESENTI=""
while [ $# -gt 0 ]; do
  case "$1" in
    --assenti|--presenti)
      [ $# -ge 2 ] || { echo "$1: manca il valore" >&2; exit 2; }
      if [ "$1" = "--assenti" ]; then ASSENTI="$2"; else PRESENTI="$2"; fi
      shift 2 ;;
    *) echo "argomento sconosciuto: $1" >&2; exit 2 ;;
  esac
done
RC=0
[ -f "$FILE" ] || { echo "✗ file inesistente: $FILE"; exit 1; }
[ -n "$ASSENTI$PRESENTI" ] || { echo "uso: serve almeno un criterio non vuoto (--assenti o --presenti)" >&2; exit 2; }

# Il contratto parla di SIMBOLI, non di regex: il punto di `a.b` deve restare
# letterale. Python (prerequisito dell'hub) ci evita escape sed diversi fra
# BSD e GNU; i confini `_`/alfanumerici restano quelli originali.
contiene_simbolo() {
  python3 - "$FILE" "$1" <<'PY'
import pathlib, re, sys
testo = pathlib.Path(sys.argv[1]).read_text(errors="replace")
simbolo = sys.argv[2]
pattern = r"(?<![A-Za-z0-9_])" + re.escape(simbolo) + r"(?![A-Za-z0-9_])"
sys.exit(0 if re.search(pattern, testo) else 1)
PY
}

while IFS= read -r s; do
  [ -z "$s" ] && continue
  if contiene_simbolo "$s"; then
    echo "✗ ASSENTE-MA-PRESENTE: '$s' è ancora in $FILE (la nota diceva rimosso)"
    RC=1
  else
    echo "✓ assente come dichiarato: $s"
  fi
done < <(printf '%s\n' "$ASSENTI" | tr ',' '\n')
while IFS= read -r s; do
  [ -z "$s" ] && continue
  if contiene_simbolo "$s"; then
    echo "✓ presente come dichiarato: $s"
  else
    echo "✗ PRESENTE-MA-ASSENTE: '$s' non è in $FILE (la cura non è atterrata)"
    RC=1
  fi
done < <(printf '%s\n' "$PRESENTI" | tr ',' '\n')
exit $RC
