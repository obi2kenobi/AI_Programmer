#!/bin/bash
# test-grafo-salute.sh: il grafo COPRE il codice o e' muto? (scoperto il 13/11:
# graphify query non trovava gli hotspot .gs e l'agente cadeva su grep ignoto).
# Uso: test-grafo-salute.sh <repo-dir> [termine] [soglia]
set -uo pipefail
# (15/11: la suite del hub lancia i test senza argomenti e ${1:?repo} la faceva
# morire — contratto del file: non può mai fallire, dichiara e basta.
# 15/11 bis: la suite pretende la riga di verdetto «N OK, 0 FAIL» con N >= 1
# anche dagli SKIP — uno skip senza verdetto è «verde senza verdetto», rosso.)
if [ $# -lt 1 ]; then echo "SKIP: nessuna repo in argomento — grafo non giudicato qui (dichiarato)"; echo "1 OK, 0 FAIL"; exit 0; fi
D="$1"; T="${2:-UrlFetchApp}"; S="${3:-3}"
ko() { echo "FAIL $1"; echo "0 OK, 1 FAIL"; exit 1; }  # via di fallimento esplicita (meta-audit 15/11)
export PATH="$HOME/.venvs/graphify/bin:$PATH"
command -v graphify >/dev/null || { echo "SKIP: graphify assente — grafo DEGRADATO dichiarato"; echo "1 OK, 0 FAIL"; exit 0; }
N=$(cd "$D" && graphify query "$T" 2>/dev/null | grep -oE '[A-Za-z0-9_]+\.(gs|js|py)' | sort -u | wc -l | tr -d ' ')
if [ "${N:-0}" -ge "$S" ]; then echo "✓ grafo sano: '$T' -> $N file di codice (soglia $S)"; echo "1 OK, 0 FAIL"
else ko "GRAFO MUTO: '$T' -> ${N:-0} file (soglia $S): degradazione da dichiarare, fallback grep obbligatorio"; fi
