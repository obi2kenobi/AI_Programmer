#!/bin/bash
# test-standard-non-opzione.sh — 2026-08-26, il problema di Luca: «invoco
# AI_Programmer all'inizio e spesso viene dimenticato». Lo standard è tale solo
# se è MECCANICO e VIAGGIA: (1) gli hook SessionStart/UserPromptSubmit esistono
# e rispondono; (2) il promemorio per prompt è compatto e si aggancia ai calcoli;
# (3) bootstrap porta gli hook al progetto nuovo; (4) sync-repo --standard porta
# il sistema intero; (5) METHOD.md dichiara lo standard con la checklist.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/metodo-reminder-hook.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. gli hook sono registrati
jq -e '.hooks.UserPromptSubmit and .hooks.SessionStart' "$HERE/.claude/settings.json" >/dev/null 2>&1 \
  && ok "settings.json registra UserPromptSubmit e SessionStart" \
  || ko "hook non registrati in settings.json"

# 2. SessionStart: la porta d'ingresso
OUT=$(echo '{"hook_event_name":"SessionStart"}' | bash "$HOOK" 2>/dev/null)
echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null | grep -q "non serve invocarlo" \
  && ok "SessionStart: il metodo entra da solo, senza invocazione" \
  || ko "SessionStart non produce il digest"

# 3. UserPromptSubmit: ogni prompt, compatto
OUT=$(echo '{"hook_event_name":"UserPromptSubmit","prompt":"sistema una cosa"}' | bash "$HOOK" 2>/dev/null)
CTX=$(echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)
[ -n "$CTX" ] && [ "${#CTX}" -lt 400 ] \
  && ok "UserPromptSubmit: promemorio presente e compatto (${#CTX} caratteri)" \
  || ko "promemorio assente o troppo lungo (${#CTX})"
echo "$CTX" | grep -q "oracolo prima della formula" \
  && ok "il promemorio contiene le regole-ancora" || ko "regole mancanti nel promemorio"

# 4. l'aggancio dinamico ai calcoli
OUT=$(echo '{"hook_event_name":"UserPromptSubmit","prompt":"calcolami il margine di magazzino"}' | bash "$HOOK" 2>/dev/null)
echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null | grep -q "tocca un calcolo" \
  && ok "prompt che parla di calcoli: aggancio agli oracoli" || ko "aggancio calcoli mancante"

# 5. bootstrap porta gli hook
grep -q 'cp "$HERE/.claude/settings.json" .claude/settings.json' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh propaga settings.json (gli hook viaggiano)" \
  || ko "bootstrap non propaga gli hook"

# 6. sync-repo --standard porta il sistema intero
grep -q '\-\-standard' "$HERE/tools/sync-repo.sh" \
  && ok "sync-repo.sh --standard: un comando per tutto lo standard" \
  || ko "sync-repo senza modalità standard"

# 7. METHOD.md dichiara lo standard
grep -q "## Lo standard" "$HERE/METHOD.md" && grep -q "non si invoca: si TROVA" "$HERE/METHOD.md" \
  && ok "METHOD.md: lo standard dichiarato (checklist + comando unico)" \
  || ko "METHOD.md non dichiara lo standard"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
