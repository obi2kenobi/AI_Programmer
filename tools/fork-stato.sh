#!/bin/bash
# fork-stato.sh — la misura della deriva fra le copie di un progetto (skill
# allineamento-fork, mossa M3). Date N cartelle, produce: per ogni copia
# (file, righe, hash normalizzato), la matrice delle differenze, e il VERDETTO
# secondo la tabella M4 — compreso chi è la base di lavoro e cosa fare PRIMA
# di toccare qualsiasi file.
#
# L'hash è NORMALIZZATO: righe vuote e spazi finali via, ordine file stabile —
# così due copie che differiscono solo di formattazione non risultano divergenti
# (la deriva che conta è quella di contenuto, non di resa).
#
# Uso: bash tools/fork-stato.sh <dir1> <dir2> [<dir3>...]
#      (una delle copie può essere un clasp clone fresco del vivo: M2 della skill)
# Esce 0 se tutte uguali · 1 se c'è deriva (con verdetto) · 2 uso errato.
set -uo pipefail
[ $# -ge 2 ] || { echo "uso: fork-stato.sh <dir1> <dir2> [<dir3>...]" >&2; exit 2; }

impronta() { # hash normalizzato del codice della copia
  local d="$1"
  find "$d" -type f \( -name '*.gs' -o -name '*.js' \) ! -name '.clasp*' 2>/dev/null | sort \
    | while IFS= read -r f; do
        sed 's/[[:space:]]*$//' "$f" | grep -v '^$'
        echo "---FILE---$(basename "$f")"
      done | shasum | awk '{print $1}'
}
conta() { find "$1" -type f \( -name '*.gs' -o -name '*.js' \) ! -name '.clasp*' 2>/dev/null | wc -l | tr -d ' '; }
righe() { find "$1" -type f \( -name '*.gs' -o -name '*.js' \) ! -name '.clasp*' -exec cat {} + 2>/dev/null | wc -l | tr -d ' '; }

# array INDICIZZATI (bash 3.2 di macOS non ha declare -A: gli indici qui sono
# numerici 0..N-1, l'associativo non serve e il -A fa solo sputare errori)
declare -a HASH FILES RIGHE NOMI
N=0
for d in "$@"; do
  [ -d "$d" ] || { echo "⛔ copia inesistente: $d" >&2; exit 2; }
  NOME=$(basename "$d" | sed 's/__[A-Za-z0-9_-]*$//')   # via il suffisso id GAS
  HASH[$N]=$(impronta "$d"); FILES[$N]=$(conta "$d"); RIGHE[$N]=$(righe "$d"); NOMI[$N]="$NOME"
  N=$((N+1))
done

echo "== fork-stato — $(date +%F) =="
for i in $(seq 0 $((N-1))); do
  echo "  ${NOMI[$i]}: ${FILES[$i]} file · ${RIGHE[$i]} righe · impronta ${HASH[$i]:0:12}"
done

# matrice: quante copie differiscono da quante
UGUALI=1
BASE=0
for i in $(seq 1 $((N-1))); do
  if [ "${HASH[$i]}" != "${HASH[$BASE]}" ]; then UGUALI=0; fi
done

if [ $UGUALI -eq 1 ]; then
  echo ""
  echo "VERDETTO: ALLINEATE — tutte le copie coincidono (contenuto normalizzato)."
  echo "  Base di lavoro: qualunque copia. Confronto col vivo comunque prima di ogni PR."
  exit 0
fi

echo ""
echo "VERDETTO: DIVERGENTI — la tabella M4 decide:"
for i in $(seq 0 $((N-1))); do
  D="="
  [ "${HASH[$i]}" != "${HASH[$BASE]}" ] && D="≠"
  echo "  ${NOMI[$i]} $D ${NOMI[$BASE]}"
done
cat <<TAB
  Il da farsi SIN DA SUBITO (skill allineamento-fork):
  - IL GAS VIVO È DEFINITIVO: se una copia è un clasp clone fresco del vivo,
    È LEI la base — le altre si allineano a lei, mai il contrario.
  - La copia più indietro non si tocca: prima l'allineamento (commit
    «allineamento al vivo»), poi le modifiche.
  - Scrivi FORK-STATO.md (copie, deriva, base scelta, data): la sessione
    prossima legge, non ri-sospetta.
TAB
exit 1
