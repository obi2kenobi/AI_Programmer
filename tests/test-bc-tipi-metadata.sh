#!/bin/bash
# test-bc-tipi-metadata.sh — bc_tipi_metadata.py vive contro il $metadata VIVO di
# Business Central (rete + credenziali): qui si verifica ciò che È verificabile
# offline, cioè il contratto: la mappatura Edm→Tipo usata per correggere il
# censimento, la dichiarazione della dipendenza dalla rete, e il fallimento
# dichiarato (esce 1, non traceback né silenzio) quando il metadata non è
# raggiungibile. La correzione tipi VERA (901 campi int→float, 2026-08-26) è
# stata fatta sul vivo e sta nella history, non si ripete in un test.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/bc_tipi_metadata.py"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# 1. La mappatura EDM è quella dichiarata: i tipi decimali diventano float,
#    gli interi restano int — è la correzione dei 901 campi tipizzati male
python3 - "$TOOL" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("btm", sys.argv[1])
m = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(m)
except SystemExit:
    pass  # il modulo può uscire in main(); la mappatura è a livello modulo
attesi = {"Edm.Decimal": "float", "Edm.Double": "float", "Edm.Single": "float",
          "Edm.Int32": "int", "Edm.String": "string", "Edm.Boolean": "bool",
          "Edm.Guid": "guid", "Edm.Date": "date", "Edm.DateTimeOffset": "datetime"}
ok, ko = 0, 0
for k, v in attesi.items():
    if m.EDM.get(k) == v: ok += 1
    else: print(f"FAIL mappatura {k}: attesa {v}, avuta {m.EDM.get(k)}"); ko += 1
print(f"mappa-EDM-ok {ok}")
sys.exit(1 if ko else 0)
EOF
[ $? -eq 0 ] && ok "mappatura Edm→Tipo completa e corretta (9 tipi)" || ko "mappatura Edm incompleta o errata"

# 2. Il tipo importo/quantità che genera i 901 errori DEVE mappare a float
python3 - "$TOOL" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("btm2", sys.argv[1])
m = importlib.util.module_from_spec(spec)
try: spec.loader.exec_module(m)
except SystemExit: pass
sys.exit(0 if m.EDM["Edm.Decimal"] == "float" else 1)
EOF
[ $? -eq 0 ] && ok "Edm.Decimal → float (la correzione dei campi importo da campione zero)" || ko "Edm.Decimal non mappa a float"

# 3. Il tool DICHARA la dipendenza dalla rete: chi lo esegue offline deve sapere
#    cosa non funzionerà, e perché esiste (inferire dal campione è debole)
grep -q '\$metadata' "$TOOL" && ok "cita il \$metadata OData V4 come fonte schema" || ko "non cita \$metadata"
grep -q 'esce 1 se il metadata non è raggiungibile' "$TOOL" && ok "dichiara il fallimento: esce 1 se metadata irraggiungibile" || ko "non dichiara il comportamento a metadata irraggiungibile"

# 4. Contratto di fallimento: credenziali che puntano a 127.0.0.1:1 (porta
#    rifiutata all'istante, NESSUNA rete vera) → main() muore, il processo esce
#    diverso da zero. Chi lo esegue offline vede il fallimento, non il silenzio.
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf 'client_id=x\nclient_secret=x\nscope=x\ntoken_url=http://127.0.0.1:1/t\nbase_url=http://127.0.0.1:1/b\n' > "$TMP/cred"
python3 - "$TOOL" "$TMP/cred" <<'EOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("btm4", sys.argv[1])
m = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(m)
except SystemExit:
    pass
m.bcm.CRED_FILE = sys.argv[2]   # credenziali avvelenate: rifiuto immediato, no rete
m.main()                        # deve sollevare, non tornare 0 in silenzio
EOF
RC=$?
[ "$RC" -ne 0 ] && ok "metadata irraggiungibile: esce $RC, non silenzio" || ko "metadata irraggiungibile: exit 0 inaspettato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
