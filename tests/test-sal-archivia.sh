#!/bin/bash
# test-sal-archivia.sh — la rotazione del SAL in sandbox (richiesta dal banco 7
# dopo i 100 giri di chiarezza: il tool era cambiato e nessun test lo citava).
# Contratto: le voci più vecchie di N giorni passano al SAL-ARCHIVIO (APPEND,
# mai sovrascrittura), le recenti restano, l'indice non si archivia, una voce
# senza data resta nel vivo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
cat > "$SB/SAL.md" <<SAL
# SAL

## Indice del diario
- finto

## Log
### 2026-05-01 — voce vecchissima
lezione antica

### 2026-05-02 — voce vecchia
altra lezione

### SENZA DATA — voce senza data
non va archiviata

### 2026-08-27 — voce recente
lezione fresca
SAL
: > "$SB/ARCHIVIO.md"

OUT=$(SAL="$SB/SAL.md" ARCHIVIO="$SB/ARCHIVIO.md" bash "$HERE/tools/sal-archivia.sh" 30)
grep -q "archiviate 2 voci" <<<"$OUT" && ok "2 voci vecchie archiviate (di 4)" || ko "conteggio archiviate: $OUT"
grep -q "voce vecchissima" "$SB/ARCHIVIO.md" && ok "l'archivio riceve in APPEND le vecchie" || ko "archivio vuoto"
grep -q "voce recente" "$SB/SAL.md" && ok "le recenti restano nel SAL" || ko "recente archiviata per errore"
grep -q "SENZA DATA" "$SB/SAL.md" && ok "voce senza data resta nel vivo (regex non golosa)" || ko "voce senza data archiviata"
grep -q "## Indice" "$SB/SAL.md" && ok "l'indice non si archivia" || ko "indice archiviato"
grep -q "voce vecchissima" "$SB/SAL.md" && ko "la vecchia resta anche nel SAL (doppione)" || ok "le vecchie NON restano nel SAL"

# idempotenza: rigirare non archivia altro
OUT2=$(SAL="$SB/SAL.md" ARCHIVIO="$SB/ARCHIVIO.md" bash "$HERE/tools/sal-archivia.sh" 30)
grep -q "nessuna voce" <<<"$OUT2" && ok "secondo giro: nulla da archiviare (idempotente)" || ko "secondo giro archivia ancora: $OUT2"
grep -c "voce vecchissima" "$SB/ARCHIVIO.md" | grep -c "^1$" >/dev/null && ok "nessun doppione in archivio" || ko "doppione in archivio"

# (2026-09-24, sesto ventaglio, S4 R1): due scritture in fila, senza transazione — accodava all'archivio, poi
# riscriveva il SAL. Ucciso fra le due, al giro dopo riaccodava le stesse voci: l'archivio (append-only per regola)
# teneva i doppioni per sempre. Ora ogni scrittura e' atomica e una voce gia' nell'archivio non si riaccoda.
SB2=$(mktemp -d)
printf '# SAL\n\n## Indice del diario\n- x\n\n## Log\n### 2026-05-01 — vecchia uno\nuno\n\n### 2026-05-02 — vecchia due\ndue\n\n### 2026-08-27 — recente\nr\n' > "$SB2/SAL.md"; : > "$SB2/ARCHIVIO.md"
if command -v strace >/dev/null 2>&1; then
  SAL="$SB2/SAL.md" ARCHIVIO="$SB2/ARCHIVIO.md" strace -f -o /dev/null -P "$SB2/SAL.md" -e trace=openat -e inject=openat:signal=KILL:when=2 bash "$HERE/tools/sal-archivia.sh" 30 >/dev/null 2>&1
  SAL="$SB2/SAL.md" ARCHIVIO="$SB2/ARCHIVIO.md" bash "$HERE/tools/sal-archivia.sh" 30 >/dev/null 2>&1
  N=$(grep -c '^### 2026-05-01 — vecchia uno' "$SB2/ARCHIVIO.md")
  [ "$N" -eq 1 ] && ! grep -c 'vecchia uno' "$SB2/SAL.md" >/dev/null && ok "S4 R1: ucciso fra le due scritture, il giro dopo non raddoppia l'archivio" || ko "S4 R1: voce nell'archivio $N volte, nel SAL: $(grep -c 'vecchia uno' "$SB2/SAL.md")"
else
  echo "⊘ S4 R1: strace assente — il kill fra le due scritture non si prova qui (dichiarato)"
fi
rm -rf "$SB2"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
