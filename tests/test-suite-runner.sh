#!/bin/bash
# test-suite-runner.sh — tools/suite.sh sotto prova (E-029: era una riga composta
# in .night-verify sopravvissuta per caso). Prova il runner su una suite finta:
# tutti verdi → rc 0 e riepilogo N/TOT; uno rosso → rc 1, nome e output del file.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$HERE/tools/suite.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$RUNNER" && ok "sintassi" || { ko "sintassi"; exit 1; }

SB=$(mktemp -d /tmp/test-suite.XXXXXX); trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/tests"
printf '#!/bin/bash\necho "vero"\necho "1 OK, 0 FAIL"\n' > "$SB/tests/test-uno.sh"
printf '#!/bin/bash\necho "anchesso"\n' > "$SB/tests/tests-due.sh" 2>/dev/null || true
printf '#!/bin/bash\necho "vero due"\necho "2 OK, 0 FAIL — con un suffisso"\n' > "$SB/tests/test-due.sh"

# 1. tutti verdi: rc 0, riepilogo 2/2
OUT=$(bash "$RUNNER" "$SB" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ok "tutti verdi: rc 0" || ko "rc $RC con suite tutta verde"
grep -q "2/2 file superati" <<<"$OUT" && ok "riepilogo N/TOT presente" || ko "riepilogo mancante: $OUT"

# 2. uno rosso: rc 1, NOME del file e suo output (la lezione del giro 7)
printf '#!/bin/bash\necho "dettaglio importante del fallimento"\nexit 7\n' > "$SB/tests/test-tre.sh"
OUT=$(bash "$RUNNER" "$SB" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "uno rosso: rc 1" || ko "rc $RC con un test rosso"
grep -q "test-tre.sh" <<<"$OUT" && ok "il file fallito viene nominato" || ko "non nomina il file fallito"
grep -q "dettaglio importante" <<<"$OUT" && ok "l'output del fallito si vede" || ko "output del fallito perso"

# 3. zero test: rosso dichiarato (verifiche-vuote non passano inosservate)
SB2=$(mktemp -d /tmp/test-suite2.XXXXXX)
mkdir -p "$SB2/tests"
OUT=$(bash "$RUNNER" "$SB2" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "zero test: rc 1 (verifiche-vuote subite)" || ko "rc $RC con zero test"
rm -rf "$SB2"

# 3b. (revisione 10 giri, 2026-09-23): VERDE SENZA VERDETTO. Otto test caricano una libreria con
# `source`: se la libreria esce (exit 0), il test muore VERDE senza aver asserito niente
# (provato dalla lente dei test finti). Un test con zero asserzioni esce 0 allo stesso modo.
# Il runner pretende la riga di verdetto «N OK, 0 FAIL» con N >= 1 — 155/156 la stampavano
# gia' identica, l'ultimo con un suffisso.
SB3=$(mktemp -d /tmp/test-suite3.XXXXXX); mkdir -p "$SB3/tests"
printf '#!/bin/bash\nexit 0\n' > "$SB3/tests/test-muto.sh"
OUT=$(bash "$RUNNER" "$SB3" 2>&1); RC=$?
[ "$RC" -eq 1 ] && grep -q "senza verdetto" <<<"$OUT" && ok "test che esce 0 senza verdetto: ROSSO (verde muto)" || ko "verde muto accettato (rc $RC)"
printf '#!/bin/bash\necho "0 OK, 0 FAIL"\n' > "$SB3/tests/test-muto.sh"
OUT=$(bash "$RUNNER" "$SB3" 2>&1); RC=$?
[ "$RC" -eq 1 ] && ok "zero asserzioni («0 OK, 0 FAIL»): ROSSO" || ko "zero asserzioni accettate (rc $RC)"
rm -rf "$SB3"

# 4. il runner e' dichiarato in .night-verify come UN COMANDO per riga
grep -Eq "^(@[0-9]+ )?bash tools/suite\.sh$" "$HERE/.night-verify" && ok "dichiarato in .night-verify" \
  || ko ".night-verify non invoca suite.sh"

# (2026-09-24, terzo ventaglio, V2#2): il riepilogo contava i GIRI del ciclo, non i banchi eseguiti — col
# ciclo sabotato (`[ "$N" -gt 5 ] && continue`) stampava «170/170 superati» avendone eseguiti 5. Qui 7
# banchi lasciano ognuno un segno, e il runner deve eseguirli tutti; e un runner che ne salta uno e' rosso.
SB3=$(mktemp -d /tmp/test-suite3.XXXXXX); mkdir -p "$SB3/tests"
for i in 1 2 3 4 5 6 7; do printf '#!/bin/bash\ntouch "%s/segno-%s"\necho "1 OK, 0 FAIL"\n' "$SB3" "$i" > "$SB3/tests/test-s$i.sh"; done
OUT=$(bash "$RUNNER" "$SB3" 2>&1); RC=$?
[ "$RC" -eq 0 ] && [ "$(ls "$SB3"/segno-* 2>/dev/null | wc -l | tr -d ' ')" -eq 7 ] && grep -c "7/7 file superati" <<<"$OUT" >/dev/null \
  && ok "7 banchi: tutti eseguiti (7 segni) e «7/7»" || ko "banchi eseguiti: $(ls "$SB3"/segno-* 2>/dev/null | wc -l | tr -d ' ') su 7, uscita: $(tail -1 <<<"$OUT")"
# il runner sabotato come nel giro: salta dal sesto in poi — deve dirlo, non stampare 7/7
sed 's/^  N=\$((N+1))$/  N=$((N+1)); [ "$N" -gt 5 ] \&\& continue/' "$RUNNER" > "$SB3/runner-saltante.sh"
grep -c 'N" -gt 5' "$SB3/runner-saltante.sh" >/dev/null || ko "il sabotaggio del runner non si e' applicato: la riga N=… e' cambiata"
OUT=$(bash "$SB3/runner-saltante.sh" "$SB3" 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -c "7/7 file superati" <<<"$OUT" >/dev/null && ok "un runner che salta banchi e' rosso, non «7/7»" || ko "runner che salta 2 banchi: rc $RC — $(tail -1 <<<"$OUT")"
rm -rf "$SB3"

# 5. (2026-09-24, E-047): il bytecode stantio. Un sabotaggio a mano che cambia 2.1 in «21 » lascia il file
# della stessa dimensione, e nello stesso secondo il .pyc in tools/__pycache__ resta «valido»: il banco che
# importa il modulo gira col codice di PRIMA. Due sabotaggi diversi davano lo stesso FAIL. La suite deve
# giudicare il sorgente, non la cache.
SB5=$(mktemp -d /tmp/test-suite5.XXXXXX); mkdir -p "$SB5/tools" "$SB5/tests"
printf 'X = 2.1\n' > "$SB5/tools/m.py"
# fuori dalla cache della suite che sta girando questo banco: qui serve il __pycache__ vero, e il runner
# sotto prova deve crearsi la SUA cache, non ereditare quella di fuori
(cd "$SB5" && env -u PYTHONPYCACHEPREFIX python3 -c 'import sys; sys.path.insert(0, "tools"); import m') 2>/dev/null
touch -r "$SB5/tools/m.py" "$SB5/rif"; printf 'X = 21 \n' > "$SB5/tools/m.py"; touch -r "$SB5/rif" "$SB5/tools/m.py"
printf '#!/bin/bash\ncd "$(dirname "$0")/.."\npython3 -c "import sys; sys.path.insert(0, \\"tools\\"); import m; sys.exit(0 if m.X == 21 else 1)" && echo "1 OK, 0 FAIL" || { echo "0 OK, 1 FAIL"; exit 1; }\n' > "$SB5/tests/test-m.sh"
if ls "$SB5"/tools/__pycache__/m.*.pyc >/dev/null 2>&1; then
  OUT=$(env -u PYTHONPYCACHEPREFIX bash "$RUNNER" "$SB5" 2>&1); RC=$?
  [ "$RC" -eq 0 ] && ok "la suite legge il sorgente, non un .pyc stantio della stessa dimensione" \
    || ko "la suite ha giudicato il bytecode stantio (rc $RC): $(tail -2 <<<"$OUT")"
else
  ko "premessa: il .pyc di prova non si e' formato"
fi
rm -rf "$SB5"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
