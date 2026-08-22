#!/bin/bash
# test-banco-prompt-allowlist-sync.sh — set 3 giro 8: bug reale trovato con dogfooding.
# Il prompt del banco avversariale diceva "sono ammessi node/python/..." ma
# gate_allowlist_ok() li scarta SEMPRE (rimossi per sicurezza, opzione (c) di Luca) —
# ogni volta che l'avversario scriveva un comando node/python (invitato a farlo dal
# prompt), quel turno di giudizio andava sprecato. Verifica che ogni tool che il prompt
# dichiara ammesso passi DAVVERO l'allowlist reale, e che node/python restino scartati
# (coerenti con quanto il prompt corretto ora dichiara).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/night-shift/lib.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

! grep -q "Sono ammessi node/python" "$HERE/night-shift/morning-gate.sh" \
  && ok "il prompt non promette più node/python come ammessi (bug corretto)" \
  || ko "il prompt promette ancora node/python — la menzogna è tornata"

grep -q "NESSUN interprete general-purpose" "$HERE/night-shift/morning-gate.sh" \
  && ok "il prompt avverte esplicitamente che gli interpreti general-purpose sono scartati" \
  || ko "il prompt non avverte più sugli interpreti general-purpose"

# ogni tool che il prompt dichiara ammesso deve passare DAVVERO l'allowlist reale
for CMD in "grep foo bar" "cat file" "diff a b" "wc -l f" "head -3 f" "tail -3 f" \
           "ls -la" "test -f x" "jq '.' f" "echo hi" \
           "git diff HEAD~1" "git log -5" "git status" "git blame f"; do
  gate_allowlist_ok "$CMD" && ok "tool dichiarato ammesso passa davvero: $CMD" \
    || ko "tool dichiarato ammesso nel prompt ma SCARTATO dall'allowlist: $CMD"
done

# node/python restano scartati (il prompt ora dice la verità su questo)
for CMD in "node -e 1" "python3 -c 1"; do
  gate_allowlist_ok "$CMD" && ko "node/python dovrebbero essere scartati, invece passano: $CMD" \
    || ok "correttamente scartato (coerente col prompt corretto): $CMD"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
