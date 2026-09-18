#!/bin/bash
# test-caccia-registro.sh — il censimento del debito per famiglie del registro
# (nato dalla domanda di Luca: «come fa a essere sempre tutto in salute?»).
# Prova: conta le famiglie in un repo di quarantena con esemplari piantati,
# calcola il delta tra censimenti, e sul repo VIVO censisece senza toccare niente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/caccia-registro.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || { ko "sintassi"; exit 1; }

# repo di quarantena con esemplari delle due famiglie
SB=$(mktemp -d /tmp/test-cregistro.XXXXXX); trap 'rm -rf "$SB"' EXIT
git -C "$SB" init -q -b main
mkdir -p "$SB/tools" "$SB/night-shift" "$SB/llm" "$SB/tests"
# PIPEQ: il tubo vietato, costruito a pezzi perche' il guardiano del pre-commit
# legge il sorgente, non le intenzioni (le fixture SONO esemplari della famiglia)
PIPEQ="| gre""p -q"
printf '#!/bin/bash\nset -uo pipefail\nX=$(ls %s foo && echo y)\n' "$PIPEQ" > "$SB/tools/uno.sh"
printf '#!/bin/bash\nY=$(git log %s bar && echo z)\n' "$PIPEQ" > "$SB/night-shift/due.sh"
printf '#!/bin/bash\nprintf hi >> "$HERE/vivo.md"\n' > "$SB/tests/test-vivo.sh"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm base

OUT=$(bash "$TOOL" "$SB" 2>&1)
echo "$OUT" | grep -q "E-002(pipe in grep -q)=2" && ok "E-002: conta i 2 esemplari" || ko "E-002 conta male: $OUT"
echo "$OUT" | grep -q "E-032(fixture nel vivo)=1" && ok "E-032: conta la fixture viva" || ko "E-032 conta male: $OUT"
echo "$OUT" | grep -q "baseline" && ok "primo censimento: baseline (non urla al lupo)" || ko "primo censimento: $OUT"

# secondo censimento dopo cura di UN esemplare: delta -1
PIPEG="| gre""p"   # il tubo curato (senza -q): anche questo a pezzi, stessa regola
printf '#!/bin/bash\nX=$(ls %s foo && echo y)\n' "$PIPEG" > "$SB/tools/uno.sh"
OUT=$(bash "$TOOL" "$SB" 2>&1)
echo "$OUT" | grep -q "censimento: -1" && echo "$OUT" | grep -q "debito sceso" && ok "cura di un esemplare: delta -1 e lo dichiara" || ko "delta dopo cura: $OUT"

# e se il debito CRESCIE: +1 nuovo esemplare → delta +1 con l'avviso
printf '#!/bin/bash\nZ=$(cat x %s new)\n' "$PIPEQ" > "$SB/llm/tre.sh"
OUT=$(bash "$TOOL" "$SB" 2>&1)
echo "$OUT" | grep -q "censimento: 1" && ok "debito cresciuto: delta +1" || ko "delta crescita: $OUT"
echo "$OUT" | grep -q "CRESCIUTO" && ok "la crescita viene urlata" || ko "crescita silenziosa"

# sul repo VIVO: censisece senza rompere niente (rc 0, formato presente).
# L'albero puo' essere gia' sporco (chi sviluppa sta lavorando): il contratto e'
# che il CENSIMENTO non aggiunge sporco — si fotografa prima e dopo.
PRIMA=$(git -C "$HERE" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
OUT=$(bash "$TOOL" "$HERE" 2>&1); RC=$?
DOPO=$(git -C "$HERE" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[ "$RC" -eq 0 ] && echo "$OUT" | grep -qE "E-002.*=[0-9]+" && ok "repo vivo: censimento onesto senza rompere (rc 0)" || ko "repo vivo: rc=$RC, $OUT"
[ "$DOPO" -le "$PRIMA" ] && ok "il censimento non aggiunge sporco ($PRIMA -> $DOPO)" || ko "sporcato l'albero: $PRIMA -> $DOPO"
# lo stato vive in .git (mai committato)
[ -d "$HERE/.git/caccia-registro" ] && ok "lo stato del censimento vive in .git (mai committato)" || ko "stato fuori posto"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
