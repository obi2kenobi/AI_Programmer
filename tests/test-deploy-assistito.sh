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

# (2026-09-23, giro A7 della notte): il gesto si fa in un TERMINALE (pty) e fuori da una sessione
# agente — com'e' quello di Luca. Prima il banco faceva `echo si |` da una sessione agente: la
# stessa strada con cui un agente deploiava davvero (deploy-ora leggeva il «si» dalla pipe).
gesto() { # gesto <risposta> <repo>
  if script --version >/dev/null 2>&1; then
    printf '%s\n' "$1" | env -u CLAUDECODE script -qec "bash $(printf %q "$TMP/tools/deploy-ora.sh") $(printf %q "$2")" /dev/null
  else
    printf '%s\n' "$1" | env -u CLAUDECODE script -q /dev/null bash "$TMP/tools/deploy-ora.sh" "$2"
  fi
}

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

gesto no repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] \
  && ok "gesto rifiutato (no) → nessun deploy, nessuno storico" \
  || ko "il no ha comunque deploeato!"

# (2026-09-23, giro A7): un agente NON deploia — ne' dichiarandosi agente, ne' fingendo il si in pipe
OUT=$(echo si | CLAUDECODE=1 bash "$TMP/tools/deploy-ora.sh" repo-verde 2>&1); RC=$?
[ "$RC" -ne 0 ] && [ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && grep -qi "sessione agente" <<<"$OUT" \
  && ok "da una sessione agente (CLAUDECODE): rifiutato, nessun deploy" || ko "una sessione agente ha deploiato (o non ha detto perche'): rc $RC"
OUT=$(echo si | env -u CLAUDECODE bash "$TMP/tools/deploy-ora.sh" repo-verde 2>&1); RC=$?
[ "$RC" -ne 0 ] && [ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && grep -qi "terminale" <<<"$OUT" \
  && ok "un «si» in pipe, senza terminale: rifiutato, nessun deploy" || ko "un si in pipe ha deploiato: rc $RC"

# (audit-2): il check legge il CONTENUTO (epoch), non l'mtime — toccare il file
# non scadeva niente e il test passava due volte per sbaglio
echo 946684800 > "$TMP/deploy-pronto/repo-verde/preparato-at.txt"
gesto si repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] \
  && ok "pacchetto scaduto (24h) → il si non basta, niente deploy" \
  || ko "il si su un pacchetto scaduto ha deploeato!"

# ── (audit-2): il PERCORSO FELICE — si + pacchetto fresco + commit coincidente
# → clasp (finto) eseguito, STORICO scritto, pacchetto consumato. La strada che
# tocca la produzione non era mai stata provata.
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-verde" >/dev/null 2>&1
gesto si repo-verde >/dev/null 2>&1
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
gesto si repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && ok "copia di lavoro con modifiche non committate → nessun deploy" \
  || ko "deploy di modifiche NON firmate (albero sporco)"
( cd "$WORK" && git checkout -q -- app.gs )
echo 'function intrusa(){}' > "$WORK/intruso.gs"
gesto si repo-verde >/dev/null 2>&1
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && ok "file NON tracciato nella copia di lavoro → nessun deploy" \
  || ko "deploy con un file non tracciato (clasp lo spedisce)"
rm -f "$WORK/intruso.gs"

# ── (2026-09-24, terzo ventaglio, V2#3): i due punti della produzione che nessun banco giudicava ──
# (a) HEAD AVANZATO e albero pulito: il controllo «commit firmato» si toglieva a banco verde, e un «si»
#     deploiava un commit mai firmato. (b) clasp che fallisce: mai provato — il npx finto vinceva sempre.
bash "$TMP/tools/prepara-deploy.sh" "$TMP/repo-verde" >/dev/null 2>&1
( cd "$WORK" && git checkout -q "$(cat "$TMP/deploy-pronto/repo-verde/commit.txt")" 2>/dev/null \
  && echo 'function nonfirmata(){}' >> app.gs && git -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qam "non firmato" )
rm -f "$TMP/deploy-pronto/repo-verde/STORICO.log"
OUT=$(gesto si repo-verde 2>&1)
[ ! -f "$TMP/deploy-pronto/repo-verde/STORICO.log" ] && grep -c "non e' quello firmato" <<<"$OUT" >/dev/null \
  && ok "HEAD avanzato su un commit non firmato, albero pulito → nessun deploy, e lo dice" || ko "deploy di un commit NON firmato (albero pulito): $(grep -m1 -E 'deploy|firmato' <<<"$OUT")"
( cd "$WORK" && git checkout -q "$(cat "$TMP/deploy-pronto/repo-verde/commit.txt")" 2>/dev/null )
printf '#!/bin/bash\necho "CLASP-FINTO $* — errore di autenticazione"\nexit 1\n' > "$TMP/bin/npx"
rm -f "$TMP/deploy-pronto/repo-verde/STORICO.log"
gesto si repo-verde >/dev/null 2>&1
grep -c "FALLITO$" "$TMP/deploy-pronto/repo-verde/STORICO.log" >/dev/null 2>&1 && ! grep -c " OK$" "$TMP/deploy-pronto/repo-verde/STORICO.log" >/dev/null 2>&1 \
  && [ -f "$TMP/deploy-pronto/repo-verde/MANIFEST.md" ] \
  && ok "clasp che fallisce → STORICO dice FALLITO, e il pacchetto resta (non consumato)" || ko "clasp fallito registrato come riuscito, o pacchetto consumato: $(tail -1 "$TMP/deploy-pronto/repo-verde/STORICO.log" 2>/dev/null)"
printf '#!/bin/bash\necho "CLASP-FINTO $*"\nexit 0\n' > "$TMP/bin/npx"; chmod +x "$TMP/bin/npx"

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
