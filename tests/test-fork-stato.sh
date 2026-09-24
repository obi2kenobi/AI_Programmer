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
[ $RC -eq 0 ] && grep -q ALLINEATE <<<"$OUT" && ok "copie identiche: ALLINEATE, exit 0" || ko "identiche non riconosciute (rc=$RC)"

# solo spazi finali/righe vuote → NON è deriva (impronta normalizzata)
printf 'function main() { return calcolo(10); }   \n\n\nfunction calcolo(n) { return n * 3; }  \n' > "$SB/fork/Codice.js"
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "formattazione diversa NON è deriva (impronta normalizzata)" || ko "la formattazione conta come deriva: falso positivo"

# deriva vera → 1 con matrice e regola del vivo
printf 'function main() { return calcolo(12); }\nfunction calcolo(n) { return n * 3; }\n' > "$SB/fork/Codice.js"
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q DIVERGENTI <<<"$OUT" && ok "deriva vera: DIVERGENTI, exit 1" || ko "deriva non vista (rc=$RC)"
echo "$OUT" | grep -q "VIVO È DEFINITIVO" && ok "il verdetto ricorda la regola del vivo" || ko "verdetto senza la regola del vivo"
echo "$OUT" | grep -q "FORK-STATO" && ok "il verdetto ordina di scrivere lo stato" || ko "verdetto senza FORK-STATO"

# tre copie con la vecchia indietro: la matrice la mostra
printf 'function main() { return 0; }\n' > "$SB/vecchia/Codice.js"
OUT=$(bash "$TOOL" "$SB/vivo" "$SB/fork" "$SB/vecchia" 2>&1); RC=$?
[ $RC -eq 1 ] && echo "$OUT" | grep -q "vecchia ≠ vivo" && ok "tre copie: l'indietro è nominato nella matrice" || ko "matrice a tre incompleta"

# copia inesistente → uso, exit 2
bash "$TOOL" "$SB/vivo" /non/esiste >/dev/null 2>&1; RC=$?
[ $RC -eq 2 ] && ok "copia inesistente: exit 2 (uso)" || ko "copia inesistente: rc=$RC"

# --- Q18 (2026-09-23, giro A2 della notte): tre ALLINEATE falsi, riprodotti.
#  (a) la misura vedeva solo .gs/.js: l'Index.html di una webapp e appsscript.json (scope, fuso,
#      runtime) diversi fra le copie davano ALLINEATE — clasp li porta entrambi;
#  (b) due copie VUOTE (un clasp clone fallito) davano ALLINEATE: nessuna misura, verdetto verde;
#  (c) senza shasum le impronte erano vuote, quindi uguali: ALLINEATE su codice diverso.
mkdir -p "$SB/h1" "$SB/h2"
printf 'function f(){}\n' > "$SB/h1/Code.gs"; cp "$SB/h1/Code.gs" "$SB/h2/"
printf '<p>uno</p>\n' > "$SB/h1/Index.html"; printf '<p>DUE</p>\n' > "$SB/h2/Index.html"
bash "$TOOL" "$SB/h1" "$SB/h2" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok "Q18a: Index.html diverso → DIVERGENTI" || ko "Q18a: Index.html diverso e rc=$RC (ALLINEATE?)"
mkdir -p "$SB/m1" "$SB/m2"
printf 'function f(){}\n' > "$SB/m1/Code.gs"; cp "$SB/m1/Code.gs" "$SB/m2/"
printf '{"timeZone":"Europe/Rome"}\n' > "$SB/m1/appsscript.json"; printf '{"timeZone":"UTC"}\n' > "$SB/m2/appsscript.json"
bash "$TOOL" "$SB/m1" "$SB/m2" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok "Q18a: appsscript.json diverso (fuso) → DIVERGENTI" || ko "Q18a: manifest diverso e rc=$RC"
mkdir -p "$SB/v1" "$SB/v2"
OUT=$(bash "$TOOL" "$SB/v1" "$SB/v2" 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q "DEGRADATO" <<<"$OUT" && ok "Q18b: copie senza codice → DEGRADATO (exit 2), non ALLINEATE" \
  || ko "Q18b: due copie vuote → rc=$RC: $(grep VERDETTO <<<"$OUT")"
mkdir -p "$SB/bin"
for c in find sort sed grep awk basename cat wc tr date seq; do ln -sf "$(command -v $c)" "$SB/bin/$c"; done
printf 'function g(){}\n' > "$SB/m2/Code.gs"
OUT=$(PATH="$SB/bin" /bin/bash "$TOOL" "$SB/m1" "$SB/m2" 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -q "ALLINEATE" <<<"$OUT" && ok "Q18c: senza strumento di hash non dice ALLINEATE (rc=$RC)" \
  || ko "Q18c: senza shasum, codice diverso e verdetto ALLINEATE"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
