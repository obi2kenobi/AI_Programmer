#!/bin/bash
# test-privacy-storia.sh — privacy-check.sh v3 (nuovo ciclo 10 giri): il guardiano deve
# vedere anche un nome/termine committato e poi RIMOSSO dal file corrente — prima
# (v1/v2, solo `git ls-files`) diceva "pulito" perché il file di oggi non lo contiene,
# anche se resta leggibile per sempre nella storia git. Caso reale, non ipotetico: è
# esattamente l'incidente citato in dev-critic/SKILL.md (credenziali committate poi
# tolte da un file, mai dalla storia).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tools" "$TMP/night-shift"
cp "$HERE/tools/privacy-check.sh" "$TMP/tools/"
printf 'REPO-T=finto/segreto-storico\n' > "$TMP/night-shift/repos.key"
cd "$TMP"
git init -q
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

# commit che introduce il nome, poi commit che lo rimuove dal file
echo "citiamo finto/segreto-storico qui" > leak.md
git add leak.md tools/
git -c user.email=t@t -c user.name=t commit -q -m "oops: commit col nome vero"
git rm -q leak.md
git -c user.email=t@t -c user.name=t commit -q -m "fix: rimosso il nome (ma resta nella storia)"

! git ls-files | grep -q leak && ok "il file col leak non è più tracciato oggi" \
  || ko "il file dovrebbe essere già rimosso"

OUT=$(bash tools/privacy-check.sh 2>&1); RC=$?
[ $RC -eq 1 ] && ok "il check FALLISCE anche se il file corrente è pulito (rc=1)" \
  || ko "il check dice pulito nonostante il leak nella storia (rc=$RC): $OUT"
grep -q "storia:" <<<"$OUT" && ok "il messaggio indica che il leak è nella storia, non nei file correnti" \
  || ko "manca l'indicazione 'storia:': $OUT"

# commit di test nel MESSAGGIO (non nel contenuto di un file)
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: nota su finto/segreto-storico nel messaggio"
OUT2=$(bash tools/privacy-check.sh 2>&1); RC2=$?
[ $RC2 -eq 1 ] && grep -q "messaggio:" <<<"$OUT2" && ok "il check vede anche il leak in un messaggio di commit" \
  || ko "leak nel messaggio non rilevato (rc=$RC2): $OUT2"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
