#!/bin/bash
# gate-esito.sh — registra l'esito umano di una PR giudicata dal gate.
# Chiude il buco trovato dalla review 2026-08-21: la colonna "esito" del CSV
# non veniva mai scritta — il livello memoria era vuoto per costruzione.
#
# Uso: gate-esito.sh <owner/repo> <numero-PR> <merge|chiusura|commessa>
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CSV="$HERE/../metrics/gate.csv"

REPO="${1:?uso: gate-esito.sh owner/repo <PR> <merge|chiusura|commessa>}"
PR="${2:?}"
ESITO="${3:?}"

case "$ESITO" in
  merge|chiusura|commessa) ;;
  *) echo "esito non valido: $ESITO (merge|chiusura|commessa)" >&2; exit 1 ;;
esac

[ -f "$CSV" ] || { echo "$CSV inesistente" >&2; exit 1; }

# Annota l'ULTIMA riga corrispondente (repo,pr) che non abbia già un esito.
# NOTA (bug trovato con dogfooding, 2026-08-21): morning-gate.sh scrive ORA 7 campi con
# virgola finale per l'esito vuoto ("...,banco,") — un conteggio di virgole fisso (==5/>=6)
# scritto per il formato pre-fix a 6 campi scambiava "esito vuoto" per "esito già presente"
# su OGNI riga nuova, rendendo questo script inutilizzabile dal giorno del fix in poi.
# Si riconosce lo stato dal numero di CAMPI (split), non dal conteggio di virgole, e si
# distinguono esplicitamente i due formati (storico a 6 campi / attuale a 7 con ultimo vuoto).
python3 - "$CSV" "$REPO" "$PR" "$ESITO" <<'PY'
import sys, io

csv, repo, pr, esito = sys.argv[1:5]
with io.open(csv, encoding="utf-8") as f:
    righe = f.read().splitlines()

target = f"{repo},#{pr},"
idx = None
for i, r in enumerate(righe):
    if target not in r:
        continue
    campi = r.split(",")
    if len(campi) == 6 or (len(campi) >= 7 and campi[6] == ""):
        idx = i  # continua: l'ULTIMA riga corrispondente ancora senza esito

if idx is None:
    if not any(target in r for r in righe):
        print(f"nessuna riga per {repo} #{pr}", file=sys.stderr); sys.exit(1)
    print(f"esito già registrato per {repo} #{pr}", file=sys.stderr); sys.exit(1)

campi = righe[idx].split(",")
# formato storico a 6 campi: manca la colonna, si aggiunge con la sua virgola.
# formato attuale a 7 campi: la virgola c'è già (campo vuoto), si scrive solo il valore.
righe[idx] = righe[idx] + (f",{esito}" if len(campi) == 6 else esito)
with io.open(csv, "w", encoding="utf-8") as f:
    f.write("\n".join(righe) + "\n")
print(f"esito registrato: {repo} #{pr} → {esito}")
PY
