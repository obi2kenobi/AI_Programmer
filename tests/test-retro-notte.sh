#!/bin/bash
# test-retro-notte.sh — il banco della retrospettiva notturna (2026-10-08, furto
# dichiarato dalla skill /retro di M. Pocock: il COME del lavoro, non il cosa).
# Presidia: lo scavo conta GIUSTO (data scope), le guardie si dicono (con registro
# / senza / vittoria), le regole in prosa si censisco dal canone VERO dell'hub.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
TMP=$(mktemp -d "${TMPDIR:-/tmp}/retro-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

DATA=2026-10-08
ALTRO=2026-09-01
LOG="$TMP/fixture.log"
{
  printf '[%s 01:00:00] Territorio: /x/Dashboard.html risolto per nome in apps-script/Dashboard.html\n' "$DATA"
  printf '[%s 02:00:00] Territorio: /x/Codice.gs risolto per nome in apps-script/Codice.gs\n' "$DATA"
  printf '[%s 03:00:00] REPO x: [revisore] nessun file del Territorio letto (Dashboard.html)\n' "$DATA"
  printf '[%s 04:00:00] REPO x: DELIBERA: RIGETTA PR #1 — verdetto ripescato da JSON rotto\n' "$DATA"
  printf '[%s 04:00:01] REPO x: DELIBERA: RIGETTA PR #2 — verdetto ripescato da JSON rotto\n' "$DATA"
  printf '[%s 04:00:02] REPO x: DELIBERA: RIGETTA PR #3 — verdetto ripescato da JSON rotto\n' "$DATA"
  printf '[%s 05:00:00] Issue #9: anche l'"'"'agente non ha converto (rc=1)\n' "$DATA"
  # righe di ALTRO giorno: NON contano
  printf '[%s 23:00:00] ⚠ issue #7: WATCHDOG scattato a 5min\n' "$ALTRO"
  printf '[%s 23:30:00] REPO x: censore non ha risposto in JSON\n' "$ALTRO"
} > "$LOG"

OUT=$(RETRO_LOG="$LOG" bash "$HERE/tools/retro-notte.sh" "$DATA" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "la retro gira pulita sul log di fixture" || ko "rc=$RC"

grep -q "PER NOME (il percorso dichiarato non bastava): 2" <<<"$OUT" \
  && ok "navigazione: 2 territori trovati per nome" || ko "fallback contato male: $(grep -m1 'per NOME' <<<"$OUT")"
grep -q "irrisolto, run spescata: 1\|irrisolto, run sprecata: 1" <<<"$OUT" \
  && ok "navigazione: 1 territorio irrisolto" || ko "irrisolto contato male"
grep -q "3 × «verdetto ripescato»" <<<"$OUT" \
  && ok "la guardia attiva conta come VINCITA (3 ripescaggi)" || ko "ripescaggi contati male"
# (2026-10-08, controllo generale): E-059 ha registrato «non-converge» — la firma
# ora dice «con voce»: il meccanismo si prova su un gap VERO ancora aperto (territorio)
grep -qE "1 × «anche l'agente non ha converto» — (con voce|\*\*SENZA voce)" <<<"$OUT" \
  && ok "la firma dell'agente si classifica (registro vivo: oggi «con voce», E-059)" \
  || ko "la firma dell agente non appare"
grep -qE "2 × «risolto per nome in» — (con voce|\*\*SENZA voce)" <<<"$OUT" \
  && ok "ogni firma viene classificata contro il registro (il lato segue il registro VIVO)" \
  || ko "la firma territorio non e classificata"
grep -q "WATCHDOG scattato" <<<"$OUT" \
  && ko "una firma di ALTRO giorno e stata contata (scope della data rotto)" \
  || ok "le firme di altri giorni non contano (scope per data)"
grep -q "non ha risposto in JSON" <<<"$OUT" \
  && ko "il censore non-JSON di altro giorno e nel report" \
  || ok "il censore di altro giorno non inquina"

# le regole: dal canone VERO dell'hub (deterministico nel repo)
grep -qE "Regole censite: [0-9]+ · con cancello mappato: [0-9]+ · candidate: [0-9]+" <<<"$OUT" \
  && ok "le regole in prosa si censisco (censite/mappate/candidate)" || ko "manca il conteggio regole"
N_CENSITE=$(grep -oE "Regole censite: [0-9]+" <<<"$OUT" | grep -oE "[0-9]+" | head -1)
[ "${N_CENSITE:-0}" -ge 40 ] && ok "il canone e ricco: $N_CENSITE regole censite" || ko "troppo poche regole censite: $N_CENSITE"
grep -q "può diventare cancello?" <<<"$OUT" \
  && ok "le candidate si domandano ad alta voce" || ko "le candidate non sono elencate"

echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
