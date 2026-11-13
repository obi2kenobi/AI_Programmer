#!/bin/bash
# verifica-doc.sh (R2, documentazione viva): il diario dice il VERO?
# Uso: verifica-doc.sh <diario.md> <repo-dir>
# Verifica: ogni file .gs citato in righe di tabella esiste nella repo;
# esce 1 con l'elenco dei fantasmi. (Battesimo: InvioEmail.gs fantasma.)
set -uo pipefail
D="${1:?diario}"; R="${2:?repo}"; RC=0; N=0
for f in $(grep -oE '[A-Za-z0-9_]+\.gs' "$D" | sort -u); do
  N=$((N+1))
  if ! find "$R" -name "$f" | grep -q .; then
    echo "✗ FANTASMA: $f citato in $D ma assente in $R"; RC=1
  fi
done
[ $RC -eq 0 ] && echo "✓ $N file .gs citati: tutti reali"
exit $RC
