#!/bin/bash
# verify-patterns.sh — le ancore dei pattern devono esistere (giro 2/10).
# Regola ereditata dal Supervisore: l'ancora muore, la voce muore. Nessuno lo verificava.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; STALE=0
for f in "$HERE"/patterns/*.md; do
  [ "$(basename "$f")" = "README.md" ] && continue
  # estrae le àncore: file:funzione o file.js:NNN
  ANCORE=$(grep -oE '[a-zA-Z_-]+\.(sh|js|py|gs|md)(:[a-zA-Z_]+|:[0-9]+)?' "$f" | sort -u | head -5)
  NOME=$(basename "$f" .md)
  if [ -z "$ANCORE" ]; then
    echo "⚠️  $NOME: nessuna àncora estratta (formato?)"
    continue
  fi
  TROVATE=0; TOTALI=0
  while IFS= read -r a; do
    TOTALI=$((TOTALI+1))
    FILE="${a%%:*}"
    [ -f "$HERE/$FILE" ] || [ -f "$HERE/night-shift/$FILE" ] && TROVATE=$((TROVATE+1)) || true
  done <<< "$ANCORE"
  ESTERNA=$(grep -c "ESTERNA" "$f" || true)
  if [ $TROVATE -ge 1 ]; then
    PASS=$((PASS+1))
  elif [ $ESTERNA -ge 1 ]; then
    echo "ℹ️  $NOME: àncora esterna (verificata al raccolto, non ri-verificabile qui)"
    PASS=$((PASS+1))
  else
    STALE=$((STALE+1))
    echo "⛔ $NOME: àncora morta (nessun file trovato fra: $ANCORE)"
  fi
done
echo ""
echo "$PASS pattern vivi, $STALE morti"
[ $STALE -eq 0 ]
