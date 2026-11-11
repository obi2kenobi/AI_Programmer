#!/bin/bash
# test-sonda-mute.sh — tools/sonda-mute.sh conta le finestre mute di Ollama per notte (2026-11-10: il primo banco;
# il tool usava `date -v`, solo BSD, e su Linux contava sempre zero; un log assente diceva «0 mute»).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
IERI=$(date -v-1d +%F 2>/dev/null || date -d "-1 day" +%F)
{ for i in 1 2 3 4 5 6 7; do echo "[$IERI 02:0$i] Ollama non ha risposto"; done; echo "[$IERI 03:00] bilancino: ok"; } > "$TMP/log"
OUT=$(bash "$HERE/tools/sonda-mute.sh" "$TMP/log" 2>&1)
grep -qF "$IERI: 7 finestre mute, 1 righe bilancino" <<<"$OUT" && ok "conta le mute di ieri (7) e il bilancino (1)" || ko "conteggio: $OUT"
grep -q "DRIFT: 7 finestre ieri" <<<"$OUT" && ok "sopra soglia (6): DRIFT dichiarato" || ko "drift mancato: $OUT"
bash "$HERE/tools/sonda-mute.sh" "$TMP/nessuno" >"$TMP/out" 2>&1; RC=$?
[ "$RC" -eq 2 ] && grep -q "log assente" "$TMP/out" && ok "log assente: rc 2, detto (non «0 mute»)" || ko "log assente (rc $RC): $(cat "$TMP/out")"
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
