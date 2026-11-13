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
    --assenti)  ASSENTI="${2:-}";  shift 2 ;;
    --presenti) PRESENTI="${2:-}"; shift 2 ;;
    *) echo "argomento sconosciuto: $1" >&2; exit 2 ;;
  esac
done
RC=0
[ -f "$FILE" ] || { echo "✗ file inesistente: $FILE"; exit 1; }
IFS=',' read -ra A <<< "$ASSENTI"
for s in "${A[@]}"; do
  [ -z "$s" ] && continue
  if grep -qE "(^|[^A-Za-z0-9_])${s}([^A-Za-z0-9_]|$)" "$FILE"; then
    echo "✗ ASSENTE-MA-PRESENTE: '$s' è ancora in $FILE (la nota diceva rimosso)"
    RC=1
  else
    echo "✓ assente come dichiarato: $s"
  fi
done
IFS=',' read -ra P <<< "$PRESENTI"
for s in "${P[@]}"; do
  [ -z "$s" ] && continue
  if grep -qE "(^|[^A-Za-z0-9_])${s}([^A-Za-z0-9_]|$)" "$FILE"; then
    echo "✓ presente come dichiarato: $s"
  else
    echo "✗ PRESENTE-MA-ASSENTE: '$s' non è in $FILE (la cura non è atterrata)"
    RC=1
  fi
done
exit $RC
