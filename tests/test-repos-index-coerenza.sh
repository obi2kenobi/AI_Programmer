#!/bin/bash
# test-repos-index-coerenza.sh — 4° ciclo, SET 3 giro 3. I codici anonimi (REPO-A,
# REPO-B, …) sono sparsi in oltre 15 file senza un indice — rischio verificato dal vivo:
# prima di assegnare REPO-E ho dovuto controllare a mano che non collidesse con un
# codice già in uso. Verifica che l'indice esista, sia citato da CLAUDE.md, e che OGNI
# codice REPO-[A-Z] usato altrove nel repo compaia anche nell'indice (nessun codice
# orfano, non documentato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
IDX="$HERE/night-shift/repos-index.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$IDX" ] && ok "night-shift/repos-index.md esiste" \
  || { ko "l'indice non esiste"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }

grep -q "repos-index.md" "$HERE/CLAUDE.md" \
  && ok "CLAUDE.md rimanda all'indice (non solo alla regola dei codici)" \
  || ko "CLAUDE.md non cita più l'indice"

# ogni codice REPO-[A-Z] usato in ALMENO un altro file tracciato deve comparire anche
# nell'indice — nessun codice orfano. Esclude tests/: quei file usano codici sintetici
# generici (REPO-X, REPO-T, REPO-Z) come fixture per verificare la logica di
# mascheramento, non come riferimento a un repo reale — non sono "usati", sono inventati
# apposta per il test.
USATI=$(cd "$HERE" && git ls-files -z -- . ':!tests' | xargs -0 grep -ohE 'REPO-[A-Z]\b' 2>/dev/null \
  | sort -u)
MANCANTI=0
while IFS= read -r codice; do
  [ -z "$codice" ] && continue
  grep -q "| $codice |" "$IDX" || { echo "   codice non indicizzato: $codice"; MANCANTI=$((MANCANTI+1)); }
done <<< "$USATI"
[ "$MANCANTI" -eq 0 ] && ok "ogni codice REPO-[A-Z] usato nel repo compare nell'indice" \
  || ko "$MANCANTI codice/i usato/i altrove ma non indicizzato/i"

# 5° ciclo, set 3 giro 3: la riga REPO-E era rimasta ai 4 casi del ciclo precedente,
# il 5° caso (scadenzario aging, set 1 giro 4 di questo ciclo) non c'era ancora — non
# basta che il codice sia presente, la sua descrizione deve restare al passo con ogni
# nuovo caso reale minato dallo stesso repo, non solo i primi. Una parola chiave per
# caso, non il nome del file (la prosa dell'indice non ripete i basename esatti).
RIGA_E=$(grep '^| REPO-E' "$IDX")
for chiave in "scostamento" "riconciliazione magazzino" "roll-forward cespiti" "indici di crisi" "scadenzario aging"; do
  echo "$RIGA_E" | grep -qi "$chiave" \
    && ok "REPO-E indicizzato cita il caso '$chiave'" \
    || ko "REPO-E non cita più il caso '$chiave' — la riga dell'indice è rimasta indietro"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
