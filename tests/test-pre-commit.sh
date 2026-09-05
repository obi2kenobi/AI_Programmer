#!/bin/bash
# test-pre-commit.sh — il gancio rapido sotto prova, COL SUO METODO: caso
# avverso vero (glifo staged → rosso) e caso pulito. Nato dall'incasso subito
# in prima persona: la prima versione dell'hook diceva OK col glifo staged
# perché il grep BSD di macOS non ha -P e moriva nel silenzio del 2>/dev/null
# — falso verde trovato verificando l'hook esattamente come lui verifica gli
# altri (il tool si prova quando DEVE fallire).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/pre-commit.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$HOOK" && ok "sintassi" || ko "sintassi rotta"
[ -x "$HERE/.githooks/pre-commit" ] && ok "il gancio git esiste ed è eseguibile" || ko ".githooks/pre-commit assente"
grep -q "git grep -lP" "$HOOK" && ok "usa git grep -P (il grep BSD non ha -P: falso verde storico)" || ko "usa grep -P nudo: muore in silenzio su macOS"

# caso avverso: glifo staged → rosso (costruito a runtime, E-007)
PROBE="$HERE/docs/_probe_glifo.md"
cleanup() { git -C "$HERE" restore --staged "$PROBE" >/dev/null 2>&1; rm -f "$PROBE"; }
trap cleanup EXIT
GLIFO=$(python3 -c "print(chr(0x81ea))")
printf 'test %s dentro\n' "$GLIFO" > "$PROBE"
git -C "$HERE" add "$PROBE"
OUT=$(bash "$HOOK"); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -qi "alieni" \
  && ok "glifo staged: l'hook diventa rosso e dice perché" \
  || ko "glifo staged NON visto (rc=$RC) — falso verde"
cleanup

# nomi NUDI col convenzione: un .md staged che cita un report di campo per
# basename NON è pendente (docs/campo/ è una delle radici di risoluzione)
PROBE2="$HERE/docs/_probe_menu.md"
printf 'vedi `2026-08-28-repo-l-fix.md` e `indici_crisi.py`\n' > "$PROBE2"
git -C "$HERE" add "$PROBE2"
OUT=$(bash "$HOOK"); RC=$?
[ "$RC" -eq 0 ] && ok "nomi nudi risolti contro tools/ e docs/campo/ (convenzioni)"   || { echo "$OUT" | grep pendenti | head -1 | sed 's/^/    /'; ko "convenzione dei nomi nudi non risolta"; }
git -C "$HERE" restore --staged "$PROBE2" >/dev/null 2>&1; rm -f "$PROBE2"

# pipeline seguita da && (controllo 5, report REPO-W 5/9: la regola-prosa violata
# 3 volte in una sessione) — il dente deve diventare rosso sul colpevole
PROBE3="$HERE/tools/_probe_pipe_and.sh"
# il colpevole si costruisce con %s: il sorgente del test NON contiene il pattern
# (il dente morde anche chi scrive la sonda che lo prova — accaduto, 5/9)
printf '#!/bin/bash\ncmd | tail -1 %s git commit -m x\n' '&&' > "$PROBE3"
chmod +x "$PROBE3"
git -C "$HERE" add "$PROBE3"
OUT=$(bash "$HOOK"); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "pipeline" && ok "pipe+&& staged: il dente morde" \
  || ko "pipe+&& NON visto (rc=$RC) — la regola del 3/9 è ancora sola prosa"
git -C "$HERE" restore --staged "$PROBE3" >/dev/null 2>&1; rm -f "$PROBE3"

# e il benigno (|| true, pipe senza &&) non deve scattare
PROBE4="$HERE/tools/_probe_pipe_ok.sh"
printf '#!/bin/bash\nls | xargs grep -l foo 2>/dev/null || true\ngrep -q x file || exit 1\n' > "$PROBE4"
git -C "$HERE" add "$PROBE4"
OUT=$(bash "$HOOK"); RC=$?
[ "$RC" -eq 0 ] && ok "pipe senza && : via libera (nessun falso positivo)" \
  || { echo "$OUT" | grep pipeline | head -1 | sed 's/^/    /'; ko "falso positivo su pipe legittima"; }
git -C "$HERE" restore --staged "$PROBE4" >/dev/null 2>&1; rm -f "$PROBE4"

# caso pulito: nessun file staged → via libera
OUT=$(bash "$HOOK"); RC=$?
[ "$RC" -eq 0 ] && ok "niente staged: via libera" || { echo "$OUT" | tail -2 | sed 's/^/    /'; ko "rosso a vuoto"; }

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
