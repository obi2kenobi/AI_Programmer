#!/bin/bash
# test-riconciliazione-magazzino.sh — 4° ciclo, SET 1 "agenti/sistema contabile" giro 1.
# tools/riconciliazione_magazzino.py implementa una formula reale (non inventata): il
# modulo di riconciliazione inventario di un progetto reale di gestione magazzino (repo
# esterno REPO-E, cartella gas-src/), survey del 2026-08-23. Verifica il caso pilota
# citato all'utente (120/4.50/115 → -5/-22.50€), la categorizzazione
# senza-discrepanza/non-contato, e l'ordinamento per |deltaValore| decrescente —
# l'aritmetica è contata a mano, non a memoria (regola CLAUDE.md "L'aspettativa si
# deriva").
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

RISULTATO=$(cd "$HERE" && python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from riconciliazione_magazzino import categorizza

righe = [
    # caso pilota citato all'utente: 120/4.50/115 -> delta=-5, deltaValore=-22.50
    {"codice": "ART-001", "qty_bc": "120", "costo_finale": "4.50", "qty_fisica": "115", "stato": ""},
    # nessuna discrepanza
    {"codice": "ART-002", "qty_bc": "50", "costo_finale": "2.00", "qty_fisica": "50", "stato": ""},
    # non contato: qty_fisica vuota -> deve restare fuori dal calcolo, mai trattato come 0
    {"codice": "ART-003", "qty_bc": "10", "costo_finale": "9.99", "qty_fisica": "", "stato": "Non Contato"},
    # rettifica di importo minore, per verificare l'ordinamento decrescente per |deltaValore|
    {"codice": "ART-004", "qty_bc": "30", "costo_finale": "1.00", "qty_fisica": "31", "stato": ""},
]
non_contato, senza_discrepanza, con_rettifica = categorizza(righe)

checks = []
checks.append(("pilota: 1 riga con rettifica ha ART-001 con delta=-5", con_rettifica[0]["codice"] == "ART-001" and con_rettifica[0]["delta"] == -5))
checks.append(("pilota: deltaValore = -22.50", abs(con_rettifica[0]["delta_valore"] - (-22.50)) < 1e-9))
checks.append(("ART-002 senza discrepanza (delta=0)", len(senza_discrepanza) == 1 and senza_discrepanza[0]["codice"] == "ART-002"))
checks.append(("ART-003 non contato, mai un delta numerico", len(non_contato) == 1 and non_contato[0]["codice"] == "ART-003" and non_contato[0]["delta"] == ""))
checks.append(("ART-004 in con_rettifica con delta=+1, deltaValore=+1.00", con_rettifica[1]["codice"] == "ART-004" and con_rettifica[1]["delta"] == 1 and abs(con_rettifica[1]["delta_valore"] - 1.00) < 1e-9))
checks.append(("ordinamento per |deltaValore| decrescente: 22.50 prima di 1.00", abs(con_rettifica[0]["delta_valore"]) >= abs(con_rettifica[1]["delta_valore"])))

for nome, esito in checks:
    print(f"{'OK' if esito else 'KO'}\t{nome}")

# bug reale (revisione 14 lenti, 2026-08-28): qty_bc/costo_finale venivano convertiti con
# float() PRIMA del controllo "non contato" — una riga "Non Contato" con costo_finale
# vuoto (plausibile: articolo non ancora valorizzato) faceva crashare l'intero script.
riga_crash = [{"codice": "ART-005", "qty_bc": "10", "costo_finale": "", "qty_fisica": "", "stato": "Non Contato"}]
try:
    nc, _, _ = categorizza(riga_crash)
    ok_crash = len(nc) == 1 and nc[0]["codice"] == "ART-005"
except Exception as e:
    ok_crash = False
print(f"{'OK' if ok_crash else 'KO'}\tNon Contato con costo_finale vuoto: nessun crash, categorizzato correttamente")
PY
)
while IFS=$'\t' read -r stato nome; do
  if [ "$stato" = "OK" ]; then ok "$nome"; else ko "$nome"; fi
done <<< "$RISULTATO"

# la formula è citata come oracolo, non inventata — deve nominare la fonte reale per
# codice anonimo (mai per nome di progetto/repo privato, regola CLAUDE.md "Public repo,
# private work")
grep -q "REPO-E" "$HERE/tools/riconciliazione_magazzino.py" \
  && ok "il tool cita la fonte reale della formula (non inventata, per codice anonimo)" \
  || ko "il tool non cita più la fonte della formula"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
