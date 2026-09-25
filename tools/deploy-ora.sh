#!/usr/bin/env bash
# deploy-ora.sh — IL GESTO del deploy assistito (dominio, Luca 2026-09-23).
#
# Questo script lo lancia LUCA, dal SUO terminale.
# (2026-09-23, giro A7 della notte): qui c'era scritto «nessun agente puo' arrivarci», ed era
# FALSO — `echo si | bash tools/deploy-ora.sh X` da una sessione agente deploiava: il cancello
# clasp vede solo il comando esterno, e il «si» arrivava dalla pipe. Ora tre strati, provati in
# tests/test-deploy-assistito.sh e tests/test-clasp-block-hook.sh:
#   1. tools/clasp-block-hook.sh nega l'invocazione di deploy-ora da una sessione agente;
#   2. qui: dentro una sessione Claude Code (CLAUDECODE impostata) si rifiuta;
#   3. qui: la conferma deve venire da un TERMINALE — un «si» in pipe non vale.
# E' un cancello contro l'errore, non contro un aggressore (un agente che si toglie la variabile
# e si finge un terminale e' fuori dal patto, come per il cancello clasp).
#
# Mostra il manifest preparato da prepara-deploy.sh (commit esatto, checksum,
# verifica verde), chiede conferma A VOCE (si/no battuto a mano), esegue
# clasp push SOLO se il pacchetto e' fresco (<24h) e il commit corrisponde.
# Rifiuta tutto il resto. Logga l'esito in ~/deploy-pronto/<repo>/STORICO.
set -euo pipefail
if [ -n "${CLAUDECODE:-}" ]; then
  echo "⛔ deploy-ora gira solo nel terminale di Luca, non in una sessione agente (CLAUDECODE e' impostata): il deploy e' dell'umano" >&2
  exit 1
fi
[ -t 0 ] || { echo "⛔ la conferma va battuta in un terminale: lo stdin non e' un terminale, e un «si» in pipe non vale" >&2; exit 1; }
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
# (revisione 10 giri, 2026-09-23): HEAD giusto non basta — clasp spedisce i FILE, e questa e'
# la copia dove lavora il turno notturno: una modifica non committata o un file non tracciato
# sarebbero andati in produzione senza essere nel commit firmato. Albero pulito, o niente.
SPORCO=$(git status --porcelain --untracked-files=all 2>/dev/null)
[ -z "$SPORCO" ] || { echo "⛔ la copia di lavoro NON e' il commit firmato: ci sono modifiche o file non tracciati —" >&2; echo "$SPORCO" | head -10 >&2; echo "   pulisci (o committa e riprepara): si deploea solo cio' che il manifest firma" >&2; exit 1; }

echo "— clasp push (credenziali del tuo profilo, mai toccate dall'agente)..."
if npx clasp push -f 2>&1 | tee -a "$STAGE/STORICO.log"; then
  echo "$REPO $SHA deploy $(date '+%F %H:%M') OK" >> "$STAGE/STORICO.log"
  echo "✓ deploy eseguito e registrato in $STAGE/STORICO.log"
  rm -f "$STAGE/MANIFEST.md" "$STAGE/commit.txt" "$STAGE/preparato-at.txt"
else
  echo "$REPO $SHA deploy $(date '+%F %H:%M') FALLITO" >> "$STAGE/STORICO.log"
  echo "⛔ clasp ha fallito — log in $STAGE/STORICO.log" >&2; exit 1
fi
