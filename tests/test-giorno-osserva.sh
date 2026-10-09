#!/bin/bash
# test-giorno-osserva.sh — il ciclo stretto del giorno: giorno.sh osserva gira il
# verify del repo a ogni modifica (furto da watchexec/entr), con SKIP dichiarato
# senza watchexec e rifiuto dichiarato senza niente da osservare.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GP="$HERE/tools/giorno.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$GP" && ok "sintassi" || { ko "sintassi"; exit 1; }

SB=$(mktemp -d /tmp/test-osserva.XXXXXX)
trap 'rm -rf "$SB"' EXIT
export GIORNO_LOG="$SB/giorno.log"

# stub watchexec: registra gli argomenti ed esce subito (il banco non aspetta eventi)
WSTUB="$SB/bin"; mkdir -p "$WSTUB"
printf '#!/bin/bash\necho "$*" >> "%s/reg"\nexit 0\n' "$SB" > "$WSTUB/watchexec"
chmod +x "$WSTUB/watchexec"

R="$SB/repo"; mkdir -p "$R"; git -C "$R" init -q -b main
git -C "$R" -c user.name=t -c user.email=t@t commit -qm init --allow-empty

# senza .night-verify e senza comando: rifiuto dichiarato (rc 2)
OUT=$(bash "$GP" osserva "$R" 2>&1); RC=$?
[ "$RC" -eq 2 ] && grep -q "niente da osservare" <<<"$OUT" && ok "senza verify e senza comando: rifiuto dichiarato (rc 2)" || ko "senza verify e senza comando (rc=$RC: $OUT)"

# col .night-verify: gira quello (via stub)
printf '#!/bin/bash\necho verifica-ok\n' > "$R/.night-verify"
OUT=$(WATCHEXEC_BIN="$WSTUB/watchexec" bash "$GP" osserva "$R" 2>&1); RC=$?
REG=$(cat "$SB/reg" 2>/dev/null)
if [ "$RC" -eq 0 ] && grep -q -- "-w ." <<<"$REG" && grep -q -- ".night-verify" <<<"$REG"; then
  ok "col .night-verify: watchexec riceve la cartella e il verify del repo"
else ko "col .night-verify: comando ricevuto (rc=$RC: reg=$REG)"; fi
grep -q "osserva avviato" "$GIORNO_LOG" && ok "osserva: la riga e' nel log del giorno" || ko "osserva: la riga e' nel log del giorno"

# comando esplicito al posto del verify
: > "$SB/reg"
OUT=$(WATCHEXEC_BIN="$WSTUB/watchexec" bash "$GP" osserva "$R" "bash tests/test-giorno.sh" 2>&1); RC=$?
REG=$(cat "$SB/reg" 2>/dev/null)
grep -q -- "tests/test-giorno.sh" <<<"$REG" && ok "comando esplicito: passa parola a watchexec tale e quale" || ko "comando esplicito (reg=$REG)"

# watchexec assente: SKIP dichiarato, rc 0, mai morte
OUT=$(WATCHEXEC_BIN=/non-esiste bash "$GP" osserva "$R" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -qi "SALTATO" <<<"$OUT" && ok "watchexec assente: skip dichiarato, rc 0" || ko "watchexec assente (rc=$RC: $OUT)"

# skill: il giorno sa di osserva e dell'ergonomia della macchina
grep -q "osserva" "$HERE/.claude/skills/giorno/SKILL.md" && ok "skill giorno: osserva documentato" || ko "skill giorno: osserva documentato"
grep -q "absorb\|difft" "$HERE/.claude/skills/giorno/SKILL.md" && ok "skill giorno: l'ergonomia della macchina (absorb/difft) e' dichiarata" || ko "skill giorno: ergonomia dichiarata"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
