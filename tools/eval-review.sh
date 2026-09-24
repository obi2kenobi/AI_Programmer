#!/bin/bash
# eval-review.sh — l'audit post-merge (studio GSD Pi eval-review): dopo che
# il censore fonde una PR, verifica che la PR include la sua PROVA.
# "Questa PR dichiara di aver aggiunto un test: il test esiste nel main?
# E il comando dichiarato nel .night-verify passa?"
#
# Audit-only: non modifica codice. Scrive il verdetto nel log del turno.
#
# Uso: eval-review.sh <dir-repo> <numero-PR>
# Esce: 0 prove vere · 1 prove mancanti · 2 uso
set -uo pipefail
DIR="${1:?uso: eval-review.sh <dir> <pr>}"; PR="${2:?pr}"
cd "$DIR" 2>/dev/null || { echo "eval-review: dir $DIR" >&2; exit 2; }

# il diff della PR fusa: cosa ha portato nel main
DIFF=$(gh pr diff "$PR" 2>/dev/null | head -100)
[ -z "$DIFF" ] && { echo "eval-review: PR #$PR non leggibile" >&2; exit 2; }

# 1. la PR aggiunge un test? (cerca nel diff file di test nuovi o modificati)
TEST_FILES=$(gh pr diff "$PR" 2>/dev/null | grep "^+++ b/" | grep -E "test|spec|verifica" | head -3)
# 2. la PR aggiunge un comando al .night-verify?
NV_CHANGE=$(gh pr diff "$PR" 2>/dev/null | grep "^+++ b/.night-verify" | head -1)

PROVE_TROVATE=0; PROVE_MANCANTI=""

if [ -n "$TEST_FILES" ]; then
  # il test esiste nel main?
  while IFS= read -r tf; do
    F=$(echo "$tf" | sed 's|^+++ b/||')
    if [ -f "$F" ]; then
      PROVE_TROVATE=$((PROVE_TROVATE+1))
    else
      PROVE_MANCANTI="$PROVE_MANCANTI test-assente:$F"
    fi
  done <<<"$TEST_FILES"
fi

if [ -n "$NV_CHANGE" ]; then
  # il .night-verify esiste e ha il comando?
  if [ -f ".night-verify" ] && [ -s ".night-verify" ]; then
    PROVE_TROVATE=$((PROVE_TROVATE+1))
  else
    PROVE_MANCANTI="$PROVE_MANCANTI night-verify-vuoto"
  fi
fi

# 3. il .night-verify GIRA e passa? (una prova che non gira non e' una prova)
if [ -f ".night-verify" ] && [ -s ".night-verify" ]; then
  while IFS= read -r riga; do
    case "$riga" in \#*|"") continue ;; esac
    SEC=120; CMD="$riga"
    case "$riga" in @*) SEC="${riga%% *}"; SEC="${SEC#@}"; CMD="${riga#* }" ;; esac
    if ! timeout "$SEC" bash -c "$CMD" >/dev/null 2>&1 </dev/null; then
      PROVE_MANCANTI="$PROVE_MANCANTI verify-rossa:$CMD"
    fi
  done < .night-verify
fi

if [ -z "$PROVE_MANCANTI" ]; then
  echo "eval-review: PR #$PR — $PROVE_TROVATE prove vere, nessuna mancante"
  exit 0
else
  echo "eval-review: PR #$PR — $PROVE_TROVATE prove vere, MANCANTI:$PROVE_MANCANTI"
  exit 1
fi
