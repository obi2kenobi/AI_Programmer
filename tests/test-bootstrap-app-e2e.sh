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
grep -q '^tester/prova-vera feat$' "$TMP/repos.conf" && ok "vero: iscritta nella coda (NIGHT_REPOS_CONF)" || ko "vero: non iscritta nella coda di prova"
: > "$TMP/gh.log"; rm -rf "$D"
lancia prova-ordine --dry-run --private
grep -q 'privata' "$TMP/out" && ok "--private vale anche dopo --dry-run (l'ordine dei flag non conta)" || ko "--private ignorato se non e' il secondo argomento"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
