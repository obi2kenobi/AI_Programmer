#!/bin/bash
# test-debiti-riapertura.sh — il settimo patto ha il suo canarino (regola dell'antivirus):
# un DEBITI sintetico con le tre classi (dominio / risolvibile / saldato) deve uscire
# contato e classificato GIUSTO. Un classificatore non provato e' un'opinione in uniforme.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/debiti-riapertura.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

SB=$(mktemp -d /tmp/debiti-t.XXXXXX); trap 'rm -rf "$SB"' EXIT
cat > "$SB/DEBITI.md" <<'FIN'
# DEBITI
## Da decidere col dominio (2026-01-01)
Va chiesto a Luca quale soglia usare per lo sconto. Decide il proprietario.
## Lavoro tecnico rimandabile (2026-01-01)
Refactor della funzione X: si può fare da soli.
## GIÀ SALDATO
| 2026-01-01 ✅ SALDATO | cosa vecchia | perché | come |
FIN
OUT=$(bash "$TOOL" "$SB" 2>&1)
echo "$OUT" | grep -q "APERTI: 2 — di DOMINIO: 1" && ok "conta 2 aperti, 1 di dominio (il saldato escluso)" || ko "conto sbagliato: $(echo "$OUT" | sed -n 2p)"
echo "$OUT" | grep -q "D1. Da decidere col dominio" && ok "il debito di dominio diventa DOMANDA singola (D1)" || ko "dominio non fra le domande"
echo "$OUT" | grep -q "R1. Lavoro tecnico" && ok "il risolvibile finisce in DA FARE SUBITO" || ko "risolvibile non elencato"
OUT0=$(bash "$TOOL" "$SB" >/dev/null 2>&1; echo $?)
[ "$OUT0" = "0" ] && ok "esce 0: informa e non blocca (la pressione e' la visibilita')" || ko "esce $OUT0"
# senza DEBITI.md: dichiarato, non muto (sesto patto)
SB2=$(mktemp -d /tmp/debiti-t2.XXXXXX)
OUT2=$(bash "$TOOL" "$SB2" 2>&1)
echo "$OUT2" | grep -q "nessun DEBITI.md: niente da bruciare (dichiarato" && ok "senza debiti lo DICE (mai muto)" || ko "silenzio senza DEBITI.md"
rm -rf "$SB2"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
