#!/bin/bash
# test-gas-gate.sh — il gate di sintassi GAS (portato dal campo Budget Vendite
# 2026-09-19: esisteva nel cliente e non nell'hub — E-028 imparata per Python,
# mai generalizzata a GAS). Prova: .gs buono e rotto, JS inline negli .html,
# perimetro vuoto dichiarato (exit 2, non verde — la lezione BusinessPlan).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$HERE/tools/gas-gate.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$GATE" && ok "sintassi" || { ko "sintassi"; exit 1; }

nuova() { SB=$(mktemp -d /tmp/test-gasgate.XXXXXX); git -C "$SB" init -q -b main; git -C "$SB" -c user.name=t -c user.email=t@t commit -qm init --allow-empty; }
commit_tutto() { git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm x; }

# 1. perimetro vuoto: exit 2 DICHIARATO, mai verde su niente
nuova
bash "$GATE" "$SB" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 2 ] && ok "perimetro vuoto: exit 2 (non giudicabile, non verde)" || ko "perimetro vuoto: rc=$RC"

# 2. .gs buono + html con JS inline buono → 0
printf 'function f(x){\n  return x*2;\n}\n' > "$SB/a.gs"
printf '<html><script>\nvar a = 1;\n</script></html>' > "$SB/p.html"
commit_tutto
bash "$GATE" "$SB" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 0 ] && ok ".gs + inline buoni: rc 0" || ko "buoni: rc=$RC"

# 3. .gs rotto → 1
printf 'function g({\n' > "$SB/rotto.gs"
commit_tutto
bash "$GATE" "$SB" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok ".gs rotto: rc 1" || ko "rotto: rc=$RC"
rm "$SB/rotto.gs"

# 4. JS inline rotto nell'html → 1 (la parte che nessun gate vedeva)
printf '<html><script>\nvar = ;\n</script></html>' > "$SB/q.html"
commit_tutto
bash "$GATE" "$SB" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok "JS inline rotto: rc 1" || ko "inline rotto: rc=$RC"
# 5. (revisione 10 giri, 2026-09-23): PIU' blocchi <script>, con attributi — `sed '1d;$d'`
# toglieva solo il primo e l'ultimo tag: i tag interni restavano nel JS e node dava un falso
# KO; un <script type="…"> non veniva nemmeno visto.
git -C "$SB" rm -q q.html
printf '<html>\n<script>\nvar a = 1;\n</script>\n<p>x</p>\n<script type="text/javascript">\nvar b = 2;\n</script>\n</html>\n' > "$SB/m.html"
commit_tutto
bash "$GATE" "$SB" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 0 ] && ok "due blocchi <script> buoni (uno con attributi): rc 0" || ko "due blocchi buoni: rc=$RC (falso KO)"
printf '<html>\n<script>\nvar a = 1;\n</script>\n<script type="text/javascript">\nvar = ;\n</script>\n</html>\n' > "$SB/m.html"
commit_tutto
bash "$GATE" "$SB" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok "rotto nel SECONDO blocco (con attributi): rc 1" || ko "rotto nel secondo blocco non visto: rc=$RC"
rm -rf "$SB"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
