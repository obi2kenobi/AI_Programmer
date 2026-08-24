#!/bin/bash
# test-hook-sal-promemoria.sh — 2026-08-24, report sul campo F5: il promemorio SAL
# scatta al 5° edit di una sessione che non tocca SAL.md (e tace prima; e resetta
# se SAL.md viene toccato; e tace se SAL.md non esiste nel progetto). Mai blocca.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/pattern-reminder-hook.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/con-sal" "$TMP/senza-sal"
echo "# diario" > "$TMP/con-sal/SAL.md"

cd "$TMP/con-sal"
edit() { echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$1\"}}" | (cd "$TMP/con-sal" && bash "$HOOK"); }

# edit 1-4: silenzio
edit "src/A.js" >/dev/null 2>&1; edit "src/B.js" >/dev/null 2>&1
edit "src/C.js" >/dev/null 2>&1; edit "src/D.js" >/dev/null 2>&1
OUT4=$(edit "src/E.js" 2>/dev/null); RC=$?
echo "$OUT4" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 && CONTESTO=$(echo "$OUT4" | jq -r '.hookSpecificOutput.additionalContext') \
  || CONTESTO=""
[ -n "$CONTESTO" ] && echo "$CONTESTO" | grep -q "PRIMA del passo successivo" \
  && ok "al 5° edit senza SAL: promemoria 'prima del passo successivo'" \
  || ko "5° edit: nessun promemoria (OUT=$OUT4)"
[ "$RC" -eq 0 ] && ok "il promemoria non blocca (exit 0, allow)" || ko "rc=$RC"

# toccare SAL resetta il contatore: il promemoria torna al 5° edit DOPO, e il
# numero nel messaggio ricomincia da 5 (senza reset direbbe 10)
edit "SAL.md" >/dev/null 2>&1
edit "src/F.js" >/dev/null 2>&1; edit "src/G.js" >/dev/null 2>&1; edit "src/H.js" >/dev/null 2>&1; edit "src/I.js" >/dev/null 2>&1
OUT=$(edit "src/L.js" 2>/dev/null)
echo "$OUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "Hai fatto 5 edit" \
  && ok "edit di SAL.md resetta il contatore (il conteggio ricomincia: dice 5, non 10)" \
  || ko "reset non funzionante: $(echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null | head -1)"

# senza SAL.md nel progetto: mai promemoria
edit_ns() { echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$1\"}}" | (cd "$TMP/senza-sal" && bash "$HOOK"); }
for i in 1 2 3 4 5 6; do edit_ns "x$i.js" >/dev/null 2>&1; done
OUT=$(edit_ns "x7.js" 2>/dev/null)
[ -z "$OUT" ] && ok "senza SAL.md nel progetto: mai promemoria" || ko "promemoria senza SAL.md: $OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
