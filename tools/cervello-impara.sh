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
# (2026-09-25, settimo ventaglio, V3 R6): IMPARA_DATA per la lezione di un giorno gia' passato (il turno la recupera
# quando nessun ciclo e' partito dopo le 22). Di norma oggi.
OGGI="${IMPARA_DATA:-$(date +%F)}"

# il contesto: le righe NOTEVOLI del giorno (gli eventi firmati, come la dashboard)
# (2026-09-24, quinto ventaglio, R4 R6): cercava «registro: debiti», e il produttore scrive «registro: debito
# famiglie» — firma morta dalla nascita. E «rianimat» non prende «rianima_ollama:». Le firme del 24/9 entrano.
# (2026-09-25, D39): la console ruota (copia e tronca): le righe di oggi di prima della rotazione stanno nel .1
CTX=$( { [ -f "$LOG.1" ] && cat "$LOG.1"; cat "$LOG"; } 2>/dev/null | grep -a "^\[$OGGI" \
      | grep -aE "AGENTE FALLITO|wedge|rianimat|rianima_ollama: esito|MIGLIORIA|gate BOCCIA|VERIFICA ROSSA|DELIBERA|quarantena|TRASFORMATORE|registro: debito famiglie|LENTE MUTA|coda ILLEGGIBILE|⛔ MANCA|SENTINELLA|SFORO DEL BUDGET|Sonda|round di pazienza|cervello:" \
      | tail -60 | cut -c1-120)
# (2026-09-28, rianimazione): erano tail -80 / 150 caratteri — con num_ctx 4096 il
# prompt mangiava quasi tutto il contesto e il modello partiva gia' strozzato.

# la scaletta di quello che il sistema GIA' sa: non si reimpara l'alfa
# (ottavo ventaglio, O3 R5): «E-[0-9]», non «E-0» — da E-100 in poi le voci nuove non entravano nel prompt
SAPEVOLI=$(grep -a "^## E-[0-9]" "$HERE/docs/errori/REGISTRO.md" 2>/dev/null | tail -12 | cut -c1-80)

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

# (2026-09-28, rianimazione — la diagnosi): 150s con -sf non bastavano MAI, dal
# 27/9 in poi «il modello non ha risposto» a ogni ciclo: il turno gira, la coda di
# Ollama mangia la finestra, e un prompt da migliaia di token sotto contesta sfora.
# Cure: 300s di fiato (IMPARA_TIMEOUT), UN secondo colpo dopo 10s, e la CAUSA nel
# messaggio (timeout 28 o HTTP?) — il fallimento dichiarato con la sua ragione.
RISPOSTA=$(mktemp /tmp/impara-risp.XXXXXX)
R=""; CURL_RC=0
for COLPO in 1 2; do
  printf '%s' "$PROMPT" | jq -cRs --arg m "$MODEL" \
    '. as $p | {model:$m, think:false, messages:[{role:"user",content:$p}], stream:false, options:{temperature:0, num_ctx:4096}}' \
    | curl -s --max-time "${IMPARA_TIMEOUT:-300}" -o "$RISPOSTA" "$API" --data-binary @- 2>/dev/null
  CURL_RC=$?
  R=$(jq -r '.message.content // empty' "$RISPOSTA" 2>/dev/null)
  [ -n "$R" ] && break
  # (2026-10-02): prompt lungo + registro cresciuto = 4826 token su 4096 di ctx: il
  # server risponde {error: exceeds context} senza content — e il messaggio storico
  # diceva «risposta non valida», che e' una bugia. L'errore si dice col suo nome.
  ERR=$(jq -r '.error.message // empty' "$RISPOSTA" 2>/dev/null)
  [ -n "$ERR" ] && echo "IMPARA: il server ha detto no: $ERR" >&2
  [ "$COLPO" -eq 2 ] || { echo "IMPARA: colpo 1 senza risposta (curl rc=$CURL_RC) — secondo colpo fra 10s" >&2; sleep 10; }
done
rm -f "$RISPOSTA"
[ -n "$R" ] || { echo "IMPARA: il modello non ha risposto in due colpi da ${IMPARA_TIMEOUT:-300}s (curl rc=$CURL_RC: 28=timeout, 7=connessione rifiutata — contesa o server muto; dichiarato, non taciuto)" >&2; exit 3; }

# il modello a volte incarta il JSON — e a volte lo SPEZZA su piu' righe (2026-10-02:
# tutta la notte di «risposta non valida» per questo): si estrae con python, dalla prima
# graffa alla sua COMPAGNA, tollerando i recinti ```json e le righe attorno.
R=$(printf '%s' "$R" | python3 -c '
import json, sys, re
t = sys.stdin.read()
t = re.sub(r"^.*?\`\`\`(?:json)?\s*", "", t.strip(), flags=re.S)
t = re.sub(r"\`\`\`\s*$", "", t.strip())
i = t.find("{")
while i != -1:
    for j in range(len(t), i, -1):
        try:
            json.loads(t[i:j]); print(t[i:j]); sys.exit(0)
        except Exception:
            continue
    i = t.find("{", i + 1)
sys.exit(1)' 2>/dev/null || true)
if jq -e '.niente == true' <<<"$R" >/dev/null 2>&1; then
  echo "IMPARA: onesto niente — $(jq -r '.perche' <<<"$R" 2>/dev/null)"
  exit 0
fi
jq -e '.titolo and .problema and .soluzione' <<<"$R" >/dev/null 2>&1 \
  || { echo "IMPARA: risposta non valida (ne' lezione ne' niente): $(head -c 120 <<<"$R")" >&2; exit 3; }

TITOLO=$(jq -r '.titolo' <<<"$R"); PROBLEMA=$(jq -r '.problema' <<<"$R")
SOLUZIONE=$(jq -r '.soluzione' <<<"$R"); QUANDO=$(jq -r '.quando' <<<"$R")
# (2026-09-25, settimo ventaglio, V4 R5): lo slug in python. Con `tr` il GNU lavorava in byte («Perché è così» diventava
# «perchuu-ui-cosuu»), il Mac per caratteri: la chiave anti-doppione cambiava con la piattaforma. Per l'ASCII e' identico.
SLUG=$(python3 -c '
import re, sys, unicodedata
t = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode().lower()
print(re.sub(r"[^a-z0-9]+", "-", t).strip("-")[:40].strip("-"))' "$TITOLO")

# una lezione al giorno e niente doppioni di slug
# (2026-09-30, dalla mail del mattino che diceva «nessuna lezione»): la nota scritta
# in cervello/ NON COMMITTATA veniva spazzata dal git clean della caccia (stesso
# meccanismo del FIX 3 perso). Ora la proposta vive in $WORK/cervello-da-approvare/
# (fuori dai repo, come i marker): la mattina la approva e la committa CHI legge.
APPROVA="${IMPARA_APPROVA:-$(dirname "$CERVELLO")}"   # default: accanto al cervello, nel WORK
APPROVA_DIR="$HOME/night-shift-work/cervello-da-approvare"
mkdir -p "$APPROVA_DIR"
NOTA="$APPROVA_DIR/lezione-$SLUG.md"
[ -f "$NOTA" ] && { echo "IMPARA: lezione '$SLUG' gia' presente — niente doppioni" ; exit 0; }
[ -f "$CERVELLO/lezione-$SLUG.md" ] && { echo "IMPARA: lezione '$SLUG' gia' approvata nel cervello — niente doppioni"; exit 0; }

# i link proposti devono puntare a note vere: si filtrano, i rotti si dichiarano
LINKI=""
ROTTI=""
while IFS= read -r lk; do
  [ -z "$lk" ] && continue
  if [ -f "$CERVELLO/$lk.md" ]; then LINKI="$LINKI [[$lk]]"; else ROTTI="$ROTTI $lk"; fi
done < <(jq -r '.link[]?' <<<"$R" 2>/dev/null)

BODY="---
tipo: lezione
titolo: $TITOLO
stato: da approvare (il mattino decide)
estratta da: $LOG, giornata $OGGI
---

**Problema.** $PROBLEMA

**Soluzione.** $SOLUZIONE

**Quando usarla.** $QUANDO$LINKI

Il gesto per approvare: mv in cervello/ + indice (chi approva, sa fare)."
# scritta DIRETTA (niente annota: l'indice del cervello si tocca solo all'approvazione,
# e una modifica non committata li' finirebbe spazzata come la nota)
printf '%s\n' "$BODY" > "$NOTA"
chmod 600 "$NOTA" 2>/dev/null || true
echo "IMPARA: lezione proposta → $NOTA (da approvare al mattino: fuori dai repo, la scopa non la tocca)${ROTTI:+ — link scartati (non esistono):$ROTTI}"
