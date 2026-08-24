#!/bin/bash
# test-claude-md-segreto-impronta-regola.sh — feedback utente esterno (2026-08-24): il
# principio "maschera, non omettere" viveva solo in patterns/segreto-come-impronta.md,
# un pattern facoltativo — troppo critico per dipendere dal fatto che qualcuno consulti
# patterns/ di sua iniziativa. Verifica che ora sia una regola vincolante in CLAUDE.md,
# con riferimento esplicito al pattern originale (non duplicazione senza traccia).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE="$HERE/CLAUDE.md"
PATTERN="$HERE/patterns/segreto-come-impronta.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$PATTERN" ] && ok "il pattern originale esiste ancora (ancora non morta)" \
  || ko "patterns/segreto-come-impronta.md non esiste più — la regola citerebbe un'ancora morta"

grep -qi 'promoted from .patterns/segreto-come-impronta.md' "$CLAUDE" && ok "CLAUDE.md dichiara la promozione e cita la fonte" \
  || ko "CLAUDE.md non cita il pattern di origine"
grep -qi 'must not print the raw value' "$CLAUDE" && ok "vieta esplicitamente di stampare il valore grezzo" \
  || ko "non vieta la stampa del valore grezzo"
grep -qi 'must not silently omit' "$CLAUDE" && ok "vieta anche l'omissione silenziosa (non solo la stampa)" \
  || ko "non vieta l'omissione silenziosa"
grep -q 'fingerprint' "$CLAUDE" && ok "descrive il formato impronta (fingerprint · N chars)" \
  || ko "non descrive il formato di mascheramento"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
