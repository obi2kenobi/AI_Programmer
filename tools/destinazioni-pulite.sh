#!/bin/bash
# destinazioni-pulite.sh — il cancello delle DESTINAZIONI (furto da OpenAPPA,
# giro 2 del 2026-10-08: «is this data allowed to go to this destination?»).
#
# Loro: politica deterministica tra agente e tool, sul FLUSSO letto→destinazione.
# Noi: la notte pubblica in tre destinazioni (corpi PR, commenti issue, messaggi
# di commit) e NESSUNO controllava che dentro non finissero dati personali letti
# dai file del repo. Il cancello e' DETERMINISTICO (regex/pattern IT: la stessa
# filosofia — stessa risposta ogni volta), il NER di rizzo-pii resta il secondo
# strato se il server vive (dichiarato: il cancello non dipende da lui).
#
# Uso: printf '%s' "$testo" | destinazioni-pulite.sh <destinazione>
#   rc 0 = pulito · rc 1 = SPORCO (le righe colpevoli su stdout) · rc 2 = uso errato
# Le righe sporche si TOLGONO dal testo (il chiamante pubblica il resto): la
# destinazione non riceve mai il dato, la notte non si ferma.
set -uo pipefail
DEST="${1:?uso: destinazioni-pulite.sh <destinazione: pr-body|issue-comment|commit-msg>}"
TESTO=$(cat)

SPORCHE=""
while IFS= read -r RIGA; do
  [ -z "$RIGA" ] && continue
  SPORCO=0
  # email (deterministico)
  grep -qE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' <<<"$RIGA" && SPORCO=1
  # telefono IT: 3xx prefisso mobile o 0prefisso, spazi/punti/trattini ammessi, >= 9 cifre
  CIFRE=$(grep -oE '[0-9]' <<<"$RIGA" | wc -l | tr -d ' ')
  grep -qE '(\+39 |0039 |3[0-9]{2}[ .-]?[0-9]{3}[ .-]?[0-9]{3,4}|0[0-9]{2,4}[ .-]?[0-9]{5,7})' <<<"$RIGA" && [ "${CIFRE:-0}" -ge 9 ] && SPORCO=1
  # IBAN IT (27 tra lettere e cifre, parte con IT + 2 cifre)
  grep -qE 'IT[0-9]{2}[A-Z][0-9]{10}[0-9A-Z]{12}' <<<"$RIGA" && SPORCO=1
  # codice fiscale (6 lettere, 2 cifre, lettera, 2 cifre, lettera, 3 cifre, lettera)
  grep -qE '[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[A-Z][0-9]{3}[A-Z]' <<<"$RIGA" && SPORCO=1
  [ "$SPORCO" -eq 1 ] && SPORCHE="${SPORCHE}${RIGA}"$'\n'
done <<<"$TESTO"

if [ -n "$SPORCHE" ]; then
  echo "destinazioni-pulite: $DEST SPORCA — righe sospette (NON pubblicate):"
  printf '%s' "$SPORCHE" | sed 's/^/  /'
  exit 1
fi
# secondo strato dichiarato: il NER di rizzo-pii, se vive — il cancello non dipende da lui
PII_URL="${PII_URL:-http://127.0.0.1:5005}"
if curl -sf --max-time 2 "$PII_URL/health" >/dev/null 2>&1; then
  RISP=$(printf '%s' "$TESTO" | jq -cRs '{text:.}' | curl -sf --max-time 15 "$PII_URL/analyze" -H 'Content-Type: application/json' --data-binary @- 2>/dev/null || true)
  N_ENT=$(printf '%s' "$RISP" | jq -r '.n_entities // 0' 2>/dev/null || true)
  if [ "${N_ENT:-0}" -gt 0 ]; then
    # il NER avvisa, NON blocca: misurato un falso positivo su testo innocuo —
    # la notte non si ferma per lui, il giorno legge il rilievo nel log
    echo "destinazioni-pulite: $DEST — avviso NER ($N_ENT entita', secondo strato, non bloccante)"
  fi
fi
echo "destinazioni-pulite: $DEST pulita"
exit 0
