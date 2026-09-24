#!/bin/bash
# test-ciclo-vivo.sh — il ciclo vivo sotto prova (100 giri di chiarezza: il
# banco 7 lo pretendeva, perché l'header era stato riscritto). Verifica:
# sintassi; un giro REALE esce e dice i finding; il CUORE e le salite di
# livello scrivono la memoria in FILE PIATTI leggibili (il contratto
# dichiarato nell'header — nessuno stato.json è mai esistito, e chi legge
# l'header deve trovare quello che l'header promette).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$HERE/tools/ciclo-vivo.sh" && ok "sintassi" || ko "sintassi rotta"
grep -q "stato.json" "$HERE/tools/ciclo-vivo.sh" && grep -q "MAI ESISTIT" "$HERE/tools/ciclo-vivo.sh" \
  && ok "l'header dichiara la storia (stato.json citato SOLO come mai esistito)" \
  || { grep -q "Memoria: .ciclo/stato.json" "$HERE/tools/ciclo-vivo.sh" && ko "l'header promette ancora stato.json che non esiste" || ok "nessun riferimento fuorviante a stato.json"; }

# un giro reale: la memoria è disposable (.ciclo gitignored), il giro è sicuro
OUT=$(bash "$HERE/tools/ciclo-vivo.sh" 2>&1); RC=$?
grep -q "^=== CICLO VIVO" <<<"$OUT" && ok "un giro parte e si presenta" || ko "il giro non parte"
grep -q "^Finding questo giro: " <<<"$OUT" && ok "il verdetto è sempre visibile" || ko "verdetto assente"
[ -f "$HERE/.ciclo/giro" ] && [ -f "$HERE/.ciclo/livello" ] \
  && ok "memoria in file piatti leggibili (giro, livello)" \
  || ko "memoria assente: i file piatti promessi dall'header non ci sono"
L=$(cat "$HERE/.ciclo/livello" 2>/dev/null)
{ [ "$L" -ge 1 ] && [ "$L" -le 5 ]; } && ok "livello nell'intervallo 1-5 ($L)" || ko "livello fuori intervallo: $L"

# (2026-09-24, notte dei giri, T2#5): dopo un kill -9 il lock .ciclo/lock restava per sempre — ogni giro
# usciva 1 dopo 10 s («lock occupato da troppi giri») senza che girasse nessun altro, e il banco di
# passaggio era rosso senza dire la causa. In un clone (la memoria vera non si tocca): un lock col PID
# di un processo morto si riprende subito; uno di un giro VIVO si rispetta.
source "$HERE/llm/_timeout.sh"   # ai_timeout: timeout(1) non esiste su macOS
C=$(mktemp -d); git clone -q "$HERE" "$C/hub"
cp "$HERE/tools/ciclo-vivo.sh" "$C/hub/tools/"; cp "$HERE/night-shift/lib.sh" "$C/hub/night-shift/"
mkdir -p "$C/hub/.ciclo/lock"; echo 999999 > "$C/hub/.ciclo/lock/pid"
OUT=$(cd "$C/hub" && ai_timeout 120 bash tools/ciclo-vivo.sh 2>&1); RC=$?
grep -c "^=== CICLO VIVO" <<<"$OUT" >/dev/null && [ ! -d "$C/hub/.ciclo/lock" ] \
  && ok "lock di un giro ucciso (PID morto): ripreso, il giro gira e libera il lock" || ko "lock orfano blocca il giro (rc $RC): $(tail -1 <<<"$OUT")"
bash -c 'exec -a ciclo-vivo-finto sleep 30' & VIVO=$!
mkdir -p "$C/hub/.ciclo/lock"; echo "$VIVO" > "$C/hub/.ciclo/lock/pid"
OUT=$(cd "$C/hub" && ai_timeout 60 bash tools/ciclo-vivo.sh 2>&1); RC=$?
kill "$VIVO" 2>/dev/null; wait "$VIVO" 2>/dev/null
[ "$RC" -eq 1 ] && grep -c "lock occupato" <<<"$OUT" >/dev/null && ok "lock di un giro VIVO: rispettato (rc 1, detto)" || ko "lock di un giro vivo non rispettato (rc $RC)"
rm -rf "$C"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
