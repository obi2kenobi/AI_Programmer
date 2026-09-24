#!/bin/bash
# test-caccia-lente.sh — ogni lente di night-shift/caccia-lente.sh esegue il comando INTERO (2026-09-24,
# notte dei giri, T6#2). Le lenti sono «nome|comando|parole», e il comando contiene a sua volta una pipe
# (`… | tail -25`): `cut -d'|' -f2` lo tagliava alla prima, e quattro lenti su cinque giravano senza il
# loro filtro — il modello leggeva le prime 50 righe invece delle ultime 25. Le parole da cercare
# (terzo campo) finivano nel filtro, e non erano usate da nessuno.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# un hub finto: la lente «sonde» (rotazione 0) chiama tools/giri-ignoranti.sh, qui un finto da 60 righe
mkdir -p "$T/hub/night-shift" "$T/hub/tools" "$T/progetto"
cp "$HERE/night-shift/caccia-lente.sh" "$T/hub/night-shift/"
printf '#!/bin/bash\nfor i in $(seq 1 60); do echo "riga $i"; done\n' > "$T/hub/tools/giri-ignoranti.sh"
echo 0 > "$T/hub/.caccia-rotazione"
OUT=$(NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" 2>&1)
grep -cF "comando: bash $T/hub/tools/giri-ignoranti.sh 2>&1 | tail -25" <<<"$OUT" >/dev/null \
  && ok "la lente esegue il comando intero, pipe interna compresa" || ko "comando tagliato: $(grep -m1 'comando:' <<<"$OUT")"
ATTESO=$(for i in $(seq 36 60); do echo "riga $i"; done | wc -c | tr -d ' ')
grep -cE "\\(($ATTESO|$((ATTESO-1))) bytes" <<<"$OUT" >/dev/null && ok "il modello riceve le ultime 25 righe ($ATTESO byte)" \
  || ko "il modello riceve altro: $(grep -m1 'bytes' <<<"$OUT")"
grep -cF "parole-spia: FIND finding" <<<"$OUT" >/dev/null && ok "le parole da cercare sono quelle dichiarate (terzo campo)" \
  || ko "parole da cercare sbagliate o mai usate: $(grep -m1 'parole' <<<"$OUT")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
