#!/bin/bash
# turno-vivo.sh — il detector del turno incastrato (2026-08-31: tre notti perse
# per un opencode in loop MAI tornato, e il job vivo ha bloccato i turni seguenti
# — launchd non avvia doppioni). Non è un watchdog che uccide: è VISIBILITÀ del
# mattino, coerente con la decisione di Luca («nessun limite: la guardia è la
# review del mattino») — la review però può guardare solo ciò che vede.
#
# Uso: bash tools/turno-vivo.sh   (da system-health, dal digest, o a mano)
# Esce 0 se nessun turno è incastrato · 1 se c'è un processo oltre soglia.
set -uo pipefail
SOGLIA_ORE=${TURNO_VIVO_SOGLIA:-6}

# il turno notturno gira con caffeinate su night-shift.sh; l'esecutore è opencode run
PS_OUT=$(ps -axo etime,command 2>/dev/null)
STUCK=$(echo "$PS_OUT" | grep -E "opencode run|night-shift\.sh" | grep -v grep || true)
[ -z "$STUCK" ] && { echo "turno-vivo: nessun processo notturno attivo"; exit 0; }

echo "$STUCK" | while IFS= read -r riga; do
  ET=$(echo "$riga" | awk '{print $1}')
  # etime di ps: [[gg-]hh:]mm:ss — si normalizza in ore
  GGI=$(echo "$ET" | grep -oE '^[0-9]+-' | tr -d '-' || echo 0)
  ORG=$(echo "$ET" | sed 's/^[0-9]*-//' | awk -F: '{if (NF==3) print $1; else if (NF==2) print 0; else print 0}')
  ORE=$(( GGI * 24 + ORG ))
  CMD=$(echo "$riga" | cut -c1-90)
  if [ "$ORE" -ge "$SOGLIA_ORE" ]; then
    echo "⛔ TURNO INCASTRATO: processo notturno attivo da ${ORE}h (soglia ${SOGLIA_ORE}h): $CMD"
    echo "   Tre notti perse così il 2026-08-31 (un loop vivo blocca i turni seguenti)."
    echo "   Pulizia consolidata: pkill -f \"opencode run\" — poi il turno si scioglie da solo."
    exit 1
  fi
done
echo "turno-vivo: processi notturni presenti, nessuno oltre le ${SOGLIA_ORE}h"
exit 0
