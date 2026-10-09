#!/bin/bash
# sacca-migliorie.sh — la SACCA delle micro-migliorie (2026-10-09).
#
# Domanda di Luca: «ma ha senso pubblicare un PR di fatto vuoto?» — no. Misurato
# sui diff veri: 19 PR di caccia su 21 degli ultimi 3 giorni erano +2/-1 cosmetiche
# (inline di variabili, echo|grep diventato herestring, docstring), ognuna col suo
# giro di GPU (lente strato 2 + censore) e il suo rumore nel mattino. Sotto soglia
# la miglioria NON apre PR: si accumula in sacca (patch in <repo>/.git/sacca/, mai
# committate) e viaggia in UNA PR sola quando la sacca vale il viaggio. Niente di
# silenzioso: accumulo, salto e spedizione sono sempre righe dichiarate.
#
# Uso:
#   sacca-migliorie.sh accumula <dir> <cat> <target>   il diff del working tree diventa patch
#   sacca-migliorie.sh pronta <dir>                    rc 0 = spedire (n >= SACCA_MIN_N o righe >= SACCA_MIN_RIGHE)
#   sacca-migliorie.sh spedisci <dir>                  ramo nuovo + patch applicate, SENZA commit (committa la consegna);
#                                                       ultima riga stdout: «RAMO <nome>»
#   sacca-migliorie.sh consumata <dir>                 svuota la sacca (dopo la PR riuscita)
#   sacca-migliorie.sh fingerprint                      scheletro del diff su stdin -> sha
#   sacca-migliorie.sh flotta <repo>                   diff su stdin: rc 0 se il template e' gia' stato
#                                                       visto in >= 2 ALTRI repo oggi (terza volta -> sacca)
#
# Override: SACCA_MIN_N (3), SACCA_MIN_RIGHE (10), SACCA_WORK (registro di flotta,
# default ~/night-shift-work). Stato: <repo>/.git/sacca/{indice,seq,NNNN.patch},
# con indice «NNNN|righe|cat|target|epoch».
set -uo pipefail
MIN_N="${SACCA_MIN_N:-3}"
MIN_RIGHE="${SACCA_MIN_RIGHE:-10}"
CMD="${1:-}"
[ -n "$CMD" ] || { echo "uso: sacca-migliorie.sh accumula|pronta|spedisci|consumata|fingerprint|flotta ..." >&2; exit 2; }
log() { echo "[sacca $(date '+%H:%M:%S')] $*" >&2; }
sacca_dir() { printf '%s/.git/sacca' "$1"; }
tot_sacca() {  # $1=dir -> "n righe" su stdout
  local I="$1/.git/sacca/indice" n r
  n=$(grep -c . "$I" 2>/dev/null || echo 0); r=$(awk -F'|' '{a+=$2} END{print a+0}' "$I" 2>/dev/null)
  printf '%s %s' "${n:-0}" "${r:-0}"
}

# lo scheletro di un diff: le righe aggiunte con nomi e letterali normalizzati —
# due trasformazioni identiche SALVO i nomi delle variabili e le stringhe cercate
# (il caso vero: la stessa herestring replicata su Golilla e Controlli) devono
# dare lo stesso scheletro, o il template di flotta non si vede.
scheletro_stdin() {
  grep '^+' | grep -v '^+++' \
    | sed -e "s/'[^']*'/'x'/g" -e 's/"[^"]*"/"x"/g' \
    | sed -e 's/[A-Za-z_][A-Za-z_0-9]*/x/g' -e 's/[0-9][0-9]*/d/g' \
    | sed -e 's/xx*/x/g' -e 's/dd*/d/g' -e 's/  */ /g' \
    | sort
}

case "$CMD" in

accumula)
  [ $# -ge 2 ] || { echo "uso: accumula <dir> <cat> <target>" >&2; exit 2; }
  DIR="$2"; CAT="${3:-?}"; TARGET="${4:-?}"
  S="$(sacca_dir "$DIR")"; mkdir -p "$S"
  # (lezione della caccia, 2026-09-23): intent-to-add prima del diff, o i file
  # NUOVI dell'agente sono invisibili a git diff — finirebbero fuori dalla sacca.
  git -C "$DIR" add -N . 2>/dev/null || true
  RIGHE=$(git -C "$DIR" diff --numstat 2>/dev/null | awk '{a+=$1+$2} END{print a+0}')
  [ "${RIGHE:-0}" -gt 0 ] || { log "accumula: diff vuoto — niente da mettere in sacca"; exit 1; }
  PROX=$(cat "$S/seq" 2>/dev/null || echo 0); PROX=$((PROX + 1)); echo "$PROX" > "$S/seq"
  NOME=$(printf '%04d' "$PROX")
  git -C "$DIR" diff > "$S/$NOME.patch" 2>/dev/null
  echo "$NOME|$RIGHE|$CAT|$TARGET|$(date +%s)" >> "$S/indice"
  read -r TN TR <<<"$(tot_sacca "$DIR")"
  log "SACCA accumulata: patch $NOME [$CAT] $TARGET ($RIGHE righe) — sacca: $TN migliorie / $TR righe (soglia: $MIN_N oppure $MIN_RIGHE)"
  ;;

pronta)
  [ $# -ge 2 ] || { echo "uso: pronta <dir>" >&2; exit 2; }
  DIR="$2"
  read -r TN TR <<<"$(tot_sacca "$DIR")"
  log "sacca: $TN migliorie / $TR righe (soglia: $MIN_N oppure $MIN_RIGHE)"
  if [ "$TN" -ge "$MIN_N" ] || [ "$TR" -ge "$MIN_RIGHE" ]; then exit 0; fi
  exit 1
  ;;

spedisci)
  [ $# -ge 2 ] || { echo "uso: spedisci <dir>" >&2; exit 2; }
  DIR="$2"; S="$(sacca_dir "$DIR")"
  [ -s "$S/indice" ] || { log "spedisci: sacca vuota"; exit 1; }
  BR="night/caccia-sacca-$(date +%Y%m%d-%H%M%S)"
  git -C "$DIR" checkout -b "$BR" -q 2>/dev/null || { log "spedisci: ramo $BR non creato"; exit 1; }
  APPLICATE=0; SALTATE=0
  cp -f "$S/indice" "$S/indice.letture"
  while IFS='|' read -r n righe cat target ep; do
    [ -n "$n" ] || continue
    # -C1: due micro-migliorie accumulate in notti diverse sulla STESSA coda di
    # file (due commenti appesi in fondo) sono legittime e devono viaggiare
    # insieme — il contesto ridotto a una riga le applica entrambe, mentre una
    # patch stantia (la riga d'ancora riscritta sul main) resta bocciata.
    if git -C "$DIR" apply -C1 "$S/$n.patch" 2>/dev/null; then
      APPLICATE=$((APPLICATE + 1))
    else
      SALTATE=$((SALTATE + 1))
      log "SACCA SALTA patch $n [$cat] $target: non si applica alla base di oggi — scarto dichiarato"
      grep -v "^$n|" "$S/indice" > "$S/indice.nuovo" || true
      mv -f "$S/indice.nuovo" "$S/indice"
      rm -f "$S/$n.patch"
    fi
  done < "$S/indice.letture"
  rm -f "$S/indice.letture"
  if [ "$APPLICATE" -gt 0 ]; then
    log "SACCA SPEDITA sul ramo $BR: $APPLICATE patch applicate, $SALTATE saltate (dichiarate) — il commit lo fa la consegna"
  else
    log "spedisci: NESSUNA patch applicabile — ritorno al ramo di prima, la sacca resta vuota a tutti gli effetti"
    git -C "$DIR" checkout -q -
    git -C "$DIR" branch -D "$BR" -q 2>/dev/null || true
    exit 1
  fi
  echo "RAMO $BR"
  ;;

consumata)
  [ $# -ge 2 ] || { echo "uso: consumata <dir>" >&2; exit 2; }
  DIR="$2"; S="$(sacca_dir "$DIR")"
  rm -rf "$S"
  log "SACCA CONSUMATA: le migliorie sono in PR — la sacca si svuota"
  ;;

fingerprint)
  SHA=$(scheletro_stdin | shasum | cut -d' ' -f1)
  [ -n "$SHA" ] || exit 1
  echo "$SHA"
  ;;

flotta)
  [ $# -ge 2 ] || { echo "uso: flotta <repo> (diff su stdin)" >&2; exit 2; }
  REPO="$2"
  WORK="${SACCA_WORK:-$HOME/night-shift-work}"
  REG="$WORK/.sacca-template"; mkdir -p "$REG"
  # finestra di un giorno: il template visto ieri non governa oggi (la sacca
  # raggruppa, non vieta) — e i file oltre due giorni se ne vanno da soli
  find "$REG" -type f -mtime +2 -delete 2>/dev/null || true
  OGGI="$REG/$(date +%Y%m%d)"
  SHA=$(scheletro_stdin | shasum | cut -d' ' -f1)
  [ -n "$SHA" ] || { log "flotta: diff illeggibile"; exit 1; }
  touch "$OGGI"
  DISTINTI=$(awk -v s="$SHA" '$1 == s {print $2}' "$OGGI" 2>/dev/null | sort -u | grep -vxF "$REPO" | grep -c .)
  if [ "${DISTINTI:-0}" -ge 2 ]; then
    log "flotta: template gia' visto in $DISTINTI repo oggi — la terza volta va in sacca, non in PR propria"
    exit 0
  fi
  grep -qE "^$SHA $REPO$" "$OGGI" 2>/dev/null || echo "$SHA $REPO" >> "$OGGI"
  exit 1
  ;;

*)
  echo "uso: sacca-migliorie.sh accumula|pronta|spedisci|consumata|fingerprint|flotta ..." >&2
  exit 2
  ;;
esac
