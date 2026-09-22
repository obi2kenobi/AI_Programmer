#!/bin/bash
# cervello-domanda.sh — la lente che interroga il secondo cervello.
#
# Tre domande, le uniche che un cervello di note deve saper fare:
#   in-sospeso            → compila gli sospesi (note tipo:sospeso + PR aperte).
#                           DETERMINISTICA: niente modello, nessuna allucinazione
#                           possibile. E' la domanda del giorno del turno.
#   archeologia <termine> → "quando/com'e' nato X?" — cerca il termine nel
#                           cervello, nel REGISTRO errori e nella SAL, poi il
#                           modello riassume CON CITAZIONI file:riga, e le
#                           citazioni vengono VERIFICATE meccanicamente.
#   collegami <termine>   → il sotto-grafo: quali note parlano di X e dove
#                           puntano i loro link. DETERMINISTICA.
#
# Uscita: 0 risposta onesta · 2 uso/termine assente · 3 citazioni non verificate
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CERVELLO="$HERE/cervello"
MODEL="${NIGHT_MODEL:-qwen3.8-27b:iq3s}"
API="${NIGHT_API_URL:-http://localhost:11434/api/chat}"

[ $# -ge 1 ] || { echo "uso: cervello-domanda.sh in-sospeso | archeologia <termine> | collegami <termine>" >&2; exit 2; }

# ── in-sospeso: deterministica, e' la domanda del giorno ────────────────────
if [ "$1" = "in-sospeso" ]; then
  echo "IN SOSPESO ($(date '+%Y-%m-%d %H:%M'))"
  echo
  echo "## note dichiarate sospese (cervello/)"
  TROVATE=0
  for f in "$CERVELLO"/sospeso-*.md; do
    [ -f "$f" ] || continue
    TROVATE=$((TROVATE+1))
    echo "  - $(sed -n '4s/^titolo: //p' "$f") — $(basename "$f" .md)"
  done
  [ "$TROVATE" -eq 0 ] && echo "  (nessuna)"
  echo
  echo "## lezioni da approvare (proposte dal turno, /learn)"
  LEZ=0
  for f in "$CERVELLO"/lezione-*.md; do
    [ -f "$f" ] || continue
    grep -q "stato: da approvare" "$f" || continue
    LEZ=$((LEZ+1))
    echo "  - $(sed -n '4s/^titolo: //p' "$f") — $(basename "$f" .md)"
  done
  [ "$LEZ" -eq 0 ] && echo "  (nessuna in attesa)"
  echo
  echo "## PR aperte nei repo del turno"
  PR_TROVATE=0
  for REPO in obi2kenobi/AI_Programmer obi2kenobi/Sistema-Gestione-Magazzino; do
    while IFS=$'\t' read -r num stato titolo; do
      [ -z "$num" ] && continue
      PR_TROVATE=$((PR_TROVATE+1))
      echo "  - #$num [$stato] $titolo ($REPO)"
    done < <(gh pr list -R "$REPO" --state open --limit 10 \
             --json number,isDraft,title -q '.[] | [.number, (if .isDraft then "bozza" else "pronta" end), .title] | @tsv' 2>/dev/null)
  done
  [ "$PR_TROVATE" -eq 0 ] && echo "  (nessuna)"
  echo
  echo "totale: $TROVATE sospesi dichiarati + $LEZ lezioni da approvare + $PR_TROVATE PR aperte"
  exit 0
fi

# ── collegami: il sotto-grafo, deterministica ───────────────────────────────
if [ "$1" = "collegami" ]; then
  [ -n "${2:-}" ] || { echo "serve un termine" >&2; exit 2; }
  TERMINE="$2"
  echo "SOTTO-GRAFO DI '$TERMINE'"
  N=0
  for f in "$CERVELLO"/*.md; do
    case "$(basename "$f")" in indice.md|README.md) continue ;; esac
    if grep -qi "$TERMINE" "$f" 2>/dev/null; then
      N=$((N+1))
      echo
      echo "· $(basename "$f" .md) ($(sed -n '2s/^tipo: //p' "$f"))"
      grep -qi "$TERMINE" "$f" && grep -oiE ".{0,40}$TERMINE.{0,40}" "$f" | head -2 | sed 's/^/    .../'
      LINKS=$(grep -oE '\[\[[a-z0-9-]+\]\]' "$f" | tr -d '[]' | sort -u | tr '\n' ' ')
      [ -n "$LINKS" ] && echo "    → $LINKS"
    fi
  done
  [ "$N" -eq 0 ] && { echo "(il termine non vive in nessuna nota — forse e' ancora solo un pensiero)"; exit 2; }
  echo
  echo "$N note collegate"
  exit 0
fi

# ── archeologia: la domanda al modello, con citazioni verificate ────────────
if [ "$1" = "archeologia" ]; then
  [ -n "${2:-}" ] || { echo "serve un termine" >&2; exit 2; }
  TERMINE="$2"

  # raccoglie il contesto: righe che contengono il termine, con provenienza
  CTX=""
  for f in "$CERVELLO"/*.md "$HERE/docs/errori/REGISTRO.md" "$HERE/CLAUDE.md" \
           "$HERE"/SAL*.md "$HERE"/docs/*.md; do
    [ -f "$f" ] || continue
    M=$(grep -in "$TERMINE" "$f" 2>/dev/null | head -4)
    [ -n "$M" ] && CTX="${CTX}### ${f#$HERE/}
$M

"
  done
  [ -z "$CTX" ] && { echo "il termine '$TERMINE' non compare in cervello, REGISTRO, SAL ne' docs: non c'e' storia da scavare" >&2; exit 2; }
  CTX=$(printf '%s' "$CTX" | head -c 6000)

  # il prompt in una variabile prima: gli apostrofi italiani dentro la stringa
  # jq sono trappole di quoting, non si mischiano col comando
  read -r -d '' PROMPT <<FINE || true
Sei la memoria di un sistema di sviluppo. Domanda: che storia ha "$TERMINE" in questo sistema?
Riassumi l'evoluzione in massimo 10 righe. OGNI affermazione deve citare la fonte come
percorso:riga (le righe sono nel contesto). Se il contesto non basta per un'affermazione,
non farla.

CONTESTO (percorso:riga:testo):
$CTX
FINE

  RISPOSTA=$(curl -sf --max-time 120 "$API" -d "$(jq -cn --arg m "$MODEL" --arg p "$PROMPT" \
    '{model:$m, think:false, messages:[{role:"user",content:$p}], stream:false, options:{temperature:0, num_ctx:4096}}')" 2>/dev/null \
    | jq -r '.message.content // empty' 2>/dev/null)

  [ -z "$RISPOSTA" ] && { echo "il modello non ha risposto (dichiarato, non taciuto)" >&2; exit 3; }
  echo "$RISPOSTA"
  echo
  # verifica meccanica delle citazioni percorso:riga
  VERIFICATE=0; ROTTE=0; ROTTE_LIST=""
  while IFS= read -r cita; do
    FILE="${cita%:*}"; RIGA="${cita##*:}"
    if [ -f "$HERE/$FILE" ] && [ "$RIGA" -le "$(wc -l < "$HERE/$FILE")" ] 2>/dev/null; then
      VERIFICATE=$((VERIFICATE+1))
    else
      ROTTE=$((ROTTE+1)); ROTTE_LIST="$ROTTE_LIST $cita"
    fi
  done < <(echo "$RISPOSTA" | grep -oE '[a-zA-Z0-9_./-]+\.[a-z]+:[0-9]+' | sort -u)
  echo "— citazioni verificate: $VERIFICATE, rotte: $ROTTE"
  [ -n "$ROTTE_LIST" ] && { echo "⚠ ROTTE (il modello ha citato cose che non esistono):$ROTTE_LIST" >&2; exit 3; }
  exit 0
fi

echo "domanda sconosciuta: $1 (in-sospeso | archeologia | collegami)" >&2
exit 2
