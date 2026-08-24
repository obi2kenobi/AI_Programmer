#!/bin/bash
# test-claude-md-secret-handoff-oneshot.sh — feedback utente esterno (2026-08-24): per un
# primo login/deploy interattivo (token OAuth, clasp login) non c'era risposta diversa da
# "incollalo in chat" — proprio quello che la regola segreto-come-impronta vuole evitare.
# Verifica che CLAUDE.md ora dichiari un'alternativa concreta, in ordine di preferenza.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE="$HERE/CLAUDE.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -qi 'One-shot secret handoff' "$CLAUDE" && ok "CLAUDE.md dichiara la sezione dedicata" \
  || ko "nessuna sezione dedicata al secret handoff one-shot"
grep -qi 'not an acceptable answer' "$CLAUDE" && ok "vieta esplicitamente 'incollalo in chat' come risposta" \
  || ko "non vieta esplicitamente il paste-in-chat"
grep -qi 'run the interactive command yourself' "$CLAUDE" && ok "prima alternativa: l'agente esegue il login interattivo" \
  || ko "non propone di eseguire il login interattivo"
grep -qi 'give you only the .path.' "$CLAUDE" && ok "seconda alternativa: solo il percorso, mai il valore in chat" \
  || ko "non propone l'alternativa del percorso file"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
