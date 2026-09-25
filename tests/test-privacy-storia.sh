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

TRACCIATI=$(git ls-files)   # (E-002: `git ls-files | grep -c` sotto pipefail puo' morire di SIGPIPE) >/dev/null
! grep -q leak <<<"$TRACCIATI" && ok "il file col leak non è più tracciato oggi" \
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

# (2026-09-25, D38, risposta delegata): la storia di graphify-out/ esce dalla scansione. E' un file generato (circa 73
# versioni al giorno, il 73% del tempo del check), e passa comunque dal cancello delle forme prima del push (V1 R3).
# Le forme di segreto nella storia restano cercate ovunque tranne li'; i file di OGGI si guardano tutti.
G=$(mktemp -d); mkdir -p "$G/tools" "$G/night-shift" "$G/graphify-out"; cp "$HERE/tools/privacy-check.sh" "$G/tools/"
printf 'REPO-T=finto/segreto-storico\n' > "$G/night-shift/repos.key"
git -C "$G" init -q && git -C "$G" add tools/ && git -C "$G" -c user.email=t@t -c user.name=t commit -qm tools
echo '{"label":"finto/segreto-storico"}' > "$G/graphify-out/graph.json"
git -C "$G" add graphify-out && git -C "$G" -c user.email=t@t -c user.name=t commit -qm "grafo"
echo '{}' > "$G/graphify-out/graph.json"
git -C "$G" add graphify-out && git -C "$G" -c user.email=t@t -c user.name=t commit -qm "grafo nuovo"
OUT3=$(bash "$G/tools/privacy-check.sh" 2>&1); RC3=$?
[ $RC3 -eq 0 ] && ! grep -q "storia:" <<<"$OUT3" && ok "D38: la storia di graphify-out/ non si scansiona" \
  || ko "D38: la storia del grafo e' ancora scansionata (rc=$RC3): $(grep -m1 'storia:' <<<"$OUT3")"
echo '{"label":"finto/segreto-storico"}' > "$G/graphify-out/graph.json"; git -C "$G" add graphify-out
OUT3=$(bash "$G/tools/privacy-check.sh" 2>&1); RC3=$?
[ $RC3 -eq 1 ] && ok "D38: il grafo di OGGI resta guardato" || ko "D38: il grafo corrente non e' piu' guardato (rc=$RC3)"
rm -rf "$G"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
