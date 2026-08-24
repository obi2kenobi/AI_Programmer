#!/bin/bash
# test-mappa-dominio-gas-src.sh — 6° ciclo, Set 1 giro 1 (2026-08-24). Presidia la
# FORMA della mappa del dominio (docs/mappa-dominio-gas-src.md), non la verità del
# censimento: (1) ogni categoria della tabella dichiara uno stato esplicito tra
# COPERTO/PARZIALE/VUOTO; (2) ogni oracolo citato come esistente esiste davvero in
# tools/ (niente promesse vuote); (3) le categorie dichiarate VUOTO o PARZIALE nel
# piano hanno una voce nel piano del Set 1 — una categoria vuota senza piano è una
# ferita dichiarata e ignorata. Stessa famiglia del glob-vs-lista: cita ciò che c'è.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MAPPA="$HERE/docs/mappa-dominio-gas-src.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$MAPPA" ] && ok "la mappa del dominio esiste" || { echo "FAIL mappa assente"; exit 1; }

# 1. ogni riga di categoria ha uno stato esplicito (il grassetto ** è ammesso;
#    l'intestazione "Categoria" non è una categoria)
RIGHE=$(grep -E '^\| [A-Z]' "$MAPPA" | grep -vc '^| Categoria')
CON_STATO=$(grep -E '^\| [A-Z]' "$MAPPA" | grep -v '^| Categoria' | grep -cE '\| ?\*{0,2}(COPERTO|PARZIALE|VUOTO)')
[ "$RIGHE" -gt 0 ] && [ "$RIGHE" -eq "$CON_STATO" ] \
  && ok "ogni categoria ($RIGHE) dichiara uno stato COPERTO/PARZIALE/VUOTO" \
  || ko "righe di categoria: $RIGHE, con stato esplicito: $CON_STATO"

# 2. ogni oracolo citato nella colonna tools esiste davvero (il backtick lo nomina)
NON_ESISTE=0
for t in $(grep -oE '`tools/[a-z_]+\.py`' "$MAPPA" | tr -d '`' | sort -u); do
  [ -f "$HERE/$t" ] || { ko "oracolo citato ma inesistente: $t"; NON_ESISTE=1; }
done
[ "$NON_ESISTE" -eq 0 ] && ok "tutti gli oracoli citati esistono in tools/"

# 3. il piano del Set 1 copre tutte le categorie VUOTO/PARZIALE a densità di calcolo
grep -q "valorizzazione" "$MAPPA" && grep -q "margine per documento" "$MAPPA" \
  && grep -q "accuratezza" "$MAPPA" \
  && ok "il piano dichiara i tre oracoli nuovi per i gap principali" \
  || ko "il piano non copre i gap dichiarati (valorizzazione/margine/accuratezza)"

# 4. privacy: nessun nome di progetto o cliente di REPO-E nella mappa (la regola
#    "Public repo, private work" — qui si lista ciò che NON deve comparire per forma:
#    nessun identificativo con trattino basso stile nome-cartella di progetto)
if grep -qE '[A-Za-z]+_[A-Za-z]+_[A-Za-z0-9]+__1' "$MAPPA"; then
  ko "la mappa cita nomi di cartelle progetto di REPO-E (privacy)"
else
  ok "nessun nome di progetto REPO-E nella mappa (privacy)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
