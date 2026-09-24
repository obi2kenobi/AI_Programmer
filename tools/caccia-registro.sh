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
# (audit-2, 2026-09-23 — il registro non mente): i SALDATI si sottraggono per
# IDENTITA' di sito e SOLO se VERIFICATI: un saldato conta quando la riga che
# cita non ha piu' il difetto. Un marker che punta a una riga cambiata (drift)
# non sottrae niente; un sito marcato saldato che porta ANCORA il difetto resta
# visibile come debito — pagato sulla carta, dovuto nella realta'. Niente piu'
# sottrazioni per conteggio cieco di famiglia.
#
# Uso: caccia-registro.sh [dir]           → il censimento (stampa i conteggi)
#       caccia-registro.sh --prossimo [dir] → il prossimo debito da saldare:
#       «FAMIGLIA|file:riga» — il primo non saldato-VERIFICATO e non rinviato.
# Esce: 0 sempre — il debito non e' un errore, e' un debito
set -uo pipefail
MODO="${1:-}"
[ "$MODO" = "--prossimo" ] && shift
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -d "$DIR" ] || { echo "⛔ dir inesistente: $DIR" >&2; exit 2; }
cd "$DIR"
STATO="$DIR/.git/caccia-registro"
SALDATI="$STATO/saldati"; RINVIA="$STATO/rinviati"
mkdir -p "$STATO"; touch "$SALDATI" "$RINVIA"

# i siti VIVI per famiglia: la stessa scannerizzazione ovunque (prima le due
# viste --prossimo/censimento escludevano i commenti con due regex diverse:
# due verita' sullo stesso debito, audit-1 finding 12)
# (revisione 10 giri, 2026-09-23): -H — con UN solo file nel glob grep non stampa il nome, e
# il sito usciva «2:…» (in una repo satellite con un test solo, misurato)
# (Q31, 2026-09-23): anche tests/ — i banchi sono il posto dove E-002 ha morso (E-042), e la caccia
# non li guardava: la voce di DEBITI che le affidava i 253 siti aspettava per sempre
siti_e002() { grep -rnH "[|] gre[p] -q" --include="*.sh" tools/ night-shift/ llm/ tests/ 2>/dev/null \
              | grep -v "^[^:]*:[0-9]*: *#" | grep -v "cattura-prima" \
              | sed 's/^\([^:]*\):\([0-9]*\):.*/\1:\2/'; }
siti_e032() { grep -rnH '>> "\$HERE\|> "\$HERE\|sed -i.*"\$HERE' tests/*.sh 2>/dev/null \
              | grep -v "^[^:]*:[0-9]*: *#" | grep -v "mktemp\|/tmp" \
              | sed 's/^\([^:]*\):\([0-9]*\):.*/\1:\2/'; }

# un saldato e' VERIFICATO quando la riga che cita non porta piu' il difetto
# della sua famiglia (il marker non pinnava il contenuto: si ricontrolla ora)
saldati_verificati() { # $1 = famiglia
  local f n
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    case "$m" in \#*) continue ;; esac
    f="${m%:*}"; n="${m##*:}"
    [ -f "$f" ] || continue
    case "$1" in
      E-002) sed -n "${n}p" "$f" 2>/dev/null | grep -q "[|] gre[p] -q" || printf '%s\n' "$m" ;;
      E-032) sed -n "${n}p" "$f" 2>/dev/null | grep -qE '>> "\$HERE|> "\$HERE|sed -i.*"\$HERE' || printf '%s\n' "$m" ;;
    esac
  done < "$SALDATI"
}

VER_E002=$(mktemp); VER_E032=$(mktemp)
saldati_verificati E-002 > "$VER_E002"
saldati_verificati E-032 > "$VER_E032"

if [ "$MODO" = "--prossimo" ]; then
  LIBERI=$(mktemp)
  if [ -s "$VER_E002" ]; then siti_e002 | grep -vxFf "$VER_E002" > "$LIBERI.e002" || true
  else siti_e002 > "$LIBERI.e002"; fi
  if [ -s "$VER_E032" ]; then siti_e032 | grep -vxFf "$VER_E032" > "$LIBERI.e032" || true
  else siti_e032 > "$LIBERI.e032"; fi
  { sed 's/^/E-002|/' "$LIBERI.e002"; sed 's/^/E-032|/' "$LIBERI.e032"; } > "$LIBERI.all"
  # (audit-3): -vF SENZA -x matchava per sottostinga — un rinviato :62 spegneva
  # :620-:629. Il confronto resta ESATTO sul sito (awk qui sotto): colpo chirurgico.
  # (revisione 10 giri, 2026-09-23): era `paste` della colonna famiglie di TUTTE le righe coi
  # siti gia' filtrati — con un rinviato le righe scivolavano e il sito prendeva la famiglia
  # di un altro. Ora si filtra la riga intera per il suo sito (campo 2, confronto esatto).
  if [ -s "$RINVIA" ]; then awk -F'|' 'NR==FNR { r[$0]=1; next } !($2 in r)' "$RINVIA" "$LIBERI.all" | head -1
  else head -1 "$LIBERI.all"; fi
  rm -f "$LIBERI" "$LIBERI.e002" "$LIBERI.e032" "$LIBERI.all"
  rm -f "$VER_E002" "$VER_E032"
  exit 0
fi


# ── censimento: i vivi meno i saldati VERIFICATI ───────────────────────────────
E002=$(siti_e002 | grep -vxFf "$VER_E002" | wc -l | tr -d ' ')
E032=$(siti_e032 | grep -vxFf "$VER_E032" | wc -l | tr -d ' ')
rm -f "$VER_E002" "$VER_E032"

# ── censimento + delta ──────────────────────────────────────────────────────────
TOT=$(( E002 + E032 ))
OGGI=$(date '+%Y-%m-%d %H:%M')
BR=$(git branch --show-current 2>/dev/null || echo "?")
if [ -f "$STATO/ultimo" ]; then
  PREC=$(cat "$STATO/ultimo")
  P002=$(echo "$PREC" | awk '{print $1}'); P032=$(echo "$PREC" | awk '{print $2}')
  DELTA=$(( TOT - (P002 + P032) ))
  NOTE="delta vs ultimo censimento: $DELTA"
else
  DELTA=0
  NOTE="baseline (primo censimento)"
fi
if [ "$BR" = "main" ] || [ "$BR" = "master" ]; then
  echo "$E002 $E032" > "$STATO/ultimo"
fi
# (audit-2): la storia si scrive SOLO dal main — la caccia gira su rami di
# lavoro e i censimenti di ramo producevano delta falsi (pagamenti fantasma)
if [ "$BR" = "main" ] || [ "$BR" = "master" ]; then
  echo "$OGGI E-002=$E002 E-032=$E032 tot=$TOT delta=$DELTA" >> "$STATO/storia"
else
  NOTE="$NOTE (storia non scritta: ramo $BR, non main)"
fi

echo "registro: debito famiglie — E-002(pipe in grep -q)=$E002 · E-032(fixture nel vivo)=$E032 · tot=$TOT ($NOTE)"
if [ "$DELTA" -gt 0 ]; then
  echo "⚠ il debito delle famiglie note e' CRESCIUTO di $DELTA: le stesse trappole del registro si stanno rimettendo"
elif [ "$DELTA" -lt 0 ]; then
  echo "✓ debito sceso di $(( -DELTA )): le famiglie del registro si stanno estinguendo"
fi
