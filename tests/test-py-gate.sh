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
echo "$OUT" | grep -q "buono.py" || ok "il file buono non viene accusato" || ko "accusa il file buono"

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

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
