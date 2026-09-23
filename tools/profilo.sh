#!/bin/bash
# profilo.sh — carica il profilo del turno (una dichiarazione, zero default
# sparsi). Ogni chiave dichiarata diventa una variabile d'ambiente per il ciclo;
# le chiavi mancanti restano ai default del codice (dichiarati come fallback).
#
# Uso: source tools/profilo.sh [nome-profilo]   (default: notturno)
# Stampa: "profilo: N chiavi caricate da <file>" su stderr
set -uo pipefail
NOME="${1:-notturno}"
# ${BASH_SOURCE:-$0}: sourced da bash nel turno, eseguito da zsh nei test
HERE="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
FILE="$HERE/profiles/$NOME.conf"
N=0
if [ -f "$FILE" ]; then
  while IFS='=' read -r k v; do
    case "$k" in \#*|"") continue ;; esac
    case "$k" in *[!A-Z_0-9]*) continue ;; esac  # solo chiavi maiuscole valide
    [ -z "$v" ] && continue
    export "$k=$v"
    N=$((N+1))
  done < "$FILE"
fi
echo "profilo: $N chiavi caricate da profiles/$NOME.conf" >&2
