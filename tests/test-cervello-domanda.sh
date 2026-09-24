#!/bin/bash
# test-cervello-domanda.sh — l'archeologia del secondo cervello giudica le citazioni che il modello
# scrive (Q30, 2026-09-23, notte dei giri). Il contesto dato al modello sono SOLO righe che contengono
# il termine: una citazione fedele cade su una riga col termine. Prima valeva qualunque riga ESISTENTE
# — «E-002 … (CLAUDE.md:1)», la riga del titolo di CLAUDE.md, contava «verificata» — e una risposta
# senza nessuna citazione usciva 0 con «verificate: 0, rotte: 0»: verde senza verdetto.
# Il modello e' un curl finto che risponde come Ollama (nessuna rete, nessun modello).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
command -v jq >/dev/null 2>&1 || { echo "jq assente, salto (dichiarato)"; exit 0; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/curl" <<'EOF'
#!/bin/bash
jq -cn --rawfile c "$RISPOSTA_FINTA" '{message:{content:$c}}'
EOF
chmod +x "$TMP/curl"
chiedi() { printf '%s' "$1" > "$TMP/risposta"; RISPOSTA_FINTA="$TMP/risposta" PATH="$TMP:$PATH" bash "$HERE/tools/cervello-domanda.sh" archeologia E-002 >"$TMP/out" 2>&1; echo $?; }

RIGA_VERA=$(grep -n 'E-002' "$HERE/docs/errori/REGISTRO.md" | head -1 | cut -d: -f1)
RC=$(chiedi "E-002 nasce dai falsi positivi SIGPIPE (docs/errori/REGISTRO.md:$RIGA_VERA).")
[ "$RC" -eq 0 ] && ok "citazione pertinente (la riga contiene il termine): rc 0" || ko "citazione pertinente rifiutata: rc $RC — $(tail -2 "$TMP/out")"
RC=$(chiedi "E-002 nasce per caso, senza fonti.")
[ "$RC" -ne 0 ] && grep -qi "nessuna citazione" "$TMP/out" && ok "risposta senza citazioni: rc $RC, detta non ancorata" \
  || ko "risposta senza citazioni accettata (rc $RC): $(tail -1 "$TMP/out")"
RC=$(chiedi "E-002 e' descritto qui (CLAUDE.md:1).")
[ "$RC" -ne 0 ] && grep -q "CLAUDE.md:1" "$TMP/out" && ok "citazione di una riga che non parla del termine: rifiutata (rc $RC)" \
  || ko "citazione estranea contata verificata (rc $RC): $(tail -1 "$TMP/out")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
