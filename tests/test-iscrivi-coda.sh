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

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
