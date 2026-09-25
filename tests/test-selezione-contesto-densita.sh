#!/bin/bash
# test-selezione-contesto-densita.sh — la ricetta della densita' di .claude/skills/selezione-contesto/SKILL.md
# §3bis, eseguita com'e' scritta (2026-09-24, terzo ventaglio, V3#6). Prima: il passo 2 era
# `grep -nE "…" progetto/*.js | grep -v "^\s*//"`. Con -n e piu' file ogni riga comincia con `file:N:`,
# quindi il filtro dei commenti non combaciava mai: i commenti contavano come aritmetica di dominio, e
# la densita' gonfiata spingeva verso l'oracolo Python. Il banco estrae il comando dalla skill e lo
# lancia su un progetto di prova: due righe di commento con le parole chiave, una di aritmetica vera.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
SK="$HERE/.claude/skills/selezione-contesto/SKILL.md"

CMD=$(sed -n 's/^2\. `\(grep .*calcola.*\)` — .*/\1/p' "$SK")
[ -n "$CMD" ] && ok "passo 2 della ricetta trovato nella skill" || ko "passo 2 della ricetta non trovato in $SK"

mkdir -p "$T/progetto"
printf '// calcola la somma delle vendite\n  // tasso di sconto applicato qui sotto\nvar importo = netto * (1 + tasso);\n' > "$T/progetto/a.js"
printf 'function leggi() { return foglio.getRange(1, 1).getValues(); }\n' > "$T/progetto/b.js"
OUT=$(cd "$T" && bash -c "$CMD" 2>&1 | tr -d ' ')
[ "$OUT" = "1" ] && ok "la ricetta conta 1 riga di aritmetica (i due commenti restano fuori)" \
  || ko "la ricetta conta i commenti: uscita «${OUT}», attesa 1"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
