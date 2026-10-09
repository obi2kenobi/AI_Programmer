#!/bin/bash
# annota.sh — righe in ERRORFORMAT → annotazioni SULLA RIGA della pull request
# (2026-10-09, furto da reviewdog: il valore loro non era il tool ma il FORMATO
# universale «file:riga: messaggio» + l'annotazione POSIZIONATA, che il commento
# generico non ha). Ogni lente che parli errorformat ottiene le annotazioni
# gratis: lente-documenti e' la prima; le altre migrano dichiarando).
#
# Uso: printf '%s\n' "file.md:12: documento[casa.AsciiSolo]: ..." | annota.sh <owner/repo> <n-pr>
# Esce: 0 = almeno un'annotazione pubblicata · 1 = zero · 2 = uso/PR illeggibile
# Override test: niente (usa gh dal PATH — stubbalo li').
set -uo pipefail
REPO="${1:?uso: annota.sh <owner/repo> <n-pr> (errorformat su stdin)}"
N="${2:?uso: annota.sh <owner/repo> <n-pr> (errorformat su stdin)}"
log() { echo "[annota $(date '+%H:%M:%S')] $*" >&2; }

OID=$(gh pr view "$N" --repo "$REPO" --json headRefOid --jq .headRefOid 2>/dev/null) || { log "PR #$N di $REPO illeggibile"; exit 2; }
[ -n "$OID" ] || { log "PR #$N senza headRefOid"; exit 2; }

INVIATE=0; SALTATE=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  case "$r" in *:*) ;; *) continue ;; esac
  F=$(cut -d: -f1 <<<"$r")
  L=$(cut -d: -f2 <<<"$r")
  RESTO=$(cut -d: -f3- <<<"$r")
  case "$L" in ''|*[!0-9]*) SALTATE=$((SALTATE+1)); continue ;; esac
  if gh api "repos/$REPO/pulls/$N/comments" -f commit_id="$OID" -f path="$F" -f side=RIGHT -F line="$L" -f body="$RESTO" >/dev/null 2>&1; then
    INVIATE=$((INVIATE + 1))
  else
    SALTATE=$((SALTATE + 1))
    log "annotazione NON pubblicata (riga oltre il diff della PR?): $r"
  fi
done

log "pubblicate $INVIATE annotazioni su riga (${SALTATE} saltate dichiarate) sulla PR #$N di $REPO"
[ "$INVIATE" -gt 0 ] && exit 0
exit 1
