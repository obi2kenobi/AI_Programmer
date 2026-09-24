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

# ambiente isolato (revisione 10 giri, 2026-09-23): prima il test SPOSTAVA il PRESIDI.md vivo
# dell'hub — le presenze delle altre sessioni sparivano finche' girava. Ora lavora su un clone
# in quarantena: il tool scrive il PRESIDI.md accanto a se', cioe' nel clone.
QT=$(mktemp -d /tmp/test-presidio.XXXXXX); trap 'rm -rf "$QT"' EXIT
git clone -q --local "$HERE" "$QT/hub" 2>/dev/null || { ko "clone di quarantena fallito"; echo "$PASS OK, $FAIL FAIL"; exit 1; }
rm -f "$QT/hub/PRESIDI.md"
# il clone parte dal COMMIT: lo strumento sotto prova si porta dal working tree, o una
# mutazione di tools/presidio.sh non arriverebbe mai qui (il banco mutazioni l'ha visto: TEATRO)
cp "$HERE/tools/presidio.sh" "$QT/hub/tools/presidio.sh"
TOOL="$QT/hub/tools/presidio.sh"
HERE="$QT/hub"

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
grep -q "potati 1" <<<"$OUT" && ok "presidio scaduto: potato E dichiarato" || ko "potatura non dichiarata"
# grep -c esce 1 quando conta ZERO: con pipefail la pipeline fallisce proprio
# quando l'asserzione è vera — si usa ! grep -q, che esce 0 sul non-trovato
! grep -q "| bob |" "$HERE/PRESIDI.md" && ok "lo scaduto non resta nel registro" || ko "scaduto sopravvissuto"

# rilascio: chiude solo il proprio (lo giudica la lista: dal 2026-09-24 il rilascio e' una riga appesa)
PRESIDIO_USER=alice bash "$TOOL" rilascia oracoli >/dev/null 2>&1
OUT=$(bash "$TOOL" lista 2>/dev/null)
! grep -c "| alice | oracoli" <<<"$OUT" >/dev/null && ok "rilascio: il proprio presidio chiuso" || ko "rilascio non funzionante: $OUT"
# (2026-09-24, terzo ventaglio, V3): il rilascio cancellava la riga — un file che si riscrive non e'
# append-only, e ne' la skill lavoro-condiviso ne' il gitattributes lo sapevano
PRESIDIO_USER=alice bash "$TOOL" claim oracoli "di nuovo" >/dev/null 2>&1
OUT=$(bash "$TOOL" lista 2>/dev/null)
grep -c "| alice | oracoli | .* | di nuovo |" <<<"$OUT" >/dev/null && ok "un claim dopo il rilascio e' vivo" || ko "claim dopo il rilascio non vivo: $OUT"
cp "$HERE/PRESIDI.md" "$QT/prima-del-rilascio"; PRESIDIO_USER=alice bash "$TOOL" rilascia oracoli >/dev/null 2>&1
[ "$(head -n "$(wc -l < "$QT/prima-del-rilascio")" "$HERE/PRESIDI.md")" = "$(cat "$QT/prima-del-rilascio")" ] \
  && ok "il rilascio non riscrive il registro: appende" || ko "il rilascio ha riscritto righe esistenti del registro"

# UNION con un merge VERO (revisione 10 giri): prima il python «simulava» il merge, stampava
# union-ok/union-persa e nessuno leggeva il verdetto (stampava union-persa e il test era verde).
# Due cloni appendono una presenza ciascuno, si fondono: nessuna riga persa, nessun conflitto.
U="$QT/union"; mkdir -p "$U/base/tools"
cp "$HERE/tools/presidio.sh" "$U/base/tools/"; grep "PRESIDI.md" "$HERE/.gitattributes" > "$U/base/.gitattributes"
G="git -c user.name=t -c user.email=t@t"
( cd "$U/base" && git init -q -b main . && $G add -A && $G commit -qm base ) >/dev/null 2>&1
git clone -q "$U/base" "$U/a" && git clone -q "$U/base" "$U/b"
( cd "$U/a" && PRESIDIO_USER=alice bash tools/presidio.sh claim zona-x prima >/dev/null 2>&1 && $G add PRESIDI.md && $G commit -qm a ) >/dev/null 2>&1
( cd "$U/b" && PRESIDIO_USER=bob bash tools/presidio.sh claim zona-y seconda >/dev/null 2>&1 && $G add PRESIDI.md && $G commit -qm b ) >/dev/null 2>&1
( cd "$U/a" && $G pull -q --no-rebase --no-edit "$U/b" main ) >/dev/null 2>&1; RC_M=$?
[ "$RC_M" -eq 0 ] && grep -q "| alice | zona-x" "$U/a/PRESIDI.md" && grep -q "| bob | zona-y" "$U/a/PRESIDI.md" && ! grep -q '^<<<<<<<' "$U/a/PRESIDI.md" \
  && ok "merge vero di due cloni: entrambe le presenze, zero conflitti (union)" \
  || ko "merge union: rc=$RC_M, $(grep -c '|' "$U/a/PRESIDI.md" 2>/dev/null) righe, conflitti: $(grep -c '^<<<<<<<' "$U/a/PRESIDI.md" 2>/dev/null)"
# il rilascio attraverso il merge: in a si rilascia l'ULTIMA riga (bob, zona-y), in b alice appende
# zona-z subito dopo, si fondono. Prima il merge union riportava in vita la riga cancellata, e la lista
# la contava viva (riprodotto: le due modifiche toccano lo stesso punto del file, e union le tiene tutte).
( cd "$U/b" && $G pull -q --no-rebase --no-edit "$U/a" main ) >/dev/null 2>&1
( cd "$U/a" && PRESIDIO_USER=bob bash tools/presidio.sh rilascia zona-y >/dev/null 2>&1 && $G commit -qam ril ) >/dev/null 2>&1
( cd "$U/b" && PRESIDIO_USER=alice bash tools/presidio.sh claim zona-z terza >/dev/null 2>&1 && $G commit -qam z ) >/dev/null 2>&1
( cd "$U/a" && $G pull -q --no-rebase --no-edit "$U/b" main ) >/dev/null 2>&1; RC_M=$?
OUT=$(cd "$U/a" && bash tools/presidio.sh lista 2>/dev/null)
[ "$RC_M" -eq 0 ] && ! grep -c "| bob | zona-y" <<<"$OUT" >/dev/null && grep -c "| alice | zona-z" <<<"$OUT" >/dev/null \
  && ok "merge dopo un rilascio: il presidio rilasciato resta chiuso, quello nuovo c'e'" \
  || ko "merge dopo un rilascio (rc=$RC_M): il rilasciato e' risorto o il nuovo e' perso: $OUT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
