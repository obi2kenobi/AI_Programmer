#!/bin/bash
# test-bc-index.sh — debito aperto in DEBITI.md dal 2026-08-21 ("Test funzionali per
# bc_map.py / bc_index.py"), mai saldato. bc_map.py chiama davvero l'API BC (OAuth,
# credenziali) — non testabile in sandbox, resta debito. bc_index.py è puro (nessuna
# rete, nessuna scrittura fuori dal suo argomento implicito CWD): testabile in
# isolamento, su una COPIA di docs/bc/endpoints, senza toccare il README.md reale.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/bc/endpoints"
cp "$HERE"/docs/bc/endpoints/*.md "$TMP/docs/bc/endpoints/"
cp "$HERE"/docs/bc/CATALOGO_ENDPOINT_BC.md "$TMP/docs/bc/" 2>/dev/null || true
N_FILE=$(ls "$TMP/docs/bc/endpoints"/*.md | wc -l | tr -d ' ')

OUT=$(cd "$TMP" && python3 "$HERE/tools/bc_index.py" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "bc_index.py esegue senza errori su una copia reale degli endpoint" \
  || ko "bc_index.py rc=$RC: $OUT"
[ -f "$TMP/docs/bc/README.md" ] && ok "README.md generato" || ko "README.md non generato"

N_RIGHE=$(grep -c '^| `' "$TMP/docs/bc/README.md" 2>/dev/null || echo 0)
[ "$N_RIGHE" -eq "$N_FILE" ] && ok "una riga per ogni endpoint copiato ($N_FILE)" \
  || ko "righe=$N_RIGHE, file=$N_FILE — endpoint persi o duplicati"

grep -q "Avanzamento — $N_FILE mappati" "$TMP/docs/bc/README.md" \
  && ok "l'avanzamento riporta il conteggio reale ($N_FILE, senza il /108 cablato: il catalogo vive in questo hub)" \
  || ko "avanzamento sbagliato: $(grep Avanzamento "$TMP/docs/bc/README.md")"
grep -q "Catalogo servizi OData" "$TMP/docs/bc/README.md" \
  && ok "l'indice riporta il catalogo e i mancanti al censimento" \
  || ko "manca il conteggio catalogo/mancanti"

# bug reale (revisione 14 lenti, 2026-08-28): ogni riga della tabella del catalogo ha DUE
# valori fra backtick (nome visualizzato con spazi, nome tecnico con underscore) — la
# regex catturava il PRIMO (visualizzato), che non corrisponde mai a un nome di file
# reale. "mancanti" risultava gonfiato di 22 unità fantasma (258-231=27 atteso, il codice
# dava 49 prima del fix). Verifica diretta sulla funzione vera, sul catalogo reale.
RISULTATO=$(cd "$HERE" && python3 - <<'PY'
import sys, os, glob
sys.path.insert(0, "tools")
import bc_index
n_cat, mancanti = bc_index.catalogo_mancanti()
n_esistenti = len(glob.glob(os.path.join(bc_index.ENDPOINTS_DIR, "*.md")))
atteso = n_cat - n_esistenti
print("OK" if len(mancanti) == atteso else f"KO (mancanti={len(mancanti)} atteso={atteso})")
PY
)
[ "$RISULTATO" = "OK" ] \
  && ok "catalogo_mancanti(): cattura il nome tecnico, l'aritmetica torna semplice (catalogo - esistenti)" \
  || ko "catalogo_mancanti(): ancora gonfiato da nomi visualizzati fantasma — $RISULTATO"
grep -q "Salute del censimento" "$TMP/docs/bc/README.md" \
  && ok "l'indice riporta la SALUTE (verificati, data refresh) — il censimento invecchia in modo visibile" \
  || ko "manca la sezione salute del censimento"

# le righe devono essere ordinate per campi DECRESCENTI (bc_index.py: rows.sort(key=lambda r: -r[1]))
python3 - "$TMP/docs/bc/README.md" <<'PY'
import re, sys
path = sys.argv[1]
righe = re.findall(r'^\| `[^`]+` \| (\d+) \|', open(path, encoding="utf-8").read(), re.M)
campi = [int(x) for x in righe]
ordinato = all(campi[i] >= campi[i+1] for i in range(len(campi)-1))
sys.exit(0 if ordinato else 1)
PY
[ $? -eq 0 ] && ok "le righe sono ordinate per numero di campi decrescente" \
  || ko "ordine dei campi non decrescente"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
