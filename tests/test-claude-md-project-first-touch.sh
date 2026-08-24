#!/bin/bash
# test-claude-md-project-first-touch.sh — feedback utente esterno (2026-08-24): la promessa
# di PROJECT.md ("una sezione per progetto") non aveva un trigger vincolante su QUANDO
# aggiungere una sezione nuova, quindi restava vuota in silenzio. Verifica che CLAUDE.md §6
# ora dichiari il trigger esplicito.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE="$HERE/CLAUDE.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SEZ6=$(awk '/^## 6\./{f=1} /^## 7\./{f=0} f' "$CLAUDE")

echo "$SEZ6" | grep -qi 'first-touch trigger' && ok "§6 dichiara il trigger di primo tocco" \
  || ko "§6 non dichiara alcun trigger"
echo "$SEZ6" | grep -qi 'before the first edit or command run' && ok "il trigger scatta PRIMA della modifica, non dopo" \
  || ko "il trigger non è dichiarato come precondizione"
echo "$SEZ6" | grep -qi 'add its section' && ok "richiede esplicitamente di aggiungere la sezione" \
  || ko "non richiede di aggiungere la sezione"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
