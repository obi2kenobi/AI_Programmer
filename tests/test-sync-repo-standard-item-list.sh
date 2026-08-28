#!/bin/bash
# test-sync-repo-standard-item-list.sh — banco di regressione nato dalla revisione
# "L'Hub Allo Specchio" (14 lenti indipendenti, 2026-08-28): sync-repo.sh --standard
# (lo strumento nato apposta per chiudere la divergenza silenziosa dopo l'onboarding, F2)
# non includeva .opencode/skills né patterns/ nell'elenco ITEM — ogni skill OpenCode o
# pattern aggiunto al hub DOPO l'onboarding di un progetto non lo raggiungeva mai più.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

LINEA=$(grep -n '^  for ITEM in' "$HERE/tools/sync-repo.sh" | head -1)

# giri avversari 2026-08-28 (A14/G8): la lista era DRIFTATA da tools/sync-repo.sh
# (mancava .opencode/plugins) e non presidiava il flag --standard
for item in CLAUDE.md .claude/skills .claude/agents .claude/settings.json .opencode/agent .opencode/skills patterns docs/campo .opencode/plugins; do
  echo "$LINEA" | grep -qF "$item" \
    && ok "ITEM list di sync-repo.sh --standard include: $item" \
    || ko "ITEM list di sync-repo.sh --standard NON include: $item"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
