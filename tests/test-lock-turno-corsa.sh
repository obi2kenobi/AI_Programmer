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
# (V4#3, 2026-09-24): le prove sono indipendenti (un lock ciascuna): a lotti di 20 in parallelo — da 21 s a
# pochi secondi, stesso giudizio (sabotato il rigiudizio del furto, resta rosso)
for i in $(seq 1 "$N"); do
  L="$T/lock-$i"; mkdir "$L"; echo 999999 > "$L/pid"   # orfano: un PID che non esiste
  : > "$T/presi-$i"
  bash "$T/night-shift-finto.sh" "$L" "$T/presi-$i" &
  bash "$T/night-shift-finto.sh" "$L" "$T/presi-$i" &
  [ $((i % 20)) -eq 0 ] && wait
done
wait
for i in $(seq 1 "$N"); do [ "$(grep -c . "$T/presi-$i")" -gt 1 ] && DOPPIE=$((DOPPIE+1)); done
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

# (T2#4): il lock PER REPO di night-shift.sh contava l'eta' (12 h): dopo un kill -9 il turno riavviato
# prendeva il lock globale e poi saltava la repo scrivendo «lock attivo di un altro turno» — falso, per
# 12 ore. Ora e' la stessa regola del PID: il blocco usa prendi_lock_turno.
BLOCCO=$(sed -n '/local LOCK="\$WORK\/.lock-/,/trap .* RETURN/p' "$HERE/night-shift/night-shift.sh")
grep -c 'prendi_lock_turno "\$LOCK"' <<<"$BLOCCO" >/dev/null && ! grep -c '43200' <<<"$BLOCCO" >/dev/null \
  && ok "il lock per repo segue il PID (prendi_lock_turno), non l'eta' di 12 h" || ko "il lock per repo conta ancora l'eta': $(grep -m1 -E 'mkdir|43200' <<<"$BLOCCO")"
# dopo un kill -9 (PID morto) il turno riavviato prende il lock della repo subito
L="$T/lock-repo"; mkdir "$L"; echo 999999 > "$L/pid"
prendi_lock_turno "$L" && ok "lock per repo lasciato da un turno ucciso: ripreso subito" || ko "lock per repo di un turno ucciso non ripreso"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
