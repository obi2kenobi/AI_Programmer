#!/bin/bash
# mutation-tests.sh — il banco che prova I TEST, non il codice: per ogni test che
# porta il nome di un tool, il tool viene NEUTRALIZZATO (exit 0) e il test DEVE
# diventare rosso. Un test che passa col soggetto neutralizzato è teatro verde:
# verifica l'idea del codice, non il codice (i quattro teatri trovati il
# 2026-08-28: backup-config si saltava da solo, install aveva ok||ok, test-lib
# moriva nell'exit-0 del source, bootstrap-app testava solo se stesso).
#
# Uso: bash tools/mutation-tests.sh   (esce 1 al primo teatro trovato)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"

# il banco muta file e li ripristina con cp: si parte da albero pulito, così un
# crash non lascia un tool neutralizzato nel repo (la lezione degli avversari)
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "⛔ albero sporco: committa prima di mutare" >&2; exit 2
fi
trap 'exit 1' INT TERM

TENGONO=0; TEATRI=0
for t in tests/test-*.sh; do
  base=$(basename "$t" .sh); base=${base#test-}
  tool=""
  for cand in tools/*.py tools/*.sh night-shift/*.sh; do
    nb=$(basename "$cand"); nb=${nb%.*}; nb=$(echo "$nb" | tr '_' '-')
    if [ "$nb" = "$base" ]; then tool="$cand"; break; fi
  done
  [ -z "$tool" ] && continue
  cp "$tool" /tmp/mutation-backup.$$ || continue
  case "$tool" in
    *.py) printf 'import sys\nsys.exit(0)\n' > "$tool" ;;
    *.sh) printf '#!/bin/bash\nexit 0\n' > "$tool"; chmod +x "$tool" ;;
  esac
  if bash "$t" >/dev/null 2>&1; then
    TEATRI=$((TEATRI+1))
    echo "TEATRO: $(basename "$t") passa con $(basename "$tool") neutralizzato — non verifica il codice"
  else
    TENGONO=$((TENGONO+1))
  fi
  cp "/tmp/mutation-backup.$$" "$tool"; chmod +x "$tool" 2>/dev/null
done
rm -f "/tmp/mutation-backup.$$"

echo ""
echo "VERDETTO: $TENGONO test reagiscono alla mutazione, $TEATRI teatri verdi"
[ "$TEATRI" -eq 0 ]
