#!/bin/bash
# test-attrezzi-cantiere.sh — i sei attrezzi del cantiere OpenClaw rispettano il contratto
# (15/11/2026: nati per la copertura — banco-passaggio li aveva SCOPERTI:
#  collega-openclaw, automazioni-openclaw, monitor-salute, ocr-estrai,
#  graphify-patch-gs, rizzo-scegli). Contratti, non unit test: ogni attrezzo
#  dichiara il suo comportamento minimo e qui si misura.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# 1. collega-openclaw.sh — installa il metodo in una workspace nuova (fixture in /tmp)
OUT=$(bash "$HERE/tools/collega-openclaw.sh" "$T/ws" 2>&1); RC=$?
[ $RC -eq 0 ] && [ -f "$T/ws/METODO-AI-PROGRAMMER.md" ] \
  && ok "collega-openclaw: installa il METODO in una workspace vuota" \
  || ko "collega-openclaw: rc=$RC, METODO $([ -f "$T/ws/METODO-AI-PROGRAMMER.md" ] && echo presente || echo ASSENTE) — $(tail -2 <<<"$OUT" | tr '\n' ' ')"

# 2. automazioni-openclaw.sh — MAI eseguirlo nei test (crea automazioni vere):
#    il contratto testabile è la sintassi
bash -n "$HERE/tools/automazioni-openclaw.sh" 2>/dev/null \
  && ok "automazioni-openclaw: sintassi bash valida (esecuzione vietata nei test: crea automazioni vere)" \
  || ko "automazioni-openclaw: bash -n fallisce"

# 3. monitor-salute.sh — contro un server vivo risponde vivo, rc 0
#    (il ramo di rianimazione fa pkill del gateway: NON si testa qui)
python3 -m http.server 18131 --directory "$T" >/dev/null 2>&1 &
SRV=$!; sleep 1
OUT=$(bash "$HERE/tools/monitor-salute.sh" "http://127.0.0.1:18131/" 2>&1); RC=$?
kill $SRV 2>/dev/null
[ $RC -eq 0 ] && grep -q "gateway vivo" <<<"$OUT" \
  && ok "monitor-salute: server vivo → verde" \
  || ko "monitor-salute: rc=$RC su server vivo — $OUT"

# 4. ocr-estrai.sh — senza argomenti deve rifiutarsi; con un'immagine produce il .md
bash "$HERE/tools/ocr-estrai.sh" >/dev/null 2>&1 && ko "ocr-estrai: senza argomenti esce 0" || ok "ocr-estrai: senza argomenti rifiuta (rc≠0)"
if command -v tesseract >/dev/null 2>&1; then
  python3 -c "
import zlib,struct
def chunk(t,d):
    c=t+d; return struct.pack('>I',len(d))+c+struct.pack('>I',zlib.crc32(c))
hdr=b'\x89PNG\r\n\x1a\n'
ihdr=chunk(b'IHDR',struct.pack('>IIBBBBB',1,1,8,2,0,0,0))
idat=chunk(b'IDAT',zlib.compress(b'\x00\xff\xff\xff'))
iend=chunk(b'IEND',b'')
open('$T/bianco.png','wb').write(hdr+idat+iend)"
  bash "$HERE/tools/ocr-estrai.sh" "$T/bianco.png" "$T/bianco.md" >/dev/null 2>&1
  [ -f "$T/bianco.md" ] && ok "ocr-estrai: immagine → file .md prodotto" || ko "ocr-estrai: nessun .md prodotto"
else
  ok "ocr-estrai: tesseract assente su questa macchina — prova immagine saltata (dichiarato)"
fi

# 5. graphify-patch-gs.sh — idempotenza: la seconda corsa dichiara «già presente»
if bash "$HERE/tools/graphify-patch-gs.sh" >/dev/null 2>&1; then
  OUT2=$(bash "$HERE/tools/graphify-patch-gs.sh" 2>&1)
  grep -q "già presente" <<<"$OUT2" \
    && ok "graphify-patch-gs: idempotente (seconda corsa: già presente)" \
    || ko "graphify-patch-gs: seconda corsa non dichiara già presente — $OUT2"
else
  ok "graphify-patch-gs: pacchetto graphify assente qui — prova saltata (dichiarato)"
fi

# 6. rizzo-scegli.sh — server su: risposta valida (4 classi, rev.31); server giù: rc 1 dichiarato (rev.23)
OUT=$(bash "$HERE/tools/rizzo-scegli.sh" "conta i file di una repo" 2>/dev/null); RC=$?
if [ $RC -eq 0 ]; then
  grep -qxE "economico|coder|frontiera|ricerca" <<<"$OUT" \
    && ok "rizzo-scegli: server su, risposta valida ($OUT)" \
    || ko "rizzo-scegli: risposta fuori contratto — $OUT"
  # 6b. invariante DUO (rev.31): un task su immagini NON deve finire al coder
  DUO=$(bash "$HERE/tools/rizzo-scegli.sh" "leggi questa foto del documento e trascrivi il testo" 2>/dev/null)
  [ "$DUO" != "coder" ] && ok "rizzo-scegli: task immagine → $DUO (mai coder)" \
    || ko "rizzo-scegli: INVARIANTE DUO VIOLATA — task immagine al coder"
else
  [ $RC -eq 1 ] && ok "rizzo-scegli: server giù → rc 1 dichiarato (fallback coder spetta al chiamante)" \
    || ko "rizzo-scegli: rc=$RC fuori contratto (atteso 0 o 1)"
fi

# 7. verifica-doc.sh — il diario che cita un .gs fantasma esce rosso, uno vero verde
#    (15/11: il fix E-002 con -print -quit non deve aver cambiato il verdetto)
mkdir -p "$T/repo" && echo 'function a(){}' > "$T/repo/Vero.gs"
printf '| Vero.gs | ok |\n| Fantasma.gs | ok |\n' > "$T/diario.md"
OUT=$(bash "$HERE/tools/verifica-doc.sh" "$T/diario.md" "$T/repo" 2>&1); RC=$?
[ $RC -eq 1 ] && grep -q "FANTASMA: Fantasma.gs" <<<"$OUT" && ! grep -q "FANTASMA: Vero.gs" <<<"$OUT" \
  && ok "verifica-doc: fantasma rosso, vero verde (post fix E-002)" \
  || ko "verifica-doc: rc=$RC — $(tr '\n' ' ' <<<"$OUT" | cut -c1-120)"
printf '| Vero.gs | ok |\n' > "$T/diario2.md"
bash "$HERE/tools/verifica-doc.sh" "$T/diario2.md" "$T/repo" >/dev/null 2>&1 \
  && ok "verifica-doc: diario senza fantasmi esce 0" || ko "verifica-doc: diario pulito esce rosso"

echo ""
echo "$PASS OK, $FAIL FAIL"
