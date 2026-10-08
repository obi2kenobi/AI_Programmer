#!/bin/bash
# test-furti-giro2.sh — i banchi dei tre furti del secondo giro (2026-10-08):
# destinazioni-pulite (OpenAPPA), mutazione-diff (DeployProof), ciclo A-B
# (RiskKernel). Uno per riga di furto, prove minime e deterministiche.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d "${TMPDIR:-/tmp}/furti2.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# ── OpenAPPA: il cancello delle destinazioni ─────────────────────────────────
printf 'riga pulita\n' | bash "$HERE/tools/destinazioni-pulite.sh" pr-body >/dev/null 2>&1 \
  && ok "destinazione pulita: passa" || ko "riga pulita bloccata"
printf 'contatto: mario.rossi@azienda.it\n' | bash "$HERE/tools/destinazioni-pulite.sh" pr-body >/dev/null 2>&1 \
  && ko "email passa nel corpo PR" || ok "email: destinazione SPORCA, non si pubblica"
printf 'IBAN IT60X0542811101000000123456\n' | bash "$HERE/tools/destinazioni-pulite.sh" commit-msg >/dev/null 2>&1 \
  && ko "IBAN passa" || ok "IBAN: destinazione SPORCA"

# ── DeployProof: le sentinelle del diff ──────────────────────────────────────
R=$TMP/rep; git -C "$R" init 2>/dev/null || { mkdir -p "$R" && git -C "$R" init -q; }
cd "$R"
printf 'def uguale(a, b):\n    return a == b\n' > calc.py
printf 'from calc import uguale\nassert uguale(2, 2) and not uguale(2, 3)\nprint("verde")\n' > banco.py
git add -A && git -c user.name=t -c user.email=t@t commit -qm base
git checkout -q -b night/x
printf 'def uguale(a, b):\n    return a == b and b is not None\n' > calc.py
git add -A && git -c user.name=t -c user.email=t@t commit -qm diff
OUT=$(bash "$HERE/tools/mutazione-diff.sh" "$R" main "python3 banco.py" 2>/dev/null | tail -1)
grep -q "sentinelle: 1/1" <<<"$OUT" && ok "mutazione della riga cambiata: il banco la vede rossa (1/1)" || ko "sentinelle: $OUT"
# senza sentinella: banco che non tocca uguale()
printf 'print("altro")\n' > banco.py
OUT=$(bash "$HERE/tools/mutazione-diff.sh" "$R" main "python3 banco.py" 2>/dev/null | tail -1)
grep -q "sentinelle: 0/1" <<<"$OUT" && ok "senza banco che morde: 0/1 dichiarato (diff non presidiato)" || ko "atteso 0/1: $OUT"

# ── RiskKernel: il ciclo A-B ────────────────────────────────────────────────
ciclo_ab() {  # le ultime 4 firme (A|B|A|B) → 0 se loop
  local u="$1"
  local a b c d
  a=$(printf '%s' "$u" | cut -d'|' -f1); b=$(printf '%s' "$u" | cut -d'|' -f2)
  c=$(printf '%s' "$u" | cut -d'|' -f3); d=$(printf '%s' "$u" | cut -d'|' -f4)
  [ -n "$a" ] && [ "$a" = "$c" ] && [ "$b" = "$d" ] && [ "$a" != "$b" ]
}
ciclo_ab "read x|edit x|read x|edit x" && ok "A-B-A-B: loop dichiarato" || ko "ciclo A-B non visto"
ciclo_ab "read x|edit x|read y|edit y" && ko "sequenza sana scambiata per loop" || ok "sequenza sana: nessun loop"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
