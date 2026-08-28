#!/bin/bash
# test-campo-triage.sh — campo-triage in SANDBOX (2026-08-28). La versione
# precedente di questo test è andata persa così: mai committata (test fantasma),
# sovrascritta da un esperimento, il checkout di ripristino falliva in silenzio
# proprio perché non era tracciata. Ricostruita dal contratto del tool, in una
# sandbox con SAL e docs/campo finti: il test NON dipende dallo stato del repo
# del giorno (un report vero appena scritto non deve arrossire la suite).
#
# Contratto: conta i report (md+html, README ESCLUSO), dichiara i non processati
# (nome del report assente da SAL), esce 1 se ce ne sono.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SB=$(mktemp -d)
trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/tools" "$SB/docs/campo"
cp "$HERE/tools/campo-triage.sh" "$SB/tools/"
printf '# SAL finto\n\n## Log\n### 2026-08-28 — lavorazione di 2026-08-28-elaborato e 2026-08-28-vecchio\n' > "$SB/SAL.md"
printf '# README del campo, non un report\n' > "$SB/docs/campo/README.md"
printf 'report processato\n' > "$SB/docs/campo/2026-08-28-elaborato.md"
printf 'report MAI processato\n' > "$SB/docs/campo/2026-08-28-dimenticato.md"
printf 'uno html che conta\n' > "$SB/docs/campo/2026-08-28-vecchio.html"

OUT=$(bash "$SB/tools/campo-triage.sh" 2>&1); RC=$?
echo "$OUT" | grep -q "3 report" && ok "conta 3 report (md+html, README escluso)" || ko "conteggio: attesi 3, avuto: $(echo "$OUT" | head -1)"
echo "$OUT" | grep -q "1 non processati" && ok "dichiara 1 non processato" || ko "non processati: atteso 1"
echo "$OUT" | grep -q "dimenticato" && ok "il colpevole è NOMINATO" || ko "il report dimenticato non è nominato"
[ $RC -ne 0 ] && ok "esce diverso da 0 con report pendenti" || ko "esce 0 con report pendenti: chi lo chiuderebbe?"

# rimosso il report pendente: pulito e verde
rm "$SB/docs/campo/2026-08-28-dimenticato.md"
OUT=$(bash "$SB/tools/campo-triage.sh" 2>&1); RC=$?
echo "$OUT" | grep -q "2 report" && ok "dopo la lavorazione: 2 report" || ko "conteggio post: attesi 2"
[ $RC -eq 0 ] && ok "esce 0 quando tutto è processato" || ko "esce $RC con tutto processato"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
