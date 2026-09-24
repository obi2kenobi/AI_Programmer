#!/bin/bash
# test-bootstrap-app-e2e.sh — bootstrap-app.sh ESEGUITO, con gh finto (2026-09-23, giri A8/A9 della
# notte). Fino a qui il bootstrap si provava con banchi di forma (una grep per riga di copia): nessuno
# lo lanciava. Lanciato, --dry-run «tutto what-if, nessuna scrittura» creava la repo locale intera,
# creava la label VERA su GitHub e iscriveva la repo nella coda VERA dell'hub.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home"
cat > "$TMP/bin/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "auth status") exit 0 ;;
  "api user") echo tester ;;
  # (2026-09-24, sesto ventaglio, S1 R2): come il gh vero (2.45), -R vuole OWNER/REPO — il finto che accettava
  # tutto lasciava verde un bootstrap che la label non la creava mai
  "label create") R=$(sed -n 's/.* -R \([^ ]*\).*/\1/p' <<<"$*"); case "$R" in */*) exit 0 ;; *) echo 'expected the "[HOST/]OWNER/REPO" format' >&2; exit 1 ;; esac ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMP/bin/gh"
printf '# coda di prova\n' > "$TMP/repos.conf"
lancia() {
  ( cd "$TMP" && HOME="$TMP/home" GH_LOG="$TMP/gh.log" NIGHT_REPOS_CONF="$TMP/repos.conf" PATH="$TMP/bin:$PATH" \
    GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
    bash "$HERE/tools/bootstrap-app.sh" "$@" ) >"$TMP/out" 2>&1
}

# --- dry-run: niente su disco, niente su GitHub, niente in coda
: > "$TMP/gh.log"
lancia prova-dry --dry-run; RC=$?
[ "$RC" -eq 0 ] && ok "dry-run: esce 0" || ko "dry-run: rc=$RC — $(tail -2 "$TMP/out")"
[ ! -e "$TMP/home/night-shift-work/prova-dry" ] && ok "dry-run: nessuna repo locale creata" \
  || ko "dry-run: ha creato $TMP/home/night-shift-work/prova-dry"
grep -qE '^(repo create|label create)' "$TMP/gh.log" && ko "dry-run: ha chiamato gh per scrivere: $(grep -E '^(repo|label) create' "$TMP/gh.log" | head -2 | tr '\n' ' ')" \
  || ok "dry-run: nessuna scrittura su GitHub (repo, label)"
grep -q 'prova-dry' "$TMP/repos.conf" && ko "dry-run: ha iscritto la repo nella coda" || ok "dry-run: la coda non cambia"
grep -q 'CLAUDE.md' "$TMP/out" && ok "dry-run: dice cosa creerebbe (l'elenco dei file)" || ko "dry-run: non dice cosa creerebbe"

# --- vero: la repo nasce, la label e la coda si toccano (la coda di PROVA, non quella dell'hub)
: > "$TMP/gh.log"
lancia prova-vera --private; RC=$?
D="$TMP/home/night-shift-work/prova-vera"
[ "$RC" -eq 0 ] && [ -f "$D/CLAUDE.md" ] && ok "vero: la repo nasce con CLAUDE.md" || ko "vero: rc=$RC — $(tail -2 "$TMP/out")"
grep -q '^repo create prova-vera --private' "$TMP/gh.log" && ok "vero: gh repo create chiamato, privata" || ko "vero: repo create assente o non privata: $(grep '^repo' "$TMP/gh.log")"
grep -q '^label create night-shift' "$TMP/gh.log" && ok "vero: la label night-shift si crea" || ko "vero: label non creata"
grep -c 'label create night-shift.* -R tester/prova-vera' "$TMP/gh.log" >/dev/null && ! grep -c 'label night-shift NON creata' "$TMP/out" >/dev/null \
  && ok "S1 R2: la label si crea su owner/repo, senza avviso" || ko "S1 R2: label chiesta senza owner: $(grep '^label' "$TMP/gh.log") — $(grep -c 'NON creata' "$TMP/out") avvisi"
grep -q '^tester/prova-vera feat$' "$TMP/repos.conf" && ok "vero: iscritta nella coda (NIGHT_REPOS_CONF)" || ko "vero: non iscritta nella coda di prova"
# (2026-09-24, notte dei giri, T1#2): i guardiani del commit (.githooks) arrivavano nel satellite ma
# spenti — nessuno impostava core.hooksPath, e il CLAUDE.md del satellite parla del pre-commit come
# se girasse. Il bootstrap li accende nella copia che crea lui (come night-shift/install.sh per l'hub).
[ "$(git -C "$D" config core.hooksPath 2>/dev/null)" = ".githooks" ] && ok "vero: i guardiani del commit sono accesi (core.hooksPath)" \
  || ko "vero: guardiani del commit spenti (core.hooksPath='$(git -C "$D" config core.hooksPath 2>/dev/null)')"
# Q15 (2026-09-23, giro A8): il CLAUDE.md che il satellite riceve CITA strumenti e file (il settimo
# patto: `bash tools/debiti-riapertura.sh`; il registro errori con la sua guardia; il formato del
# report di campo) — e il bootstrap non li portava: 43 citazioni su 62 al nulla, lo stesso difetto
# del report REPO-I gia' curato in sync-repo e mai arrivato qui. Cricchetto: ogni percorso citato
# esiste nella repo nuova, oppure e' dichiarato qui sotto come «solo nell'hub», col perche'.
SOLO_HUB="night-shift/morning-gate.sh night-shift/revisore.sh tools/grafo-semantico.sh tools/claude-md-satellite.sh tests/test-claude-md-snello.sh patterns/segreto-come-impronta.md"
# (i giudici della notte e il passo semantico girano nell'hub; claude-md-satellite genera questo
#  file e il suo banco vivono li'; segreto-come-impronta e' citato come implementazione di
#  riferimento dell'hub — patterns/ del satellite e' un registro suo)
MANCANTI=""
for C in $(bash "$HERE/tools/claude-md-satellite.sh" | grep -oE '(tools|night-shift|llm|tests|docs|patterns)/[A-Za-z0-9_./-]+[A-Za-z0-9_-]|`[A-Z][A-Za-z_-]+\.md`' | tr -d '`' | sort -u); do
  case " $SOLO_HUB " in *" $C "*) continue ;; esac
  [ -e "$D/$C" ] || MANCANTI="$MANCANTI $C"
done
[ -z "$MANCANTI" ] && ok "Q15: ogni percorso citato dal CLAUDE.md dei satelliti esiste nella repo nuova" \
  || ko "Q15: citati dal CLAUDE.md ma assenti nella repo nuova:$MANCANTI"
for F in .githooks/pre-commit tools/pre-commit.sh tools/cita-verifica.sh; do
  [ -e "$D/$F" ] || ko "Q15: il guardiano del commit $F non arriva alla repo nuova"
done
# Q24 (2026-09-23, notte): i banchi di propagazione del bootstrap cercavano la riga di copia con grep
# e poi rifacevano la copia A MANO — con la copia vera commentata restavano verdi. Qui si guarda la
# repo NATA: ogni skill, agente, specchio, pattern dell'hub e il template dell'issue ci sono.
MANCA=""
for d in .claude/skills .opencode/skills .claude/agents .opencode/agent; do
  for x in "$HERE/$d"/*; do [ -e "$D/$d/$(basename "$x")" ] || MANCA="$MANCA $d/$(basename "$x")"; done
done
[ -f "$D/patterns/README.md" ] || MANCA="$MANCA patterns/README.md"
[ -f "$D/.github/ISSUE_TEMPLATE/night-shift.md" ] || MANCA="$MANCA .github/ISSUE_TEMPLATE/night-shift.md"
while IFS= read -r H; do [ -x "$D/$H" ] || MANCA="$MANCA $H(hook)"; done < <(bash "$HERE/tools/copia-hook.sh" --elenco)
[ -z "$MANCA" ] && ok "Q24: skill, agenti, specchi, pattern, template e hook dell'hub sono nella repo nata" \
  || ko "Q24: assenti nella repo nata:$MANCA"
grep -q 'Da review Opus 2026-08-21' "$D/DEBITI.md" 2>/dev/null && ko "Q15: la repo nuova nasce coi debiti dell'hub" || ok "Q15: DEBITI.md della repo nuova e' lo scheletro (se c'e')"
: > "$TMP/gh.log"; rm -rf "$D"
lancia prova-ordine --dry-run --private
grep -q 'privata' "$TMP/out" && ok "--private vale anche dopo --dry-run (l'ordine dei flag non conta)" || ko "--private ignorato se non e' il secondo argomento"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
