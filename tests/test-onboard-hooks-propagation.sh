#!/bin/bash
# test-onboard-hooks-propagation.sh — banco di regressione nato dalla revisione "L'Hub
# Allo Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in onboard-repo.sh, i cp
# di metodo-reminder-hook.sh/pattern-reminder-hook.sh (nel ramo "settings.json assente")
# non avevano il controllo [ ! -f ... ] che OGNI altro merge dello script ha (skill,
# pattern, agenti) — un progetto con hook personalizzati (ma senza ancora
# .claude/settings.json) li vedeva sovrascritti in silenzio dall'onboarding.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'WORK/tools/metodo-reminder-hook\.sh" \] || cp' "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh contiene la logica di merge per metodo-reminder-hook.sh (mai sovrascrive)" \
  || ko "logica di merge metodo-reminder-hook.sh non trovata in onboard-repo.sh"
grep -q 'WORK/tools/pattern-reminder-hook\.sh" \] || cp' "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh contiene la logica di merge per pattern-reminder-hook.sh (mai sovrascrive)" \
  || ko "logica di merge pattern-reminder-hook.sh non trovata in onboard-repo.sh"

# riproduce esattamente il ramo reale (settings.json assente) su una copia di lavoro
merge_hooks() {
  local work="$1"
  mkdir -p "$work/tools"
  [ -f "$work/tools/metodo-reminder-hook.sh" ] || cp "$HERE/tools/metodo-reminder-hook.sh" "$work/tools/" 2>/dev/null || true
  [ -f "$work/tools/pattern-reminder-hook.sh" ] || cp "$HERE/tools/pattern-reminder-hook.sh" "$work/tools/" 2>/dev/null || true
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

WORK1="$TMP/repo-senza-hook"
merge_hooks "$WORK1"
[ -f "$WORK1/tools/metodo-reminder-hook.sh" ] && [ -f "$WORK1/tools/pattern-reminder-hook.sh" ] \
  && ok "repo senza hook propri: entrambi gli hook del hub arrivano" \
  || ko "repo senza hook propri: hook mancanti dopo il merge"

WORK2="$TMP/repo-con-hook-personalizzato"
mkdir -p "$WORK2/tools"
echo "HOOK PERSONALIZZATO DAL PROGETTO" > "$WORK2/tools/metodo-reminder-hook.sh"
merge_hooks "$WORK2"
[ "$(cat "$WORK2/tools/metodo-reminder-hook.sh")" = "HOOK PERSONALIZZATO DAL PROGETTO" ] \
  && ok "hook personalizzato del progetto NON sovrascritto dall'onboarding" \
  || ko "hook personalizzato sovrascritto (bug di merge)"
[ -f "$WORK2/tools/pattern-reminder-hook.sh" ] \
  && ok "l'altro hook (non personalizzato) arriva comunque" \
  || ko "pattern-reminder-hook.sh non arrivato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
