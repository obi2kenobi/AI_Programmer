#!/bin/bash
# test-sync-repo-hooks-propagation.sh — dal campo (REPO-V, progetto GAS nuovo, 2026-09-03).
#
# Il buco: `tools/sync-repo.sh --standard` è IL comando insegnato in
# docs/benvenuto-collaboratori.md per portare una repo a standard, e copiava due dei tre
# hook dichiarati in .claude/settings.json — mancava tools/clasp-block-hook.sh. Una repo
# portata a standard con lo strumento riceveva quindi un settings.json che punta a uno
# script inesistente, e perdeva l'unico cancello TECNICO del metodo, quello sul deploy in
# produzione: il rischio più caro, scoperto solo installando lo standard a mano.
#
# Nessun banco lo copriva: test-bootstrap-hooks-propagation.sh guarda bootstrap-app.sh
# (repo NUOVE) e non ha mai guardato sync-repo.sh (repo ESISTENTI, il caso più frequente).
# Questo file è la guardia mancante, gemella di quella. Non esegue lo script intero
# (chiama gh e clona): isola l'invariante, come gli altri banchi di propagazione.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HERE/tools/sync-repo.sh"
SETTINGS="$HERE/.claude/settings.json"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

DICHIARATI=$(jq -r '.hooks | to_entries[] | .value[]? | .hooks[]? | .command' "$SETTINGS" \
  | awk '{print $1}' | grep -E '^tools/.*\.sh$' | sort -u)
N_DICHIARATI=$(echo "$DICHIARATI" | grep -c .)

grep -q 'copia-hook\.sh' "$SCRIPT" \
  && ok "sync-repo.sh delega la copia degli hook a tools/copia-hook.sh" \
  || ko "sync-repo.sh non usa copia-hook.sh: la lista degli hook è scritta a mano e può divergere"

# La divergenza si misura, non si assume: nessun hook dichiarato in settings.json deve
# essere assente dal risultato della copia che sync-repo.sh esegue.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo-esistente/tools"   # repo esistente: tools/ c'è già, con altro dentro
echo '# strumento preesistente del progetto' > "$TMP/repo-esistente/tools/mio-script.sh"

bash "$HERE/tools/copia-hook.sh" "$TMP/repo-esistente" >"$TMP/copiati" 2>"$TMP/err" \
  && ok "copia-hook.sh esce 0 su una repo con tools/ già popolata" \
  || ko "copia-hook.sh fallisce su repo esistente: $(head -2 "$TMP/err")"

while IFS= read -r H; do
  [ -n "$H" ] || continue
  [ -x "$TMP/repo-esistente/$H" ] \
    && ok "$H arriva nella repo esistente" \
    || ko "$H NON arriva: settings.json lo dichiara, la repo portata a standard non lo avrebbe"
done <<< "$DICHIARATI"

# Attesa condizionata: se copia-hook.sh non è mai partito, "il file c'è ancora" è verde
# per il motivo sbagliato (nessuno l'ha toccato) — non è una prova di non-distruttività.
if [ ! -x "$HERE/tools/copia-hook.sh" ]; then
  ko "non-distruttività non verificabile: copia-hook.sh non esiste (attesa non verificata)"
else
  [ -f "$TMP/repo-esistente/tools/mio-script.sh" ] \
    && ok "gli strumenti preesistenti del progetto non vengono cancellati" \
    || ko "la copia degli hook ha distrutto tools/ del progetto di destinazione"
fi

[ "$(grep -c . "$TMP/copiati")" -eq "$N_DICHIARATI" ] \
  && ok "$N_DICHIARATI hook dichiarati, $N_DICHIARATI riportati copiati" \
  || ko "$(grep -c . "$TMP/copiati") copiati contro $N_DICHIARATI dichiarati"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
