#!/bin/bash
# turno-vivo.sh — il detector del turno incastrato (2026-08-31: tre notti perse
# per un opencode in loop MAI tornato, e il job vivo ha bloccato i turni seguenti
# — launchd non avvia doppioni). Non è un watchdog che uccide: è VISIBILITÀ del
# mattino, coerente con la decisione di Luca («nessun limite: la guardia è la
# review del mattino») — la review però può guardare solo ciò che vede.
#
# (2026-09-18, era continua): il turno gira 24/7 e si ri-lancia con exec a ogni
# fine ciclo — un processo VECCHIO e' BY DESIGN, e la soglia sulle ORE di eta'
# scattava ogni notte su un sistema sano (beccato dalla lente alle 18:32:
# «processo attivo da 7h, soglia 6h» su un turno che ciclava perfettamente).
# Il segnale vero di incastrato nel continuo e' IL LOG CHE NON CICLA PIU':
# un ciclo non supera i ~15 minuti, se l'ultimo TURNO INIZIATO e' piu'
# vecchio della soglia qualcosa dentro sta hangando (l'agente in loop, il
# solver appeso) — ed e' quello il turno da sciogliere.
#
# Uso: bash tools/turno-vivo.sh   (da system-health, dal digest, o a mano)
# Esce 0 se il turno cicla (o non c'e') · 1 se il log e' fermo oltre soglia · 2 se non so giudicare
# (timestamp illeggibile o python3 assente: 2026-09-24, Q3 R6 — prima era 0, e il polso lo contava ✅).
set -uo pipefail
SOGLIA_MIN=${TURNO_VIVO_SOGLIA:-30}
LOG=${TURNO_VIVO_LOG:-$HOME/night-shift-console.log}

if [ ! -f "$LOG" ]; then
  echo "turno-vivo: nessun log del turno ($LOG) — niente da giudicare"
  exit 0
fi
ULTIMA=$(grep -a "TURNO INIZIATO" "$LOG" | tail -1 | awk -F'[][]' '{print $2}')
if [ -z "$ULTIMA" ]; then
  echo "turno-vivo: il log non contiene nessun TURNO INIZIATO — niente da giudicare"
  exit 0
fi
ETA_MIN=$(python3 -c "
from datetime import datetime
try:
    d = datetime.strptime('$ULTIMA'.strip(), '%Y-%m-%d %H:%M:%S')
    print(int((datetime.now() - d).total_seconds() // 60))
except ValueError:
    print(-1)" 2>/dev/null || echo -1)
if [ "${ETA_MIN:--1}" -lt 0 ]; then
  echo "turno-vivo: timestamp dell'ultimo ciclo illeggibile ('$ULTIMA') o python3 assente — NON SO giudicare"
  exit 2
fi
if [ "$ETA_MIN" -ge "$SOGLIA_MIN" ]; then
  echo "⛔ TURNO INCASTRATO: ultimo ciclo iniziato ${ETA_MIN} minuti fa (soglia ${SOGLIA_MIN}min)."
  echo "   Nel continuo un ciclo non supera i ~15 minuti: qualcosa dentro sta hangando."
  echo "   Dove si e' fermato: l'ultima riga di $LOG."
  # (Q12, 2026-09-23): prometteva un riavvio automatico di launchd — il plist parte alle 23:00 e non ha
  # KeepAlive (night-shift/plist/com.luca.nightshift.plist): dopo il pkill il turno resta giu'.
  # (2026-09-24, Q1 R4): `[n]ight-shift` — la forma nuda, eseguita da un agente, uccide anche la sua shell
  echo "   Pulizia: pkill -f \"[n]ight-shift/night-shift.sh\", poi riavvialo — launchd da solo lo riparte solo alle 23:00:"
  echo "   launchctl kickstart gui/\$(id -u)/\$(launchctl list | awk '/nightshift/{print \$3}')"
  exit 1
fi
echo "turno-vivo: il turno cicla (ultimo iniziato ${ETA_MIN}min fa, soglia ${SOGLIA_MIN}min)"
exit 0
