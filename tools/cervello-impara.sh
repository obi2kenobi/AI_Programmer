#!/bin/bash
# cervello-impara.sh — il /learn del sistema: a fine giornata il turno distilla
# UNA lezione riusabile dal proprio log e la propone come nota del cervello,
# DA APPROVARE al mattino. Mai auto-salvata senza occhio umano.
#
# (Ispirazione dichiarata: everything-claude-code di WorldFlowAI — il loro
# continuous-learning gira su Stop-hook con auto_approve:false. Il giro e' lo
# stesso; le nostre lezioni pero' nascono col cita-verifica e finiscono nel
# cervello, dove annota rifiuta i link rotti.)
#
# Cosa estrae (tassonomia rubata e adattata):
#   - workaround: quisquilie di bash/macOS/portabilita' scoperte sul campo
#   - tecnica di debug: come si e' arrivati a una diagnosi non ovvia
#   - convenzione: come si fa una cosa in QUESTO sistema
# Filtri anti-trivial (rubati): refusi, fix una-tantum, problemi esterni —
# non sono lezioni, sono rumore. L'onesto "niente da imparare" e' un esito.
#
# Uscita: 0 lezione proposta o onesto niente · 2 uso · 3 il modello non rispose
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CERVELLO="$HERE/cervello"
MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"
LOG="${NIGHT_LOG:-$HOME/night-shift-console.log}"

[ -f "$LOG" ] || { echo "log assente: $LOG" >&2; exit 2; }
OGGI=$(date +%F)

# il contesto: le righe NOTEVOLI del giorno (gli eventi firmati, come la dashboard)
CTX=$(grep -a "^\[$OGGI" "$LOG" 2>/dev/null \
      | grep -aE "AGENTE FALLITO|wedge|rianimat|MIGLIORIA|gate BOCCIA|VERIFICA ROSSA|DELIBERA|quarantena|TRASFORMATORE|registro: debiti|Sonda|round di pazienza|cervello:" \
      | tail -80 | cut -c1-150)

# la scaletta di quello che il sistema GIA' sa: non si reimpara l'alfa
SAPEVOLI=$(grep -a "^## E-0" "$HERE/docs/errori/REGISTRO.md" 2>/dev/null | tail -12 | cut -c1-80)

read -r -d '' PROMPT <<FINE || true
Sei la memoria di un sistema di sviluppo autonomo (AI_Programmer) che gira 24/7.
Questi sono gli eventi notevoli della giornata di oggi ($OGGI):

$CTX

Cosa il sistema SA GIA' (Registro errori, per non reimparare l'alfa):
$SAPEVOLI

Estrai AL MASSIMO UNO pattern riusabile che NON sia gia' nel registro e che capiti
ancora: un workaround (bash/macOS/portabilita'), una tecnica di debug non ovvia,
o una convenzione di questo sistema. Escludi refusi, fix una-tantum e problemi
esterni: non sono lezioni.

Rispondi SOLO con JSON su una riga:
{"titolo":"...","problema":"...","soluzione":"...","quando":"...","link":["nome-di-una-nota-esistente"]}
 oppure esattamente: {"niente":true,"perche":"una riga"}
I link devono puntare a note esistenti in cervello/ (slug minuscoli col trattino) o essere lista vuota.
FINE

R=$(curl -sf --max-time 150 "$API" -d "$(jq -cn --arg m "$MODEL" --arg p "$PROMPT" \
  '{model:$m, think:false, messages:[{role:"user",content:$p}], stream:false, options:{temperature:0, num_ctx:4096}}')" 2>/dev/null \
  | jq -r '.message.content // empty' 2>/dev/null)
[ -n "$R" ] || { echo "IMPARA: il modello non ha risposto (dichiarato, non taciuto)" >&2; exit 3; }

# il modello a volte incarta il JSON: si estrae dalla PRIMA { all'ultima } della riga.
# (revisione 10 giri, 2026-09-23): era `sed 's/.*\({.*}\).*/\1/'` — il `.*` iniziale, avido,
# arrivava all'ULTIMA graffa aperta: una lezione con `${VAR:-x}` diventava JSON rotto.
# `grep -o` prende la corrispondenza piu' a sinistra: parte dalla prima graffa.
R=$(grep -oE '\{.*\}' <<<"$R" | head -1)
if jq -e '.niente == true' <<<"$R" >/dev/null 2>&1; then
  echo "IMPARA: onesto niente — $(jq -r '.perche' <<<"$R" 2>/dev/null)"
  exit 0
fi
jq -e '.titolo and .problema and .soluzione' <<<"$R" >/dev/null 2>&1 \
  || { echo "IMPARA: risposta non valida (ne' lezione ne' niente): $(head -c 120 <<<"$R")" >&2; exit 3; }

TITOLO=$(jq -r '.titolo' <<<"$R"); PROBLEMA=$(jq -r '.problema' <<<"$R")
SOLUZIONE=$(jq -r '.soluzione' <<<"$R"); QUANDO=$(jq -r '.quando' <<<"$R")
SLUG=$(printf '%s' "$TITOLO" | tr 'àèéìòù' 'aeeiou' | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | cut -c1-40)

# una lezione al giorno e niente doppioni di slug
NOTA="$CERVELLO/lezione-$SLUG.md"
[ -f "$NOTA" ] && { echo "IMPARA: lezione '$SLUG' gia' presente — niente doppioni" ; exit 0; }

# i link proposti devono puntare a note vere: si filtrano, i rotti si dichiarano
LINKI=""
ROTTI=""
while IFS= read -r lk; do
  [ -z "$lk" ] && continue
  if [ -f "$CERVELLO/$lk.md" ]; then LINKI="$LINKI [[$lk]]"; else ROTTI="$ROTTI $lk"; fi
done < <(jq -r '.link[]?' <<<"$R" 2>/dev/null)

BODY="stato: da approvare (il mattino decide)
estratta da: $LOG, giornata $OGGI

**Problema.** $PROBLEMA

**Soluzione.** $SOLUZIONE

**Quando usarla.** $QUANDO$LINKI"
printf '%s\n' "$BODY" | bash "$HERE/tools/cervello-annota.sh" "lezione-$SLUG" lezione "$TITOLO" \
  && echo "IMPARA: lezione proposta → cervello/lezione-$SLUG.md (da approvare al mattino)${ROTTI:+ — link scartati (non esistono):$ROTTI}"
