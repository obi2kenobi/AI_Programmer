#!/bin/bash
# test-verifica-profonda.sh — la suite profonda gira UNA volta al giorno, non a
# ogni ciclo (2026-10-02, giro di velocita'): il ciclo non paga 25 minuti per lo
# stesso albero, e un rosso non si martella. Il blocco si estrae dal turno vero
# (pattern del banco del grafo) e gira su una mini-repo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

T=$(mktemp -d /tmp/test-profonda.XXXXXX); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/repo" "$T/work" "$T/hub/night-shift"
printf 'true\n' > "$T/repo/.night-verify"
printf '@10 sleep 0.1\nfalse\n' > "$T/repo/.night-verify-profonda"

# il blocco profonda, estratto dal turno
BLOCCO=$(sed -n '/la verifica PROFONDA (.night-verify-profonda/,/^    # (2026-09-25, D17/p' "$HERE/night-shift/night-shift.sh" | sed '$d')
[ -n "$BLOCCO" ] && ok "blocco profonda trovato nel turno" || { ko "blocco non trovato"; echo "$PASS OK, $FAIL FAIL"; exit 1; }
printf '%s\n' '#!/bin/bash' 'set -uo pipefail' "source $(printf %q "$HERE/night-shift/lib.sh")" 'log() { echo "LOG: $*"; }' \
  "DIR=$(printf %q "$T/repo")" "REPO=pippo/x" "WORK=$(printf %q "$T/work")" "$BLOCCO" > "$T/ciclo.sh"

bash "$T/ciclo.sh" > "$T/out1" 2>&1
grep -q 'verifica profonda girata (1x al giorno)' "$T/out1" && ok "primo ciclo: la profonda gira e lo dice" || ko "primo ciclo: $(cat "$T/out1")"
N_ROSSI_PROF=$(grep -c 'LOG: REPO pippo/x: VERIFICA ROSSA (profonda): false' "$T/out1" 2>/dev/null || true)
[ "${N_ROSSI_PROF:-0}" -eq 1 ] && ok "il rosso della profonda e' dichiarato" || ko "rosso non dichiarato: $(cat "$T/out1")"
ls "$T/work/.profonda-pippo_x-"* >/dev/null 2>&1 && ok "il marker del giorno e' scritto (anche col rosso)" || ko "marker mancante"

# secondo ciclo nello stesso giorno: NON gira
N_PRIMA=$(grep -c 'VERIFICA ROSSA (profonda)' "$T/out1")
bash "$T/ciclo.sh" > "$T/out2" 2>&1
SECONDE=$(grep -c 'verifica profonda girata' "$T/out2" || true)
[ "${SECONDE:-0}" -eq 0 ] && ok "secondo ciclo: la profonda non si ripete" || ko "la profonda e' girata DUE volte nello stesso giorno"
grep -q 'LOG: REPO pippo/x: .night-verify (formato script)' "$T/out2" || true   # il per-cycle non e' qui: ok

# giorno dopo: il marker del giorno manca → riparte (si simula togliendo quello di oggi)
rm -f "$T/work/.profonda-pippo_x-$(date +%F)"
bash "$T/ciclo.sh" > "$T/out3" 2>&1
grep -q 'verifica profonda girata' "$T/out3" && ok "giorno nuovo (marker assente): la profonda riparte" || ko "giorno nuovo non riparte: $(head -3 "$T/out3")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
