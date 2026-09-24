#!/bin/bash
# system-health.sh — un solo comando, tutto il polso del sistema (giro 1/10 feature).
# Il sistema ha 7 pezzi mobili: chi vive, chi tace, chi rallenta. Questo lo dice.
set -uo pipefail
GREEN=0; YELLOW=0; RED=0
ok()    { GREEN=$((GREEN+1));  echo "✅ $1"; }
warn()  { YELLOW=$((YELLOW+1)); echo "⚠️  $1"; }
ko()    { RED=$((RED+1));      echo "⛔ $1"; }
echo "== Sistema — $(date '+%Y-%m-%d %H:%M') =="

# il turno incastrato (2026-08-31: tre notti perse così). (Q30, 2026-09-23, notte dei giri): girava
# FUORI dai contatori — «⛔ TURNO INCASTRATO» stampato, verdetto ed exit code identici a un turno
# sano, e quindi status-page cieca. Ora conta: incastrato = critico.
TV=$(bash "$(dirname "$0")/turno-vivo.sh"); case $? in 0) ok "$TV" ;; 2) warn "$TV" ;; *) ko "$TV" ;; esac   # (Q3 R6): 2 = non so

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
# (E-026, 2026-09-16): il job nightshift caricato deve puntare al plist DI CASA.
# Una notte intera e' stata persa perche' una registrazione spuria (path in una
# directory TMP) teneva il posto di quella vera, mai caricata. Il job con il
# calendario giusto su disco non conta: conta quello CARICATO.
NS_PATH=$(launchctl print "gui/$(id -u)/luca.nightshift" 2>/dev/null | grep -m1 '^[[:space:]]*path = ' | sed 's/^.*= //')
# (giro 13, 2026-09-20): queste tre righe stampavano OK/ROSSO con `echo` nudo — fuori dai
# contatori GREEN/RED. Un «ROSSO nightshift non caricato» non toccava il verdetto finale
# ne' l'exit code: il controllo E-026 era un cartello, non una sonda. Ora conta.
if command -v launchctl >/dev/null 2>&1; then
  if [ -n "$NS_PATH" ]; then
    case "$NS_PATH" in
      "$HOME/Library/LaunchAgents/"*) ok "nightshift caricato dal plist di casa ($NS_PATH)";;
      *) ko "nightshift caricato da: $NS_PATH — REGISTRAZIONE SPURIA: bootout + bootstrap da ~/Library/LaunchAgents (E-026)";;
    esac
  else
    ko "nightshift non caricato: la finestra notturna non partira'"
  fi
else
  warn "launchctl assente (non e' un Mac): il caricamento del turno non e' verificabile qui"
fi
# (2026-09-18): wayfinder tolto dal controllo — non e' piu' parte del sistema
# (sostituito dal nostro agente.sh) e il suo warn permanente dava alla lente
# un segnale falso: il modello della caccia lo ha riassunto come 'nightshift
# NON caricato' mentre nightshift era caricato e girava. La lente riassume:
# quello che le diamo dev'essere vero, o riassume rumore.
# (E-002 di nuovo, stesso giorno): launchctl list | grep -q con pipefail —
# grep -q chiude stdin al primo match, launchctl prende SIGPIPE (rc 141) e la
# pipeline 'fallisce' anche quando il job c'e'. Cattura-prima, come da canone.
LAUNCHD_LIST=$(launchctl list 2>/dev/null)
for AG in luca.ollama luca.nightshift; do
  if grep -q "$AG" <<<"$LAUNCHD_LIST"; then
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
