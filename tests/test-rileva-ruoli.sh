#!/bin/bash
# test-rileva-ruoli.sh — il banco del rilevamento ruoli (2026-10-03, faretra).
#
# Presidia:
#   1. un repo trading (py + molti .md) attiva: analista-trading, revisore-python,
#      curatore-conoscenza — i tre domini scoperti dall'analisi della faretra
#   2. un repo GAS gestionale generico attiva il canone di default (sviluppatore+revisore)
#   3. un repo magazzino GAS attiva specialista-logistica SOPRA al canone GAS
#   4. un repo pipeline (nome + .gs di raccolta) attiva pipeline-dati
#   5. il file ESISTENTE non viene toccato (è di Luca: editabile a mano)
#   6. --asciutti non scrive nulla
# Le fixture sono repo git vere in tmpdir (il tool esige .git — giusto: senza
# storia non c'è nemmeno il file .git/ruoli-attivi dove scrivere).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d "${TMPDIR:-/tmp}/rileva-ruoli.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

nuova_fixture() {  # <nome>
  F="$TMP/$1"
  mkdir -p "$F" && git -C "$F" init -q 2>/dev/null
  echo "$F"
}

# ── 1. repo trading ───────────────────────────────────────────────────────────
F=$(nuova_fixture Trading-Short)
mkdir -p "$F/docs"
echo "# Trading-Short" > "$F/README.md"
echo "analisi strategia backtest" > "$F/README.md"
for i in 1 2 3 4 5 6 7; do echo "print($i)" > "$F/modulo$i.py"; done
for i in $(seq 1 25); do echo "# analisi $i" > "$F/docs/nota$i.md"; done  # 25 .md: nel repo vero sono 121 contro 8 di codice
OUT=$(bash "$HERE/tools/rileva-ruoli.sh" "$F" --asciutti 2>&1)
for atteso in analista-trading revisore-python curatore-conoscenza; do
  grep -q "$atteso" <<<"$OUT" \
    && ok "repo trading attiva: $atteso" \
    || ko "repo trading NON attiva: $atteso (uscita: $(printf '%s' "$OUT" | tr '\n' ' ' | cut -c1-120))"
done
[ ! -f "$F/.git/ruoli-attivi" ] \
  && ok "--asciuti non scrive .git/ruoli-attivi" \
  || ko "--asciutti HA scritto .git/ruoli-attivi"

# ── 2. repo GAS generico ──────────────────────────────────────────────────────
F=$(nuova_fixture GestioneGenerica)
echo "function calcola(){}" > "$F/Codice.gs"
bash "$HERE/tools/rileva-ruoli.sh" "$F" >/dev/null 2>&1
R=$(cat "$F/.git/ruoli-attivi" 2>/dev/null)
for atteso in sviluppatore-gas revisore-gas; do
  grep -qx "$atteso" <<<"$R" && ok "repo GAS generico attiva: $atteso" || ko "repo GAS generico NON attiva: $atteso"
done
grep -qx "analista-trading" <<<"$R" && ko "repo GAS generico attiva analista-trading (falso positivo)" || ok "nessun falso positivo trading"

# ── 3. repo magazzino ─────────────────────────────────────────────────────────
F=$(nuova_fixture Magazzino_Treviso)
echo "function giacenza(){}" > "$F/Magazzino.gs"
bash "$HERE/tools/rileva-ruoli.sh" "$F" >/dev/null 2>&1
R=$(cat "$F/.git/ruoli-attivi" 2>/dev/null)
grep -qx "specialista-logistica" <<<"$R" && ok "repo magazzino attiva specialista-logistica" || ko "repo magazzino NON attiva specialista-logistica"
# il canone GAS resta: il logistico È un gestionale GAS
grep -qx "sviluppatore-gas" <<<"$R" && ok "repo magazzino mantiene il canone GAS" || ko "repo magazzino ha perso il canone GAS"

# ── 4. repo pipeline ──────────────────────────────────────────────────────────
F=$(nuova_fixture Price-Intelligence)
echo "function raccogli(){}" > "$F/Collector.gs"
bash "$HERE/tools/rileva-ruoli.sh" "$F" >/dev/null 2>&1
R=$(cat "$F/.git/ruoli-attivi" 2>/dev/null)
grep -qx "pipeline-dati" <<<"$R" && ok "repo price attiva pipeline-dati" || ko "repo price NON attiva pipeline-dati"

# ── 4bis. repo solo-documenti: curatore, NON il canone GAS (giro 2) ───────────
F=$(nuova_fixture RiflessioniCampo)
mkdir -p "$F/docs"
for i in 1 2 3; do echo "# riflessione $i" > "$F/docs/nota$i.md"; done
bash "$HERE/tools/rileva-ruoli.sh" "$F" >/dev/null 2>&1
R=$(cat "$F/.git/ruoli-attivi" 2>/dev/null)
grep -qx "curatore-conoscenza" <<<"$R" && ok "repo solo-documenti attiva curatore-conoscenza" || ko "repo solo-documenti NON attiva curatore-conoscenza ($R)"
grep -qx "sviluppatore-gas" <<<"$R" && ko "repo solo-documenti attiva il canone GAS (falso positivo: zero codice)" || ok "repo solo-documenti senza canone GAS"

# ── 5. il file esistente è di Luca ────────────────────────────────────────────
F=$(nuova_fixture Magazzino_Treviso)
printf 'specialista-logistica\n' > "$F/.git/ruoli-attivi"
OUT=$(bash "$HERE/tools/rileva-ruoli.sh" "$F" 2>&1)
grep -q "esiste già" <<<"$OUT" && ok "il file esistente non viene toccato (editabile)" || ko "il rilevamento ha sovrascritto il file di Luca"
grep -qx "specialista-logistica" "$F/.git/ruoli-attivi" && ok "il contenuto editato resta" || ko "il contenuto editato è stato perso"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
