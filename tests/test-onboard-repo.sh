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
echo "$OUT2" | grep -q "agenti del hub già tutti presenti" && ok "caso 2: agenti riconosciuti come gia' presenti" || ko "caso 2: agenti ricopiati"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
