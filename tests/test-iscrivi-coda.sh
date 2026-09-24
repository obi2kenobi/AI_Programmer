#!/bin/bash
# test-iscrivi-coda.sh — una repo entra nella coda della notte una volta, e solo se non c'e' GIA' LEI
# (2026-09-24, notte dei giri, T6#6). I due installatori avevano due regex sbagliate in modi opposti:
# tools/onboard-repo.sh (`^$REPO\b`) dava luca/app per presente se c'era luca/app-v2 (e il punto del
# nome faceva da jolly) — la repo non entrava mai in coda, in silenzio; tools/bootstrap-app.sh
# (`^login/nome$`) non combaciava mai con «login/nome feat» e aggiungeva un doppione a ogni giro.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
ISCRIVI="$HERE/tools/iscrivi-coda.sh"
[ -f "$ISCRIVI" ] || { ko "tools/iscrivi-coda.sh non esiste"; echo; echo "$PASS OK, $FAIL FAIL"; exit 1; }

printf '# coda\nluca/app-v2 feat\nluca/appXv2 fix\n' > "$T/c"
bash "$ISCRIVI" "$T/c" luca/app feat >/dev/null
grep -qx 'luca/app feat' "$T/c" && ok "luca/app entra anche se c'e' luca/app-v2 (niente prefissi)" || ko "luca/app non iscritta: $(tr '\n' ' ' < "$T/c")"
bash "$ISCRIVI" "$T/c" luca/app.v2 feat >/dev/null
grep -qx 'luca/app.v2 feat' "$T/c" && ok "il punto nel nome e' un punto, non un jolly" || ko "luca/app.v2 non iscritta (il punto ha combaciato con appXv2)"
OUT=$(bash "$ISCRIVI" "$T/c" luca/app feat)
[ "$(grep -c '^luca/app ' "$T/c")" -eq 1 ] && grep -c "gia'" <<<"$OUT" >/dev/null && ok "gia' presente: nessun doppione, e lo dice" || ko "doppione o silenzio: $(grep -c '^luca/app ' "$T/c") righe, «$OUT»"
printf '# luca/zeta feat (commentata)\n' > "$T/d"; bash "$ISCRIVI" "$T/d" luca/zeta feat >/dev/null
grep -qx 'luca/zeta feat' "$T/d" && ok "una riga commentata non conta come iscrizione" || ko "la riga commentata ha contato"

# i due installatori usano questo gesto, non una regex loro
for f in tools/onboard-repo.sh tools/bootstrap-app.sh; do
  grep -c 'tools/iscrivi-coda.sh' "$HERE/$f" >/dev/null && ok "$f iscrive con tools/iscrivi-coda.sh" || ko "$f ha ancora la sua regex"
done

# (2026-09-24, quarto ventaglio, Q2 R4): col login GitHub illeggibile il bootstrap iscriveva «/nome» — il
# turno poi falliva il clone ogni notte, lontano dalla causa — e diceva «Fatto». La forma owner/repo si
# pretende; e il bootstrap, con `gh api user` in errore, non iscrive e lo dice.
Q=$(mktemp -d); printf '# coda\n' > "$Q/repos.conf"
for SBAGLIATA in "/prova" "prova" "a/b/c" "a b/c"; do
  bash "$HERE/tools/iscrivi-coda.sh" "$Q/repos.conf" "$SBAGLIATA" feat >/dev/null 2>&1; RC=$?
  [ "$RC" -ne 0 ] && ! grep -cF -- "$SBAGLIATA feat" "$Q/repos.conf" >/dev/null && ok "iscrivi-coda rifiuta «$SBAGLIATA» (non e' owner/repo)" || ko "iscrivi-coda ha iscritto «$SBAGLIATA» (rc $RC)"
done
mkdir -p "$Q/bin" "$Q/home"
printf '#!/bin/bash\ncase "$1 $2" in "api user") echo "error connecting to api.github.com" >&2; exit 1 ;; "label create") exit 1 ;; esac\nexit 0\n' > "$Q/bin/gh"; chmod +x "$Q/bin/gh"
OUT=$(HOME="$Q/home" PATH="$Q/bin:$PATH" NIGHT_REPOS_CONF="$Q/repos.conf" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
  GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false bash "$HERE/tools/bootstrap-app.sh" prova-coda 2>&1); RC=$?
! grep -cE '^/prova-coda' "$Q/repos.conf" >/dev/null && [ "$RC" -ne 0 ] && grep -ci 'login' <<<"$OUT" >/dev/null \
  && ok "bootstrap col login illeggibile: non iscrive «/prova-coda», esce $RC e lo dice" || ko "bootstrap col login illeggibile: rc $RC, coda: $(grep -v '^#' "$Q/repos.conf"), $(tail -1 <<<"$OUT")"
grep -c 'label night-shift NON creata' <<<"$OUT" >/dev/null && ok "la label non creata si dice" || ko "label non creata taciuta"
rm -rf "$Q"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
