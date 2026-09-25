#!/bin/bash
# (dominio 2026-09-23): il morning-gate e' in pensione — questo test verifica codice che resta nel repo ma non gira piu' da launchd. Tenuto perche' il gate resta invocabile a mano.
# test-morning-gate-issue-num.sh — set 3 giro 5: bug reale che corrompe metrics/gate.csv.
# "${BRANCH#night/issue-}" non rimuove nulla se il branch non inizia per "night/issue-" —
# per un branch claude/* o glm/* (che morning-gate.sh giudica esplicitamente "con due
# occhi"), ISSUE_NUM diventava l'INTERO nome del branch, finendo così nella colonna
# "issue" del CSV condiviso invece di un numero o di un placeholder onesto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# (2026-09-23, notte dei giri): qui c'era una COPIA del blocco — spento nel sorgente, il banco restava
# verde. Ora si estrae ed ESEGUE il blocco vero di night-shift/morning-gate.sh (lo stesso gesto di
# tests/test-night-shift-log-onesto.sh: la riga del sorgente, non una copia ridigitata).
BLOCCO=$(sed -n '/^    case "\$BRANCH" in$/,/^    esac$/p' "$HERE/night-shift/morning-gate.sh")
[ -n "$BLOCCO" ] || ko "il blocco case \$BRANCH non si trova in night-shift/morning-gate.sh"
estrai_issue_num() {
  local BRANCH="$1" ISSUE_NUM
  eval "$BLOCCO"
  echo "$ISSUE_NUM"
}

grep -q 'night/issue-\*) ISSUE_NUM=' "$HERE/night-shift/morning-gate.sh" \
  && ok "morning-gate.sh distingue night/issue-* dagli altri branch (bug corretto)" \
  || ko "logica di estrazione ISSUE_NUM non trovata/aggiornata in morning-gate.sh"

[ "$(estrai_issue_num 'night/issue-42')" = "42" ] && ok "night/issue-42 -> 42 (invariato)" \
  || ko "night/issue-42 non estrae più 42"

R=$(estrai_issue_num "claude/ai-programmer-process-improvement-t1876t")
[ "$R" = "—" ] && ok "branch claude/*: placeholder onesto, non l'intero nome del branch (bug corretto)" \
  || ko "branch claude/* produce ancora dati sporchi: [$R]"

R2=$(estrai_issue_num "glm/feat3-digest-mattina")
[ "$R2" = "—" ] && ok "branch glm/*: placeholder onesto, non l'intero nome del branch (bug corretto)" \
  || ko "branch glm/* produce ancora dati sporchi: [$R2]"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
