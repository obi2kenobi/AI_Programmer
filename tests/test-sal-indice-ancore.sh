#!/bin/bash
# test-sal-indice-ancore.sh — banco di regressione nato dalla revisione "L'Hub Allo
# Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in tools/sal-indice.sh, il
# generatore di ancore ([^a-z0-9]+) non traslitterava le lettere accentate italiane —
# "città" generava il link "#citt" invece di "#citt%C3%A0"/"#città", non corrispondente
# all'ancora reale che GitHub assegna allo stesso heading. Difetto ricorrente in un diario
# scritto in italiano (città, già, così, perché, più...). Nessun test esisteva.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tools"
cp "$HERE/tools/sal-indice.sh" "$TMP/tools/"
printf '# Titolo\n\nintro\n\n### Terzo giro: nuova funzionalità\n\ncontenuto\n\n### Perché è così\n\naltro\n' > "$TMP/SAL.md"

OUT=$(bash "$TMP/tools/sal-indice.sh" 2>&1)
echo "$OUT" | grep -q "indice rigenerato: 2 voci" \
  && ok "indice rigenerato con 2 voci" \
  || ko "rigenerazione indice fallita: $OUT"

grep -q '\[Terzo giro: nuova funzionalità\](#terzo-giro-nuova-funzionalità)' "$TMP/SAL.md" \
  && ok "ancora con 'à' preservata (non 'terzo-giro-nuova-funzionalit')" \
  || ko "ancora con lettera accentata rotta — riga: $(grep 'Terzo giro' "$TMP/SAL.md")"

grep -q '\[Perché è così\](#perché-è-così)' "$TMP/SAL.md" \
  && ok "ancora con 'é'/'è'/'ì' preservate" \
  || ko "ancora con più accenti rotta — riga: $(grep 'Perché' "$TMP/SAL.md")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
