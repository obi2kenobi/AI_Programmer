#!/bin/bash
# test-bc-map-leggi-curati.sh — banco di regressione nato dalla revisione "L'Hub Allo
# Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in tools/bc_map.py,
# write_md() esegue l'escape dei pipe letterali (\|) nella colonna Esempio, ma
# leggi_curati() li riparsava con uno split("|") naive che non conosceva l'escape — un
# valore campione con un pipe (es. "Sedie|Tavoli") sfasava le colonne successive
# (Significato/Verificato), corrompendo silenziosamente il censimento compilato a mano
# a ogni refresh. Nessun test esisteva per questo tool.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

RISULTATO=$(cd "$TMP" && python3 - "$HERE/tools" <<'PY'
import sys, os
sys.path.insert(0, sys.argv[1])
import bc_map

os.makedirs("docs/bc/endpoints", exist_ok=True)
bc_map.OUT_DIR = "docs/bc/endpoints"

checks = []

# caso 1: campo il cui ESEMPIO contiene un pipe letterale
fields = {"Descrizione": {"type": "string", "sample": "Sedie|Tavoli"}}
path = bc_map.write_md("TestEndpoint", "http://x", [{}], fields)
checks.append(("write_md esegue l'escape del pipe nell'esempio", "Sedie\\|Tavoli" in open(path).read()))

# simula compilazione manuale delle colonne Significato/Verificato
content = open(path).read().replace("|  | ☐ |", "| Categoria prodotto | ✅ |")
open(path, "w").write(content)

curati = bc_map.leggi_curati(path)
checks.append(("nessuno sfasamento: Significato letto correttamente",
                curati.get("Descrizione", (None, None))[0] == "Categoria prodotto"))
checks.append(("nessuno sfasamento: Verificato letto correttamente",
                curati.get("Descrizione", (None, None))[1] == "✅"))

# caso 2: campo SENZA pipe nell'esempio, deve continuare a funzionare come prima
fields2 = {"Codice": {"type": "string", "sample": "ABC123"}}
path2 = bc_map.write_md("TestEndpoint2", "http://x", [{}], fields2)
content2 = open(path2).read().replace("|  | ☐ |", "| Codice articolo | ✅ |")
open(path2, "w").write(content2)
curati2 = bc_map.leggi_curati(path2)
checks.append(("caso senza pipe: invariato",
                curati2.get("Codice") == ("Codice articolo", "✅")))

for nome, esito in checks:
    print(f"{'OK' if esito else 'KO'}\t{nome}")
PY
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
