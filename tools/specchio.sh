#!/bin/bash
# specchio.sh — il sistema si specchia (2026-09-28, proposta del giorno).
#
# Il turno misura i server (sonde, watchdog) ma non la propria CASA: il digest
# e' stato 127 per giorni senza che nessuno aprisse issue, la lezione di ieri
# manca in silenzio, i cloni satellitari sono stati ciechi per giorni (E-052).
# Qui sei verifiche puntuali: ogni ROSSO diventa una issue sull'hub — aperta
# dal sistema a se stesso, idempotente per componente (niente spam). I GIALLI
# si dichiarano e basta: degradazioni note (razzo giu', pii giu') che il
# mattino legge nel log, non tartane in coda.
#
# Uso: specchio.sh            (dall'hub: gira una volta al giorno dal turno)
# Esce: 0 sempre, tranne 2 (uso) — l'esito e' nel log e nelle issue
# Override test: SPECCHIO_DRY=1 (stampa le issue, non le apre) · SPECCHIO_WORK
#       SPECCHIO_CONF · SPECCHIO_REPO (default obi2kenobi/AI_Programmer)
#       SPECCHIO_LAUNCHD_LABEL (default com.luca.morningdigest)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${SPECCHIO_WORK:-$HOME/night-shift-work}"
CONF="${SPECCHIO_CONF:-$HERE/night-shift/repos.conf}"
REPO_HUB="${SPECCHIO_REPO:-obi2kenobi/AI_Programmer}"
LABEL="${SPECCHIO_LAUNCHD_LABEL:-com.luca.morningdigest}"
[ -f "$CONF" ] || { echo "specchio: repos.conf assente ($CONF) — niente da specchiare" >&2; exit 2; }

VERDI=0; GIALLI=0; ROSSI=0

apri_issue() { # apri_issue <componente> <dettaglio>
  local comp="$1" det="$2" gia
  local titolo="specchio: $comp — degradato"
  gia=$(gh issue list -R "$REPO_HUB" --state open --limit 200 --json title -q '.[].title' 2>/dev/null | grep -F "$titolo" || true)
  if [ -n "$gia" ]; then
    echo "specchio: issue gia' aperta per $comp — niente doppioni" >&2
    return
  fi
  if [ -n "${SPECCHIO_DRY:-}" ]; then
    echo "[DRY] issue: $titolo — $det" >&2
    return
  fi
  if gh issue create -R "$REPO_HUB" --title "$titolo" \
      --body "Aperta dallo specchio del turno ($(date '+%F %H:%M')): il sistema se l'e' detto da solo.
Evidenza: $det
Il componente e' degradato: chi cura guarda qui, poi chiude l'issue quando il rosso torna verde." >/dev/null 2>&1; then
    echo "specchio: issue aperta → $titolo" >&2
  else
    echo "specchio: ⚠ issue NON aperta per $comp (gh ha detto no — domani si riprova)" >&2
  fi
}

verdetto() { # verdetto <verde|giallo|rosso> <componente> [dettaglio]
  local lvl="${1:-}" comp="${2:-}" det="${3:-}"
  case "$lvl" in
    verde) VERDI=$((VERDI+1)) ;;
    giallo) GIALLI=$((GIALLI+1)); echo "specchio: GIALLO $comp — $det" >&2 ;;
    rosso)  ROSSI=$((ROSSI+1));  echo "specchio: ROSSO $comp — $det" >&2; apri_issue "$comp" "$det" ;;
  esac
}

etag() { python3 -c 'import os,sys; print(int(os.path.getmtime(sys.argv[1])))' "$1" 2>/dev/null || echo 0; }

# ── 1. il digest del mattino: caricato, verde, e davvero girato ────────────────
DIGEST_SH="$HERE/night-shift/morning-digest.sh"
if [ ! -x "$DIGEST_SH" ]; then
  verdetto rosso digest "lo script non esiste o non e' eseguibile: night-shift/morning-digest.sh"
else
  ST=$(launchctl list 2>/dev/null | awk -v l="$LABEL" '$3==l{print $2}')
  if [ -z "$ST" ]; then
    verdetto rosso digest "il job $LABEL non e' caricato in launchd (il mattino resta al buio)"
  elif [ "$ST" != "0" ]; then
    verdetto rosso digest "ultima esecuzione del job exit=$ST (127=script non trovato — e' stato cosi' per giorni)"
  else
    DL="$HOME/morning-digest.log"
    if [ -f "$DL" ] && [ $(( $(date +%s) - $(etag "$DL") )) -lt 115200 ]; then   # 32h: il digest gira alle 7:30
      verdetto verde digest
    else
      verdetto giallo digest "job caricato ed exit 0, ma il log e' vecchio o assente: $DL"
    fi
  fi
fi

# ── 2. la lezione di ieri: se il turno e' girato, la scuola ha scritto ─────────
IERI=$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F 2>/dev/null || true)
if [ -n "$IERI" ]; then
  if [ -f "$WORK/.impara-$IERI" ]; then
    verdetto verde impara
  else
    ATTIVO=$( { [ -f "$HOME/night-shift.log" ] && grep -ac "^\[$IERI" "$HOME/night-shift.log"; } 2>/dev/null || echo 0)
    ATTIVO=$(printf '%s\n' "$ATTIVO" | awk '{s+=$1} END{print s+0}')
    if [ "$ATTIVO" -eq 0 ]; then
      verdetto verde impara   # il turno non e' girato ieri: niente lezione da pretendere
    else
      verdetto giallo impara "il turno e' girato ieri ($ATTIVO righe di log) ma la lezione manca: $WORK/.impara-$IERI"
    fi
  fi
fi

# ── 3. i cloni vedono i rami PR (la ricaduta di E-052 non si rifà viva) ────────
# (niente IFS= qui: la riga SI spezza — owner/repo e il tipo di commit sono due parole)
while read -r ENTRY _resto; do
  case "$ENTRY" in ''|'#'*) continue ;; esac
  NOME="${ENTRY##*/}"
  CLONE="$WORK/$NOME"
  if [ ! -d "$CLONE/.git" ]; then
    verdetto rosso "clone $NOME" "clone assente: $CLONE (il turno lo ricreera' o va ricreato a mano)"
    continue
  fi
  FETCH=$(git -C "$CLONE" config --get remote.origin.fetch 2>/dev/null || true)
  case "$FETCH" in
    *'*'*) verdetto verde "clone $NOME" ;;
    *) verdetto rosso "clone $NOME" "refspec single-branch ('$FETCH'): il revisore non vedra' mai i rami PR (E-052, --no-single-branch)" ;;
  esac
done < "$CONF"

# ── 4-6. i tre cervelli di casa ────────────────────────────────────────────────
if curl -s --max-time 5 http://localhost:11434/api/tags >/dev/null 2>&1; then
  verdetto verde server-iq3s
else
  verdetto rosso server-iq3s "Ollama non risponde su 11434: la notte non lavora (il watchdog rianima, l'issue ricorda)"
fi
if curl -s --max-time 3 http://127.0.0.1:8017/ >/dev/null 2>&1; then
  verdetto verde server-razzo
else
  verdetto giallo server-razzo "razzo giu' su 8017: il censore paga il LLM intero (degradazione nota, dichiarata)"
fi
if curl -s --max-time 3 http://127.0.0.1:5005/health >/dev/null 2>&1; then
  verdetto verde server-pii
else
  verdetto giallo server-pii "rizzo-pii giu' su 5005: il gate GDPR degrada a shape+lista locale"
fi

echo "specchio: $VERDI verdi · $GIALLI gialli · $ROSSI rossi$( [ "$ROSSI" -eq 0 ] && printf ' — casa in ordine' || printf ' — %d issue all hub' "$ROSSI" )"
