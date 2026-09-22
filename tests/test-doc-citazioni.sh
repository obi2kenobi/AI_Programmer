#!/bin/bash
# test-doc-citazioni.sh — la lente dei fantasmi documentali (audit 2026-09-23).
# Il MANUALE comandava da tre settimane `bash tools/verify-patterns.sh` — uno
# script che NON E' MAI ESISTITO su nessun branch mergiato (PR #23, l'unica del
# suo batch mai fusa, ma il diario la registrava consegnata con "risultati
# misurati"). Chi segue il manuale otteneva «No such file».
#
# La lente: ogni path tools/*.sh|py o tests/*.sh CITATO come comando nei tre
# documenti operativi deve esistere nell'hub. Le eccezioni si dichiarano qui
# sotto con la ragione, non col silenzio.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# eccezioni dichiarate: path citato → perche' non deve esistere nell'hub
ECCEZIONI=""

FANTASMI=""
for doc in docs/MANUALE-OPERATIVO.md night-shift/README.md README.md; do
  [ -f "$HERE/$doc" ] || continue
  while IFS= read -r cito; do
    [ -f "$HERE/$cito" ] && continue
    if grep -qF "$cito" <<<"$ECCEZIONI"; then continue; fi
    FANTASMI="$FANTASMI
  $doc → $cito"
  done < <(grep -oE '(tools|tests)/[a-zA-Z0-9_.-]+\.(sh|py)' "$HERE/$doc" | sort -u)
done
if [ -z "$FANTASMI" ]; then
  ok "ogni tool citato come comando nei documenti operativi esiste nell'hub"
else
  ko "tool citati nei documenti ma inesistenti:$FANTASMI"
fi

# e il modello del turno: i documenti devono citare quello VERO, non il precedente
MODELLO=$(grep -oE '^MODEL_TAG="[^"]+"' "$HERE/night-shift/night-shift.sh" | cut -d'"' -f2)
if [ -n "$MODELLO" ]; then
  if grep -q "$MODELLO" "$HERE/night-shift/README.md"; then
    ok "il README cita il modello di turno vero ($MODELLO)"
  else
    ko "il README non cita il modello attuale ($MODELLO): dice ancora quello di ieri?"
  fi
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
