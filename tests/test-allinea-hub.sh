#!/bin/bash
# test-allinea-hub.sh — il self-pull del turno non butta il lavoro del giorno (2026-09-24, quinto ventaglio,
# R5 R1). Prima: a ogni ciclo, 24/7, `checkout main || true` e poi `reset --hard origin/HEAD` sulla copia
# installata. Una modifica non committata spariva; un commit non pushato su main usciva dalla storia; con il
# checkout fallito il reset colpiva il ramo del giorno (due commit fuori da ogni ramo). E il log diceva
# «Hub allineato a main». Ora: lo sporco va in uno stash, i commit fuori da origin in un ramo salvataggio/,
# il checkout fallito vuol dire niente reset — e ogni cosa messa da parte si dice coi numeri.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"
type allinea_hub >/dev/null 2>&1 && ok "allinea_hub e' definita in night-shift/lib.sh" \
  || { ko "allinea_hub non esiste"; echo ""; echo "$PASS OK, $FAIL FAIL"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_COUNT=3 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false \
  GIT_CONFIG_KEY_1=user.name GIT_CONFIG_VALUE_1=t GIT_CONFIG_KEY_2=user.email GIT_CONFIG_VALUE_2=t@t
nuovo() { # nuovo <nome>: remoto bare con un commit avanti rispetto all'hub clonato
  git init -q --bare -b main "$T/$1.git"; git clone -q "$T/$1.git" "$T/$1-seed" 2>/dev/null
  echo base > "$T/$1-seed/SAL.md"; git -C "$T/$1-seed" add -A; git -C "$T/$1-seed" commit -qm base; git -C "$T/$1-seed" push -q origin main
  git clone -q "$T/$1.git" "$T/$1"
  echo avanti > "$T/$1-seed/nuovo.txt"; git -C "$T/$1-seed" add -A; git -C "$T/$1-seed" commit -qm "remoto avanti"; git -C "$T/$1-seed" push -q origin main
}

# a) una modifica non committata: finisce in uno stash, non sparisce
nuovo a; echo "lavoro del giorno" >> "$T/a/SAL.md"
OUT=$(allinea_hub "$T/a" 2>&1)
git -C "$T/a" stash list | grep -c 'salvataggio turno' >/dev/null && git -C "$T/a" stash show -p stash@{0} | grep -c 'lavoro del giorno' >/dev/null \
  && ok "a) il file non committato e' in uno stash «salvataggio turno»" || ko "a) modifica non committata persa: $OUT"
[ -f "$T/a/nuovo.txt" ] && grep -c '1 file' <<<"$OUT" >/dev/null && ok "a) hub allineato al remoto, e detto quanti file sono stati messi da parte" || ko "a) uscita: $OUT"

# b) un commit non pushato su main: resta raggiungibile da un ramo salvataggio/
nuovo b; echo x > "$T/b/giorno.txt"; git -C "$T/b" add giorno.txt; git -C "$T/b" commit -qm "giorno non pushato"
OUT=$(allinea_hub "$T/b" 2>&1)
git -C "$T/b" log --all --format=%s | grep -cx 'giorno non pushato' >/dev/null && git -C "$T/b" branch --list 'salvataggio/*' | grep -c . >/dev/null \
  && ok "b) il commit non pushato resta in un ramo salvataggio/" || ko "b) commit non pushato perso: $OUT"

# d) sul ramo del giorno, e main non si puo' prendere (e' aperto in un altro worktree): prima il reset colpiva
# il ramo del giorno; ora niente reset, il ramo resta com'era, e il log non dice «allineato»
nuovo d; git -C "$T/d" checkout -q -b claude/y; echo y1 > "$T/d/x.sh"; git -C "$T/d" add x.sh; git -C "$T/d" commit -qm "giorno y1"
PRIMA=$(git -C "$T/d" rev-parse claude/y)
git -C "$T/d" worktree add -q "$T/d-wt" main 2>/dev/null
OUT=$(allinea_hub "$T/d" 2>&1); RC=$?
[ "$(git -C "$T/d" rev-parse claude/y)" = "$PRIMA" ] && [ "$RC" -ne 0 ] && ok "d) main non prendibile: niente reset, il ramo del giorno intatto (rc $RC)" || ko "d) claude/y spostato o rc 0: $OUT"
! grep -c 'hub allineato' <<<"$OUT" >/dev/null && ok "d) il log non dice «allineato» quando non lo e'" || ko "d) il log mente: $OUT"

# pulito: si allinea e basta
nuovo p; OUT=$(allinea_hub "$T/p" 2>&1); RC=$?
[ "$RC" -eq 0 ] && [ -f "$T/p/nuovo.txt" ] && ! grep -c salvat <<<"$OUT" >/dev/null && ok "copia pulita: allineata, niente da salvare" || ko "pulita: rc=$RC $OUT"

NS="$HERE/night-shift/night-shift.sh"
grep -c 'allinea_hub "$HERE"' "$NS" >/dev/null && ! grep -c 'reset -q --hard "$(git -C "$HERE" symbolic-ref' "$NS" >/dev/null \
  && ok "il turno si allinea con allinea_hub, non col reset nudo" || ko "il turno fa ancora il reset nudo"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
