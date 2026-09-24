#!/bin/bash
# test-e002-codice.sh — la famiglia E-002 nel CODICE, non solo nei banchi (Q27, 2026-09-23, notte dei
# giri). `echo "$X" | grep -q …` sotto pipefail: grep esce al primo riscontro, il produttore muore di
# SIGPIPE (rc 141) e la condizione diventa FALSA proprio quando il riscontro c'e'. Succede quando $X
# ha molte righe: riprodotto stanotte sugli hook veri — con un comando lungo l'avviso sulle
# credenziali di tools/clasp-block-hook.sh e il promemoria di tools/pattern-reminder-hook.sh tacevano
# 5 volte su 5 (con il comando corto escono). tests/test-e002-banchi-curati.sh presidia tests/;
# questo presidia tools/, night-shift/ e llm/.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

python3 - "$TMP" <<'PY'
import json, sys
t = sys.argv[1]; pad = "\n".join(["riga di riempimento lunga abbastanza"] * 40000)
json.dump({"tool_name": "Bash", "tool_input": {"command": "cat .env\n" + pad}}, open(t + "/cred.json", "w"))
json.dump({"tool_name": "Bash", "tool_input": {"command": "cat id_rsa\n" + pad}}, open(t + "/sens.json", "w"))
PY
N=0; for i in 1 2 3; do grep -q credenziali <<<"$(bash "$HERE/tools/clasp-block-hook.sh" < "$TMP/cred.json" 2>/dev/null)" && N=$((N+1)); done
[ "$N" -eq 3 ] && ok "clasp-block-hook: l'avviso sulle credenziali esce anche su un comando lungo (3/3)" \
  || ko "clasp-block-hook: avviso sulle credenziali perso su un comando lungo ($N/3)"
N=0; for i in 1 2 3; do grep -q sensibile <<<"$(bash "$HERE/tools/pattern-reminder-hook.sh" < "$TMP/sens.json" 2>/dev/null)" && N=$((N+1)); done
[ "$N" -eq 3 ] && ok "pattern-reminder-hook: il promemoria sul materiale sensibile esce anche su un comando lungo (3/3)" \
  || ko "pattern-reminder-hook: promemoria perso su un comando lungo ($N/3)"

# il cricchetto: nessun `echo|printf … | grep -q` nei file sotto pipefail di tools/ night-shift/ llm/
SITI=""
while IFS= read -r f; do
  grep -q 'pipefail' "$f" || continue
  while IFS= read -r r; do SITI="$SITI $f:${r%%:*}"; done \
    < <(grep -nE '(^|[^#]*[;&|(![:space:]])(echo|printf)[^|]*\|[[:space:]]*grep -[a-zA-Z]*q' "$f" | grep -vE '^[0-9]+:[[:space:]]*#' || true)
done < <(cd "$HERE" && git ls-files 'tools/*.sh' 'night-shift/*.sh' 'llm/*.sh' | sed "s|^|$HERE/|")
[ -z "$SITI" ] && ok "nessun echo/printf | grep -q sotto pipefail in tools/, night-shift/, llm/" \
  || ko "siti E-002 nel codice:$(sed "s|$HERE/||g" <<<"$SITI")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
