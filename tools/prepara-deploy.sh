#!/usr/bin/env bash
# prepara-deploy.sh — il primo tempo del DEPLOY ASSISTITO (dominio, Luca 2026-09-23).
#
# La regola fondativa «clasp push MAI (per l'agente)» resta INTERA: l'hook blocca
# l'agente, sempre. Ma il report d'agosto misurava che il rischio vero e' l'agente
# che MANEGGIA le credenziali, non un deploy eseguito: da qui il rituale in due
# tempi — questo tool PREPARA (verifica, congela, firma il pacchetto), il gesto
# umano (tools/deploy-ora.sh, lanciato da Luca nel SUO terminale) ESEGUE.
#
# Cosa fa: albero pulito -> verifiche di .night-verify verdi -> manifest con SHA,
# data, checksum dei file di produzione -> tutto in ~/deploy-pronto/<repo>/.
# Il mattino dopo, il digest porta il "deploy pronto" tra le cose che aspettano
# il tuo gesto. Il pacchetto scade dopo 24h: si deploera fresco o niente.
#
# Uso: prepara-deploy.sh <dir-repo>       (esce 0 = pacchetto pronto)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=llm/_timeout.sh
[ -f "$HERE/llm/_timeout.sh" ] && source "$HERE/llm/_timeout.sh"

DIR="${1:?uso: prepara-deploy.sh <dir-repo>}"
cd "$DIR"
REPO=$(basename "$DIR")
STAGE="$HOME/deploy-pronto/$REPO"
mkdir -p "$STAGE"

# 1. l'albero dev'essere pulito: si deploera un commit, non un pasticcio
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "⛔ albero sporco: committa prima — il deploy firma un commit esatto" >&2; exit 1
fi
SHA=$(git rev-parse HEAD)
DATA=$(date '+%Y-%m-%d %H:%M')

# 2. le verifiche dichiarate del repo devono essere verdi QUI, ORA
if [ -f .night-verify ]; then
  while IFS= read -r riga; do
    case "$riga" in \#*|"") continue ;; esac
    SEC=120; CMD="$riga"
    case "$riga" in @*) SEC="${riga%% *}"; SEC="${SEC#@}"; CMD="${riga#* }" ;; esac
    if ! ai_timeout "$SEC" bash -c "$CMD" >/dev/null 2>&1 </dev/null; then
      echo "⛔ verifica rossa, niente pacchetto: $CMD" >&2; exit 1
    fi
  done < .night-verify
fi

# 3. il manifest: cio' che il gesto umano vedra' e firmara'
SUM=$(find . -name "*.gs" -not -path "./.git/*" -exec cat {} + 2>/dev/null | shasum | cut -c1-16)
N_FILE=$(find . -name "*.gs" -not -path "./.git/*" 2>/dev/null | wc -l | tr -d ' ')
cat > "$STAGE/MANIFEST.md" <<EOF
# Deploy pronto — $REPO

- commit: $SHA
- preparato: $DATA (scade dopo 24h)
- verifica: .night-verify verde su questo commit
- file di produzione: $N_FILE .gs — shasum complessivo: $SUM

## Il gesto
Esegui dal TUO terminale (mai da una sessione agente):
    deploy-ora $REPO

Il comando mostra questo manifest, chiede conferma a voce, esegue clasp push
del commit esatto. Le credenziali restano nel tuo profilo clasp: l'agente
non le vede e non le tocca — l'hook continua a bloccare ogni suo tentativo.
EOF
echo "$SHA" > "$STAGE/commit.txt"
date +%s > "$STAGE/preparato-at.txt"
echo "pacchetto pronto: $STAGE/MANIFEST.md (commit $SHA)"
echo "il gesto: deploy-ora $REPO"
