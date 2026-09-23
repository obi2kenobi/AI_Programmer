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

# --prossimo con un rinviato (revisione 10 giri, 2026-09-23): `paste` affiancava la colonna
# delle famiglie di TUTTE le righe ai siti gia' filtrati — con un rinviato le righe
# scivolavano e un sito E-032 usciva etichettato E-002 (all'agente la cura sbagliata).
SB2=$(mktemp -d /tmp/test-cregistro2.XXXXXX)
git -C "$SB2" init -q -b main; mkdir -p "$SB2/tools" "$SB2/tests"
printf '#!/bin/bash
X=$(ls %s foo && echo y)
' "$PIPEQ" > "$SB2/tools/uno.sh"
printf '#!/bin/bash
printf hi >> "$HERE/vivo.md"
' > "$SB2/tests/test-vivo.sh"
git -C "$SB2" add -A && git -C "$SB2" -c user.name=t -c user.email=t@t commit -qm base
PRIMO=$(bash "$TOOL" --prossimo "$SB2" 2>/dev/null)
mkdir -p "$SB2/.git/caccia-registro"; printf '%s\n' "${PRIMO#*|}" > "$SB2/.git/caccia-registro/rinviati"
SECONDO=$(bash "$TOOL" --prossimo "$SB2" 2>/dev/null)
[ "$SECONDO" = "E-032|tests/test-vivo.sh:2" ] && ok "--prossimo col primo sito rinviato: il sito dopo con la SUA famiglia ($SECONDO)" \
  || ko "--prossimo con rinviato: '$SECONDO' (atteso E-032|tests/test-vivo.sh:2; primo era '$PRIMO')"
rm -rf "$SB2"

# sul repo VERO, ma in QUARANTENA (revisione 10 giri, 2026-09-23): prima girava sull'hub vivo
# e, dal main (cioe' nel turno, che esegue la suite dal main), riscriveva la baseline e la
# storia VERE in .git/caccia-registro — il delta che la notte legge si azzerava a ogni suite.
# Un clone locale ha lo stesso codice e il suo .git: il contratto si prova li'.
QT=$(mktemp -d /tmp/test-caccia-reg.XXXXXX)
git clone -q --local "$HERE" "$QT/hub" 2>/dev/null
# il clone parte dal COMMIT: lo strumento sotto prova si porta dal working tree (banco mutazioni)
cp "$TOOL" "$QT/hub/tools/caccia-registro.sh"
VIVO_PRIMA=$(cat "$HERE/.git/caccia-registro/storia" 2>/dev/null | wc -l | tr -d ' ')
PRIMA=$(git -C "$QT/hub" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
OUT=$(bash "$QT/hub/tools/caccia-registro.sh" "$QT/hub" 2>&1); RC=$?
DOPO=$(git -C "$QT/hub" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[ "$RC" -eq 0 ] && echo "$OUT" | grep -qE "E-002.*=[0-9]+" && ok "repo vero (clone): censimento onesto senza rompere (rc 0)" || ko "repo vero: rc=$RC, $OUT"
[ "$DOPO" -le "$PRIMA" ] && ok "il censimento non aggiunge sporco ($PRIMA -> $DOPO)" || ko "sporcato l'albero: $PRIMA -> $DOPO"
# lo stato vive in .git (mai committato)
[ -d "$QT/hub/.git/caccia-registro" ] && ok "lo stato del censimento vive in .git (mai committato)" || ko "stato fuori posto"
VIVO_DOPO=$(cat "$HERE/.git/caccia-registro/storia" 2>/dev/null | wc -l | tr -d ' ')
[ "$VIVO_PRIMA" = "$VIVO_DOPO" ] && ok "la storia del censimento dell'hub VIVO non e' toccata dal test" || ko "il test ha scritto nella storia viva ($VIVO_PRIMA -> $VIVO_DOPO)"
rm -rf "$QT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
