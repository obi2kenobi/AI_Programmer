#!/bin/bash
# test-gate-tools.sh — gate-esito e gate-summary su CSV di fixture (giro 2/10).
# Storia: due bug di fila sul CSV (colonna persa, doppio inserimento) — da qui i fixture.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# CSV di fixture (prima il banco sovrascriveva il CSV REALE dell'hub e lo rimetteva con un trap)
REAL="$HERE/metrics/gate.csv"
# (2026-09-23, notte dei giri): il banco non deve nemmeno SCRIVERE il dato vero dell'hub — si
# fotografa la data di modifica all'inizio e si confronta alla fine
mtime_vero() { python3 -c 'import os,sys; print(os.stat(sys.argv[1]).st_mtime_ns if os.path.exists(sys.argv[1]) else "assente")' "$REAL"; }
MTIME_PRIMA=$(mtime_vero)
trap 'rm -rf "$TMP"' EXIT
# i tool lavorano sulla fixture via HUB_METRICS; il dato vero resta dov'e'
export HUB_METRICS="$TMP/gate.csv"

cat > "$HUB_METRICS" <<'CSV'
data,repo,pr,issue,verifiche,banco,esito
2026-08-20,REPO-A,#1,#1,verifiche-ok,eseguito:sopravvissuta,merge
2026-08-21,REPO-A,#2,#2,verifiche-ok,eseguito:smentita,commessa
2026-08-21,REPO-B,#3,#3,non-dichiarate,—,
CSV

# 1) gate-esito annota la riga APERTA
OUT=$(bash "$HERE/night-shift/gate-esito.sh" REPO-B 3 merge 2>&1 | head -1)
grep -q "esito registrato" <<<"$OUT" && ok "gate-esito registra l'ultima riga aperta" || ko "gate-esito: $OUT"
TAIL=$(tail -1 "$HUB_METRICS")
[ "$TAIL" = "2026-08-21,REPO-B,#3,#3,non-dichiarate,—,merge" ] && ok "gate-esito: settima colonna scritta, resto intatto" || ko "riga: $TAIL"

# 2) rifiuta il doppio inserimento (il bug storico)
OUT2=$(bash "$HERE/night-shift/gate-esito.sh" REPO-B 3 chiusura 2>&1 | head -1)
grep -q "già registrato" <<<"$OUT2" && ok "gate-esito rifiuta il doppio inserimento (bug storico chiuso)" || ko "doppio: $OUT2"

# 3) repo/PR ignota
OUT3=$(bash "$HERE/night-shift/gate-esito.sh" REPO-Z 99 merge 2>&1 | head -1)
grep -q "nessuna riga" <<<"$OUT3" && ok "gate-esito: ignota → nessuna riga" || ko "ignota: $OUT3"

# 4) esito non valido rifiutato
OUT4=$(bash "$HERE/night-shift/gate-esito.sh" REPO-A 1 pippo 2>&1 | head -1)
grep -q "non valido" <<<"$OUT4" && ok "gate-esito: esito fuori vocabolario rifiutato" || ko "vocabolario: $OUT4"

# 5) summary conta giusto sul fixture
SUM=$(bash "$HERE/night-shift/gate-summary.sh" 0)
grep -q "3 righe, 2 repo" <<<"$SUM" && ok "summary: 3 righe, 2 repo" || ko "conteggio: $(grep 'righe' <<<"$SUM")"
grep -q "1 merge · 0 chiusure · 1 commesse" <<<"$SUM" && ok "summary: esiti umani giusti" || ko "esiti umani"
grep -q "AREA FRAGILE" <<<"$SUM" && ko "area fragile scatta già a 1 commessa (soglia ≥2)" || ok "summary: soglia area-fragile ≥2 rispettata"
grep -q "smentite banco: 1 (50%)" <<<"$SUM" && ok "summary: % smentite per-repo (REPO-A: 1/2 = 50%)" || ko "percentuali: $(grep smentite <<<"$SUM" | head -1)"

# 6) aging: la riga di REPO-A #2 ha esito → nessuna attesa con dati freschi
# (audit-2): il doppio-ok passava qualunque stato — ora l'attesa e' DETtata dal
# csv: con la riga di REPO-A #2 APERTA, l'aging DEVE esserci
if grep -q ",aperta," "$TMP/gate.csv" 2>/dev/null || grep -qE ",[0-9]+," <(grep -vc "chiusa" "$TMP/gate.csv" 2>/dev/null); then
  grep -q " aging" <<<"$SUM" && ok "summary: aging presente con righe aperte (dettato dal dato)" || ko "righe aperte ma nessun aging nel summary"
else
  grep -q " aging" <<<"$SUM" && ko "aging mostrato senza righe aperte" || ok "summary: nessun aging, tutte chiuse — coerente col dato"
fi

# (2026-09-23): il digest del mattino incorpora questo riepilogo ogni giorno, intestato alla data
# di OGGI — con un registro fermo da un mese (il gate e' in pensione) i dati vecchi sembravano
# freschi. L'intestazione dice l'ultima riga e, oltre 7 giorni, che il registro e' STORICO.
SUM=$(bash "$HERE/night-shift/gate-summary.sh" 0)
grep -q "ultima riga 2026-08-21" <<<"$SUM" && grep -q "STORICO" <<<"$SUM" \
  && ok "gate-summary dice l'eta' del registro (ultima riga, STORICO oltre 7 giorni)" \
  || ko "gate-summary presenta dati di un mese fa come freschi: $(head -1 <<<"$SUM")"
[ "$(mtime_vero)" = "$MTIME_PRIMA" ] && ok "il metrics/gate.csv vero dell'hub non e' stato scritto dal banco" \
  || ko "il banco ha scritto metrics/gate.csv vero (fixture al posto del dato: un SIGKILL la lascerebbe li')"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
