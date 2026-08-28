#!/bin/bash
# test-report-campo.sh — 2026-08-27, proposta di Luca: «a ogni uso, un report di
# come si è comportato, per migliorarlo a ogni sviluppo». Verifica: (1) il formato
# esiste e forza i fatti (le quattro sezioni + il divieto del silenzio); (2) l'hook
# Stop ricorda se il report di oggi manca e TACE se c'è; (3) mai bloccante.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/metodo-reminder-hook.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "Cosa ho usato" "$HERE/docs/campo/README.md" && grep -q "Cosa ho improvvisato" "$HERE/docs/campo/README.md" \
  && grep -q "Proposta al canone" "$HERE/docs/campo/README.md" \
  && ok "formato presente: le sezioni che forzano i fatti (usato/improvvisato/proposta)" \
  || ko "formato incompleto"
grep -q "nessuna proposta" "$HERE/docs/campo/README.md" \
  && ok "il silenzio è vietato ('nessuna proposta' dichiarata conta)" || ko "manca il divieto del silenzio"
jq -e '.hooks.Stop' "$HERE/.claude/settings.json" >/dev/null 2>&1 \
  && ok "hook Stop registrato in settings.json" || ko "hook Stop non registrato"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
OUT=$(cd "$TMP" && echo '{"hook_event_name":"Stop"}' | bash "$HOOK")
echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null | grep -q "report dal campo" \
  && ok "fine sessione senza report di oggi: promemoria emesso (meccanico, non mnemonico)" \
  || ko "nessun promemoria: $OUT"
mkdir -p "$TMP/docs/campo"; touch "$TMP/docs/campo/$(date +%F)-x.md"
OUT=$(cd "$TMP" && echo '{"hook_event_name":"Stop"}' | bash "$HOOK")
[ -z "$OUT" ] && ok "report di oggi presente: il promemoria TACE (non rompe chi ha fatto)" \
  || ko "promemoria anche col report presente: $OUT"
# giri avversari 2026-08-28 (G9): il puntatore di CLAUDE.md a docs/campo poteva
# degradare senza rosso — il format vive nel README di campo, ma il canone deve
# continuare a DIRIGERE lì chi chiude la sessione
grep -q "docs/campo" "$HERE/CLAUDE.md" \
  && ok "CLAUDE.md dirige i report in docs/campo/" \
  || ko "CLAUDE.md ha perso il puntatore a docs/campo/"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
