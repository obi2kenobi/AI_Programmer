#!/bin/bash
# test-privacy.sh — privacy-check v2 sotto prova (giro 4/10).
# Il guardiano si prova quando DEVE fallire: si pianta una leak in un file temporaneo
# e il check deve vederla. Persone e termini aziendali oltre ai nomi di repo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# il check lavora su git ls-files: serve un repo git temporaneo col tool copiato
TMP=$(mktemp -d)
mkdir -p "$TMP/tools" "$TMP/night-shift"
cp "$HERE/tools/privacy-check.sh" "$TMP/tools/"
printf '# chiave di test\nREPO-T=finto/prova\nPERSONA=IlPagoDelleCose\nTERMINI=SuperSegretoAziendale\n' > "$TMP/night-shift/repos.key"
git -C "$TMP" init -q && git -C "$TMP" add tools/ && git -C "$TMP" -c user.email=t@t -c user.name=t commit -qm tools

# 1) pulito: passa
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "pulito: exit 0" || ko "pulito rc=$RC: $OUT"

# 2) leak di REPO nel file versionato → deve fallire
echo "guarda finto/prova" > "$TMP/docs.md" && git -C "$TMP" add docs.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "finto/prova\|NOME PRIVATO" <<<"$OUT" && ok "leak repo: FAIL con il nome citato" || ko "leak repo rc=$RC"
rm "$TMP/docs.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached docs.md

# 3) leak di PERSONA → deve fallire (nuovo in v2)
echo "chiesto a IlPagoDelleCose" > "$TMP/nota.md" && git -C "$TMP" add nota.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
if [ $RC -eq 1 ]; then ok "leak persona: FAIL (v2)"; elif grep -q "non ancora" <<<"$OUT"; then ko "v2 non implementata: $OUT"; else ko "persona rc=$RC"; fi
rm "$TMP/nota.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached nota.md

# 4) leak di TERMINE aziendale → deve fallire (nuovo in v2)
echo "progetto SuperSegretoAziendale" > "$TMP/x.md" && git -C "$TMP" add x.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && ok "leak termine: FAIL (v2)" || ko "termine rc=$RC"
rm "$TMP/x.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached x.md

# 5) la chiave stessa non è versionata → non conta come leak
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "la chiave locale non versionata non è leak" || ko "fine rc=$RC: $OUT"

# 6) v4 (2026-08-24, report dal campo): chiave ASSENTE = gate degradato, NON "pulito"
rm "$TMP/night-shift/repos.key"
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "GATE DEGRADATO" <<<"$OUT" \
  && ok "chiave assente: exit 1 con GATE DEGRADATO dichiarato (non 'pulito')" \
  || ko "chiave assente: rc=$RC — il gate cieco si spaccia ancora per pulito: $OUT"

# 7) bug reale (revisione 14 lenti, 2026-08-28): repos.key SENZA newline finale — `while
# read` salta silenziosamente l'ultima riga, un nome sensibile su quella riga passava
# "pulito" per errore. printf senza \n finale riproduce esattamente il caso.
printf '# chiave di test\nREPO-T=finto/prova\nREPO-U=ultimo/senzanewline' > "$TMP/night-shift/repos.key"
echo "guarda ultimo/senzanewline" > "$TMP/leak-ultima-riga.md" && git -C "$TMP" add leak-ultima-riga.md
OUT=$(bash "$TMP/tools/privacy-check.sh" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "ultimo/senzanewline" <<<"$OUT" \
  && ok "repos.key senza newline finale: ultima riga letta comunque, leak rilevato" \
  || ko "ultima riga di repos.key ignorata silenziosamente: rc=$RC — $OUT"
rm "$TMP/leak-ultima-riga.md" && git -C "$TMP" add -A 2>/dev/null || git -C "$TMP" rm -q --cached leak-ultima-riga.md

rm -rf "$TMP"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
