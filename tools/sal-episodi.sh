#!/bin/bash
# sal-episodi.sh — comprime il SAL in episodi (furto dal pattern "periodic
# summarization" dei sistemi di memoria): a fine giornata, 3-5 episodi densi
# al posto del flusso completo. Il SAL resta, il contesto del giorno dopo
# legge gli episodi.
set -uo pipefail
DIR="${1:?uso: sal-episodi.sh <dir-repo>}"
cd "$DIR" || exit 2
[ -f SAL.md ] || { echo "sal-episodi: SAL.md assente (dichiarato)"; exit 0; }
DATA=$(date +%F)
EPI="SAL-episodi.md"
N_RIGHE=$(grep -c . SAL.md)
if [ "$N_RIGHE" -lt 50 ]; then
  echo "sal-episodi: SAL ha solo $N_RIGHE righe — niente da comprimere"
  exit 0
fi
# gli ultimi 50 eventi (o tutto se meno)
CODA=$(tail -50 SAL.md)
# conta i tipi
LEZIONI=$(grep -c "^## " <<<"$CODA" || true)
FALLIMENTI=$(grep -ci "errore\|fallit\|⛔" <<<"$CODA" || true)
SUCCESSI=$(grep -ci "ok\|verde\|✓" <<<"$CODA" || true)
{
  printf '\n## Episodi del %s (da %s righe di SAL)\n\n' "$DATA" "$N_RIGHE"
  printf '- **Lezioni** (%s eventi): i pattern confermati oggi sono in patterns/\n' "${LEZIONI:-0}"
  printf '- **Fallimenti** (%s segnali): le cause in REGISTRO.md\n' "${FALLIMENTI:-0}"
  printf '- **Successi** (%s verdi): le prove in tests/\n' "${SUCCESSI:-0}"
  printf '- **Prossimo giorno**: guarda i debiti aperti in DEBITI.md\n'
} >> "$EPI"
echo "sal-episodi: aggiunto a $EPI (SAL: $N_RIGHE righe, compresse in episodi)"
