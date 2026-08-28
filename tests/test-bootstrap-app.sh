#!/bin/bash
# test-bootstrap-app.sh — bug reale trovato con dogfooding (nuovo ciclo 10 giri):
# tools/bootstrap-app.sh usava la catena
#   "[ dry ] || git add -A && [ dry ] || git commit -q -m ..."
# come idioma povero di if/else — ma se `git add -A` falliva, `set -e` non lo
# intercettava (un fallimento intermedio dentro una catena &&/|| non conta per
# `set -e`, solo l'ultimo comando eseguito) e `git commit` veniva eseguito
# comunque. Riprodotto qui isolando la stessa struttura di controllo, non l'intero
# script (che richiede gh/gitleaks autenticati, non disponibili in sandbox).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# --- la struttura VECCHIA (per documentare il bug, non per usarla) ---
run_vecchia() {
  local DRY_RUN=0
  git() {
    if [ "$1" = "add" ]; then echo "git-add-fallito"; return 1; fi
    if [ "$1" = "commit" ]; then echo "git-commit-eseguito"; return 0; fi
  }
  set -euo pipefail
  [ "$DRY_RUN" -eq 1 ] || git add -A && [ "$DRY_RUN" -eq 1 ] || git commit -q -m test
  echo "script-arrivato-alla-fine"
}
OUT_VECCHIA=$(bash -c "$(declare -f run_vecchia); run_vecchia" 2>&1) || true
grep -q "git-commit-eseguito" <<<"$OUT_VECCHIA" && ok "documentato: la struttura vecchia esegue commit anche se add falliva (bug)" \
  || ko "la struttura vecchia non riproduce il bug atteso: $OUT_VECCHIA"

# --- la struttura NUOVA (quella reale in bootstrap-app.sh oggi) ---
run_nuova() {
  local DRY_RUN=0
  git() {
    if [ "$1" = "add" ]; then echo "git-add-fallito"; return 1; fi
    if [ "$1" = "commit" ]; then echo "git-commit-eseguito"; return 0; fi
  }
  set -euo pipefail
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry: creerebbe la repo)"
  else
    git add -A
    git commit -q -m test
  fi
  echo "script-arrivato-alla-fine"
}
OUT_NUOVA=$(bash -c "$(declare -f run_nuova); run_nuova" 2>&1) || true
! grep -q "git-commit-eseguito" <<<"$OUT_NUOVA" && ok "fix: la struttura nuova NON esegue commit se add fallisce" \
  || ko "fix non funziona, commit eseguito comunque: $OUT_NUOVA"
! grep -q "script-arrivato-alla-fine" <<<"$OUT_NUOVA" && ok "fix: set -e ferma lo script sul git add fallito" \
  || ko "lo script prosegue oltre il fallimento: $OUT_NUOVA"

# --- il caso sano: add e commit riescono entrambi, lo script arriva alla fine ---
run_nuova_sana() {
  local DRY_RUN=0
  git() { echo "git-$1-ok"; return 0; }
  set -euo pipefail
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry: creerebbe la repo)"
  else
    git add -A
    git commit -q -m test
  fi
  echo "script-arrivato-alla-fine"
}
OUT_SANA=$(bash -c "$(declare -f run_nuova_sana); run_nuova_sana" 2>&1)
grep -q "git-commit-ok" <<<"$OUT_SANA" && grep -q "script-arrivato-alla-fine" <<<"$OUT_SANA" \
  && ok "caso sano: add e commit eseguiti, script completa normalmente" \
  || ko "caso sano rotto: $OUT_SANA"

# mutation-testing 2026-08-28: il test riproduce la struttura IN ISOLAMENTO
# (dichiarato: il tool vero richiede gh autenticato) ma nulla lo legava al file
# reale — il fix poteva sparire da bootstrap-app.sh senza rosso. Si presidia la
# struttura portante: comandi separati, non la catena &&/|| che non si fermava.
grep -q 'git add -A' "$HERE/tools/bootstrap-app.sh" \
  && ! grep -vE '^[[:space:]]*#' "$HERE/tools/bootstrap-app.sh" | grep -qE 'git add -A *&&' \
  && ok "bootstrap-app.sh: git add e commit separati (la catena fatale non è tornata)" \
  || ko "bootstrap-app.sh: struttura git add/commit degradata (torna la catena che non si ferma?)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
