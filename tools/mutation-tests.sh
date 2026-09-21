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

# (2026-09-21, seconda troncatura di giri-ignoranti.sh, 283 righe → 2): il cp di
# ripristino non era atomico ne' protetto — un kill a metà copia lasciava il tool
# troncato a mano a mano che i byte arrivavano. Due cure:
#   1. OGNI scrittura passa da file temporaneo + mv (rename atomico): un kill
#      lascia il file VECCHIO o NUOVO, mai a metà;
#   2. trap su INT/TERM/EXIT che ripristina la mutazione viva.
# Un SIGKILL sfonda anche questo, ma ciò che resta è un tool NEUTRALIZZATO (due
# righe piene, visibili al git diff, e l'albero sporco blocca il giro dopo) —
# mai più il silenzio di un file monco che nessuno vede.
MUTATO=""; BACKUP=""
ripristina() {
  if [ -n "$MUTATO" ] && [ -f "$BACKUP" ]; then
    cp "$BACKUP" "${MUTATO}.rest.$$" 2>/dev/null \
      && chmod +x "${MUTATO}.rest.$$" 2>/dev/null \
      && mv -f "${MUTATO}.rest.$$" "$MUTATO" 2>/dev/null
  fi
  [ -n "$BACKUP" ] && rm -f "$BACKUP" 2>/dev/null
  MUTATO=""; BACKUP=""
}
trap ripristina INT TERM EXIT

TENGONO=0; TEATRI=0
for t in tests/test-*.sh; do
  base=$(basename "$t" .sh); base=${base#test-}
  tool=""
  for cand in tools/*.py tools/*.sh night-shift/*.sh; do
    nb=$(basename "$cand"); nb=${nb%.*}; nb=$(echo "$nb" | tr '_' '-')
    if [ "$nb" = "$base" ]; then tool="$cand"; break; fi
  done
  [ -z "$tool" ] && continue
  BACKUP=$(mktemp /tmp/mutation-backup.XXXXXX) || continue
  cp "$tool" "$BACKUP" || { BACKUP=""; continue; }
  MUTATO="$tool"
  case "$tool" in
    *.py) printf 'import sys\nsys.exit(0)\n' > "${tool}.mut.$$" && mv -f "${tool}.mut.$$" "$tool" ;;
    *.sh) printf '#!/bin/bash\nexit 0\n' > "${tool}.mut.$$" && chmod +x "${tool}.mut.$$" && mv -f "${tool}.mut.$$" "$tool" ;;
  esac
  if bash "$t" >/dev/null 2>&1; then
    TEATRI=$((TEATRI+1))
    echo "TEATRO: $(basename "$t") passa con $(basename "$tool") neutralizzato — non verifica il codice"
  else
    TENGONO=$((TENGONO+1))
  fi
  ripristina
done

echo ""
echo "VERDETTO: $TENGONO test reagiscono alla mutazione, $TEATRI teatri verdi"
[ "$TEATRI" -eq 0 ]
