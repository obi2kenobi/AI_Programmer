#!/bin/bash
# test-bc-map.sh — bc_map.py come COMANDO (giro 22 dell'analisi profonda, 2026-09-20).
# Il tool aveva un solo banco (tests/test-bc-map-leggi-curati.sh) sul merge delle colonne
# curate: la riga di comando — uso, credenziali assenti, rete giu' — non era mai provata, e
# la mutazione non lo vedeva (nessun test col suo nome). A rete giu' usciva URLError nudo
# (D33): il docstring del fratello bc_tipi_metadata promette «morte loud, non traceback nudo».
# Nessuna rete vera: 127.0.0.1:1 rifiuta all'istante.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/bc_map.py"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

OUT=$(cd "$TMP" && python3 "$TOOL" 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "^Uso:" <<<"$OUT" && ok "senza argomenti: uso, rc $RC" || ko "senza argomenti: rc $RC — $OUT"

OUT=$(cd "$TMP" && BC_CRED_FILE="$TMP/nonesiste" python3 "$TOOL" Servizio 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "credenziali BC assenti" <<<"$OUT" && ! grep -q Traceback <<<"$OUT" \
  && ok "credenziali assenti: dichiarato, rc $RC" || ko "credenziali assenti: rc $RC — $(tail -1 <<<"$OUT")"

printf '{"client_id": "x", "client_secret": "x", "scope": "x", "token_url": "http://127.0.0.1:1/t", "base_url": "http://127.0.0.1:1/b"}\n' > "$TMP/cred.json"
OUT=$(cd "$TMP" && BC_CRED_FILE="$TMP/cred.json" timeout 30 python3 "$TOOL" Servizio 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -q Traceback <<<"$OUT" && grep -q "irraggiungibile (127.0.0.1:1)" <<<"$OUT" \
  && ok "rete giu' (D33): errore dichiarato con host e ragione, nessun traceback" \
  || ko "rete giu' (D33): rc $RC, traceback=$(grep -c Traceback <<<"$OUT") — $(tail -1 <<<"$OUT" | cut -c1-90)"
grep -q "/t" <<<"$OUT" && ko "l'URL intero del token e' finito nell'output (porta il tenant)" || ok "nell'errore c'e' solo l'host, non l'URL del token"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
