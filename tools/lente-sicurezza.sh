#!/bin/bash
# lente-sicurezza.sh — la lente sicurezza di dev-critic (§2bis) su una PR, AUTOMATICA
# (decisione di Luca, D2 2026-09-23: «a» — su tutte le PR della notte). Prima era solo un
# promemoria nel template issue: una commessa «stampa la config a console per debug» produceva
# codice che stampava una chiave in chiaro, e nessun punto della pipeline lo diceva.
#
# Uso: tools/lente-sicurezza.sh <dir-repo> <base> [head=HEAD]
# Stampa un rapporto markdown (valori sempre MASCHERATI: «segreto <impronta> · N caratteri»),
# l'ultima riga e' il verdetto:
#   LENTE SICUREZZA: PULITA        exit 0
#   LENTE SICUREZZA: RILIEVI (n)   exit 1
#   LENTE SICUREZZA: DEGRADATA (…) exit 2 — mai «pulita» per silenzio del cervello
# Due strati:
#   1. deterministico, BLOCCANTE da solo: le forme di segreto (UNA definizione, quella di
#      tools/privacy-check.sh, letta da li') e le credenziali letterali assegnate nel codice
#   2. il cervello con la lente §2bis (MODELLO, lo stesso del turno), che riceve anche gli
#      INDIZI: righe aggiunte che stampano valori sensibili. graphify-out/ resta fuori dal prompt
#      (e' generato; i segreti li cerca comunque lo strato 1).
# Test: LENTE_STUB=<script> sostituisce il cervello ($1 = modello, prompt su stdin).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: lente-sicurezza.sh <dir-repo> <base> [head]}"
BASE="${2:?uso: lente-sicurezza.sh <dir-repo> <base> [head]}"
TESTA="${3:-HEAD}"
MODEL="${MODELLO:-qwen3.8-27b:iq3s}"
MAX_PROMPT=12000   # caratteri di diff al cervello (~4 tok/s: oltre, il giudizio costa ore)
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"   # mask_secrets
log() { echo "[lente-sicurezza] $*" >&2; }
verdetto() { echo ""; echo "LENTE SICUREZZA: $1"; exit "$2"; }

echo "### Lente sicurezza (dev-critic §2bis) — automatica sulle PR della notte"
log "inizio: $DIR $BASE...$TESTA (modello $MODEL)"
DIFF=$(git -C "$DIR" diff -U0 "$BASE...$TESTA" 2>/dev/null) || verdetto "DEGRADATA (diff $BASE...$TESTA illeggibile)" 2
[ -n "$DIFF" ] && echo "" || { echo "Diff vuoto: niente da guardare."; verdetto "PULITA" 0; }

# le righe AGGIUNTE, come «file:riga: contenuto» (dagli header @@ del diff)
AGG=$(awk '/^\+\+\+ /{f=substr($2,3); next} /^@@/{split($3,a,","); n=substr(a[1],2)+0; next}
           /^\+/{print f ":" n ": " substr($0,2); n++}' <<<"$DIFF")

# ── strato 1: forme di segreto e credenziali letterali (bloccanti) ────────────────
SHAPES=$(sed -n "s/^SHAPES='\(.*\)'$/\1/p" "$HERE/tools/privacy-check.sh")
[ -n "$SHAPES" ] || verdetto "DEGRADATA (forme di segreto illeggibili da tools/privacy-check.sh)" 2
LETTERALE='(secret|token|password|passwd|api[_-]?key|client[_-]?secret)[A-Za-z_]*["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$[:space:]]{8,}["'"'"']'
SEGRETI=$( { grep -E "$SHAPES" <<<"$AGG"; grep -iE "$LETTERALE" <<<"$AGG"; } | sort -u | mask_secrets)
N_SEG=$(grep -c . <<<"$SEGRETI")
echo "**Segreti e credenziali letterali nel diff: $N_SEG**"
[ "$N_SEG" -gt 0 ] && sed 's/^/- /' <<<"$SEGRETI"
log "strato 1: $N_SEG segreti/credenziali"

# ── indizi per il cervello: righe che stampano valori sensibili (non bloccanti da sole) ──
STAMPA='(echo|printf|print|console\.(log|info|debug|error)|Logger\.log|logger\.[a-z]+|log)[[:space:](].*(token|secret|password|passw|api[_-]?key|credential|credenzial|private[_-]?key|[(, ]config[), .]|[(, ]cfg[), .]|settings|process\.env|os\.environ|\$\{?[A-Z_]*(TOKEN|SECRET|PASSWORD|KEY))|printenv|set -x'
# (niente \b: il grep BSD del Mac non lo garantisce — i confini si scrivono come classi)
INDIZI=$(grep -iE "$STAMPA" <<<"$AGG" | grep -v '^graphify-out/' | head -20 | mask_secrets)
N_IND=$(grep -c . <<<"$INDIZI")
echo ""; echo "**Indizi (righe che stampano valori sensibili): $N_IND**"
[ "$N_IND" -gt 0 ] && sed 's/^/- /' <<<"$INDIZI"
log "indizi: $N_IND righe"

# un segreto basta: il cervello non serve a confermarlo
[ "$N_SEG" -gt 0 ] && { echo ""; echo "Il cervello non e' stato consultato: un segreto nel diff basta a fermare la PR."; verdetto "RILIEVI ($N_SEG)" 1; }

# ── strato 2: il cervello con la lente §2bis ─────────────────────────────────────
DIFF_PROMPT=$(git -C "$DIR" diff "$BASE...$TESTA" -- . ':(exclude)graphify-out' 2>/dev/null | mask_secrets | head -c "$MAX_PROMPT")
# (2026-09-23, giro A6 della notte): un diff piu' lungo del taglio non e' giudicato per intero — la
# coda poteva nascondere il problema, e il verdetto era PULITA. Ora: DEGRADATA, e il censore non fonde.
LUNGO=$(git -C "$DIR" diff "$BASE...$TESTA" -- . ':(exclude)graphify-out' 2>/dev/null | mask_secrets | wc -c | tr -d ' ')
if [ "$LUNGO" -gt "$MAX_PROMPT" ]; then
  echo ""; echo "Il diff ($LUNGO caratteri) supera quanto il cervello vede ($MAX_PROMPT): il giudizio sarebbe su una parte."
  verdetto "DEGRADATA (diff oltre il taglio del cervello: $LUNGO > $MAX_PROMPT caratteri)" 2
fi
# solo file generati (il grafo): lo strato 1 li ha gia' guardati, al cervello non resta niente
[ -n "$DIFF_PROMPT" ] || { echo ""; echo "Solo graphify-out/ nel diff: guardato dallo strato 1, il cervello non serve."; verdetto "PULITA" 0; }
PROMPT="Sei la LENTE SICUREZZA (dev-critic §2bis) su una pull request notturna. Cerca SOLO problemi di sicurezza: segreti o credenziali stampati, loggati o scritti in chiaro (anche indirettamente: stampare un oggetto config intero che contiene una chiave); comandi generati da un modello eseguiti con un interprete general-purpose; controlli di accesso aggirabili; dati sensibili mandati fuori. I valori gia' mascherati appaiono come «segreto …».

Indizi deterministici (righe aggiunte che stampano valori sensibili — verificali, possono essere innocui):
${INDIZI:-nessuno}

Diff (troncato a $MAX_PROMPT caratteri, graphify-out/ escluso):
$DIFF_PROMPT

Rispondi SOLO con JSON su una riga: {\"sicuro\": true|false, \"rilievi\": [\"file:riga — problema\", ...]}"
if [ -n "${LENTE_STUB:-}" ]; then
  RISP=$(printf '%s' "$PROMPT" | bash "$LENTE_STUB" "$MODEL")
else
  RISP=$(printf '%s' "$PROMPT" | QWEN_MODEL="$MODEL" ASK_TIMEOUT=300 bash "$HERE/llm/ask-qwen.sh" "Rispondi alla richiesta qui sotto." 2>/dev/null)
fi
JSON=$(grep -oE '\{.*\}' <<<"$RISP" | tail -1)
SICURO=$(jq -r 'if has("sicuro") then (.sicuro|tostring) else empty end' <<<"$JSON" 2>/dev/null)
log "strato 2: il cervello dice sicuro=${SICURO:-?}"
echo ""; echo "**Giudizio del cervello ($MODEL):**"
case "$SICURO" in
  true)  echo "nessun rilievo."; verdetto "PULITA" 0 ;;
  false) RIL=$(jq -r '.rilievi[]?' <<<"$JSON" 2>/dev/null | head -10 | mask_secrets)
         sed 's/^/- /' <<<"${RIL:-(nessun motivo dato)}"
         verdetto "RILIEVI ($(grep -c . <<<"${RIL:-x}"))" 1 ;;
  *)     echo "nessuna risposta in JSON — la lente non ha un verdetto."
         verdetto "DEGRADATA (cervello muto o fuori formato)" 2 ;;
esac
