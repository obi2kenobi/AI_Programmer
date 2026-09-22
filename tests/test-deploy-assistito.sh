#!/bin/bash
# test-deploy-assistito.sh — il rituale del deploy assistito (dominio, Luca
# 2026-09-23): il sistema PREPARA (pacchetto firmato, verifica verde), l'umano
# ESEGUE (gesto a voce, dal suo terminale). Prova: pacchetto creato su verify
# verde e rifiutato su verify rossa; il gesto rifiutato non deploea; il
# pacchetto scaduto (24h) non si deploea manco col si.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/llm/_timeout.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d); export TMP
trap 'rm -rf "$TMP"' EXIT
export HOME_BAK="$HOME"; export HOME="$TMP"
mkdir -p "$TMP/llm" "$TMP/tools" "$TMP/bin"
cp "$HERE/llm/_timeout.sh" "$TMP/llm/"
cp "$HERE/tools/prepara-deploy.sh" "$HERE/tools/deploy-ora.sh" "$TMP/tools/"
# npx finto: il deploy vero non si tocca nel banco — registra e vince
printf '#!/bin/bash\necho "CLASP-FINTO $*"\nexit 0\n' > "$TMP/bin/npx"; chmod +x "$TMP/bin/npx"
export PATH="$TMP/bin:$PATH"

mkrepo() { # $1 nome, $2 verify (true|false)
  mkdir -p "$TMP/$1/.git" "$TMP/night-shift-work/$1"
  ( cd "$TMP/$1" && git init -q . && git commit -qm base --allow-empty \
    && printf '%s\n' "$2" > .night-verify && printf 'function x(){}\n' > app.gs \
    && git add -A && git commit -qm app ) >/dev/null 2>&1
}

mkrepo repo-verde true
mkrepo repo-rossa false

bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-verde" >/dev/null 2>&1 \
  && [ -f "$TMP/deploy-pronto/repo-verde/MANIFEST.md" ] && [ -f "$TMP/deploy-pronto/repo-verde/commit.txt" ] \
  && ok "verify verde → pacchetto pronto (manifest + commit congelato)" \
  || ko "verify verde ma niente pacchetto"

bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-rossa" >/dev/null 2>&1 \
  && ko "verify ROSSA ma il pacchetto e' pronto: si deploea robaccia" \
  || ok "verify rossa → nessun pacchetto"

echo no | bash "$TMP/tools/deploy-ora.sh" repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] \
  && ok "gesto rifiutato (no) → nessun deploy, nessuno storico" \
  || ko "il no ha comunque deploeato!"

touch -t 202001010000 "$TMP/deploy-pronto/repo-verde/preparato-at.txt"
echo si | bash "$TMP/tools/deploy-ora.sh" repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] \
  && ok "pacchetto scaduto (24h) → il si non basta, niente deploy" \
  || ko "il si su un pacchetto scaduto ha deploeato!"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
