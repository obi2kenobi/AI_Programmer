#!/bin/bash
# anonimizza-aziendale.sh — il cancello PII per QUALUNQUE sistema che parla con un LLM.
#
# (dominio, Luca 2026-09-28): rizzo-pii diventa il metodo standard di
# anonimizzazione aziendale. Ogni sistema — il turno notturno, il repo
# vendite, il morning-gate, qualunque script — che manda dati a un LLM
# (locale o cloud) passa da qui PRIMA. Il LLM vede placeholder, non vede
# mai nomi, IBAN, CF, PIVA, telefoni, email.
#
# Tre comandi:
#   anonimizza-aziendale.sh pulisci "<testo>"         → testo anonimizzato + diz su file
#   anonimizza-aziendale.sh ripristina "<testo>"       → testo vero (dal diz)
#   anonimizza-aziendale.sh stato                      → il server è su? quante categorie?
#
# Il dizionario vive in $ANON_DIZ_DIR (default: /tmp/anon-aziendale-$$/) e
# NON passa mai al LLM. Ogni sistema ha il suo dizionario per-sessione.
#
# Requisiti: rizzo-pii server su http://127.0.0.1:5005 (CPU, ~0.5GB, zero GPU)
# Se spento: passthrough dichiarato su stderr, il testo NON viene bloccato
# (il sistema continua a lavorare, ma vede i dati veri — dichiarato, non taciuto).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PII_URL="${PII_URL:-http://127.0.0.1:5005}"
CMD="${1:?uso: anonimizza-aziendale.sh <pulisci|ripristina|stato> [testo]}"
shift || true
# ANON_DIZ_DIR: la CHIAMANTE la imposta a inizio sessione (cosi' pulisci e
  # ripristina condividono il dizionario). Default: fissa, non per-PID.
  ANON_DIZ_DIR="${ANON_DIZ_DIR:-/tmp/anon-aziendale}"
ANON_DIZ="$ANON_DIZ_DIR/dizionario.json"
# (2026-10-01, giro 1): il fallimento inghiottito rompeva la catena in silenzio —
# senza dizionario il ripristino fa passthrough e i dati restano anonimi per sempre
mkdir -p "$ANON_DIZ_DIR" 2>/dev/null || { echo "⛔ anonimizza: non creo $ANON_DIZ_DIR — senza dizionario la catena GDPR e' rotta (fail-closed)" >&2; exit 1; }

case "$CMD" in
  stato)
    if curl -sf --max-time 3 "$PII_URL/health" >/dev/null 2>&1; then
      TAGS=$(curl -sf --max-time 3 "$PII_URL/health" 2>/dev/null | jq -r '.tags // "?"')
      MODEL=$(curl -sf --max-time 3 "$PII_URL/health" 2>/dev/null | jq -r '.model // "?"')
      echo "rizzo-pii: ATTIVO su $PII_URL (modello $MODEL, $TAGS categorie)"
      echo "  dizionario: $ANON_DIZ"
      exit 0
    else
      echo "rizzo-pii: SPENTO su $PII_URL — passthrough (i dati veri passano al LLM)"
      exit 1
    fi ;;

  pulisci)
    TESTO="${1:?serve il testo}"
    # (T5#6, 2026-10-01): il testo su STDIN, mai negli argv (ps li mostra a chi guarda)
    RISP=$(printf '%s' "$TESTO" | jq -cRs '{text:., include_mapping: true}' \
      | curl -sf --max-time 30 "$PII_URL/analyze" -H 'Content-Type: application/json' --data-binary @- 2>/dev/null)
    [ -z "$RISP" ] && { printf '%s' "$TESTO"; echo "⚠ passthrough: server PII spento" >&2; exit 0; }
    # salva il dizionario locale
    printf '%s' "$RISP" | jq '.mapping // {}' > "$ANON_DIZ" 2>/dev/null
    N=$(printf '%s' "$RISP" | jq -r '.n_entities // 0')
    [ "$N" -gt 0 ] && echo "  [$N PII anonimizzati]" >&2
    # stampa SOLO il testo anonimizzato (per pipe)
    printf '%s' "$RISP" | jq -r '.anonymized_text // empty'
    ;;

  ripristina)
    TESTO="${1:?serve il testo}"
    [ -f "$ANON_DIZ" ] || { printf '%s' "$TESTO"; exit 0; }
    python3 -c "
import json, sys
mapping = json.load(open('$ANON_DIZ'))
testo = sys.argv[1]
for ph, reale in mapping.items():
    testo = testo.replace(ph, reale)
sys.stdout.write(testo)
" "$TESTO"
    ;;

  *) echo "uso: anonimizza-aziendale.sh <pulisci|ripristina|stato> [testo]" >&2; exit 2 ;;
esac
