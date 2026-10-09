#!/bin/bash
# pre-push.sh — il cancello dei segreti anche per chi programma di GIORNO
# (2026-10-09, Luca: «deve essere un harness piu' per il giorno che per la
# notte — lenti, agenti e sistemi anche di giorno»).
#
# Fino a ieri le forme di segreto fermavano solo il push della NOTTE
# (forme_prima_del_push, nel turno): le consegne del giorno passavano accanto
# al cancello. Ora lo stesso strato deterministico (lente-sicurezza
# LENTE_SOLO_FORME=1, zero GPU, istantaneo) gira a OGNI push, notte e giorno.
#
# In piu': se il diff porta requirements/package.json, la lente-dipendenze
# AVVISA (non blocca: la dipendenza non pinnata e' qualita', non sicurezza).
#
# stdin: le righe di git pre-push «<ref locale> <sha locale> <ref remoto> <sha remoto>».
# Esce: 0 = push consentito · 1 = SEGRETO nel diff, push fermato.
# Il cancello degradato NON bricka il giorno: se la lente non si trova o torna
# rc 2, si dichiara a voce alta e si passa (la notte ha il suo cancello in
# aggiunta; qui il fallimento silente sarebbe peggio del passaggio dichiarato).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
log() { echo "[pre-push $(date '+%H:%M:%S')] $*" >&2; }

# la lente sta nell'hub: locale se siamo nell'hub, altrimenti AI_PROGRAMMER_HUB
# o il default del turno (i satelliti ricevono solo .githooks, non tools/)
LENTE=""
if [ -f "$HERE/tools/lente-sicurezza.sh" ]; then
  LENTE="$HERE/tools/lente-sicurezza.sh"
elif [ -f "${AI_PROGRAMMER_HUB:-/inesistente}/tools/lente-sicurezza.sh" ]; then
  LENTE="${AI_PROGRAMMER_HUB%/}/tools/lente-sicurezza.sh"
elif [ -f "$HOME/night-shift-work/AI_Programmer/tools/lente-sicurezza.sh" ]; then
  LENTE="$HOME/night-shift-work/AI_Programmer/tools/lente-sicurezza.sh"
else
  log "⚠ cancello segreti SALTATO (dichiarato): lente-sicurezza.sh non trovata (nemmeno in AI_PROGRAMMER_HUB=${AI_PROGRAMMER_HUB:-<vuoto>})"
  exit 0
fi
DEPS=""
if [ -f "$(dirname "$LENTE")/lente-dipendenze.sh" ]; then DEPS="$(dirname "$LENTE")/lente-dipendenze.sh"; fi

# ramo di default del remote (base per i rami nuovi: sha remoto a zeri)
DB=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || echo main)

BLOCCO=0
while read -r L_REF L_SHA R_REF R_SHA; do
  [ -n "${L_SHA:-}" ] || continue
  case "$L_SHA" in 0000000000000000000000000000000000000000) continue ;; esac   # cancellazione di ramo
  if [ -n "$R_SHA" ] && [ "$R_SHA" != "0000000000000000000000000000000000000000" ]; then
    BASE="$R_SHA"
  elif git rev-parse -q --verify "origin/$DB" >/dev/null 2>&1; then
    BASE="origin/$DB"
  else
    log "⚠ $L_REF: base non determinabile (niente origin/$DB) — riga non controllata, dichiarato"
    continue
  fi
  RIGHE=$(git diff --numstat "$BASE...$L_SHA" 2>/dev/null | awk '{a+=$1+$2} END{print a+0}')
  [ "${RIGHE:-0}" -eq 0 ] && continue
  RAP=$(LENTE_SOLO_FORME=1 bash "$LENTE" "$PWD" "$BASE" "$L_SHA" 2>/dev/null); RC=$?
  if [ "$RC" -eq 1 ]; then
    log "⛔ forme di segreto nel diff ($BASE...$L_SHA): push NON eseguito"
    grep '^- ' <<<"$RAP" | head -5 >&2
    BLOCCO=1
  elif [ "$RC" -ne 0 ]; then
    log "⚠ lente degradata (rc=$RC) su $L_REF: passaggio dichiarato"
  fi
  # dipendenze: avviso, mai blocco
  if [ -n "$DEPS" ]; then
    DOC_DEP=$(git diff --name-only "$BASE...$L_SHA" 2>/dev/null | grep -E '(^|/)requirements[^/]*\.txt$|(^|/)package\.json$' || true)
    if [ -n "$DOC_DEP" ]; then
      DEP_RIGHE=$(bash "$DEPS" "$PWD" 2>/dev/null | grep -ciE 'non pinnat|senza range|non dichiarat' || true)
      [ "${DEP_RIGHE:-0}" -gt 0 ] && log "⚠ lente-dipendenze: ${DEP_RIGHE} rilievi (dipendenze non pinnate o import non dichiarati) — qualità, non blocco"
    fi
  fi
  # documenti: la lente prosa (Vale, offline) sulle righe AGGIUNTE dei .md del
  # diff — avviso, mai blocco (2026-10-09: il buco «documenti» della fareta)
  DOC_MD=$(git diff --name-only "$BASE...$L_SHA" 2>/dev/null | grep -E '\.mdx?$' || true)
  if [ -n "$DOC_MD" ] && [ -f "$(dirname "$LENTE")/lente-documenti.sh" ]; then
    DOC_RIGHE=$(bash "$(dirname "$LENTE")/lente-documenti.sh" "$PWD" "$BASE" "$L_SHA" 2>/dev/null)
    DOC_N=$(grep -c ': documento\[' <<<"$DOC_RIGHE" || true)
    if [ "${DOC_N:-0}" -gt 0 ]; then
      log "⚠ lente documenti: ${DOC_N} righe (prosa fuori stile di casa) — qualità, non blocco"
      printf '%s\n' "$DOC_RIGHE" | head -5 >&2
    fi
  fi
done

[ "$BLOCCO" -eq 0 ] || exit 1
exit 0
