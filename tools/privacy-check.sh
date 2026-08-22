#!/bin/bash
# privacy-check.sh — il hub è PUBBLICO: nessun nome di repo privata nei file versionati.
# La chiave (night-shift/repos.key) è locale e gitignored: questo check la usa come lista
# nera e FALLISCE se un nome compare nei file committati. Pattern: citazione-non-presidio.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
KEY="$HERE/night-shift/repos.key"
[ -f "$KEY" ] || { echo "privacy-check: manca la chiave locale (repos.key) — niente da controllare"; exit 0; }
RC=0
while IFS='=' read -r code name; do
  case "$code" in \#*|"") continue ;; esac
  base="${name##*/}"
  HITS=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -F "$base" 2>/dev/null) | grep -v "repos.key" || true)
  HITS2=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -F "$name" 2>/dev/null) | grep -v "repos.key" || true)
  ALL=$(printf '%s\n%s\n' "$HITS" "$HITS2" | grep -v '^$' | sort -u || true)
  if [ -n "$ALL" ]; then
    echo "⛔ NOME PRIVATO NEL REPO PUBBLICO ($base) in:" >&2
    echo "$ALL" | head -8 >&2
    RC=1
  fi
done < "$KEY"
# v2 (giro 4/10): anche PERSONE e TERMINI riservati — chiavi PERSONA=x / TERMINI=a,b,c
# nella stessa repos.key (locale, gitignored). La privacy non è solo il nome delle repo.
while IFS='=' read -r chiave valore; do
  case "$chiave" in PERSONA|TERMINI) ;; *) continue ;; esac
  IFS=',' read -ra TERMINI <<<"$valore"
  for t in "${TERMINI[@]}"; do
    tt=$(echo "$t" | xargs)
    [ -z "$tt" ] && continue
    H=$( (cd "$HERE" && git ls-files -z | xargs -0 grep -l -F "$tt" 2>/dev/null) | grep -v "repos.key" || true)
    if [ -n "$H" ]; then
      echo "⛔ TERMINE PRIVATO NEL REPO PUBBLICO ($tt) in:" >&2
      echo "$H" | head -8 >&2
      RC=1
    fi
  done
done < "$KEY"
[ $RC -eq 0 ] && echo "privacy-check: pulito"
exit $RC
