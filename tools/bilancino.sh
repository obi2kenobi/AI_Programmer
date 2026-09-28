#!/bin/bash
# bilancino.sh — la riga di conto della notte per un repo (2026-09-28, proposta del
# giorno: «il sistema misura il mondo ma non se stesso»).
#
# metrics/gate.csv — il funnel delle consegne — e' fermo al 21 agosto (era REPO-A):
# da allora il sistema fonde, rigetta, brucia debiti e GPU senza scrivere piu' una
# riga di storia. Qui una riga al giorno per repo, LETTA DAL LOG VERO: quel che c'e'
# nel log e' quel che e' successo (verify-the-world, applicato a noi stessi).
#
# Il CSV vive in $WORK (fuori dai repo): i cloni del turno fanno reset/clean e un
# file non committato li dentro viene spazzato (lezione del FIX 3 perso, 2026-09-28;
# e E-038 per i file generati in git). $WORK e' stabile come i marker .impara-.
#
# Upsert: la riga di OGGI per il repo si riscrive a ogni chiamata (fine ciclo) —
# una notte parziale e' comunque contata, l'ultima chiamata vince. Le colonne
# debiti_aperti e lezioni sono SNAPSHOT a fine giornata, non delta.
#
# Uso: bilancino.sh <owner/repo o repo>
# Esce: 0 riga scritta · 2 uso · 3 il log del giorno non esiste proprio
# Override test: BILANCINO_CSV, BILANCINO_WORK, BILANCINO_DATA, BILANCINO_LOG_EXTRA
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${BILANCINO_WORK:-$HOME/night-shift-work}"
CSV="${BILANCINO_CSV:-$WORK/funnel.csv}"
DATA="${BILANCINO_DATA:-$(date +%F)}"
[ $# -ge 1 ] || { echo "uso: bilancino.sh <repo>" >&2; exit 2; }
REPO="${1##*/}"

# le righe del giorno per SOLO questo repo, da tutti i log (il .1: la console ruota, D39)
LOGGI=( "$HOME/night-shift.log" "$HOME/night-shift.log.1" "$HOME/night-shift-console.log" "$HOME/night-shift-console.log.1" )
GIORNO=$( { for f in "${LOGGI[@]}" "${BILANCINO_LOG_EXTRA:-}"; do [ -f "$f" ] && cat "$f"; done; } 2>/dev/null \
  | grep -a "^\[$DATA" | grep -a "REPO [^ ]*/$REPO[ :]" )
[ -n "$GIORNO" ] || { echo "bilancino: nessuna riga di log per $REPO il $DATA — niente da contare"; exit 3; }

conto() { printf '%s\n' "$GIORNO" | grep -ac "$1" || true; }
CICLI=$(conto "===== REPO ")
V_VERDI=$(conto ": verifica VERDE")
V_ROSSE=$(conto ": VERIFICA ROSSA")
PR_APERTE=$(conto ": PR di .*→")
PR_FUSE=$(conto "censore ha DELIBERATO il merge")
PR_RIGETTATE=$(conto "censore ha RIGETTATO la PR")
RIGETTI_DET=$(conto "rigetto deterministico")
GPU_S=$(printf '%s\n' "$GIORNO" | grep -aoE '\([0-9]+s GPU\)' | grep -oE '[0-9]+' | awk '{s+=$1} END{print s+0}')
# il conteggio gpu firma solo le migliorie concluse ((Ns GPU)): e' un minimo dichiarato,
# non il costo totale della notte — il turno non firma ancora i secondi delle issue
LEZIONI=$( { for f in "${LOGGI[@]}" "${BILANCINO_LOG_EXTRA:-}"; do [ -f "$f" ] && cat "$f"; done; } 2>/dev/null \
  | grep -ac "^\[$DATA.*impara: lezione proposta" || true)

# snapshot dei debiti dal censimento del repo (i vivi in coda: file del registro, non opinioni)
DEBITI=0
RINV_FILE="$WORK/$REPO/.git/caccia-registro/rinviati"
[ -f "$RINV_FILE" ] && DEBITI=$(grep -c . "$RINV_FILE" || true)

mkdir -p "$(dirname "$CSV")"
[ -f "$CSV" ] || echo "data,repo,cicli,verify_verdi,verify_rosse,pr_aperte,pr_fuse,pr_rigettate,rigetti_det,gpu_s,debiti_aperti,lezioni" > "$CSV"
# upsert: la riga di oggi per questo repo si sostituisce (grep -v), le altre restano
grep -v "^$DATA,$REPO," "$CSV" > "$CSV.tmp" 2>/dev/null || true
echo "$DATA,$REPO,$CICLI,$V_VERDI,$V_ROSSE,$PR_APERTE,$PR_FUSE,$PR_RIGETTATE,$RIGETTI_DET,$GPU_S,$DEBITI,$LEZIONI" >> "$CSV.tmp"
mv "$CSV.tmp" "$CSV"
echo "bilancino: $REPO $DATA — cicli=$CICLI fuse=$PR_FUSE rigettate=$PR_RIGETTATE rigetti-det=$RIGETTI_DET gpu=${GPU_S}s debiti=$DEBITI"
