#!/bin/bash
# test-garante-standard.sh — il garante dello standard: installa se manca, e (fase B)
# AVVERTE se il metodo installato diverge dall'hub. Nato con il dente della deriva,
# provato col morso: un metodo installato VECCHIO deve produrre l'avviso.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GARANTE="$HERE/tools/garante-standard.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$GARANTE" ] || { echo "FAIL garante-standard.sh assente"; exit 1; }
bash -n "$GARANTE" && ok "sintassi" || ko "sintassi rotta"

# caso 1: installazione esistente con metodo DIVERSO da quello dell'hub → AVVISO deriva
SB=$(mktemp -d /tmp/garante-t1.XXXXXX)
trap 'rm -rf "$SB" "$SB2"' EXIT
mkdir -p "$SB/.claude/skills/gas-sviluppo/references"
echo '{"hooks":{"SessionStart":[{"hooks":[{"command":"x"}]}]}}' > "$SB/.claude/settings.json"
echo "metodo vecchio" > "$SB/.claude/skills/gas-sviluppo/references/metodo.md"
OUT=$(cd "$SB" && bash "$GARANTE" 2>&1)
if echo "$OUT" | grep -q "DIVERGE"; then
  ok "metodo installato vecchio → avviso deriva (con il comando per aggiornare)"
  echo "$OUT" | grep -q "sync-repo" && ok "l'avviso dice COME aggiornare" || ko "avviso senza rimedio"
else
  ko "deriva del metodo NON vista — il garante e' tornato una-tantum"
fi

# caso 2: installazione esistente con metodo UGUALE → silenzio (nessun falso allarme)
SB2=$(mktemp -d /tmp/garante-t2.XXXXXX)
mkdir -p "$SB2/.claude/skills/gas-sviluppo/references"
echo '{"hooks":{"SessionStart":[{"hooks":[{"command":"x"}]}]}}' > "$SB2/.claude/settings.json"
cp "$HERE/.claude/skills/gas-sviluppo/references/metodo.md" "$SB2/.claude/skills/gas-sviluppo/references/metodo.md"
OUT2=$(cd "$SB2" && bash "$GARANTE" 2>&1)
if [ -z "$OUT2" ]; then
  ok "metodo allineato → silenzio (il garante non urla a vuoto)"
else
  ko "falso allarme su metodo allineato: $(echo "$OUT2" | head -1)"
fi

# caso 3: l'avviso NON tocca i file (diff prima/dopo) — il garante avverte, non sovrascrive
PRIMA=$(cd "$SB" && find . -type f | sort | xargs md5 2>/dev/null | md5)
cd "$SB" && bash "$GARANTE" >/dev/null 2>&1
DOPO=$(find . -type f | sort | xargs md5 2>/dev/null | md5)
cd "$HERE"
[ "$PRIMA" = "$DOPO" ] && ok "avviso senza modifiche: il garante non sovrascrive mai" \
  || ko "il garante ha MODIFICATO file esistenti (deve solo avvisare)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
