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
# (revisione 10 giri, 2026-09-23): con HOME spostato git perde l'identita' del
# ~/.gitconfig — i `git commit` di mkrepo fallivano in silenzio (>/dev/null), il
# repo non aveva HEAD e prepara-deploy moriva su rev-parse: 2 rossi del BANCO,
# non del tool (riprodotto: con un'identita' il pacchetto nasce). Identita' esplicita.
export GIT_AUTHOR_NAME=banco GIT_AUTHOR_EMAIL=banco@example.invalid
export GIT_COMMITTER_NAME=banco GIT_COMMITTER_EMAIL=banco@example.invalid
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
# (audit-2): la copia di lavoro deve essere un REPO vero, non una directory
# vuota — deploy-ora ci fa cd e rev-parse: il percorso felice moriva qui
git clone -q "$TMP/repo-verde" "$TMP/night-shift-work/repo-verde" 2>/dev/null || true
git clone -q "$TMP/repo-rossa" "$TMP/night-shift-work/repo-rossa" 2>/dev/null || true

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

# (audit-2): il check legge il CONTENUTO (epoch), non l'mtime — toccare il file
# non scadeva niente e il test passava due volte per sbaglio
echo 946684800 > "$TMP/deploy-pronto/repo-verde/preparato-at.txt"
echo si | bash "$TMP/tools/deploy-ora.sh" repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] \
  && ok "pacchetto scaduto (24h) → il si non basta, niente deploy" \
  || ko "il si su un pacchetto scaduto ha deploeato!"

# ── (audit-2): il PERCORSO FELICE — si + pacchetto fresco + commit coincidente
# → clasp (finto) eseguito, STORICO scritto, pacchetto consumato. La strada che
# tocca la produzione non era mai stata provata.
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-verde" >/dev/null 2>&1
echo si | bash "$TMP/tools/deploy-ora.sh" repo-verde >/dev/null 2>&1
if [ -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && grep -q "CLASP-FINTO" "$TMP/deploy-pronto/repo-verde/STORICO.log" && grep -q "OK$" "$TMP/deploy-pronto/repo-verde/STORICO.log"; then
  ok "percorso felice: si → clasp eseguito, STORICO scritto"
  [ -f "$TMP/deploy-pronto/repo-verde/MANIFEST.md" ] && ko "il pacchetto NON e' stato consumato dopo il deploy" || ok "pacchetto consumato dopo il deploy"
else
  ko "percorso felice rotto: il si non ha deploeato ($(head -c 80 "$TMP/deploy-pronto/repo-verde/STORICO.log" 2>/dev/null))"
fi

# ── (revisione 10 giri, 2026-09-23): il gesto spediva cio' che il manifest non firmava ──
# deploy-ora guardava solo HEAD == commit firmato: una modifica NON committata o un file NON
# tracciato nella copia di lavoro (quella dove il turno notturno lavora) andava in produzione.
WORK="$TMP/night-shift-work/repo-verde"
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-verde" >/dev/null 2>&1
( cd "$WORK" && git checkout -q "$(cat "$TMP/deploy-pronto/repo-verde/commit.txt")" 2>/dev/null )
echo 'function sporca(){}' >> "$WORK/app.gs"
rm -f "$TMP/deploy-pronto/repo-verde/STORICO.log"
echo si | bash "$TMP/tools/deploy-ora.sh" repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && ok "copia di lavoro con modifiche non committate → nessun deploy" \
  || ko "deploy di modifiche NON firmate (albero sporco)"
( cd "$WORK" && git checkout -q -- app.gs )
echo 'function intrusa(){}' > "$WORK/intruso.gs"
echo si | bash "$TMP/tools/deploy-ora.sh" repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && ok "file NON tracciato nella copia di lavoro → nessun deploy" \
  || ko "deploy con un file non tracciato (clasp lo spedisce)"
rm -f "$WORK/intruso.gs"

# prepara-deploy: «verifica verde» senza verifiche e' una frase falsa nel manifest
mkrepo repo-vuota '# solo commenti'
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-vuota" >/dev/null 2>&1 \
  && ko ".night-verify senza comandi ma pacchetto pronto («verifica verde» falsa)" \
  || ok ".night-verify senza comandi → nessun pacchetto (verifiche-vuote, come gli altri lettori)"
# prepara-deploy: un file non tracciato nel repo non e' un albero pulito
echo 'x' > "$TMP/repo-verde/nuovo.gs"
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-verde" >/dev/null 2>&1 \
  && ko "file non tracciato nel repo ma pacchetto pronto" || ok "file non tracciato nel repo → nessun pacchetto (albero non pulito)"
rm -f "$TMP/repo-verde/nuovo.gs"
# prepara-deploy: FORMATO script si esegue intero (come turno, gate e censore)
mkdir -p "$TMP/repo-script/.git"
( cd "$TMP/repo-script" && git init -q . && printf '# FORMATO: script\nX=1\nif [ "$X" = 1 ]; then\n  true\nfi\n' > .night-verify \
  && printf 'function y(){}\n' > app.gs && git add -A && git commit -qm s ) >/dev/null 2>&1
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-script" >/dev/null 2>&1 \
  && ok "FORMATO script: eseguito intero, pacchetto pronto" || ko "FORMATO script eseguito riga per riga (rosso falso)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
