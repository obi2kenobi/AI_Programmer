#!/bin/bash
# mappa-test.sh — la mappa test→codice (furto da Martin Fowler / Test Impact
# Analysis): per ogni banco del repo, registra quali file sorgente tocca.
# La mappa vive in .git/test-mappa (locale, non tracciata): lookup istantaneo.
# SPOSA: gira ogni banco da solo, guarda i require/import che risolve, e scrive
# «file-sorgente → lista-di-test». Se un banco non si puo' mappare, dichiara.
set -uo pipefail
DIR="${1:?uso: mappa-test.sh <dir-repo>}"
cd "$DIR" || exit 2
MAPPA="$(git rev-parse --absolute-git-dir 2>/dev/null || echo .git)/test-mappa"
> "$MAPPA"
N_MAPPATI=0; N_SALTATI=0
for banco in tests/test-*.sh tests/banco-*.js tests/banco-*.sh; do
  [ -f "$banco" ] || continue
  # i file sorgente che il banco tocca: i require/import nei .js, i bash nei .sh
  FILES=$(grep -oE "require\(['\"]\.\./[^'\"]+['\"]\)|source .*\.sh|\. .*\.sh|bash .*tools/[a-z-]+\.sh|bash .*lib\.sh|\.\./tools/[a-z-]+\.sh" "$banco" 2>/dev/null 2>/dev/null \
    | sed -e "s/require(['\"]//" -e "s/['\"])$//" -e "s|^source ||" -e "s|^\. ||" \
    | sort -u | head -20)
  if [ -n "$FILES" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      # normalizza il percorso relativo al repo
      case "$f" in ../*) f="${f#../}" ;; esac
      echo "$f $banco" >> "$MAPPA"
    done <<<"$FILES"
    N_MAPPATI=$((N_MAPPATI+1))
  else
    N_SALTATI=$((N_SALTATI+1))
  fi
done
# dedup e ordina
sort -u "$MAPPA" > "$MAPPA.tmp" && mv "$MAPPA.tmp" "$MAPPA"
echo "MAPPA: $N_MAPPATI banchi mappati, $N_SALTATI saltati (dichiarati), $(grep -c . "$MAPPA") righe in $MAPPA"
