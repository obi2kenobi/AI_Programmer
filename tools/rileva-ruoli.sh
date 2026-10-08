#!/bin/bash
# rileva-ruoli.sh — dichiara quali ruoli della faretra (roles/) sono attivi per un repo.
#
# (2026-10-03, allargamento della faretra deciso da Luca: la notte lavorava
# SENZA canone di dominio — i 6 agenti Claude erano armi del giorno e
# risolvi-issue non li vedeva affatto. Ora ogni repo dichiara i suoi ruoli
# in .git/ruoli-attivi e la notte li inietta nel prompt.)
#
# Il rilevamento è DETERMINISTICO e AUDITABILE: due soli segnali, il NOME del
# repo (Luca chiama i repo col dominio: è il segnale più forte del parco) e il
# CENSIMENTO dei file. Ogni ruolo attivato dice PERCHÉ. Il file è di Luca:
# si può EDITARE a mano, il rilevamento non lo tocca se esiste già (a meno
# di --rileggi).
#
# Uso: rileva-ruoli.sh <dir-repo> [--rileggi]
#   scrive <dir-repo>/.git/ruoli-attivi (una riga: un nome di roles/<nome>.md)
#   --rileggi: sovrascrive anche se il file esiste (dopo un edit sbagliato)
#   --asciutti: non scrive, stampa il rilevamento (per banchi e ispezioni)
set -euo pipefail

DIR="${1:-}"
MODO="${2:-}"
[ -d "$DIR/.git" ] || { echo "rileva-ruoli: $DIR non è un repo git" >&2; exit 1; }
HUB="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$HUB/roles" ] || { echo "rileva-ruoli: $HUB/roles manca — la faretra è nell'hub, questo tool gira nell'hub" >&2; exit 1; }

FILE="$DIR/.git/ruoli-attivi"
if [ -f "$FILE" ] && [ "$MODO" != "--rileggi" ] && [ "$MODO" != "--asciutti" ]; then
  echo "rileva-ruoli: $FILE esiste già (editabile a mano) — non tocco. Usa --rileggi per rifare."
  exit 0
fi

NOME_REPO=$(basename "$DIR" | tr '[:upper:]' '[:lower:]')
# il README dice il fine del progetto: prime 3000 righe-carattere bastano
TESTO=""
for CANDIDATO in README.md readme.md README.MD; do
  if [ -f "$DIR/$CANDIDATO" ]; then TESTO=$(head -c 3000 "$DIR/$CANDIDATO" | tr '[:upper:]' '[:lower:]'); break; fi
done
SEGNALE="$NOME_REPO $TESTO"

# il censimento (contano i file, non le righe: cheap e stabile)
N_GS=$(find "$DIR" -name '*.gs' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
N_PY=$(find "$DIR" -name '*.py' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
N_JS=$(find "$DIR" -name '*.js' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
N_MD=$(find "$DIR" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
N_CODICE=$(( N_GS + N_PY + N_JS ))

RUOLI=""
attiva() { RUOLI="$RUOLI$1"$'\n'; echo "  + $1 ($2)"; }

# ── per nome: il dominio dichiarato da Luca nel nome/README ─────────────────
if grep -qiE 'trading|strategia|backtest|long.?short|scalp' <<<"$SEGNALE"; then
  attiva analista-trading "nome/README: trading"
fi
if grep -qiE 'price.?intelligen|middleware|pipeline|etl|sync|collector|scraping' <<<"$SEGNALE"; then
  attiva pipeline-dati "nome/README: pipeline"
fi
if grep -qiE 'ordin|magazzin|logistic|dropship|golilla|spediz|warehous' <<<"$SEGNALE"; then
  attiva specialista-logistica "nome/README: logistica"
fi
if grep -qiE 'contabilit|bilanc|fattur|cespit|scadenz|margine|dso|riconcili' <<<"$SEGNALE"; then
  attiva contabilita-analitica "nome/README: contabilità"
  attiva costruttore-calcoli-gestionali "nome/README: contabilità"
  attiva revisore-calcoli-critici "nome/README: contabilità"
fi
if grep -qiE 'business central|\bbc\b|navision|dynamics' <<<"$SEGNALE"; then
  attiva censitore-forma-dati "nome/README: dati Business Central"
fi

# ── per censimento: la forma del codice parla ───────────────────────────────
# (giro 6): la webapp GAS (App.html o simili) ha il suo verificatore d'interfaccia
if [ "$(find "$DIR" -name 'App.html' -not -path '*/.git/*' 2>/dev/null | head -1)" != "" ] || [ "$N_GS" -gt 0 ] && find "$DIR" -maxdepth 2 -name '*.html' -not -path '*/.git/*' 2>/dev/null | grep -q .; then
  attiva verificatore-frontend "censimento: webapp HTML nel repo GAS"
fi
if [ "$N_GS" -gt 0 ]; then
  case "$RUOLI" in *sviluppatore-gas*) ;; *)
    attiva sviluppatore-gas "censimento: $N_GS file .gs" ;;
  esac
  case "$RUOLI" in *revisore-gas*) ;; *)
    attiva revisore-gas "censimento: $N_GS file .gs" ;;
  esac
fi
if [ "$N_PY" -gt 2 ] && [ "$N_GS" -eq 0 ]; then
  case "$RUOLI" in *revisore-python*) ;; *)
    attiva revisore-python "censimento: $N_PY file .py" ;;
  esac
fi
# un repo dove i documenti superano il doppio del codice: la conoscenza È il prodotto
if [ "$N_MD" -ge 10 ] && [ "$N_MD" -gt $(( N_CODICE * 2 )) ]; then
  attiva curatore-conoscenza "censimento: $N_MD .md contro $N_CODICE di codice"
fi

if [ -z "$RUOLI" ]; then
  if [ "$N_CODICE" -eq 0 ] && [ "$N_MD" -gt 0 ]; then
    # (giro 2, 2026-10-04): un repo di soli documenti col canone GAS era un falso positivo
    # — non c'e' niente da sviluppare in .gs. Il prodotto di un repo doc-only e' la conoscenza.
    attiva curatore-conoscenza "censimento: solo documenti ($N_MD .md, zero codice)"
  else
    RUOLI="sviluppatore-gas"$'\n'"revisore-gas"$'\n'
    echo "  (nessun segnale: canone GAS di default — il baricentro del parco)"
  fi
fi

if [ "$MODO" = "--asciutti" ]; then
  exit 0
fi
printf '%s' "$RUOLI" > "$FILE"
echo "rileva-ruoli: scritto $FILE ($(printf '%s' "$RUOLI" | grep -c . ) ruoli)"
