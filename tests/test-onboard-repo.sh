#!/bin/bash
# test-onboard-repo.sh — onboard-repo.sh END-TO-END con un gh finto (giro 20 dell'analisi
# profonda, 2026-09-20). Fino a qui lo script aveva solo banchi strutturali (grep sul
# sorgente) e banchi che RIFACEVANO a mano il merge degli hook — specchio del codice, non
# prova del codice. Qui gira lo script vero su una repo sandbox locale (bare + clone) e si
# guarda cosa ARRIVA sull'origin, che e' l'unica cosa che conta per la repo onboardata.
#
# Due difetti che questo banco vede e i vecchi no:
#  D28 — il ramo «settings.json assente» copiava solo gli hook PreToolUse: settings.json
#        dichiara tools/metodo-reminder-hook.sh su UserPromptSubmit/SessionStart/Stop, e
#        la repo riceveva un settings.json che punta a uno script inesistente.
#  D29 — settings.json e gli hook venivano solo `git add`: il commit lo faceva, per caso,
#        la sezione degli agenti — se la repo aveva gia' tutti gli agenti, restavano
#        nell'indice della copia di lavoro e sull'origin non arrivava niente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
command -v jq >/dev/null 2>&1 || { echo "⊘ jq assente: banco saltato (dichiarato)"; exit 0; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

# gh finto: autenticato, repo esistente, label ok, clone = git clone dall'origin locale.
# Attenzione all'ordine degli argomenti (E-035): `gh repo clone <repo> <dir> -- ...`.
STUB="$TMP/stub"; mkdir -p "$STUB"
cat > "$STUB/gh" <<'GH'
#!/bin/bash
case "$1 $2" in
  "auth status") exit 0;;
  "repo view") exit 0;;
  "label create") exit 0;;
  "repo clone") git clone -q "$ORIGIN_DIR" "$4";;
  *) echo "gh finto: comando inatteso: $*" >&2; exit 1;;
esac
GH
chmod +x "$STUB/gh"

# una sandbox: bare repo con un commit su main; $1 = nome, $2 = funzione che la popola
nuova_sandbox() {
  local NOME="$1" SRC="$TMP/src-$1"
  git init -q -b main "$SRC" && echo "# $NOME" > "$SRC/README.md"
  ( cd "$SRC" && "$2" && git add -A && git commit -q -m "init" )
  git clone -q --bare "$SRC" "$TMP/$NOME.git"
  echo "$TMP/$NOME.git"
}
vuota() { :; }
# tutti gli agenti gia' presenti + un hook personalizzato: il caso in cui D29 morde
con_agenti_e_hook_proprio() {
  mkdir -p .claude/agents .opencode/agent tools
  cp "$HERE"/.claude/agents/*.md .claude/agents/
  cp "$HERE"/.opencode/agent/*.md .opencode/agent/
  echo "HOOK PERSONALIZZATO DAL PROGETTO" > tools/metodo-reminder-hook.sh
  # (revisione 10 giri, 2026-09-23): anche una SKILL personalizzata dal progetto — i banchi
  # di propagazione rifacevano a mano il merge delle skill, e con la guardia dell'onboarding
  # sostituita da `if true; then rm -rf …` la suite restava verde (provato)
  mkdir -p .claude/skills/dev-critic .opencode/skills/dev-critic
  echo "SKILL PERSONALIZZATA DAL PROGETTO" > .claude/skills/dev-critic/SKILL.md
  echo "SKILL PERSONALIZZATA DAL PROGETTO" > .opencode/skills/dev-critic/SKILL.md
  # (Q15): anche i DEBITI del progetto — l'onboard porta gli strumenti citati, mai sopra i suoi
  printf '# DEBITI del progetto\n' > DEBITI.md
}

DICHIARATI=$(bash "$HERE/tools/copia-hook.sh" --elenco)

onboard() {  # $1 = origin bare, $2 = nome repo finto
  HOME="$TMP/home-$2" ORIGIN_DIR="$1" NIGHT_REPOS_CONF="$TMP/repos.conf" PATH="$STUB:$PATH" \
    bash "$HERE/tools/onboard-repo.sh" "sandbox/$2" 2>&1
}

# --- caso 1: repo vuota ---------------------------------------------------------------
ORIGIN1=$(nuova_sandbox vuota vuota)
OUT1=$(onboard "$ORIGIN1" vuota); RC1=$?
[ "$RC1" -eq 0 ] && ok "caso 1: onboard-repo termina 0 sulla repo vuota" || { ko "caso 1: rc $RC1 — $OUT1"; }
git clone -q "$ORIGIN1" "$TMP/check1"
[ -f "$TMP/check1/.claude/settings.json" ] && ok "caso 1: settings.json arrivato sull'origin" || ko "caso 1: settings.json NON sull'origin"
MANCANTI=""
while IFS= read -r H; do
  [ -n "$H" ] || continue
  [ -x "$TMP/check1/$H" ] || MANCANTI="$MANCANTI $H"
done <<< "$DICHIARATI"
[ -z "$MANCANTI" ] && ok "caso 1: OGNI hook dichiarato in settings.json e' sull'origin ed eseguibile" \
  || ko "caso 1 (D28): hook dichiarati ma assenti/non eseguibili sull'origin:$MANCANTI"
# (Q24, 2026-09-23, notte): i banchi di propagazione dell'onboard rifacevano il merge a mano; qui si
# guarda l'origin VERO dopo l'onboarding: ogni skill, agente, specchio e pattern dell'hub arriva
MANCA=""
for d in .claude/skills .opencode/skills .claude/agents .opencode/agent patterns; do
  for x in "$HERE/$d"/*; do [ -e "$TMP/check1/$d/$(basename "$x")" ] || MANCA="$MANCA $d/$(basename "$x")"; done
done
[ -z "$MANCA" ] && ok "caso 1 (Q24): ogni skill, agente, specchio e pattern dell'hub e' sull'origin" \
  || ko "caso 1 (Q24): assenti sull'origin:$MANCA"
[ -f "$TMP/check1/.night-verify" ] && ok "caso 1: .night-verify arrivato" || ko "caso 1: .night-verify assente"
grep -q "^sandbox/vuota" "$TMP/repos.conf" && ok "caso 1: iscritta nella coda (repos.conf del test, non dell'hub)" || ko "caso 1: non iscritta in repos.conf"

# --- caso 2: repo con tutti gli agenti e un hook proprio -------------------------------
ORIGIN2=$(nuova_sandbox piena con_agenti_e_hook_proprio)
OUT2=$(onboard "$ORIGIN2" piena); RC2=$?
[ "$RC2" -eq 0 ] && ok "caso 2: onboard-repo termina 0 sulla repo gia' popolata" || ko "caso 2: rc $RC2 — $OUT2"
git clone -q "$ORIGIN2" "$TMP/check2"
[ -f "$TMP/check2/.claude/settings.json" ] && ok "caso 2 (D29): settings.json arrivato anche senza agenti da aggiungere" \
  || ko "caso 2 (D29): settings.json mai committato — restava nell'indice della copia di lavoro"
[ -x "$TMP/check2/tools/clasp-block-hook.sh" ] && ok "caso 2 (D29): il cancello clasp e' sull'origin" || ko "caso 2 (D29): clasp-block-hook.sh non sull'origin"
[ "$(cat "$TMP/check2/tools/metodo-reminder-hook.sh")" = "HOOK PERSONALIZZATO DAL PROGETTO" ] \
  && ok "caso 2: l'hook personalizzato del progetto NON e' stato sovrascritto" \
  || ko "caso 2: hook personalizzato sovrascritto dall'onboarding"
[ "$(cat "$TMP/check2/.claude/skills/dev-critic/SKILL.md" 2>/dev/null)" = "SKILL PERSONALIZZATA DAL PROGETTO" ] \
  && [ "$(cat "$TMP/check2/.opencode/skills/dev-critic/SKILL.md" 2>/dev/null)" = "SKILL PERSONALIZZATA DAL PROGETTO" ] \
  && ok "caso 2: la skill personalizzata del progetto (claude e opencode) NON e' stata sovrascritta" \
  || ko "caso 2: skill personalizzata sovrascritta dall'onboarding"
[ -f "$TMP/check2/.claude/skills/gas-sviluppo/SKILL.md" ] && ok "caso 2: le skill dell'hub mancanti sono arrivate" || ko "caso 2: skill dell'hub mancanti non propagate"
grep -q "agenti del hub già tutti presenti" <<<"$OUT2" && ok "caso 2: agenti riconosciuti come gia' presenti" || ko "caso 2: agenti ricopiati"

# (Q15, 2026-09-23): gli strumenti che lo standard CITA arrivano (settimo patto, guardiani del
# commit), e lo stato del progetto resta suo
[ -x "$TMP/check1/tools/debiti-riapertura.sh" ] && [ -f "$TMP/check1/.githooks/pre-commit" ] && [ -f "$TMP/check1/tools/cita-verifica.sh" ] \
  && ok "caso 1 (Q15): gli strumenti citati dallo standard arrivano sull'origin" \
  || ko "caso 1 (Q15): strumenti citati assenti (debiti-riapertura, .githooks, cita-verifica)"
[ "$(cat "$TMP/check2/DEBITI.md" 2>/dev/null)" = "# DEBITI del progetto" ] \
  && ok "caso 2 (Q15): i DEBITI del progetto NON sono stati toccati" || ko "caso 2 (Q15): DEBITI del progetto sovrascritti"

# --- caso 3 (2026-09-24, quinto ventaglio, R2 R6): una repo GAS -----------------------------
# L'onboard copiava gli hook da solo, senza la seconda meta' di copia-hook: le righe «residuo» della
# .gitignore (il primo Stop lasciava «?? .campo-rem»). Seminava un .night-verify di soli commenti anche su una
# repo GAS, e il sync non seminava piu' il gate perche' il file c'era: la prima notte, «verifiche-vuote».
# E PROJECT.md, che il CLAUDE.md del satellite cita, lo creava solo il bootstrap.
gas() { printf 'function onOpen(){}\n' > Code.gs; }
ORIGIN3=$(nuova_sandbox gasrepo gas)
OUT3=$(onboard "$ORIGIN3" gasrepo); RC3=$?
git clone -q "$ORIGIN3" "$TMP/check3"
grep -qxF '.campo-rem' "$TMP/check3/.gitignore" 2>/dev/null && ok "caso 3 (R2 R6): il residuo degli hook e' nella .gitignore sull'origin" \
  || ko "caso 3 (R2 R6): .gitignore senza i residui degli hook (rc $RC3)"
grep -cxF 'bash tools/gas-gate.sh' "$TMP/check3/.night-verify" >/dev/null && ok "caso 3 (R2 R6): la repo GAS ha il suo gate seminato in .night-verify" \
  || ko "caso 3 (R2 R6): .night-verify senza comandi su una repo GAS: $(grep -vc '^#' "$TMP/check3/.night-verify" 2>/dev/null) righe non commentate"
[ -f "$TMP/check3/PROJECT.md" ] && [ -f "$TMP/check1/PROJECT.md" ] && ok "caso 3 (R2 R6): PROJECT.md arriva anche con l'onboard" || ko "caso 3 (R2 R6): PROJECT.md assente dopo l'onboard"
! grep -cxF 'bash tools/gas-gate.sh' "$TMP/check1/.night-verify" >/dev/null && ok "caso 3 (R2 R6): una repo non GAS non riceve il gate GAS" || ko "caso 3 (R2 R6): gate GAS seminato su una repo senza .gs"

# --- caso 4 (2026-09-24, sesto ventaglio, S2 R1 e S4 R3): la copia di lavoro c'e' gia' ---------------------
# L'onboard lavorava in $HOME/night-shift-work/<repo>, la stessa copia del turno: se c'era, niente fetch e niente
# ritorno su main. Il turno la lascia sul ramo della PR notturna, e lo standard finiva DENTRO quella PR. E un file
# rimasto non tracciato da un giro interrotto valeva «gia' presente»: quella skill non arrivava mai, e diceva «Fatto».
ORIGIN4=$(nuova_sandbox turno vuota)
T4="$TMP/home-turno/night-shift-work/turno"; mkdir -p "$(dirname "$T4")"; git clone -q "$ORIGIN4" "$T4"
git -C "$T4" checkout -q -b night/issue-7; echo fix > "$T4/fix.txt"; git -C "$T4" add fix.txt; git -C "$T4" commit -qm "fix issue 7"; git -C "$T4" push -q -u origin night/issue-7 2>/dev/null
PRIMA7=$(git -C "$ORIGIN4" rev-parse night/issue-7)
UNA=$(basename "$(ls -d "$HERE"/.claude/skills/*/ | head -1)"); mkdir -p "$T4/.claude/skills/$UNA"; cp -r "$HERE/.claude/skills/$UNA/." "$T4/.claude/skills/$UNA/"
OUT4=$(onboard "$ORIGIN4" turno); RC4=$?
git clone -q "$ORIGIN4" "$TMP/check4"
[ "$(git -C "$ORIGIN4" rev-parse night/issue-7)" = "$PRIMA7" ] && ok "caso 4 (S2 R1): il ramo della PR notturna resta com'era" || ko "caso 4 (S2 R1): lo standard e' finito sul ramo della PR notturna"
MANCA4=""; for x in "$HERE"/.claude/skills/*; do [ -e "$TMP/check4/.claude/skills/$(basename "$x")" ] || MANCA4="$MANCA4 $(basename "$x")"; done
[ -z "$MANCA4" ] && [ "$RC4" -eq 0 ] && ok "caso 4 (S4 R3): ogni skill e' su main dell'origin, anche quella rimasta non tracciata nella copia" || ko "caso 4: su main mancano:$MANCA4 (rc $RC4)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
