#!/bin/bash
# system-health.sh — un solo comando, tutto il polso del sistema (giro 1/10 feature).
# Il sistema ha 7 pezzi mobili: chi vive, chi tace, chi rallenta. Questo lo dice.
set -uo pipefail
GREEN=0; YELLOW=0; RED=0
ok()    { GREEN=$((GREEN+1));  echo "✅ $1"; }
warn()  { YELLOW=$((YELLOW+1)); echo "⚠️  $1"; }
ko()    { RED=$((RED+1));      echo "⛔ $1"; }
# il turno incastrato (2026-08-31: tre notti perse così) — visibilità, non watchdog
bash "$(dirname "$0")/turno-vivo.sh"

echo "== Sistema — $(date '+%Y-%m-%d %H:%M') =="

# 1. Ollama (il motore notturno)
if curl -sf --max-time 3 http://localhost:11434/api/version >/dev/null 2>&1; then
  ok "Ollama attivo ($(curl -s http://localhost:11434/api/version | jq -r .version))"
  MODELLO=$(curl -s http://localhost:11434/api/ps 2>/dev/null | jq -r '.models[0].name // "nessuno"' 2>/dev/null)
  [ "$MODELLO" != "nessuno" ] && ok "modello residente: $MODELLO" || warn "nessun modello residente (normale a riposo)"
else
  ko "Ollama GIÙ — il turno notturno non partirà"
fi

# 2. Wayfinder (il router)
if curl -sf --max-time 3 http://127.0.0.1:8088/healthz >/dev/null 2>&1; then
  ok "Wayfinder attivo ($(curl -s http://127.0.0.1:8088/healthz | jq -r .status 2>/dev/null))"
else
  warn "Wayfinder giù (il turno notturno ha la linea diretta: non blocca, ma il routing giorno è fuori)"
fi

# 3. LaunchAgent
for AG in luca.ollama luca.nightshift luca.wayfinder; do
  if launchctl list 2>/dev/null | grep -q "$AG"; then
    ok "launchd: $AG caricato"
  else
    warn "launchd: $AG NON caricato"
  fi
done

# 4. Tool CLI
for CMD in gh opencode graphify ollama jq; do
  command -v $CMD >/dev/null 2>&1 && ok "$CMD sul PATH" || ko "$CMD ASSENTE"
done

# 5. Memoria (il collo di bottiglia notturno)
SWAP=$(sysctl -n vm.swapusage 2>/dev/null | grep -o 'used = [0-9.]*' | awk '{print $3}')
FREEMB=$(memory_pressure -Q 2>/dev/null | grep -o '[0-9]*' | head -1)
if python3 -c "exit(0 if float('${SWAP:-0}') < 4000 else 1)" 2>/dev/null; then
  ok "swap: ${SWAP}M (sotto controllo)"
else
  warn "swap: ${SWAP}M — chiudi le app pesanti prima del turno"
fi

# 6. Config locale
CONF="$(cd "$(dirname "$0")/.." && pwd)/night-shift/repos.conf"
# bug reale (revisione 14 lenti, 2026-08-28): `grep -c` STAMPA sempre un conteggio (anche
# "0"), ma esce con status 1 quando il conteggio è zero — con solo commenti/righe vuote in
# repos.conf (coda vuota, uno stato normalissimo) il "|| echo 0" scattava COMUNQUE,
# appendendo un secondo "0": N_REPO diventava la stringa a due righe "0\n0", e
# `[ "$N_REPO" -gt 0 ]` generava un errore di shell ("integer expression expected") invece
# di valutare la coda vuota. Il fallback serve solo per il file ASSENTE, non per zero match.
if [ -f "$CONF" ]; then
  N_REPO=$(grep -cvE '^\s*#|^\s*$' "$CONF" 2>/dev/null)
  N_REPO="${N_REPO:-0}"
else
  N_REPO=0
fi
[ "$N_REPO" -gt 0 ] && ok "coda: $N_REPO repo in repos.conf" || warn "repos.conf vuoto o assente"
KEY="$(dirname "$CONF")/repos.key"
[ -f "$KEY" ] && ok "privacy key presente (locale)" || warn "repos.key assente (privacy-check degradato)"

# 7. Coda notturna
if [ "$N_REPO" -gt 0 ]; then
  TOT=0
  while IFS= read -r line; do
    line="${line%%#*}"; [ -z "$(echo $line | tr -d ' ')" ] && continue
    REPO=$(echo "$line" | awk '{print $1}')
    N=$(gh issue list -R "$REPO" --label night-shift --state open --json number -q 'length' 2>/dev/null || echo "?")
    [ "$N" != "0" ] && [ "$N" != "?" ] && echo "   📋 $REPO: $N commesse in coda"
    [ "$N" != "?" ] && TOT=$((TOT+N))
  done < "$CONF"
  [ $TOT -gt 0 ] && ok "$TOT commesse totali in coda per stanotte" || ok "coda vuota: la notte dormirà"
fi

echo ""
echo "== Verdetto: $GREEN ok · $YELLOW attenzione · $RED critici =="
[ $RED -eq 0 ]
