#!/bin/bash
# test-onboard-repo-percorso-cloud-in-testa.sh — 4° ciclo, SET 3 giro 6. docs/system.md
# dichiara "il dettaglio operativo [sul percorso cloud/ibrido] è in testa a
# tools/onboard-repo.sh" — ma il blocco viveva nelle ULTIME righe del file (127/127),
# dopo l'intero script, mai visto da un agente che legge l'inizio prima di eseguire (o
# che — come una sessione cloud — non può nemmeno eseguirlo, perché lo script chiama
# `gh` direttamente senza mai avvisarlo). Verifica che il blocco sia ora vicino alla
# testa del file (non in coda) e citato una sola volta (non duplicato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HERE/tools/onboard-repo.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$SCRIPT" && ok "onboard-repo.sh ha sintassi valida dopo lo spostamento" \
  || ko "onboard-repo.sh ha un errore di sintassi"

RIGA=$(grep -n "PERCORSO CLOUD/IBRIDO" "$SCRIPT" | head -1 | cut -d: -f1)
[ -n "$RIGA" ] && [ "$RIGA" -le 20 ] \
  && ok "il blocco PERCORSO CLOUD/IBRIDO è vicino alla testa del file (riga $RIGA)" \
  || ko "il blocco non è vicino alla testa (riga ${RIGA:-assente}) — regressione al bug del giro 6"

N_OCCORRENZE=$(grep -c "PERCORSO CLOUD/IBRIDO" "$SCRIPT")
[ "$N_OCCORRENZE" -eq 1 ] && ok "il blocco è citato una sola volta (non duplicato)" \
  || ko "il blocco compare $N_OCCORRENZE volte — attese 1"

grep -q "gh\b" <(sed -n "${RIGA},$((RIGA+15))p" "$SCRIPT") \
  && ok "il blocco avverte esplicitamente che lo script chiama gh direttamente" \
  || ko "il blocco non avverte più sulla dipendenza da gh"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
