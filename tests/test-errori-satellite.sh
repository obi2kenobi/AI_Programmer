#!/bin/bash
# test-errori-satellite.sh — la lente del registro errori in una repo appena nata (2026-09-24, notte dei
# giri, T1#6). tests/test-errori.sh arriva nei satelliti con lo scheletro del registro (zero voci), e
# rispondeva «registro vuoto» — rosso dal primo giorno, per un registro che vuoto DEVE essere. La regola
# vera era «il registro non si svuota mai»: zero voci sono lecite se non ce ne sono mai state; togliere
# voci rispetto a HEAD e' rosso (il registro e' append-only).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null -c commit.gpgsign=false "$@"; }

S="$T/sat"; mkdir -p "$S"; g -C "$S" init -q -b main
bash "$HERE/tools/claude-md-satellite.sh" "$HERE/CLAUDE.md" > "$S/CLAUDE.md"
mkdir -p "$S/.claude"; cp -R "$HERE/.claude/skills" "$S/.claude/"
bash "$HERE/tools/installa-citati.sh" "$S" >/dev/null 2>&1
g -C "$S" add -A; g -C "$S" commit -qm nascita
OUT=$(bash "$S/tests/test-errori.sh" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "satellite appena nato: la lente del registro e' verde (rc 0)" || ko "satellite appena nato rosso: $(grep FAIL <<<"$OUT" | tr '\n' ' ')"
grep -c "nessun errore" <<<"$OUT" >/dev/null && ok "e dice che il registro non ha ancora voci (non tace)" || ko "zero voci taciute: $(tail -3 <<<"$OUT" | tr '\n' ' ')"

# una voce registrata e committata, poi tolta: rosso (append-only)
cat >> "$S/docs/errori/REGISTRO.md" <<'VOCE'

## E-001 Voce di prova

- Data / sessione: 2026-09-24
- Famiglia: R1
- Chi l'ha trovato: banco
- Sintomo: x
- Causa prossima: x
- Causa del ragionamento: x
- Perché non ci ha fermati: x
- Guardia: tests/test-errori.sh
- Verifica guardia: x
- Aggiramento: x
VOCE
g -C "$S" commit -qam "voce"
bash "$S/tests/test-errori.sh" >/dev/null 2>&1 && ok "una voce completa: verde" || ko "una voce completa: rosso"
head -6 "$S/docs/errori/REGISTRO.md" > "$S/reg.tmp" && mv "$S/reg.tmp" "$S/docs/errori/REGISTRO.md"
OUT=$(bash "$S/tests/test-errori.sh" 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -c "tolte" <<<"$OUT" >/dev/null && ok "voce tolta rispetto a HEAD: rosso (il registro non si svuota)" || ko "voce tolta e lente verde (rc $RC)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
