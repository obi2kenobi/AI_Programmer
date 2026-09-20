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

# (D9, test del sistema completo 2026-09-20): il rilevatore che MUORE deve essere rosso.
# `git grep -P` sotto un locale non-UTF muore con rc 128 («code point too large»); la
# vecchia pipeline lo passava a xargs (che mappa 1 E 128 sullo stesso 123) e poi a un
# `grep -v` finale (che lo faceva diventare 1 = «nessun reperto»): la guardia E-024 non
# poteva scattare MAI, e un commit in cirillico e' passato su una macchina senza
# en_US.UTF-8. Qui il locale C forza la morte del rilevatore: il verdetto deve dirlo.
PROBE5="$HERE/docs/_probe_morto.md"
printf 'solo ascii qui\n' > "$PROBE5"
git -C "$HERE" add "$PROBE5"
OUT=$(LC_ALL=C LANG=C bash "$HOOK" 2>/dev/null); RC=$?
if git -C "$HERE" grep -lP '[\x{4E00}]' -- :docs/_probe_morto.md >/dev/null 2>&1 || [ "$(LC_ALL=C LANG=C git -C "$HERE" grep -lP '[\x{4E00}]' -- :docs/_probe_morto.md >/dev/null 2>&1; echo $?)" -lt 2 ]; then
  echo "· D9: su questa macchina git grep -P non muore sotto LC_ALL=C — il caso «morto» non e' forzabile qui (dichiarato)"
else
  [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "MORTO" \
    && ok "D9: rilevatore glifi morto (rc 128) → l'hook e' ROSSO e lo dice" \
    || ko "D9: rilevatore morto e l'hook e' verde (rc=$RC) — falso verde: $(echo "$OUT" | tail -1)"
fi
git -C "$HERE" restore --staged "$PROBE5" >/dev/null 2>&1; rm -f "$PROBE5"

# (D10): il numero-test nel messaggio si controlla nel gancio commit-msg (il pre-commit
# di git non conosce il messaggio: il vecchio .githooks/pre-commit passava "" e il
# controllo 4 non girava MAI dall'hook — «test: 999 test verdi» e' passato).
[ -x "$HERE/.githooks/commit-msg" ] && ok "D10: il gancio commit-msg esiste ed e' eseguibile" || ko "D10: .githooks/commit-msg assente"
MSGF=$(mktemp); printf 'test: 999 test verdi\n' > "$MSGF"
OUT=$(bash "$HOOK" --commit-msg "$MSGF" 2>/dev/null); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "999 test" \
  && ok "D10: messaggio con numero-test sbagliato → rosso dal gancio commit-msg" \
  || ko "D10: «999 test» passa ancora (rc=$RC): $(echo "$OUT" | tail -1)"
printf 'docs: aggiorna il diario\n' > "$MSGF"
OUT=$(bash "$HOOK" --commit-msg "$MSGF" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "D10: messaggio senza numeri-test → via libera" || ko "D10: falso rosso su messaggio benigno: $OUT"
rm -f "$MSGF"

# caso pulito: nessun file staged → via libera
OUT=$(bash "$HOOK"); RC=$?
[ "$RC" -eq 0 ] && ok "niente staged: via libera" || { echo "$OUT" | tail -2 | sed 's/^/    /'; ko "rosso a vuoto"; }

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
