#!/bin/bash
# automazioni-openclaw.sh — collega il turno notturno al scheduler nativo di OpenClaw
# Sostituisce launchd/plist: il mini accende e il turno parte da solo.
set -euo pipefail
HUB="$(cd "$(dirname "$0")/.." && pwd)"
echo "=== Automazioni OpenClaw per AI_Programmer ==="

# Turno notturno 23:00
openclaw automations create 2>/dev/null <<'AUTO' || echo "(verificare sintassi: openclaw automations --help)"
{
  "name": "turno-notturno",
  "cron": "0 23 * * *",
  "prompt": "Turno notturno: source ~/openclaw-lab/profiles/mini.sh (o max.sh), poi segui il METODO per il turno notturno: per ogni repo in ~/openclaw-lab/ che ha commesse aperte, lavorale col cervello locale. Guardie tutte attive. Digest a fine turno."
}
AUTO

# Digest mattutino 07:30
openclaw automations create 2>/dev/null <<'AUTO2' || echo "(verificare sintassi)"
{
  "name": "digest-mattutino",
  "cron": "30 7 * * *",
  "prompt": "Digest del mattino: leggi tutti i MIGLIORAMENTI.md e i digest di ieri in ~/openclaw-lab/, riassumi in 10 righe: fatto / sospeso / lezione / decisioni dovute a Luca. Aggiorna DECISIONI-DOVUTE.md se ci sono blocchi umani."
}
AUTO2

echo "=== Automazioni configurate ==="
openclaw automations list 2>/dev/null | head -10 || echo "(elenco non disponibile — verificare con openclaw automations --help)"
