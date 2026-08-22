#!/bin/bash
# test-night-shift-sal.sh — bug reale trovato con dogfooding (nuovo ciclo 10 giri):
# night-shift.sh scrive il proprio SAL dopo il for su repos.conf leggendo
# $PR_CREATED/$FAILED — ma quelle sono `local` DENTRO shift_repo(): una volta che
# la funzione ritorna, non esistono più. Il SAL scritto ad ogni turno reale aveva
# i contatori sempre vuoti. Non serve gh/opencode per riprodurlo: è puro scope di
# bash, isolato qui sulla stessa identica struttura.
set -uo pipefail
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# --- la struttura VECCHIA: PR_CREATED/FAILED letti fuori scope dopo il for ---
OUT_VECCHIA=$(bash -c '
shift_repo() {
  local PR_CREATED=0 FAILED=0
  PR_CREATED=3; FAILED=1
}
for r in a b; do shift_repo "$r"; done
echo "SAL: ${PR_CREATED:-VUOTO} PR create, ${FAILED:-VUOTO} fallite"
' 2>&1)
grep -q "VUOTO" <<<"$OUT_VECCHIA" && ok "documentato: la struttura vecchia legge contatori vuoti fuori scope (bug)" \
  || ko "la struttura vecchia non riproduce il bug atteso: $OUT_VECCHIA"

# --- la struttura NUOVA (quella reale in night-shift.sh oggi): aggregazione globale ---
OUT_NUOVA=$(bash -c '
TOT_PR_CREATED=0
TOT_FAILED=0
shift_repo() {
  local PR_CREATED=0 FAILED=0
  case "$1" in
    a) PR_CREATED=2; FAILED=1 ;;
    b) PR_CREATED=0; FAILED=3 ;;
  esac
  TOT_PR_CREATED=$((TOT_PR_CREATED+PR_CREATED))
  TOT_FAILED=$((TOT_FAILED+FAILED))
}
for r in a b; do shift_repo "$r"; done
echo "SAL: $TOT_PR_CREATED PR create, $TOT_FAILED fallite"
' 2>&1)
[ "$OUT_NUOVA" = "SAL: 2 PR create, 4 fallite" ] && ok "fix: il totale aggrega correttamente più repo (2+0=2 PR, 1+3=4 fallite)" \
  || ko "aggregazione sbagliata: $OUT_NUOVA"

# --- verifica sul file reale: i contatori globali devono esistere PRIMA del primo shift_repo ---
# range di righe, non fisso: robusto a modifiche future del file (già disallineato una
# volta dopo il giro 5 del set 2, che ha spostato le righe più in basso).
REAL_NS="$(cd "$(dirname "$0")/.." && pwd)/night-shift/night-shift.sh"
RIGA_TOT=$(grep -n '^TOT_PR_CREATED=0$' "$REAL_NS" | cut -d: -f1)
RIGA_FOR=$(grep -n '^for ENTRY in' "$REAL_NS" | cut -d: -f1)
[ -n "$RIGA_TOT" ] && [ -n "$RIGA_FOR" ] && [ "$RIGA_TOT" -lt "$RIGA_FOR" ] \
  && ok "night-shift.sh dichiara TOT_PR_CREATED prima del for (set -u non esplode)" \
  || ko "TOT_PR_CREATED (riga ${RIGA_TOT:-assente}) non precede il for (riga ${RIGA_FOR:-assente})"

# --- set 2 giro 8: contatore SKIPPED_DESIGN aggregato come PR_CREATED/FAILED ---
OUT_SKIP=$(bash -c '
TOT_PR_CREATED=0; TOT_FAILED=0; TOT_SKIPPED_DESIGN=0
shift_repo() {
  local PR_CREATED=0 FAILED=0 SKIPPED_DESIGN=0
  case "$1" in
    a) PR_CREATED=2; FAILED=1; SKIPPED_DESIGN=3 ;;
    b) PR_CREATED=0; FAILED=3; SKIPPED_DESIGN=1 ;;
  esac
  TOT_PR_CREATED=$((TOT_PR_CREATED+PR_CREATED))
  TOT_FAILED=$((TOT_FAILED+FAILED))
  TOT_SKIPPED_DESIGN=$((TOT_SKIPPED_DESIGN+SKIPPED_DESIGN))
}
for r in a b; do shift_repo "$r"; done
echo "$TOT_PR_CREATED $TOT_FAILED $TOT_SKIPPED_DESIGN"
')
[ "$OUT_SKIP" = "2 4 4" ] && ok "SKIPPED_DESIGN aggrega correttamente su più repo (3+1=4) — debito docs/test-processo-2026-08-21.md #4 saldato" \
  || ko "aggregazione SKIPPED_DESIGN sbagliata: $OUT_SKIP"

RIGA_SKIP_DICH=$(grep -n '^TOT_SKIPPED_DESIGN=0$' "$REAL_NS" | cut -d: -f1)
[ -n "$RIGA_SKIP_DICH" ] && [ "$RIGA_SKIP_DICH" -lt "$RIGA_FOR" ] \
  && ok "night-shift.sh dichiara TOT_SKIPPED_DESIGN prima del for" \
  || ko "TOT_SKIPPED_DESIGN non dichiarato prima del for"
N_INCREMENTI=$(grep -c 'SKIPPED_DESIGN=\$((SKIPPED_DESIGN+1))' "$REAL_NS")
[ "$N_INCREMENTI" -eq 5 ] && ok "i 5 punti di skip Design/Territorio incrementano tutti il contatore" \
  || ko "trovati $N_INCREMENTI incrementi invece di 5 — un punto di skip non conta più?"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
