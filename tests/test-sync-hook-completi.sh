#!/bin/bash
# test-sync-hook-completi.sh — (issue 2026-09-03) clasp-block-hook.sh non era
# copiato dai tre script di distribuzione mentre settings.json lo dichiara:
# il DENTE del "clasp push MAI" mancava in ogni repo adottante. Ora la lista
# si DERIVA da settings.json. Test: ogni command dichiarato esiste nell'hub,
# e ogni script deriva la lista (non la scrive a mano).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

while IFS= read -r hook; do
  [ -n "$hook" ] || continue
  [ -f "$HERE/tools/$(basename "$hook")" ] \
    && ok "hook dichiarato esiste: $(basename "$hook")" \
    || ko "hook dichiarato ma ASSENTE: $(basename "$hook")"
done < <(jq -r '.hooks.PreToolUse[]?.hooks[]?.command' "$HERE/.claude/settings.json" 2>/dev/null)

for script in tools/sync-repo.sh tools/onboard-repo.sh tools/bootstrap-app.sh; do
  grep -q 'settings.json' "$HERE/$script" \
    && ok "$(basename $script) deriva da settings.json" \
    || ko "$(basename $script) usa lista fissa"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
