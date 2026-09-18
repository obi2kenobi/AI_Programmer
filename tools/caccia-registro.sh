#!/bin/bash
# caccia-registro.sh — la caccia che legge il REGISTRO DEGLI ERRORI e cerca le
# famiglie di bug DOVE DAVVERO SI NASCONDONO (2026-09-18, domanda di Luca:
# «come fa a essere sempre tutto in salute se troviamo sempre una marea di
# errori?»). Le cacce per categoria (morto/docs/semplice) guardano un file alla
# volta in cerca di qualita' del codice — ma E-028..E-032 sono tutti bug
# D'INTEGRAZIONE e DI PROCESSO: contratti, stdin condiviso, fixture nel repo
# vivo. Il registro e' la mappa di quelle famiglie: questa caccia la usa.
#
# Non e' un verdetto rosso/verde: e' il CENSIMENTO del debito per famiglia,
# su TUTTO il repo, ogni ciclo — deterministico (solo grep, niente modello,
# niente un-file-per-volta). «In salute» diventa onesto: salute E debito
# dichiarato insieme. Il delta tra censimenti mostra se il debito cresce.
#
# Famiglie censite (ogni nuova famiglia del registro entra qui):
#   E-002  pipe che finiscono in `grep -q` (SIGPIPE + pipefail: cattura-prima)
#   E-032  fixture di test scritte nel repo VIVO invece che in quarantena
#
# Uso: caccia-registro.sh [dir]           → il censimento (stampa i conteggi)
#       caccia-registro.sh --prossimo [dir] → il prossimo debito da saldare:
#       «FAMIGLIA|file:riga|snippet» — il primo non saldato e non rinviato.
#       (2026-09-18, Luca: il debito censito si SALDA — un sito per finestra,
#       fix del canone, gate, PR, censore. saldati/rinviati vivono in .git.)
# Esce: 0 sempre — il debito non e' un errore, e' un debito
set -uo pipefail
MODO="${1:-}"
[ "$MODO" = "--prossimo" ] && shift
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -d "$DIR" ] || { echo "⛔ dir inesistente: $DIR" >&2; exit 2; }
cd "$DIR"
STATO="$DIR/.git/caccia-registro"
mkdir -p "$STATO"

if [ "$MODO" = "--prossimo" ]; then
  SALDATI="$STATO/saldati"; RINVIA="$STATO/rinviati"
  touch "$SALDATI" "$RINVIA"
  # tutti i siti (famiglia|file:riga), cattura-prima esclusa dai commenti gia' curati
  { grep -rn "| grep -q" --include="*.sh" tools/ night-shift/ llm/ 2>/dev/null | grep -v "^[^:]*:[0-9]*: *#" | sed 's/^\([^:]*\):\([0-9]*\):.*/E-002|\1:\2/' ; grep -rn '>> "\$HERE\|> "\$HERE\|sed -i.*"\$HERE' tests/*.sh 2>/dev/null | grep -v "mktemp\|/tmp" | sed 's/^\([^:]*\):\([0-9]*\):.*/E-032|\1:\2/' ; } | grep -vFf "$SALDATI" | grep -vFf "$RINVIA" | head -1
  exit 0
fi

# ── famiglia E-002: pipe in grep -q ─────────────────────────────────────────────
E002=$(grep -rn "| grep -q" --include="*.sh" tools/ night-shift/ llm/ 2>/dev/null \
  | grep -v "^\S*:\s*#" | grep -vc "cattura-prima" || true)
[ -z "$E002" ] && E002=0

# ── famiglia E-032: fixture nel repo vivo ───────────────────────────────────────
E032=$(grep -rn '>> "\$HERE\|> "\$HERE\|sed -i.*"\$HERE' tests/*.sh 2>/dev/null \
  | grep -v "mktemp\|/tmp" | wc -l | tr -d ' ')

# ── censimento + delta ──────────────────────────────────────────────────────────
TOT=$(( E002 + E032 ))
OGGI=$(date '+%Y-%m-%d %H:%M')
if [ -f "$STATO/ultimo" ]; then
  PREC=$(cat "$STATO/ultimo")
  P002=$(echo "$PREC" | awk '{print $1}'); P032=$(echo "$PREC" | awk '{print $2}')
  DELTA=$(( TOT - (P002 + P032) ))
  NOTE="delta vs ultimo censimento: $DELTA"
else
  DELTA=0
  NOTE="baseline (primo censimento)"
fi
echo "$E002 $E032" > "$STATO/ultimo"
echo "$OGGI E-002=$E002 E-032=$E032 tot=$TOT delta=$DELTA" >> "$STATO/storia"

echo "registro: debito famiglie — E-002(pipe in grep -q)=$E002 · E-032(fixture nel vivo)=$E032 · tot=$TOT ($NOTE)"
if [ "$DELTA" -gt 0 ]; then
  echo "⚠ il debito delle famiglie note e' CRESCIUTO di $DELTA: le stesse trappole del registro si stanno rimettendo"
elif [ "$DELTA" -lt 0 ]; then
  echo "✓ debito sceso di $(( -DELTA )): le famiglie del registro si stanno estinguendo"
fi
