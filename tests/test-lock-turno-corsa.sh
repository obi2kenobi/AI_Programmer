#!/bin/bash
# test-lock-turno-corsa.sh — davanti a un lock ORFANO, due avvii insieme non lo prendono entrambi
# (2026-09-24, notte dei giri, T2#3). prendi_lock_turno (night-shift/lib.sh) faceva `rm -rf` + `mkdir`
# dopo aver giudicato orfano il lock: il secondo avvio poteva cancellare il lock APPENA preso dal primo
# e prendersene uno suo. Misurato dal giro T2: 32 doppie prese su 200 prove.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# il concorrente porta «night-shift» nel nome, come il turno vero: il lock di un vivo non si ruba
cat > "$T/night-shift-finto.sh" <<EOF2
source "$HERE/night-shift/lib.sh"
if prendi_lock_turno "\$1"; then echo "\$\$" >> "\$2"; sleep 0.3; fi
EOF2
N=${PROVE:-60}; DOPPIE=0
for i in $(seq 1 "$N"); do
  L="$T/lock-$i"; mkdir "$L"; echo 999999 > "$L/pid"   # orfano: un PID che non esiste
  : > "$T/presi-$i"
  bash "$T/night-shift-finto.sh" "$L" "$T/presi-$i" & A=$!
  bash "$T/night-shift-finto.sh" "$L" "$T/presi-$i" & B=$!
  wait "$A" "$B"
  [ "$(grep -c . "$T/presi-$i")" -gt 1 ] && DOPPIE=$((DOPPIE+1))
done
[ "$DOPPIE" -eq 0 ] && ok "lock orfano conteso da due avvii: mai preso da entrambi ($N prove)" \
  || ko "lock orfano preso da ENTRAMBI gli avvii in $DOPPIE prove su $N"

# un furto lasciato a meta' da un processo morto (<lock>.furto vecchio) non blocca per sempre
source "$HERE/night-shift/lib.sh"
L="$T/lock-furto"; mkdir "$L" "$L.furto"; echo 999999 > "$L/pid"; touch -d "5 minutes ago" "$L.furto" 2>/dev/null \
  || python3 -c "import os,sys,time; t=time.time()-300; os.utime(sys.argv[1],(t,t))" "$L.furto"
prendi_lock_turno "$L"; R1=$?; prendi_lock_turno "$L"; R2=$?
[ "$R2" -eq 0 ] && [ "$(cat "$L/pid")" = "$$" ] && [ ! -d "$L.furto" ] \
  && ok "un .furto vecchio si toglie e il lock orfano si prende (rc $R1 poi $R2)" || ko "furto vecchio: rc $R1/$R2, pid $(cat "$L/pid"), furto $([ -d "$L.furto" ] && echo resta)"
# un lock senza PID (versione di prima) oltre l'ora e' orfano
L="$T/lock-vecchio"; mkdir "$L"; python3 -c "import os,sys,time; t=time.time()-7200; os.utime(sys.argv[1],(t,t))" "$L"
prendi_lock_turno "$L" && [ "$(cat "$L/pid")" = "$$" ] && ok "lock senza PID di 2 ore: orfano, preso" || ko "lock senza PID di 2 ore non preso"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
