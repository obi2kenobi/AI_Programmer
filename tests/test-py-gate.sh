#!/bin/bash
# test-py-gate.sh — il gate della sintassi python sotto prova (E-028+E-029).
# Prova: verde su repo sana, rosso su un .py rotto (in una dir scratch, non
# nell'hub), e che .night-verify lo invochi come UN COMANDO per riga — il
# contratto che la prima versione violava regalando falsi rossi alla notte.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$HERE/tools/py-gate.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$GATE" && ok "sintassi" || { ko "sintassi"; exit 1; }

# 1. verde sull'hub (tutti i .py tracciati compilano)
OUT=$(bash "$GATE" "$HERE" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "hub verde ($OUT)" || ko "hub rosso: $OUT"

# 2. rosso su un .py rotto — in uno scratch, con un git vero come nella realta'
SB=$(mktemp -d /tmp/test-pygate.XXXXXX); trap 'rm -rf "$SB"' EXIT
git -C "$SB" init -q
printf 'x = 1\nif x = 2:\n    pass\n' > "$SB/rotto.py"
printf 'ok = True\n' > "$SB/buono.py"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm x
OUT=$(bash "$GATE" "$SB" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "rotto bocciato (rc 1)" || ko "rc $RC (atteso 1)"
echo "$OUT" | grep -q "rotto.py" && ok "il file rotto viene Nominato" || ko "non dice quale file"
# (revisione 10 giri, 2026-09-23): era `echo "$OUT" | if grep …; then ko …` — il ko girava nella
# SUBSHELL della pipe e il contatore si perdeva: stampava FAIL e chiudeva 7 OK, 0 FAIL.
if grep -q "buono.py" <<<"$OUT"; then ko "accusa il file buono (falso positivo — audit 2026-09-23)"; else ok "il file buono non viene accusato"; fi
# e da un'ALTRA cartella: i path di git ls-files sono relativi a DIR, non alla cartella corrente
OUT_ALTROVE=$(cd / && bash "$GATE" "$SB" 2>&1)
if grep -q "buono.py" <<<"$OUT_ALTROVE"; then ko "lanciato da un'altra cartella accusa il file buono"; else ok "lanciato da un'altra cartella: il file buono non e' accusato"; fi

# 3. il gate non scrive __pycache__ (compile(), non py_compile)
[ -z "$(find "$SB" -name __pycache__ 2>/dev/null)" ] && ok "nessun __pycache__ scritto" || ko "ha sporcato con __pycache__"

# 4. il contratto E-029: in .night-verify UN COMANDO per riga — le righe che
# iniziano con un'assegnazione seguita da ';' rompono il prefix `ai_timeout 120`
# del turno (l'assegnazione diventa argomento, non assegnazione)
VIOLATORE=""
while IFS= read -r riga; do
  case "$riga" in ""|\#*) continue;; esac
  case "$riga" in
    [A-Za-z_]*=*\;*) VIOLATORE="$VIOLATORE ${riga%%;*}" ;;
  esac
done < "$HERE/.night-verify"
[ -z "$VIOLATORE" ] && ok ".night-verify: nessuna riga composta con assegnazione (contratto E-029)" \
  || ko "righe che violano il contratto un-comando-per-riga:$VIOLATORE"

# 5. la riga del gate c'e' e invoca il tool
grep -q "^bash tools/py-gate.sh$" "$HERE/.night-verify" && ok "il gate è dichiarato in .night-verify" \
  || ko ".night-verify non invoca py-gate.sh"

# (Q30, 2026-09-23, notte dei giri): fuori da una repo git `git ls-files` falliva nel 2>/dev/null e il
# gate diceva «tutti i .py compilano (0 file)», rc 0 — con un .py ROTTO nella cartella. Zero
# giudicati non e' verde: come tools/gas-gate.sh, perimetro non giudicabile, exit 2.
NG=$(mktemp -d); printf 'def x(:\n' > "$NG/rotto.py"
OUT=$(bash "$GATE" "$NG" 2>&1); RC=$?
[ "$RC" -eq 2 ] && ! grep -q "tutti i .py compilano" <<<"$OUT" && ok "fuori da git: perimetro non giudicabile (exit 2), non «tutti compilano»" \
  || ko "fuori da git con un .py rotto: rc=$RC — $(tail -1 <<<"$OUT")"
git -C "$NG" init -q; rm -f "$NG/rotto.py"
OUT=$(bash "$GATE" "$NG" 2>&1); RC=$?
[ "$RC" -eq 2 ] && ok "repo senza .py tracciati: exit 2 dichiarato (zero giudicati non e' verde)" || ko "zero .py: rc=$RC — $(tail -1 <<<"$OUT")"
rm -rf "$NG"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
