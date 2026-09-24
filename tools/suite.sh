#!/bin/bash
# suite.sh — il runner della suite di test dell'hub (un comando per riga, E-029).
#
# Storia: questa riga viveva composta dentro .night-verify (`N=0; TOT=$(...);
# for t in ...`) e sopravviveva PER CASO: il turno antepone `ai_timeout 120` a
# ogni riga, l'assegnazione iniziale diventava argomento del comando, e solo il
# fatto che l'ULTIMO comando fosse un echo la teneva verde. Scoperto da E-029
# (2026-09-18): il contratto di .night-verify e' UN COMANDO per riga. La riga
# diventa tool: testabile, citabile, con una porta.
#
# Porta con se' le due lezioni del report del gate (4° ciclo, 2026-08-23):
# 1. l'elenco per nome lasciava fuori i test nuovi — il loop li prende tutti;
# 2. il report mostra solo il tail: serve un riepilogo esplicito N/TOT sempre
#    visibile, e sul fallimento QUALE file e il suo output.
#
# Uso: suite.sh [dir-repo]   (default: la radice del repo che lo contiene)
# Esce: 0 = tutti i test superati · 1 = almeno un test fallito (o zero test)
set -uo pipefail
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$DIR"

# (2026-09-24, E-047): una cache di bytecode FRESCA per ogni giro della suite. Un sabotaggio a mano della
# stessa dimensione, nello stesso secondo, lascia valido il .pyc in tools/__pycache__: i banchi che
# importano il modulo giudicavano il codice di prima. Con PYTHONPYCACHEPREFIX Python legge e scrive il
# bytecode solo qui dentro, mai nei __pycache__ del sorgente.
PYTHONPYCACHEPREFIX=$(mktemp -d "${TMPDIR:-/tmp}/suite-pyc.XXXXXX"); export PYTHONPYCACHEPREFIX
trap 'case "$PYTHONPYCACHEPREFIX" in */suite-pyc.??????) rm -rf "$PYTHONPYCACHEPREFIX" ;; esac' EXIT

N=0; SUPERATI=0
TOT=$(ls tests/test-*.sh 2>/dev/null | wc -l | tr -d ' ')
[ "$TOT" -eq 0 ] && { echo "⛔ suite: nessun tests/test-*.sh trovato"; exit 1; }
T0=$(date +%s)
for t in tests/test-*.sh; do
  N=$((N+1))
  # (2026-09-24, terzo ventaglio, V4#1): il banco in corso, su stderr — se un budget taglia la suite,
  # l'ultima riga dice dove si e' fermata
  echo "▶ $t" >&2
  OUT=$(bash "$t" 2>&1) || {
    echo "FALLITO ($N/$TOT): $t"
    echo "$OUT" | tail -10
    exit 1
  }
  # (revisione 10 giri, 2026-09-23): rc 0 non basta — un test che carica una libreria con
  # `source` muore VERDE se la libreria esce, e uno con zero asserzioni esce 0 lo stesso.
  # Si pretende la riga di verdetto «N OK, 0 FAIL» con N >= 1 (la stampano tutti i test).
  if ! grep -qE '^[1-9][0-9]* OK, 0 FAIL( |$)' <<<"$OUT"; then
    echo "FALLITO ($N/$TOT): $t — verde senza verdetto (manca «N OK, 0 FAIL» con N >= 1)"
    echo "$OUT" | tail -5
    exit 1
  fi
  SUPERATI=$((SUPERATI+1))
done
# (2026-09-24, terzo ventaglio, V2#2): il riepilogo contava i GIRI del ciclo (N), non i banchi superati — un
# ciclo che saltava banchi stampava lo stesso «TOT/TOT». Si conta dopo il verdetto, e mancarne uno e' rosso.
if [ "$SUPERATI" -ne "$TOT" ]; then
  echo "FALLITO: superati $SUPERATI banchi su $TOT — il runner ne ha saltati $((TOT - SUPERATI))"
  exit 1
fi
echo "Durata della suite: $(( $(date +%s) - T0 )) s"
echo "Suite test hub: $SUPERATI/$TOT file superati"   # l'ULTIMA riga: il riepilogo che il turno e i banchi leggono
