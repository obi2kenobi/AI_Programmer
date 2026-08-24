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

# CLAUDE.md assente → errore esplicito
mkdir -p "$TMP/vuota"
bash "$HERE/tools/sync-repo.sh" --from-local "$TMP/vuota" >/dev/null 2>&1
[ $? -eq 1 ] && ok "CLAUDE.md assente nel progetto: errore esplicito" || ko "assenza silenziosa"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
