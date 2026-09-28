#!/bin/bash
# pii-scan.sh — il rilevatore PII con modello (studio rizzo-pii, 2026-09-28).
#
# 22 categorie di dati personali rilevate da un modello NER 0.3B su CPU
# (mmBERT, micro-F1 0.989 su testo legale italiano). Include codice fiscale,
# partita IVA, dati catastali con validazione checksum — cose che nessun
# grep manuale puo' fare.
#
# Uso:
#   pii-scan.sh <testo>                  → JSON con PII rilevato
#   pii-scan.sh --file <percorso>        → scansiona un file
#   pii-scan.sh --check                  → exit 0 se il server risponde
# Esce: 0 PII trovato o server ok · 1 nessun PII · 2 server spento/errore
set -uo pipefail
PII_URL="${PII_URL:-http://127.0.0.1:5005}"

# il server e' su?
curl -sf --max-time 3 "$PII_URL/health" >/dev/null 2>&1 || { echo "pii-scan: server spento su $PII_URL" >&2; exit 2; }

if [ "${1:-}" = "--check" ]; then
  echo "pii-scan: server OK"
  exit 0
fi

TESTO=""
if [ "${1:-}" = "--file" ] && [ -n "${2:-}" ]; then
  TESTO=$(cat "$2" 2>/dev/null || { echo "pii-scan: file illeggibile: $2" >&2; exit 2; })
else
  TESTO="${1:-}"
fi
[ -z "$TESTO" ] && { echo "pii-scan: nessun testo" >&2; exit 2; }

RISP=$(curl -sf --max-time 30 "$PII_URL/analyze" \
  -H 'Content-Type: application/json' \
  -d "$(jq -cn --arg t "$TESTO" '{text:$t}')" 2>/dev/null)

[ -z "$RISP" ] && { echo "pii-scan: server non ha risposto" >&2; exit 2; }

# conta le entita' rilevate (formato: n_entities + by_label + segments)
N_ENT=$(printf '%s' "$RISP" | jq -r '.n_entities // 0' 2>/dev/null)
[ -z "$N_ENT" ] && N_ENT=0

if [ "$N_ENT" -gt 0 ]; then
  echo "pii-scan: $N_ENT entita' PII rilevate"
  printf '%s' "$RISP" | jq -r '.by_label | to_entries[] | "  \(.key): \(.value)"' 2>/dev/null
  exit 0
else
  echo "pii-scan: nessun PII rilevato"
  exit 1
fi
