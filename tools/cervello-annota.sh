#!/bin/bash
# cervello-annota.sh — scrive una nota nel secondo cervello, ma solo se e' sana.
#
# Il cervello (cervello/*.md) e' la memoria STABILIZZATA del sistema: le decisioni
# prese, i concetti con un nome, le famiglie d'errore, gli sospesi dichiarati.
# La SAL e' il diario; il REGISTRO e' la moglia degli errori; il cervello sono
# le COSE CHE RESTANO, una nota per concetto, collegata con [[wikilink]].
#
# Ogni nota ha frontmatter: tipo (decisione|concetto|famiglia|sospeso|repo),
# data, titolo. Un wikilink che non punta a una nota esistente e' un pensiero
# rotto: si rifiuta (exit 2) e si dice quale.
#
# Uso:
#   cervello-annota.sh <slug> <tipo> <titolo>   # body da stdin, crea o aggiorna
#   cervello-annota.sh --indice                 # rigenera cervello/indice.md
#   cervello-annota.sh --anteprima-indice       # l'indice in stdout (per i test)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CERVELLO="$HERE/cervello"

# raccoglie ogni nota in una riga "slug|tipo|data|titolo"
indice_vero() {
  local f slug tipo data titolo
  for f in "$CERVELLO"/*.md; do
    case "$(basename "$f")" in indice.md|README.md) continue ;; esac
    slug=$(basename "$f" .md)
    tipo=$(sed -n '2s/^tipo: //p' "$f")
    data=$(sed -n '3s/^data: //p' "$f")
    titolo=$(sed -n '4s/^titolo: //p' "$f")
    [ -n "$tipo" ] && printf '%s|%s|%s|%s\n' "$slug" "$tipo" "$data" "$titolo"
  done
}

scrivi_indice() { # $1 = destinazione ("-" per stdout)
  {
    echo "# Indice del cervello"
    echo
    echo "<!-- generato da tools/cervello-annota.sh --indice: non si scrive a mano -->"
    for tipo in decisione concetto famiglia sospeso repo; do
      SEZIONE=$(indice_vero | awk -F'|' -v t="$tipo" '$2==t')
      [ -z "$SEZIONE" ] && continue
      echo; echo "## $tipo"
      while IFS='|' read -r slug t d titolo; do
        echo "- [$titolo]($slug.md) — $d"
      done <<<"$SEZIONE"
    done
  } > "$1"
}

[ $# -ge 1 ] || { echo "uso: cervello-annota.sh <slug> <tipo> <titolo> | --indice | --anteprima-indice" >&2; exit 2; }

case "$1" in
  --indice)         mkdir -p "$CERVELLO"; scrivi_indice "$CERVELLO/indice.md"; echo "indice rigenerato" ;;
  --anteprima-indice) scrivi_indice /dev/stdout ;;
  *) ;;
esac
[ "$1" = "--indice" ] || [ "$1" = "--anteprima-indice" ] && exit 0

SLUG="$1"; TIPO="$2"; TITOLO="$3"
[ -n "$SLUG" ] && [ -n "$TIPO" ] && [ -n "$TITOLO" ] || { echo "uso: cervello-annota.sh <slug> <tipo> <titolo>" >&2; exit 2; }
case "$TIPO" in decisione|concetto|famiglia|sospeso|repo) ;; *) echo "tipo '$TIPO' non valido: decisione|concetto|famiglia|sospeso|repo" >&2; exit 2 ;; esac
[[ "$SLUG" =~ ^[a-z0-9-]+$ ]] || { echo "lo slug deve essere minuscolo con trattini: '$SLUG'" >&2; exit 2; }
mkdir -p "$CERVELLO"

BODY=$(cat)

# i wikilink devono puntare a note esistenti (o alla nota che stiamo scrivendo)
ROTTI=""
while IFS= read -r link; do
  [ -z "$link" ] && continue
  [ "$link" = "$SLUG" ] && continue
  [ -f "$CERVELLO/$link.md" ] || ROTTI="$ROTTI $link"
done < <(grep -oE '\[\[[a-z0-9-]+\]\]' <<<"$BODY" | tr -d '[]' | sort -u)
[ -n "$ROTTI" ] && { echo "⛔ wikilink rotti (crea prima la nota, o correggi):$ROTTI" >&2; exit 2; }

# aggiorna o crea: la data di oggi se e' nuova, la PRIMA data se aggiorna
DATA=$(date +%F)
[ -f "$CERVELLO/$SLUG.md" ] && DATA=$(sed -n 's/^data: //p' "$CERVELLO/$SLUG.md" | head -1)
{
  echo "---"
  echo "tipo: $TIPO"
  echo "data: ${DATA:-$(date +%F)}"
  echo "titolo: $TITOLO"
  echo "---"
  printf '%s\n' "$BODY"
} > "$CERVELLO/$SLUG.md"

scrivi_indice "$CERVELLO/indice.md"
echo "nota scritta: cervello/$SLUG.md ($TIPO) — indice aggiornato"
