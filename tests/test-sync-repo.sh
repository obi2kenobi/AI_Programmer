#!/bin/bash
# test-sync-repo.sh — 2026-08-24, report sul campo F2: onboard/bootstrap sono a un
# colpo solo, nessuno strumento riallineava. sync-repo.sh lo fa nella forma minima
# (diff + copia). Verifica: allineato=0, divergente=1 col conteggio righe, il verdetto
# è sulla riga finale, e --from-local funziona senza rete (per questo test).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# repo finta ALLINEATA
mkdir -p "$TMP/allineata"
bash "$HERE/tools/claude-md-satellite.sh" > "$TMP/allineata/CLAUDE.md"  # D8: allineata = la versione per i satelliti
# (canarino v2, audit 2026-09-23): allineata vuol dire ANCHE gli hook uguali
mkdir -p "$TMP/allineata/tools"
while IFS= read -r H; do cp "$HERE/$H" "$TMP/allineata/tools/"; done < <(bash "$HERE/tools/copia-hook.sh" --elenco)  # (D1: derivata, non scritta a mano)
bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/allineata" >/dev/null 2>&1
[ $? -eq 0 ] && ok "repo allineata: exit 0" || ko "allineata non riconosciuta"

# repo finta DIVERGENTE (versione vecchia: manca la coda dell'hub)
mkdir -p "$TMP/divergente"
head -50 "$HERE/CLAUDE.md" > "$TMP/divergente/CLAUDE.md"
# (canarino v2): gli hook allineati, cosi' la divergenza misurata e' quella del CLAUDE
mkdir -p "$TMP/divergente/tools"
while IFS= read -r H; do cp "$HERE/$H" "$TMP/divergente/tools/"; done < <(bash "$HERE/tools/copia-hook.sh" --elenco)  # (D1: derivata, non scritta a mano)
OUT=$(bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/divergente" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "DIVERGENTE" <<<"$OUT" \
  && ok "repo divergente: exit 1 col verdetto DIVERGENTE dichiarato" \
  || ko "divergente rc=$RC: $OUT"
grep -qE "dista [0-9]+ righe" <<<"$OUT" \
  && ok "il verdetto porta il conteggio delle righe di distanza" \
  || ko "conteggio righe mancante"
# bug reale (revisione 14 lenti, 2026-08-28): "$HUB_CLAUDE.md" invece di "$HUB_CLAUDE"
# faceva fallire silenziosamente entrambi i diff — DIFF_LINES restava sempre "dista 0
# righe" (che il check sopra, con una regex troppo permissiva, non distingueva da un
# conteggio vero) e il blocco di dettaglio sotto restava vuoto. Verifica esplicita che il
# conteggio sia REALMENTE positivo e che il blocco di dettaglio non sia vuoto.
grep -qE "dista [1-9][0-9]* righe" <<<"$OUT" \
  && ok "il conteggio delle righe è realmente positivo, non sempre 0" \
  || ko "conteggio righe fermo a 0 nonostante una divergenza vera — output: $OUT"
DETTAGLIO=$(echo "$OUT" | grep -c '^  [<>]')
[ "$DETTAGLIO" -gt 0 ] \
  && ok "il blocco di dettaglio diff mostra righe reali ($DETTAGLIO)" \
  || ko "blocco di dettaglio diff vuoto — output: $OUT"

# CLAUDE.md assente → errore esplicito
mkdir -p "$TMP/vuota"
bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/vuota" >/dev/null 2>&1
[ $? -eq 1 ] && ok "CLAUDE.md assente nel progetto: errore esplicito" || ko "assenza silenziosa"

# --- test del sistema completo 2026-09-20 (D11-D14): --standard end-to-end con gh stub ---
# gh e' uno stub: `api contents/CLAUDE.md` risponde dal file $GH_CLAUDE_MD (o 404 se
# assente), `repo clone` clona dal bare $GH_CLONE_SRC, `pr create` stampa una URL.
mkdir -p "$TMP/bin"
bash "$HERE/tools/claude-md-satellite.sh" > "$TMP/claude-sat.md"   # D8: il CLAUDE.md che un satellite allineato ha
cat > "$TMP/bin/gh" <<'EOF'
#!/bin/bash
case "$1 $2" in
  "api "*) [ -f "${GH_CLAUDE_MD:-}" ] && base64 < "$GH_CLAUDE_MD" || { echo "gh: HTTP 404" >&2; exit 1; } ;;
  "repo clone") git clone -q "${GH_CLONE_SRC:?}" "$4" ;;
  "pr create") echo "https://github.invalid/stub/pull/1" ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMP/bin/gh"
nuovo_bare() { # $1=nome $2=con-claude(0/1) → bare in $TMP/$1.git col seed committato
  git init -q --bare "$TMP/$1.git" && git -C "$TMP/$1.git" symbolic-ref HEAD refs/heads/main
  git clone -q "$TMP/$1.git" "$TMP/$1-seed" 2>/dev/null
  printf 'function onOpen(){}\n' > "$TMP/$1-seed/Code.gs"; echo "# $1" > "$TMP/$1-seed/README.md"
  [ "$2" = 1 ] && cp "$HERE/CLAUDE.md" "$TMP/$1-seed/CLAUDE.md"
  git -C "$TMP/$1-seed" add -A && git -C "$TMP/$1-seed" -c user.name=t -c user.email=t@t commit -qm seed && git -C "$TMP/$1-seed" push -q origin HEAD:main 2>/dev/null
}
ramo_standard() { git -C "$TMP/$1.git" branch --list 'claude/standard-*' | tr -d ' *' | head -1; }

# D11: repo VUOTA (senza CLAUDE.md) — il comando insegnato deve onboardarla, non morire
nuovo_bare vuota-remota 0
OUT=$(cd "$TMP" && GH_CLONE_SRC="$TMP/vuota-remota.git" GH_CLAUDE_MD="" PATH="$TMP/bin:$PATH" bash "$HERE/tools/sync-repo.sh" sandbox/vuota-remota --standard 2>&1); RC=$?
BR=$(ramo_standard vuota-remota)
[ "$RC" -eq 0 ] && [ -n "$BR" ] && git -C "$TMP/vuota-remota.git" ls-tree --name-only "$BR" | grep -xc CLAUDE.md >/dev/null \
  && ok "D11: repo senza CLAUDE.md → --standard apre il ramo con CLAUDE.md (onboarding da zero)" \
  || ko "D11: repo vuota non onboardabile (rc=$RC, ramo='$BR'): $(echo "$OUT" | tail -1)"
grep -q "ASSENTE" <<<"$OUT" && ok "D11: il verdetto dice che CLAUDE.md era ASSENTE (non un errore di rete)" \
  || ko "D11: assenza non dichiarata come tale: $(echo "$OUT" | head -1)"

# D12: CLAUDE.md IDENTICO ma senza skill/hook → --standard NON deve dire ALLINEATO e fermarsi
nuovo_bare canarino-uguale 1
OUT=$(cd "$TMP" && GH_CLONE_SRC="$TMP/canarino-uguale.git" GH_CLAUDE_MD="$TMP/claude-sat.md" PATH="$TMP/bin:$PATH" bash "$HERE/tools/sync-repo.sh" sandbox/canarino-uguale --standard 2>&1); RC=$?
BR=$(ramo_standard canarino-uguale)
[ -n "$BR" ] && git -C "$TMP/canarino-uguale.git" ls-tree -r --name-only "$BR" | grep -c '^\.claude/settings.json$' >/dev/null \
  && ok "D12: CLAUDE.md uguale ma standard mancante → il ramo porta lo standard (skill, hook)" \
  || ko "D12: CLAUDE.md uguale e --standard si e' fermato ad ALLINEATO (rc=$RC, ramo='$BR'): $(echo "$OUT" | tail -1)"
# D13: i guardiani del commit viaggiano con lo standard
if [ -n "$BR" ]; then
  git -C "$TMP/canarino-uguale.git" ls-tree -r --name-only "$BR" | grep -xc 'tools/pre-commit.sh' >/dev/null \
    && git -C "$TMP/canarino-uguale.git" ls-tree -r --name-only "$BR" | grep -xc '.githooks/commit-msg' >/dev/null \
    && ok "D13: tools/pre-commit.sh e .githooks/ viaggiano con --standard" \
    || ko "D13: i guardiani del commit non viaggiano: $(git -C "$TMP/canarino-uguale.git" ls-tree -r --name-only "$BR" | grep -E 'githooks|pre-commit' | tr '\n' ' ')"
  # (2026-09-24, terzo ventaglio, V2#4): gli HOOK dichiarati da settings.json — il cancello clasp compreso —
  # arrivano sul ramo, eseguibili. Prima si guardava solo settings.json: con la copia degli hook spenta in
  # sync-repo.sh la suite intera restava verde (0 rossi su 170), e la repo riceveva un settings.json che
  # punta a script inesistenti.
  ALBERO=$(git -C "$TMP/canarino-uguale.git" ls-tree -r "$BR")
  MANCANTI=""
  while IFS= read -r H; do
    [ -n "$H" ] || continue
    grep -qE "^100755 blob [0-9a-f]+[[:space:]]$H$" <<<"$ALBERO" || MANCANTI="$MANCANTI $H"
  done < <(bash "$HERE/tools/copia-hook.sh" --elenco)
  [ -z "$MANCANTI" ] && ok "V2#4: ogni hook dichiarato (clasp compreso) arriva sul ramo, eseguibile" || ko "V2#4: hook dichiarati assenti o non eseguibili sul ramo:$MANCANTI"
fi
# riallineo su repo GIA' onboardata: niente annidamento (.claude/skills/skills) e verdetto
# «GIÀ A STANDARD» se non c'e' nulla da portare (misurato nell'hub durante il test del sistema)
if [ -n "$BR" ]; then
  git -C "$TMP/canarino-uguale-seed" fetch -q origin && git -C "$TMP/canarino-uguale-seed" merge -q --no-edit "origin/$BR" && git -C "$TMP/canarino-uguale-seed" push -q origin HEAD:main 2>/dev/null
  OUT=$(cd "$TMP" && GH_CLONE_SRC="$TMP/canarino-uguale.git" GH_CLAUDE_MD="$TMP/claude-sat.md" PATH="$TMP/bin:$PATH" bash "$HERE/tools/sync-repo.sh" sandbox/canarino-uguale --standard 2>&1); RC=$?
  grep -q "GIÀ A STANDARD" <<<"$OUT" && ok "riallineo su repo a standard: «GIÀ A STANDARD», nessun ramo nuovo" \
    || ko "riallineo: atteso GIÀ A STANDARD, avuto (rc=$RC): $(echo "$OUT" | tail -1)"
  git -C "$TMP/canarino-uguale.git" ls-tree -r --name-only main | grep -c '\.claude/skills/skills/' >/dev/null \
    && ko "riallineo: lo standard si e' ANNIDATO (.claude/skills/skills)" \
    || ok "riallineo: nessun annidamento delle directory dello standard"
fi

# D14: il clone che «riesce» senza creare la directory NON deve far copiare nella CWD
mkdir -p "$TMP/bin-rotto"; cp "$TMP/bin/gh" "$TMP/bin-rotto/gh"
sed -i 's|git clone -q "${GH_CLONE_SRC:?}" "$4"|exit 0|' "$TMP/bin-rotto/gh"
mkdir -p "$TMP/cwd-pulita"
OUT=$(cd "$TMP/cwd-pulita" && GH_CLAUDE_MD="$TMP/claude-sat.md" PATH="$TMP/bin-rotto:$PATH" bash "$HERE/tools/sync-repo.sh" sandbox/fantasma --standard 2>&1); RC=$?
[ "$RC" -ne 0 ] && [ -z "$(ls -A "$TMP/cwd-pulita")" ] \
  && ok "D14: clone senza directory → errore detto, la CWD resta intatta" \
  || ko "D14: rc=$RC e la CWD contiene: $(ls -A "$TMP/cwd-pulita" | tr '\n' ' ')"
[ -z "$(git -C "$HERE" status --porcelain -- .claude patterns .opencode tools 2>/dev/null | grep '^??')" ] \
  && ok "D14: l'hub non ha file NUOVI dopo il test (nessuna copia dello standard finita qui)" \
  || ko "D14: l'hub ha file nuovi dopo il test: $(git -C "$HERE" status --porcelain -- .claude patterns .opencode tools | grep '^??' | head -3 | tr '\n' ' ')"

# --- Q13 (2026-09-23, giro A8 della notte): --standard copiava DEBITI.md e il REGISTRO DELL'HUB
#     sopra quelli del satellite (i debiti e gli errori del satellite sparivano nella PR, e il
#     REGISTRO dell'hub cita guardie che li' non esistono), e sovrascriveva .claude/settings.json
#     intero (i permessi del satellite persi). Ora lo stato del satellite non si tocca, e da zero
#     arriva lo scheletro vuoto; settings.json si FONDE: gli hook dello standard + il resto suo.
if [ -n "$(ramo_standard vuota-remota)" ]; then
  BRV=$(ramo_standard vuota-remota)
  DEB_V=$(git -C "$TMP/vuota-remota.git" show "$BRV:DEBITI.md" 2>/dev/null)
  [ -n "$DEB_V" ] && ! grep -q 'Da review Opus 2026-08-21' <<<"$DEB_V" \
    && ok "Q13: repo da zero → DEBITI.md e' lo scheletro, non i debiti dell'hub" \
    || ko "Q13: repo da zero → DEBITI.md assente o coi debiti dell'hub"
  REG_V=$(git -C "$TMP/vuota-remota.git" show "$BRV:docs/errori/REGISTRO.md" 2>/dev/null)
  [ -n "$REG_V" ] && ! grep -q '^## E-001' <<<"$REG_V" \
    && ok "Q13: repo da zero → il REGISTRO e' lo scheletro, non gli errori dell'hub" \
    || ko "Q13: repo da zero → REGISTRO assente o con gli errori dell'hub"
fi
nuovo_bare con-stato 1
mkdir -p "$TMP/con-stato-seed/docs/errori" "$TMP/con-stato-seed/.claude"
printf '# DEBITI.md\n\n| 2026-09-01 | debito-del-satellite | x | y |\n' > "$TMP/con-stato-seed/DEBITI.md"
printf '# Registro\n\n## E-001 errore-del-satellite\n' > "$TMP/con-stato-seed/docs/errori/REGISTRO.md"
printf '{"permissions":{"allow":["Bash(npm run lint)"]},"model":"scelta-del-satellite"}\n' > "$TMP/con-stato-seed/.claude/settings.json"
git -C "$TMP/con-stato-seed" add -A && git -C "$TMP/con-stato-seed" -c user.name=t -c user.email=t@t commit -qm stato && git -C "$TMP/con-stato-seed" push -q origin HEAD:main 2>/dev/null
OUT=$(cd "$TMP" && GH_CLONE_SRC="$TMP/con-stato.git" GH_CLAUDE_MD="$TMP/claude-sat.md" PATH="$TMP/bin:$PATH" bash "$HERE/tools/sync-repo.sh" sandbox/con-stato --standard 2>&1); RC=$?
BRS=$(ramo_standard con-stato)
if [ -n "$BRS" ]; then
  git -C "$TMP/con-stato.git" show "$BRS:DEBITI.md" | grep -c 'debito-del-satellite' >/dev/null \
    && ok "Q13: i DEBITI del satellite restano i suoi" || ko "Q13: i DEBITI del satellite sovrascritti da quelli dell'hub"
  git -C "$TMP/con-stato.git" show "$BRS:docs/errori/REGISTRO.md" | grep -c 'errore-del-satellite' >/dev/null \
    && ok "Q13: il REGISTRO del satellite resta il suo" || ko "Q13: il REGISTRO del satellite sovrascritto da quello dell'hub"
  SET=$(git -C "$TMP/con-stato.git" show "$BRS:.claude/settings.json")
  jq -e '(.permissions.allow | index("Bash(npm run lint)")) and .model == "scelta-del-satellite"' <<<"$SET" >/dev/null 2>&1 \
    && ok "Q13: settings.json tiene i permessi e le scelte del satellite" || ko "Q13: settings.json del satellite sovrascritto: $(head -c 120 <<<"$SET")"
  grep -q 'clasp-block-hook' <<<"$SET" \
    && ok "Q13: settings.json porta comunque gli hook dello standard" || ko "Q13: la fusione ha perso gli hook dello standard"
else
  ko "Q13: nessun ramo standard per la repo con stato (rc=$RC): $(echo "$OUT" | tail -1)"
fi

# (2026-09-24, quarto ventaglio, Q2 R1): senza jq `copia-hook --elenco` esce 1, il suo rc si perdeva nel
# `< <(…)`, e sync-repo diceva «ALLINEATO (e gli hook pure)» con un hook DIVERGENTE — il cancello clasp
# era proprio l'hook che spariva dal confronto. Un PATH senza jq (tutto il resto c'e').
NOJQ="$TMP/senza-jq"; mkdir -p "$NOJQ"
for b in /usr/local/bin/* /usr/bin/* /bin/*; do n=${b##*/}; [ "$n" = jq ] || [ -e "$NOJQ/$n" ] || ln -s "$b" "$NOJQ/$n" 2>/dev/null; done
cp -r "$TMP/allineata" "$TMP/hook-div"; echo '# refuso' >> "$TMP/hook-div/tools/clasp-block-hook.sh"
OUT=$(PATH="$NOJQ" bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/hook-div" 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -c 'ALLINEATO' <<<"$OUT" >/dev/null \
  && ok "senza jq, hook divergente: niente ALLINEATO (rc $RC), e lo dice" || ko "senza jq ALLINEATO con un hook divergente (rc $RC): $OUT"
# (Q2 R6): mktemp fallito (TMPDIR inesistente) — senza guardia i file finivano alla radice (da root, nel
# container, /CLAUDE.md e /claude-satellite.md)
OUT=$(TMPDIR="$TMP/non-esiste" bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/allineata" 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -c 'mktemp' <<<"$OUT" >/dev/null && ! grep -c 'ALLINEATO\|DIVERGENTE' <<<"$OUT" >/dev/null \
  && ok "mktemp fallito: si ferma e lo dice, senza scrivere altrove" || ko "mktemp fallito e sync-repo prosegue (rc $RC): $OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
