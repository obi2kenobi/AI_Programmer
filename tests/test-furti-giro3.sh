#!/bin/bash
# test-furti-giro3.sh — i banchi del terzo giro di furti (2026-10-08):
# canone selettivo (agent-os), giudice misurato (jev-lab), promemoria TDD
# (claude-night-market).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
source "$HERE/night-shift/lib.sh"
F=$(mktemp -d); git -C "$F" init -q

# ── agent-os: canone SELETTIVO per bersaglio ─────────────────────────────────
printf 'specialista-logistica\n' > "$F/.git/ruoli-attivi"
# bersaglio magazzino, budget STRETTO: la sezione magazzino deve sopravvivere
# piu' della media (densita' di pertinenza maggiore della cieca)
CIECO=$(canone_ruoli "$F" 1200 2)
SEL=$(canone_ruoli "$F" 1200 2 "src/Magazzino.gs")
D_CIECO=$(printf '%s' "$CIECO" | grep -iocE 'magazzin|giacenz|moviment' || true)
D_SEL=$(printf '%s' "$SEL" | grep -iocE 'magazzin|giacenz|moviment' || true)
L_CIECO=$(printf '%s' "$CIECO" | wc -c | tr -d ' '); L_SEL=$(printf '%s' "$SEL" | wc -c | tr -d ' ')
[ "${D_SEL:-0}" -gt 0 ] && [ "$(( D_SEL * 1000 / (L_SEL+1) ))" -ge "$(( D_CIECO * 1000 / (L_CIECO+1) ))" ] \
  && ok "canone selettivo: bersaglio magazzino → densita' logistica non inferiore alla cieca ($D_SEL/$L_SEL vs $D_CIECO/$L_CIECO)" \
  || ko "selettivo peggiora la pertinenza: $D_SEL/$L_SEL vs $D_CIECO/$L_CIECO"
# senza bersaglio: comportamento invariato (il risolutore resta cieco e contento)
[ "$(canone_ruoli "$F" 1200 2 | wc -c | tr -d ' ')" = "$L_CIECO" ] \
  && ok "senza bersaglio il canone non cambia (retrocompatibile)" || ko "il canone cieco e' cambiato"

# ── jev-lab: il giudice misurato ────────────────────────────────────────────
OUT=$(bash "$HERE/tools/consenso-giudice.sh" 2>/dev/null)
grep -q "delibere del censore nel log:" <<<"$OUT" && grep -q "esiti umani registrati" <<<"$OUT" \
  && ok "il consenso dichiara i due numeri (delibere vs esiti)" || ko "output mancante: $OUT"
grep -qE "NON e' ancora misurabile|concordanza" <<<"$OUT" \
  && ok "dice se il giudice e' misurabile (oggi no: esiti pochi — detto forte)" || ko "non dichiara la misurabilita'"

# ── claude-night-market: promemoria TDD nel pre-commit ──────────────────────
grep -q "9ter" "$HERE/tools/pre-commit.sh" && grep -q "senza banchi toccati" "$HERE/tools/pre-commit.sh" \
  && ok "il pre-commit porta il promemorio codice-senza-banchi (9ter, mai blocco)" \
  || ko "il blocco 9ter manca"
grep -qE "if ! staged" "$HERE/tools/pre-commit.sh" && ok "il promemorio guarda gli STAGED (non il working tree)" || ko "non guarda gli staged"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
