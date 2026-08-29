#!/bin/bash
# presidio.sh — il protocollo di presenza per il lavoro condiviso (multiutenza
# sullo stesso repo, 100 giri 2026-08-29). Il problema: due utenti (o due
# sessioni AI) sullo stesso repo nello stesso momento si accorgono l'uno
# dell'altro solo al conflitto. L'assignee GitHub vale per le COMMESSE (giusto
# così); il presidio vale per le ZONE: «sto toccando SAL/oracoli/agente-X
# fino alle 14:30». Presenza dichiarata in PRESIDI.md — un file append-only
# che si fonde col driver union: due presidii simultanei da due cloni
# sopravvivono entrambi al merge, per costruzione.
#
# NESSUN LOCK GLOBALE: il presidio è visibilità, non blocco. Se due persone
# dichiarano la stessa zona, `lista` lo dice a entrambe (CONTESA) e la
# risoluzione è umana (parlarsi, o il secondo si sposta): un lock distribuito
# fareva finta di risolvere ciò che solo la conversazione risolve.
#
# Uso:
#   presidio.sh claim <zona> <nota>     dichiara presenza (scade dopo 4h di default)
#   presidio.sh lista                   i presidii vivi (i scaduti potati, dichiarati)
#   presidio.sh rilascia <zona>         chiude il tuo presidio (fatto o cambiato idea)
# Esce 0 sempre tranne uso errato: la presenza è un servizio, non un gate.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$HERE/PRESIDI.md"
ORARIO=${PRESIDIO_ORE:-4}
# identità: l'override ESPLICITO vince sul git config (due utenti provano sullo
# stesso clone col PRESIDIO_USER; in produzione ognuno ha il suo nome in git)
CHI="${PRESIDIO_USER:-$(git -C "$HERE" config user.name 2>/dev/null || echo "${USER:-io}")}"

init() {
  [ -f "$FILE" ] || cat > "$FILE" <<EOF
# PRESIDI.md — chi sta toccando cosa, adesso (protocollo di presenza)

> Il registro dei presidii: una riga per presenza dichiarata, append-only,
> merge union come i diari. I presidii scaduti vengono potati da \`lista\` e
> dichiarati nel conteggio. Non è un lock: è visibilità. Due presidii sulla
> stessa zona = CONTESA, e la contesa si risolve parlandosi, non da git.

| Dichiarato | Chi | Zona | Scade | Nota |
|---|---|---|---|---|
EOF
}

case "${1:-}" in
  claim)
    ZONA="${2:?uso: presidio.sh claim <zona> <nota>}"; NOTA="${3:-}"
    init
    ADESSO=$(date +%Y-%m-%dT%H:%M)
    SCADE=$(date -v+${ORARIO}H +%Y-%m-%dT%H:%M 2>/dev/null || date -d "+${ORATIO:-$ORARIO} hours" +%Y-%m-%dT%H:%M 2>/dev/null || echo "?")
    # contesa attuale? (presidio vivo di ALTRO sulla stessa zona)
    VIVI=$(grep "^| " "$FILE" | grep "| $ZONA |" | grep -v "^| Dichiarato" || true)
    if [ -n "$VIVI" ]; then
      echo "⚠ CONTESA: sulla zona '$ZONA' c'è già:"; echo "$VIVI"
      echo "  (dichiarato lo stesso: la visibilità non è un permesso — ma avvisati a vicenda)"
    fi
    printf '| %s | %s | %s | %s | %s |\n' "$ADESSO" "$CHI" "$ZONA" "$SCADE" "$NOTA" >> "$FILE"
    echo "presidio dichiarato: $CHI su '$ZONA' fino alle $SCADE"
    echo "ricordati di committare PRESIDI.md presto (la presenza si vede solo se pushata)"
    ;;
  lista)
    [ -f "$FILE" ] || { echo "nessun presidio: il registro non esiste ancora"; exit 0; }
    ADESSO=$(date +%Y-%m-%dT%H:%M)
    POTATI=0; VIVI=0
    TMP=$(mktemp)
    while IFS= read -r riga; do
      case "$riga" in
        "| Dichiarato"*|""|"#"*|">"*|---*|"|"*---*) echo "$riga" >> "$TMP"; continue ;;
      esac
      SCAD=$(echo "$riga" | awk -F'|' '{print $5}' | tr -d ' ')
      SCAD="${SCAD:-?}"
      if [ "$SCAD" != "?" ] && [ "$SCAD" \< "$ADESSO" ]; then
        POTATI=$((POTATI+1))
      else
        echo "$riga" >> "$TMP"; VIVI=$((VIVI+1))
      fi
    done < "$FILE"
    [ "$POTATI" -gt 0 ] && { mv "$TMP" "$FILE"; echo "potati $POTATI presidii scaduti (dichiarato, non in silenzio)"; } || rm -f "$TMP"
    echo "== presidii vivi: $VIVI =="
    grep "^| 20" "$FILE" 2>/dev/null | sed 's/^/  /' || echo "  (nessuno)"
    # contese: stessa zona, chi diversi
    # contesa VERA: due CHI DIVERSI sulla stessa zona (il conteggio parte da 1:
    # il primo nome è sempre lì — si confrontano i nomi distinti, non gli spazi)
    awk -F'|' '/^\| 20/ {c=$3; z=$4; gsub(/ /,"",z); nomi[z"|"c]=1} END {for (k in nomi) {split(k,p,"|"); n[p[1]]++} for (z in n) if (n[z]>1) print "  ⚠ CONTESA su " z ": " n[z] " presidii distinti"}' "$FILE" || true
    ;;
  rilascia)
    ZONA="${2:?uso: presidio.sh rilascia <zona>}"
    [ -f "$FILE" ] || { echo "registro assente: niente da rilasciare"; exit 0; }
    python3 - "$FILE" "$CHI" "$ZONA" <<'EOF'
import sys
f, chi, zona = sys.argv[1], sys.argv[2], sys.argv[3]
righe = open(f).read().split('\n')
tenute, rilasciati = [], 0
for r in righe:
    parti = [p.strip() for p in r.split('|')]
    if len(parti) >= 4 and parti[1].startswith('20') and parti[2] == chi and parti[3] == zona:
        rilasciati += 1; continue
    tenute.append(r)
open(f, 'w').write('\n'.join(tenute))
print(f"rilasciati {rilasciati} presidii di {chi} su '{zona}'")
EOF
    ;;
  *)
    echo "uso: presidio.sh claim <zona> <nota> | lista | rilascia <zona>" >&2
    exit 1 ;;
esac
