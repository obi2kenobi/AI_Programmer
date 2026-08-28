#!/bin/bash
# test-sync-repo.sh — 2026-08-24, report sul campo F2: onboard/bootstrap sono a un
# colpo solo, nessuno strumento riallineava. sync-repo.sh lo fa nella forma minima
# (diff + copia). Verifica: allineato=0, divergente=1 col conteggio righe, il verdetto
# è sulla riga finale, e --from-local funziona senza rete (per questo test).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# repo finta ALLINEATA
mkdir -p "$TMP/allineata"
cp "$HERE/CLAUDE.md" "$TMP/allineata/CLAUDE.md"
bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/allineata" >/dev/null 2>&1
[ $? -eq 0 ] && ok "repo allineata: exit 0" || ko "allineata non riconosciuta"

# repo finta DIVERGENTE (versione vecchia: manca la coda dell'hub)
mkdir -p "$TMP/divergente"
head -50 "$HERE/CLAUDE.md" > "$TMP/divergente/CLAUDE.md"
OUT=$(bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/divergente" 2>&1); RC=$?
[ $RC -eq 1 ] && echo "$OUT" | grep -q "DIVERGENTE" \
  && ok "repo divergente: exit 1 col verdetto DIVERGENTE dichiarato" \
  || ko "divergente rc=$RC: $OUT"
echo "$OUT" | grep -qE "dista [0-9]+ righe" \
  && ok "il verdetto porta il conteggio delle righe di distanza" \
  || ko "conteggio righe mancante"

# bug reale (revisione 14 lenti, 2026-08-28): "$HUB_CLAUDE.md" invece di "$HUB_CLAUDE"
# faceva fallire silenziosamente entrambi i diff — DIFF_LINES restava sempre "dista 0
# righe" (che il check sopra, con una regex troppo permissiva, non distingueva da un
# conteggio vero) e il blocco di dettaglio sotto restava vuoto. Verifica esplicita che il
# conteggio sia REALMENTE positivo e che il blocco di dettaglio non sia vuoto.
echo "$OUT" | grep -qE "dista [1-9][0-9]* righe" \
  && ok "il conteggio delle righe è realmente positivo, non sempre 0" \
  || ko "conteggio righe fermo a 0 nonostante una divergenza vera — output: $OUT"
DETTAGLIO=$(echo "$OUT" | grep -c '^  [<>]')
[ "$DETTAGLIO" -gt 0 ] \
  && ok "il blocco di dettaglio diff mostra righe reali ($DETTAGLIO)" \
  || ko "blocco di dettaglio diff vuoto — output: $OUT"

# CLAUDE.md assente → errore esplicito
mkdir -p "$TMP/vuota"
bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/vuota" >/dev/null 2>&1
[ $? -eq 1 ] && ok "CLAUDE.md assente nel progetto: errore esplicito" || ko "assenza silenziosa"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
