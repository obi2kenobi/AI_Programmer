#!/bin/bash
# test-grafo-notturno.sh — il pass semantico del grafo, una volta al giorno in background (2026-09-24, sesto ventaglio,
# S4 R6). Il segno «fatto oggi» si scriveva PRIMA del pass, e il lock non aveva il PID: un turno ucciso a meta' pass
# lasciava segno e lock, e il pass mancava in silenzio fino a 24 ore. Qui il blocco vero di night-shift.sh gira con un
# grafo-semantico finto (lento) e un graphify finto; il pass si uccide per PID, e il ciclo dopo deve ripartire.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'kill $(cat "$T/work/.lock-grafo/pid" 2>/dev/null) 2>/dev/null; rm -rf "$T"' EXIT
mkdir -p "$T/hub/night-shift" "$T/hub/tools" "$T/bin" "$T/work"
printf '#!/bin/bash\nsleep 20\necho pass-finito\n' > "$T/hub/tools/grafo-semantico.sh"
printf '#!/bin/bash\nexit 0\n' > "$T/bin/graphify"; chmod +x "$T/bin/graphify"
BLOCCO=$(sed -n '/^GRAFO_DATA=/,/^log "=== TURNO INIZIATO/p' "$HERE/night-shift/night-shift.sh" | sed '$d')
[ -n "$BLOCCO" ] || { ko "blocco del grafo non trovato in night-shift.sh"; echo "$PASS OK, $FAIL FAIL"; exit 1; }
# (sesto ventaglio, rinviati di S3 R6): i percorsi entrano nello script quotati con %q, non fra apici
# (un apice in $TMPDIR o nel percorso dell'hub spezzava la riga).
printf '%s\n' '#!/bin/bash' 'set -uo pipefail' "source $(printf %q "$HERE/night-shift/lib.sh")" 'log() { echo "LOG: $*"; }' \
  "HERE=$(printf %q "$T/hub/night-shift"); WORK=$(printf %q "$T/work"); REPO_LIST=(); MODEL_TAG=x" "$BLOCCO" > "$T/night-shift-ciclo.sh"
# l'uscita va su file: con $( ) la sostituzione aspetterebbe la fine del pass in background (tiene la pipe)
ciclo() { PATH="$T/bin:$PATH" bash "$T/night-shift-ciclo.sh" > "$T/out.$1" 2>&1; cat "$T/out.$1"; }
OUT1=$(ciclo 1); sleep 1
grep -c 'avviato in background' <<<"$OUT1" >/dev/null && ok "ciclo 1: il pass parte" || ko "ciclo 1: il pass non parte: $OUT1"
[ ! -f "$T/work/.grafo-$(date +%F)" ] && ok "il segno del giorno NON c'e' mentre il pass gira" || ko "il segno del giorno si scrive prima del pass"
P=$(cat "$T/work/.lock-grafo/pid" 2>/dev/null)
[ -n "$P" ] && kill -0 "$P" 2>/dev/null && ok "il lock porta il PID del pass ($P)" || ko "il lock non ha un PID vivo: «${P}»"
# (2026-09-25, settimo ventaglio, V5 R2; E-049): prima si fermava il padre con STOP. Uccisi prima i figli, la subshell del
# pass restava viva un attimo e scriveva il segno del giorno: rosso a caso (6 su 19 sotto carico). Con una pausa di
# mezzo secondo fra i due colpi era rosso sempre (3 su 3), con lo STOP davanti mai (0 su 3).
[ -n "$P" ] && { kill -STOP "$P" 2>/dev/null; pkill -KILL -P "$P" 2>/dev/null; kill -KILL "$P" 2>/dev/null; }; sleep 1
OUT2=$(ciclo 2); sleep 1
grep -c 'avviato in background' <<<"$OUT2" >/dev/null && grep -ci 'morto' <<<"$OUT2" >/dev/null \
  && ok "pass ucciso a meta': il ciclo dopo toglie il lock morto, lo dice, e riparte" || ko "pass ucciso: il ciclo dopo non riparte: $OUT2"
OUT3=$(ciclo 3)
! grep -c 'avviato in background' <<<"$OUT3" >/dev/null && ! grep -ci 'morto' <<<"$OUT3" >/dev/null \
  && ok "pass vivo: il ciclo dopo non lo tocca e non ne avvia un secondo" || ko "pass vivo trattato da morto: $OUT3"
# (2026-09-25, settimo ventaglio, V3 R3): un lock oltre le 24 ore si toglieva anche col pass VIVO — due extract sulla
# stessa copia, e il primo a finire toglieva il lock del secondo. E il messaggio leggeva il PID dopo averlo cancellato
# («PID ?»). Ora il PID vivo tiene il lock a qualunque eta', e il turno lo dice. Qui il pass del ciclo 3 e' vivo.
python3 -c 'import os,sys,time; t=time.time()-25*3600; os.utime(sys.argv[1],(t,t))' "$T/work/.lock-grafo"
OUT4=$(ciclo 4)
! grep -c 'avviato in background' <<<"$OUT4" >/dev/null && ! grep -ci 'rimosso' <<<"$OUT4" >/dev/null && grep -c 'oltre 24' <<<"$OUT4" >/dev/null \
  && ok "V3 R3: pass vivo da oltre 24 ore: il lock resta, nessun secondo pass, e lo dice" || ko "V3 R3: pass vivo oltre 24h: $(grep LOG <<<"$OUT4" | head -2 | tr '\n' ' ')"
# (2026-09-25, D25, risposta delegata): un pass che FALLISCE non lascia il segno del giorno — al primo fallimento resta un
# segno «tentato» e il ciclo dopo riprova; al secondo il giorno si chiude, e il log lo dice. Qui il pass finto esce 1.
printf '#!/bin/bash\necho pass-rotto; exit 1\n' > "$T/hub/tools/grafo-semantico.sh"
P=$(cat "$T/work/.lock-grafo/pid" 2>/dev/null); [ -n "$P" ] && { kill -STOP "$P" 2>/dev/null; pkill -KILL -P "$P" 2>/dev/null; kill -KILL "$P" 2>/dev/null; }
rm -rf "$T/work/.lock-grafo" "$T/work/.grafo-"*
fine_pass() { for _ in $(seq 1 50); do [ -d "$T/work/.lock-grafo" ] || return 0; sleep 0.2; done; return 1; }
ciclo 5 >/dev/null; fine_pass
[ ! -f "$T/work/.grafo-$(date +%F)" ] && [ -f "$T/work/.grafo-tentato-$(date +%F)" ] \
  && ok "D25: pass fallito: niente segno del giorno, resta il «tentato»" || ko "D25: pass fallito lascia il segno del giorno: $(ls -a "$T/work" | tr '\n' ' ')"
OUT6=$(ciclo 6); fine_pass
grep -c 'avviato in background' <<<"$OUT6" >/dev/null && [ -f "$T/work/.grafo-$(date +%F)" ] && grep -ci 'fallito due volte' "$T/work/grafo-semantico.log" >/dev/null \
  && ok "D25: secondo tentativo, fallito anche lui: il giorno si chiude e il log lo dice" || ko "D25: secondo tentativo: $(tail -2 "$T/work/grafo-semantico.log" | tr '\n' ' ')"
OUT7=$(ciclo 7)
! grep -c 'avviato in background' <<<"$OUT7" >/dev/null && ok "D25: dopo due fallimenti niente terzo pass nello stesso giorno" || ko "D25: terzo pass avviato"
# E-049 (guardia): chi uccide un albero di processi ferma il padre con STOP prima di ucciderne i figli. Figli prima:
# il padre vivo un attimo prosegue (qui scriveva il segno del giorno). Padre prima: i figli restano orfani.
NUDI=$(grep -n 'pkill -KILL -P "\$[A-Za-z_]*"' "$HERE"/tests/*.sh "$HERE/tools/mutation-tests.sh" | grep -v ':[[:space:]]*#' \
  | grep -v 'kill -STOP "\$[A-Za-z_]*" 2>/dev/null; pkill -KILL -P' || true)
[ -z "$NUDI" ] && ok "E-049: ogni pkill -KILL -P ha lo STOP al padre davanti" || ko "E-049: albero ucciso senza STOP al padre: $NUDI"
echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
