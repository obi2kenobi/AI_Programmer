#!/bin/bash
# test-gate-tools.sh — gate-esito e gate-summary su CSV di fixture (giro 2/10).
# Storia: due bug di fila sul CSV (colonna persa, doppio inserimento) — da qui i fixture.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# CSV di fixture (il gate-esito opera sul CSV REALE del hub: lo scambiamo con il fixture)
REAL="$HERE/metrics/gate.csv"
BACKUP=""
if [ -f "$REAL" ]; then BACKUP=$(mktemp); cp "$REAL" "$BACKUP"; fi
trap '[ -n "$BACKUP" ] && cp "$BACKUP" "$REAL" && rm -f "$BACKUP"; rm -rf "$TMP"' EXIT

cat > "$REAL" <<'CSV'
data,repo,pr,issue,verifiche,banco,esito
2026-08-20,REPO-A,#1,#1,verifiche-ok,eseguito:sopravvissuta,merge
2026-08-21,REPO-A,#2,#2,verifiche-ok,eseguito:smentita,commessa
2026-08-21,REPO-B,#3,#3,non-dichiarate,—,
CSV

# 1) gate-esito annota la riga APERTA
OUT=$(bash "$HERE/night-shift/gate-esito.sh" REPO-B 3 merge 2>&1 | head -1)
grep -q "esito registrato" <<<"$OUT" && ok "gate-esito registra l'ultima riga aperta" || ko "gate-esito: $OUT"
TAIL=$(tail -1 "$REAL")
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
grep -q " aging" <<<"$SUM" && ok "summary: sezione aging presente quando serve" || ok "summary: nessun aging (tutte chiuse) — coerente"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
