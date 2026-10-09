#!/bin/bash
# lente-documenti.sh — la lente PROSA dei documenti del diff (2026-10-09, mandato
# di Luca: «cerca tool per migliorare l'assistente diurno» — il buco «documenti»
# della faretra, riempito alla nostra maniera: deterministica, diff-aware,
# LLM-agnostic). Motore: Vale (offline, stili personalizzati); regola di casa:
# ASCII — la casa scrive «e'» non «è» (stessa legge che il pre-commit impone
# alle righe di codice aggiunte, estesa ai .md; non una moda nuova).
#
# Furto integrato dal primo giorno: l'uscita e' in ERRORFORMAT
# («file:riga: livello: messaggio», il formato universale di reviewdog/vim) —
# cosi' ogni lente futura eredita parser, relay e annotazioni (tools/annota.sh)
# senza un formato per ciascuna.
#
# Uso: lente-documenti.sh <dir-repo> <base> [head=HEAD]
# Esce: 0 = pulita (o niente .md nel diff, o Vale assente = SKIP dichiarato)
#       1 = rilievi (le righe AGGIUNTE dei .md cambiati) · 2 = uso errato
# Override: VALE_BIN (default: vale nel PATH).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
VALE="${VALE_BIN:-vale}"
[ $# -ge 2 ] || { echo "uso: lente-documenti.sh <dir-repo> <base> [head]" >&2; exit 2; }
DIR="$1"; BASE="$2"; TESTA="${3:-HEAD}"
log() { echo "[lente-documenti $(date '+%H:%M:%S')] $*" >&2; }

# i .md cambiati nel range (nessuno = pulita: la lente morde solo dove il diff porta)
FILES=$(git -C "$DIR" diff --name-only --diff-filter=ACMR "$BASE...$TESTA" -- '*.md' '*.mdx' 2>/dev/null)
[ -n "$FILES" ] || { log "nessun documento nel diff ($BASE...$TESTA)"; exit 0; }
if ! command -v "$VALE" >/dev/null 2>&1; then
  log "⚠ Vale assente — lente documenti SALTATA (dichiarato: brew install vale)"
  exit 0
fi
INI="$HERE/tools/lente-documenti.vale.ini"
[ -f "$INI" ] || { log "⚠ $INI assente — lente documenti DEGRADATA (config non trovata)"; exit 0; }

# le righe AGGIUNTE per file (dagli header @@, come lente-sicurezza): la lente
# non giudica la prosa che era gia' li' — solo quella che il diff porta
righe_aggiunte() {  # $1=file → elenco numeri riga
  git -C "$DIR" diff -U0 "$BASE...$TESTA" -- "$1" 2>/dev/null \
    | awk '/^@@/{split($3,a,","); n=substr(a[1],2)+0; next}
           /^\+/ && !/^\+\+\+/ {print n; n++}'
}

TOT=0
VISTE=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  AGG=$(righe_aggiunte "$f")
  [ -n "$AGG" ] || continue
  # vale sul file intero (line format), poi si tengono SOLO le righe aggiunte
  OUT=$("$VALE" --config="$INI" --output=line --no-exit "$DIR/$f" 2>/dev/null || true)
  [ -n "$OUT" ] || continue
  while IFS= read -r r; do
    # formato vale: percorso:riga:colonna:controllo:messaggio
    RIGA=$(printf '%s' "$r" | cut -d: -f2)
    case "$RIGA" in ''|*[!0-9]*) continue ;; esac
    # un rilievo per riga basta (i caratteri accentrati sulla stessa riga sono uno)
    grep -qx "$f:$RIGA" <<<"$VISTE" && continue
    if grep -qx "$RIGA" <<<"$AGG"; then
      CHECK=$(printf '%s' "$r" | cut -d: -f4)
      MSG=$(printf '%s' "$r" | cut -d: -f5-)
      printf '%s:%s: documento[%s]: %s\n' "$f" "$RIGA" "$CHECK" "$MSG"
      VISTE="$VISTE$f:$RIGA
"
      TOT=$((TOT + 1))
    fi
  done <<<"$OUT"
done <<<"$FILES"

log "righe aggiunte dei documenti guardate: $TOT rilievi"
[ "$TOT" -gt 0 ] && exit 1
exit 0
