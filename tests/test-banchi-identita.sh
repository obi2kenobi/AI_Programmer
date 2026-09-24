#!/bin/bash
# test-banchi-identita.sh — il primo giorno senza identità git (2026-09-24, quarto ventaglio, Q1 R1).
# Prima: in una HOME vuota la verifica che AGENTS.md prescrive (`bash tools/suite.sh`) si fermava rossa a
# 101/174 — tests/test-mutation-atomico.sh faceva un commit senza identità, e 73 banchi non giravano mai
# (gli altri 173, uno per uno, erano verdi). E tools/bootstrap-app.sh moriva a metà (rc 128) DOPO aver
# creato la cartella, che bloccava il secondo lancio. Qui: (1) ogni banco che fa un commit vero porta la sua
# identità; (2) il bootstrap controlla l'identità prima di scrivere, e lo dice.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. il cricchetto: un banco con un commit e nessuna identità (-c user.email, GIT_AUTHOR_EMAIL, ...) e'
# rosso per chi non ha la sua in ~/.gitconfig. Escluso per nome chi usa un git FINTO (dichiarato).
FINTI="tests/test-bootstrap-app.sh"   # git e' una funzione finta: nessun commit vero
SENZA=""
for f in "$HERE"/tests/test-*.sh; do
  rel=${f#"$HERE"/}
  grep -qxF "$rel" <<<"$FINTI" && continue
  grep -qE '(^|[[:space:];&(])git( -C [^ ]+)?( -c [^ ]+)* commit\b|\$G(IT)? commit|commit -q' "$f" || continue
  grep -qE 'user\.email|GIT_AUTHOR_EMAIL|GIT_COMMITTER_EMAIL' "$f" || SENZA="$SENZA $rel"
done
[ -z "$SENZA" ] && ok "ogni banco che fa un commit porta la sua identita' git (niente dipendenza da ~/.gitconfig)" \
  || ko "banchi con un commit senza identita' (rossi in una HOME vuota):$SENZA"

# 2. il bootstrap senza identita': si ferma PRIMA di creare la cartella, e dice cosa manca
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home" "$T/bin"
printf '#!/bin/bash\nexit 0\n' > "$T/bin/gh"; chmod +x "$T/bin/gh"   # gh «autenticato», nient'altro
OUT=$(HOME="$T/home" GIT_CONFIG_NOSYSTEM=1 PATH="$T/bin:$PATH" bash "$HERE/tools/bootstrap-app.sh" prova-identita 2>&1); RC=$?
[ "$RC" -ne 0 ] && [ ! -e "$T/home/night-shift-work/prova-identita" ] \
  && ok "bootstrap senza identita' git: si ferma prima di creare la cartella (rc $RC)" \
  || ko "bootstrap senza identita': rc $RC, cartella $([ -e "$T/home/night-shift-work/prova-identita" ] && echo LASCIATA || echo assente)"
grep -ciE '^bootstrap-app: .*user.email' <<<"$OUT" >/dev/null && ok "e dice il comando che manca (git config user.email)" || ko "il bootstrap non dice cosa manca: $(tail -2 <<<"$OUT")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
