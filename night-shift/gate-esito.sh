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
righe_target = [i for i, r in enumerate(righe) if target in r]
if not righe_target:
    print(f"nessuna riga per {repo} #{pr}", file=sys.stderr); sys.exit(1)

idx = None          # ultima riga ancora pendente (senza esito)
ultimo_esito = None # ultimo esito già scritto per questo repo+pr, in ordine di file

for i in righe_target:
    campi = righe[i].split(",")
    if len(campi) == 6 or (len(campi) >= 7 and campi[6] == ""):
        idx = i  # continua: l'ULTIMA riga corrispondente ancora senza esito
    elif len(campi) >= 7 and campi[6] != "":
        ultimo_esito = campi[6]  # continua: l'ultimo esito visto, in ordine di file

# Bug trovato al Giro 9 dei test 2026-08-21: con più righe pendenti per lo stesso
# repo+PR (realistico — più notti sullo stesso PR aperto), una doppia chiamata
# scriveva l'esito due volte su righe diverse invece di respingere la seconda.
# Fix: un esito TERMINALE (merge/chiusura) chiude la questione per sempre — nessuna
# riga pendente più vecchia va toccata dopo. "commessa" non è terminale: un ciclo
# correttivo può legittimamente produrre più avanti una riga nuova con un esito
# successivo (es. commessa → poi merge dopo la correzione), quindi non blocca.
if ultimo_esito in ("merge", "chiusura"):
    print(f"esito già registrato per {repo} #{pr} ({ultimo_esito}, stato finale)", file=sys.stderr)
    sys.exit(1)

if idx is None:
    print(f"nessuna riga in attesa di esito per {repo} #{pr}", file=sys.stderr)
    sys.exit(1)

campi = righe[idx].split(",")
# formato storico a 6 campi: manca la colonna, si aggiunge con la sua virgola.
# formato attuale a 7 campi: la virgola c'è già (campo vuoto), si scrive solo il valore.
righe[idx] = righe[idx] + (f",{esito}" if len(campi) == 6 else esito)
with io.open(csv, "w", encoding="utf-8") as f:
    f.write("\n".join(righe) + "\n")
print(f"esito registrato: {repo} #{pr} → {esito}")
PY
