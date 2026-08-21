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

# Annota l'ULTIMA riga corrispondente (repo,pr) che non abbia già un esito
python3 - "$CSV" "$REPO" "$PR" "$ESITO" <<'PY'
import sys, io

csv, repo, pr, esito = sys.argv[1:5]
with io.open(csv, encoding="utf-8") as f:
    righe = f.read().splitlines()

target = f"{repo},#{pr},"
idx = None
for i, r in enumerate(righe):
    if target in r and not r.rstrip().endswith(("," + esito,)) and r.count(",") == 5:
        idx = i  # continua: l'ULTIMA riga da 6 campi (senza esito)

if idx is None:
    # nessuna riga da 6 campi: prova l'ultima riga corrispondente in generale
    for i, r in enumerate(righe):
        if target in r:
            idx = i
    if idx is None:
        print(f"nessuna riga per {repo} #{pr}", file=sys.stderr); sys.exit(1)
    if righe[idx].count(",") >= 6:
        print(f"esito già registrato per {repo} #{pr}", file=sys.stderr); sys.exit(1)

righe[idx] = righe[idx] + f",{esito}"
with io.open(csv, "w", encoding="utf-8") as f:
    f.write("\n".join(righe) + "\n")
print(f"esito registrato: {repo} #{pr} → {esito}")
PY
