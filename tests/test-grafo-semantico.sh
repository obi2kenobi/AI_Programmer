#!/bin/bash
# test-grafo-semantico.sh — il pass del grafo sotto prova. (2026-09-25, settimo ventaglio, V3 R2): un pass del grafo partito il 25 e finito
# dopo mezzanotte prendeva il ramo, il commit e il titolo del 26 (tre `date +%F` a fine pass), mentre il segno del
# turno diceva 25. Il pass del 26 moriva al push: il ramo c'era gia'. Ora il turno passa GRAFO_DATA, la data del
# segno, e vale per ramo, commit e titolo. Qui la `date` finta dice sempre 26: il ramo deve dire 25.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
g() { git -c user.email=t@t -c user.name=t -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
mkdir -p "$T/bin" "$T/work" "$T/home"
g init -q --bare -b main "$T/remoto.git"
g clone -q "$T/remoto.git" "$T/seme" 2>/dev/null
echo "# x" > "$T/seme/README.md"; g -C "$T/seme" add README.md; g -C "$T/seme" commit -qm inizio; g -C "$T/seme" push -q origin main 2>/dev/null
g clone -q "$T/remoto.git" "$T/work/grafo-prova"
VERA=$(command -v date)
printf '#!/bin/bash\n[ "$*" = "+%%F" ] && { echo 2026-09-26; exit 0; }\nexec %q "$@"\n' "$VERA" > "$T/bin/date"
printf '#!/bin/bash\nif [ "$1" = extract ]; then mkdir -p graphify-out; echo "{\\"n\\":$RANDOM,\\"t\\":\\"${FORMA:-}\\"}" > graphify-out/graph.json; fi\nexit 0\n' > "$T/bin/graphify"
printf '#!/bin/bash\necho "$*" >> %q\necho https://example.invalid/pr/1\n' "$T/gh.log" > "$T/bin/gh"
chmod +x "$T/bin/"*

OUT=$(cd "$T" && HOME="$T/home" GIT_CONFIG_GLOBAL=/dev/null PATH="$T/bin:$PATH" GRAFO_DATA=2026-09-25 \
  GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
  bash "$HERE/tools/grafo-semantico.sh" obi2kenobi/prova "$T/work" 2>&1); RC=$?
RAMI=$(git -C "$T/remoto.git" branch --format='%(refname:short)' | tr '\n' ' ')
grep -cw 'night/grafo-2026-09-25' <<<"$RAMI" >/dev/null && ! grep -cw 'night/grafo-2026-09-26' <<<"$RAMI" >/dev/null \
  && ok "V3 R2: il ramo prende la data del segno (GRAFO_DATA), non quella di fine pass" \
  || ko "V3 R2: rami sul remoto «$RAMI» (rc=$RC): $(tail -2 <<<"$OUT" | tr '\n' ' ')"
grep -cF 'grafo semantico 2026-09-25' "$T/gh.log" >/dev/null 2>&1 && ok "V3 R2: il titolo della PR dice la stessa data" \
  || ko "V3 R2: titolo della PR: $(cat "$T/gh.log" 2>/dev/null | head -1 | cut -c1-120)"
MSG=$(git -C "$T/remoto.git" log -1 --format=%s night/grafo-2026-09-25 2>/dev/null)
grep -cF 'notturno 2026-09-25' <<<"$MSG" >/dev/null && ok "V3 R2: il commit dice la stessa data" || ko "V3 R2: messaggio del commit «$MSG»"
# il turno passa la data del segno
grep -cE 'GRAFO_DATA="\$GRAFO_DATA"[^#]*grafo-semantico\.sh' "$HERE/night-shift/night-shift.sh" >/dev/null \
  && grep -cF 'GRAFO_MARKER="$WORK/.grafo-$GRAFO_DATA"' "$HERE/night-shift/night-shift.sh" >/dev/null \
  && ok "V3 R2: night-shift.sh calcola la data una volta e la passa al pass" \
  || ko "V3 R2: night-shift.sh non passa al pass la data del segno"

# (settimo ventaglio, V1 R3): dei cinque push notturni questo era l'unico senza il cancello delle forme: un grafo
# scritto da un modello con una forma di token arrivava sul remoto, e la lente la vedeva solo DOPO il push. Il
# token si compone a runtime (E-007) e non deve mai comparire nell'uscita.
TOK="gh""p_$(printf 'Z%.0s' $(seq 1 24))"
OUT=$(cd "$T" && HOME="$T/home" GIT_CONFIG_GLOBAL=/dev/null PATH="$T/bin:$PATH" GRAFO_DATA=2026-09-27 FORMA="$TOK" \
  GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
  bash "$HERE/tools/grafo-semantico.sh" obi2kenobi/prova "$T/work" 2>&1); RC=$?
RAMI=$(git -C "$T/remoto.git" branch --format='%(refname:short)' | tr '\n' ' ')
[ "$RC" -ne 0 ] && ! grep -cw 'night/grafo-2026-09-27' <<<"$RAMI" >/dev/null \
  && ok "V1 R3: una forma di segreto nel grafo ferma il push (il ramo non arriva al remoto)" \
  || ko "V1 R3: grafo con una forma di segreto: rc=$RC, rami «$RAMI»"
! grep -cF "$TOK" <<<"$OUT" >/dev/null && ok "V1 R3: il valore non compare nell'uscita" || ko "V1 R3: il valore compare nell'uscita"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
