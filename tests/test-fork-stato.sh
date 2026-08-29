#!/bin/bash
# test-fork-stato.sh — la misura della deriva fra copie sotto prova (skill
# allineamento-fork, mossa M3). Contratti: copie identiche → ALLINEATE/exit 0;
# copia divergente → DIVERGENTI/exit 1 CON la matrice e il verdetto M4; copia
# inesistente → uso/exit 2; e l'impronta è NORMALIZZATA (spazi finali e righe
# vuote non contano come deriva: la deriva che conta è di contenuto).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/fork-stato.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || ko "sintassi rotta"

SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/vivo" "$SB/fork" "$SB/vecchia"
cat > "$SB/vivo/Codice.js" <<'J'
function main() { return calcolo(10); }
function calcolo(n) { return n * 3; }
J
cp "$SB/vivo/Codice.js" "$SB/fork/Codice.js"
cp "$SB/vivo/Codice.js" "$SB/vecchia/Codice.js"

# identiche → 0
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" 2>&1); RC=$?
[ $RC -eq 0 ] && echo "$OUT" | grep -q ALLINEATE && ok "copie identiche: ALLINEATE, exit 0" || ko "identiche non riconosciute (rc=$RC)"

# solo spazi finali/righe vuote → NON è deriva (impronta normalizzata)
printf 'function main() { return calcolo(10); }   \n\n\nfunction calcolo(n) { return n * 3; }  \n' > "$SB/fork/Codice.js"
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "formattazione diversa NON è deriva (impronta normalizzata)" || ko "la formattazione conta come deriva: falso positivo"

# deriva vera → 1 con matrice e regola del vivo
printf 'function main() { return calcolo(12); }\nfunction calcolo(n) { return n * 3; }\n' > "$SB/fork/Codice.js"
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" 2>&1); RC=$?
[ $RC -eq 1 ] && echo "$OUT" | grep -q DIVERGENTI && ok "deriva vera: DIVERGENTI, exit 1" || ko "deriva non vista (rc=$RC)"
echo "$OUT" | grep -q "VIVO È DEFINITIVO" && ok "il verdetto ricorda la regola del vivo" || ko "verdetto senza la regola del vivo"
echo "$OUT" | grep -q "FORK-STATO" && ok "il verdetto ordina di scrivere lo stato" || ko "verdetto senza FORK-STATO"

# tre copie con la vecchia indietro: la matrice la mostra
printf 'function main() { return 0; }\n' > "$SB/vecchia/Codice.js"
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" "$SB/vecchia" 2>&1); RC=$?
[ $RC -eq 1 ] && echo "$OUT" | grep -q "vecchia ≠ vivo" && ok "tre copie: l'indietro è nominato nella matrice" || ko "matrice a tre incompleta"

# copia inesistente → uso, exit 2
bash "$TOOL" "$SB/vivo" /non/esiste >/dev/null 2>&1; RC=$?
[ $RC -eq 2 ] && ok "copia inesistente: exit 2 (uso)" || ko "copia inesistente: rc=$RC"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
