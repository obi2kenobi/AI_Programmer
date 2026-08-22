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
grep -q 'TOT_PR_CREATED=0' <<<"$(sed -n '256,285p' "$(cd "$(dirname "$0")/.." && pwd)/night-shift/night-shift.sh")" \
  && ok "night-shift.sh dichiara TOT_PR_CREATED prima del for (set -u non esplode)" \
  || ko "TOT_PR_CREATED non trovato dichiarato prima del for in night-shift.sh"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
