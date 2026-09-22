#!/usr/bin/env bash
# deploy-ora.sh — IL GESTO del deploy assistito (dominio, Luca 2026-09-23).
#
# Questo script lo lancia LUCA, dal SUO terminale. Nessun agente puo' arrivarci:
# l'hook clasp-block continua a bloccare clasp dentro ogni sessione agente, e
# questo script non fa parte di nessun flusso autonomo — sta nel registro dei
# comandi umani, come il morning-gate di una volta.
#
# Mostra il manifest preparato da prepara-deploy.sh (commit esatto, checksum,
# verifica verde), chiede conferma A VOCE (si/no battuto a mano), esegue
# clasp push SOLO se il pacchetto e' fresco (<24h) e il commit corrisponde.
# Rifiuta tutto il resto. Logga l'esito in ~/deploy-pronto/<repo>/STORICO.
set -euo pipefail
REPO="${1:?uso: deploy-ora <repo> (il pacchetto lo prepara prepara-deploy.sh)}"
STAGE="$HOME/deploy-pronto/$REPO"

[ -f "$STAGE/MANIFEST.md" ] || { echo "⛔ nessun pacchetto per $REPO — prima: prepara-deploy.sh"; exit 1; }
[ -f "$STAGE/commit.txt" ]  || { echo "⛔ pacchetto incompleto (manca il commit congelato)" >&2; exit 1; }

# freschezza: il pacchetto scade dopo 24h — si deploera FESCO o niente
ETA=$(( $(date +%s) - $(cat "$STAGE/preparato-at.txt") ))
if [ "$ETA" -gt 86400 ]; then
  echo "⛔ pacchetto scaduto ($((ETA/3600))h): riprepara con prepara-deploy.sh — il deploy firma roba fresca" >&2; exit 1
fi

cat "$STAGE/MANIFEST.md"
echo
printf 'Deploy di %s in ADESSO? [si/no] ' "$REPO"
read -r RISP
[ "$RISP" = "si" ] || { echo "nessun deploy. Il pacchetto resta li' finche' scade."; exit 0; }

SHA=$(cat "$STAGE/commit.txt")
cd "$HOME/night-shift-work/$REPO" 2>/dev/null || { echo "⛔ la copia locale di $REPO non c'e' in ~/night-shift-work" >&2; exit 1; }
[ -d .git ] || { echo "⛔ $REPO non e' un repo git" >&2; exit 1; }
ATTUALE=$(git rev-parse HEAD)
[ "$ATTUALE" = "$SHA" ] || { echo "⛔ il commit attuale ($ATTUALE) non e' quello firmato ($SHA): riprepara" >&2; exit 1; }

echo "— clasp push (credenziali del tuo profilo, mai toccate dall'agente)..."
if npx clasp push -f 2>&1 | tee -a "$STAGE/STORICO.log"; then
  echo "$REPO $SHA deploy $(date '+%F %H:%M') OK" >> "$STAGE/STORICO.log"
  echo "✓ deploy eseguito e registrato in $STAGE/STORICO.log"
  rm -f "$STAGE/MANIFEST.md" "$STAGE/commit.txt" "$STAGE/preparato-at.txt"
else
  echo "$REPO $SHA deploy $(date '+%F %H:%M') FALLITO" >> "$STAGE/STORICO.log"
  echo "⛔ clasp ha fallito — log in $STAGE/STORICO.log" >&2; exit 1
fi
