#!/bin/bash
# test-grafo-salute.sh: il grafo COPRE il codice o e' muto? (scoperto il 13/11:
# graphify query non trovava gli hotspot .gs e l'agente cadeva su grep ignoto).
# Uso: test-grafo-salute.sh <repo-dir> [termine] [soglia]
set -uo pipefail
D="${1:?repo}"; T="${2:-UrlFetchApp}"; S="${3:-3}"
export PATH="$HOME/.venvs/graphify/bin:$PATH"
command -v graphify >/dev/null || { echo "SKIP: graphify assente — grafo DEGRADATO dichiarato"; exit 0; }
N=$(cd "$D" && graphify query "$T" 2>/dev/null | grep -oE '[A-Za-z0-9_]+\.(gs|js|py)' | sort -u | wc -l | tr -d ' ')
if [ "${N:-0}" -ge "$S" ]; then echo "✓ grafo sano: '$T' -> $N file di codice (soglia $S)"
else echo "✗ GRAFO MUTO: '$T' -> ${N:-0} file (soglia $S): degradazione da dichiarare, fallback grep obbligatorio"; exit 1; fi
