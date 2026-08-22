#!/bin/bash
# test-onboard-patterns-propagation.sh — set 3 giro 4: stesso gap del giro 3 ma per
# l'onboarding di repo esistenti, con lo stesso merge prudente per-file usato per le skill.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'if \[ ! -f "\$WORK/patterns/\$pattern_name" \]' "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh contiene la logica di merge per-pattern (mai sovrascrive)" \
  || ko "logica di merge pattern non trovata in onboard-repo.sh"

merge_patterns() {
  local work="$1" aggiunti=0
  mkdir -p "$work/patterns"
  for pattern_file in "$HERE"/patterns/*.md; do
    local pattern_name; pattern_name="$(basename "$pattern_file")"
    if [ ! -f "$work/patterns/$pattern_name" ]; then
      cp "$pattern_file" "$work/patterns/$pattern_name"
      aggiunti=$((aggiunti+1))
    fi
  done
  echo "$aggiunti"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
N_HUB=$(find "$HERE/patterns" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')

WORK1="$TMP/repo-vuota"
N1=$(merge_patterns "$WORK1")
[ "$N1" -eq "$N_HUB" ] && ok "repo senza pattern: tutti i $N_HUB arrivano" \
  || ko "repo vuota: arrivati $N1 su $N_HUB"

WORK2="$TMP/repo-con-personalizzazione"
mkdir -p "$WORK2/patterns"
echo "PERSONALIZZATO DAL PROGETTO" > "$WORK2/patterns/jq-slurp.md"
N2=$(merge_patterns "$WORK2")
[ "$N2" -eq "$((N_HUB-1))" ] && ok "repo con jq-slurp.md personalizzato: arrivano solo gli altri $((N_HUB-1))" \
  || ko "conteggio sbagliato: arrivati $N2, attesi $((N_HUB-1))"
[ "$(cat "$WORK2/patterns/jq-slurp.md")" = "PERSONALIZZATO DAL PROGETTO" ] \
  && ok "il pattern personalizzato NON è stato sovrascritto" \
  || ko "il pattern personalizzato è stato sovrascritto (bug di merge)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
