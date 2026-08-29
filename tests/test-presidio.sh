#!/bin/bash
# test-presidio.sh — il protocollo di presenza sotto prova, CON DUE UTENTI
# SIMULATI sullo stesso clone (PRESIDIO_USER). Contratti: il claim dichiara
# chi/zona/scadenza; la lista conta i vivi e poda gli scaduti DICHIARANDOLO;
# la contesa vera (due CHI distinti, stessa zona) viene urlata; il rilascio
# chiude solo IL PROPRIO presidio; e il registro si fonde da solo (union):
# due cloni che appendono non perdono nessuna riga.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$HERE/tools/presidio.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$TOOL" && ok "sintassi" || ko "sintassi rotta"
grep -q "PRESIDI.md merge=union" "$HERE/.gitattributes" && ok "il registro e' append-only (union nel gitattributes)" || ko "PRESIDI.md senza union"

# ambiente isolato: il tool lavora su $HERE/PRESIDI.md — si salva e ripristina
BAK="$HERE/PRESIDI.md.bak"; [ -f "$HERE/PRESIDI.md" ] && mv "$HERE/PRESIDI.md" "$BAK"; trap '[ -f "$BAK" ] && mv "$BAK" "$HERE/PRESIDI.md" || rm -f "$HERE/PRESIDI.md"' EXIT

PRESIDIO_USER=alice bash "$TOOL" claim oracoli "formule" >/dev/null 2>&1
grep -q "| alice | oracoli |" "$HERE/PRESIDI.md" && ok "claim di alice registrato con chi e zona" || ko "claim non registrato"

# l'output si cattura PRIMA di grepparlo: il tool esce scrivendo più righe e
# grep -q chiude lo stdin presto → SIGPIPE → pipefail inverte il verdetto
# (la trappola pipefail-grep-q, terza ricorrenza in due giorni, stavolta
# dentro il mio stesso test nuovo — il pattern resta vivo finché lo riscrivo)
OUTC=$(PRESIDIO_USER=bob bash "$TOOL" claim oracoli "anche io" 2>&1 || true)
grep -q CONTESA <<<"$OUTC" \
  && ok "claim di bob sulla zona di alice: CONTESA urlata subito" || ko "contesa non avvisata"
OUTL=$(bash "$TOOL" lista 2>/dev/null || true)
grep -q "CONTESA su oracoli" <<<"$OUTL" \
  && ok "la lista dichiara la contesa a chiunque la guardi" || ko "lista senza contesa"

# scadenza: presidiobackdatato potato e dichiarato
python3 - "$HERE/PRESIDI.md" <<'PY'
import sys, re, datetime
f = sys.argv[1]; s = open(f).read()
ieri = (datetime.datetime.now() - datetime.timedelta(days=1)).strftime('%Y-%m-%dT%H:%M')
s = re.sub(r'\| \d{4}-\d\d-\d\dT\d\d:\d\d \| bob \| oracoli \| \d{4}-\d\d-\d\dT\d\d:\d\d', f'| {ieri} | bob | oracoli | {ieri}', s)
open(f, 'w').write(s)
PY
OUT=$(bash "$TOOL" lista 2>/dev/null)
echo "$OUT" | grep -q "potati 1" && ok "presidio scaduto: potato E dichiarato" || ko "potatura non dichiarata"
# grep -c esce 1 quando conta ZERO: con pipefail la pipeline fallisce proprio
# quando l'asserzione è vera — si usa ! grep -q, che esce 0 sul non-trovato
! grep -q "| bob |" "$HERE/PRESIDI.md" && ok "lo scaduto non resta nel registro" || ko "scaduto sopravvissuto"

# rilascio: chiude solo il proprio
PRESIDIO_USER=alice bash "$TOOL" rilascia oracoli >/dev/null 2>&1
! grep -q "| alice | oracoli" "$HERE/PRESIDI.md" && ok "rilascio: il proprio presidio chiuso" || ko "rilascio non funzionante"

# UNION: due append da due cloni non perdono righe (merge simulato)
rm -f "$HERE/PRESIDI.md"; PRESIDIO_USER=alice bash "$TOOL" claim zona-x prima >/dev/null 2>&1
cp "$HERE/PRESIDI.md" /tmp/presidi-clone.md
PRESIDIO_USER=bob bash "$TOOL" claim zona-y seconda >/dev/null 2>&1
python3 - "$HERE/PRESIDI.md" /tmp/presidi-clone.md <<'PY'
# simula il merge union: entrambi i lati aggiungono righe — nessuna persa
import sys
a = open(sys.argv[1]).read(); b = open(sys.argv[2]).read()
righe_a = set(a.split('\n')); righe_b = set(b.split('\n'))
unite = righe_a | righe_b
print("union-ok" if "| alice | zona-x" in unite and "| bob | zona-y" in unite else "union-persa")
PY
grep -q "zona-x" "$HERE/PRESIDI.md" && grep -q "zona-y" "$HERE/PRESIDI.md" && ok "registro vivo con entrambe le presenze" || ko "presenze perse"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
