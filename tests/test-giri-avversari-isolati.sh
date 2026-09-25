#!/bin/bash
# test-giri-avversari-isolati.sh — la batteria d'attacchi non si pesta i piedi e non sporca l'albero
# (2026-09-23, notte dei giri, T2#1). tools/giri-avversari.sh mutava l'ALBERO VERO (un'ancora rotta, un
# tools/test.py, un file tolto…) e usava 20 percorsi fissi /tmp/avv-*: due batterie insieme sullo stesso
# albero davano 8 AGGIRA falsi, due in cloni diversi 1 (una si riprendeva il file dell'altra da /tmp), e un
# kill -9 a meta' lasciava gli attacchi nel repo. tools/banco-passaggio.sh promette «due banchi
# sovrapposti non si calpestano» e chiama proprio questa batteria.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d)
# (2026-09-24, terzo ventaglio, V4#4): ogni giro del banco lasciava in /tmp il clone della batteria uccisa
# (14 MB) e le cartelle delle altre: TMPDIR dentro la cartella del banco, e la pulizia toglie tutto
# (2026-09-24, sesto ventaglio, S3 R5): con lo spazio — la batteria che misura le difese si misurava solo sui percorsi
# piani, e con un TMPDIR ostile dava 6 AGGIRA falsi e TIENE per attacchi mai partiti
mkdir -p "$T/tmp spazio"; export TMPDIR="$T/tmp spazio"
PIDS=()
pulisci() { for p in ${PIDS[@]+"${PIDS[@]}"}; do kill -9 -- "-$p" 2>/dev/null; done; sleep 1; rm -rf "$T"; }
trap pulisci EXIT
g() { git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null "$@"; }

# 0. (E-044, 2026-09-24): la pulizia della batteria cancella SOLO la cartella che si e' data. Un mio
# sabotaggio (AVVT=/tmp) con la pulizia nuda `rm -rf "$AVVT"` ha svuotato /tmp intera. Ogni riga che
# cancella $AVVT deve portare la guardia del nome, e la guardia deve lasciare stare una cartella altrui.
RIGHE=$(grep -E 'rm -rf "?\$AVVT' "$HERE/tools/giri-avversari.sh")
NUDE=$(grep -vE 'case "\$AVVT" in \*/giri-avversari\.\?\?\?\?\?\?\)' <<<"$RIGHE" || true)
[ -n "$RIGHE" ] && [ -z "$NUDE" ] && ok "ogni rm -rf di \$AVVT porta la guardia del nome" || ko "rm -rf di \$AVVT senza guardia: ${NUDE:-nessuna riga di pulizia}"
mkdir -p "$T/altrui" "$T/giri-avversari.abcdef"; touch "$T/altrui/vivo" "$T/giri-avversari.abcdef/x"
while IFS= read -r R; do AVVT="$T/altrui"; eval "$R"; AVVT="$T/giri-avversari.abcdef"; eval "$R"; done <<<"$RIGHE"
[ -f "$T/altrui/vivo" ] && [ ! -d "$T/giri-avversari.abcdef" ] && ok "la pulizia lascia una cartella altrui e toglie la propria" \
  || ko "pulizia sbagliata: altrui $([ -f "$T/altrui/vivo" ] && echo intatta || echo CANCELLATA), propria $([ -d "$T/giri-avversari.abcdef" ] && echo rimasta || echo tolta)"

# un hub usa e getta con la batteria di QUESTO albero (non quella di HEAD)
git clone -q "$HERE" "$T/hub"
cp "$HERE/tools/giri-avversari.sh" "$T/hub/tools/giri-avversari.sh"
g -C "$T/hub" commit -qam "batteria in prova" >/dev/null 2>&1 || true

# 1. due batterie INSIEME sullo stesso albero: nessun AGGIRA falso
# (V4#4): `( … setsid … ) &` metteva in PIDS la subshell, non il capo della sessione nuova: la pulizia
# uccideva un gruppo che non era quello delle batterie. Ora `$!` e' il capo della sessione.
# (2026-09-24, sesto ventaglio, S5 R1): `setsid` sul Mac non c'e' — le batterie non partivano e il banco era rosso.
# Una sessione nuova (un gruppo di processi da uccidere intero) anche con perl, che il Mac ha.
# `exec`: lanciata con `&` la funzione gira in una subshell, e $! deve essere il capo della sessione (V4#4)
# (rinviati di S3 R6): il percorso del clone arriva a bash -c come argomento, non fra apici: un apice in $TMPDIR
# spezzava il comando, e le batterie non partivano.
sessione_nuova() { if command -v setsid >/dev/null 2>&1; then exec setsid "$@"; else exec perl -e 'setpgrp(0,0); exec @ARGV or die "exec: $!"' "$@"; fi; }
sessione_nuova bash -c 'cd "$1" && exec bash tools/giri-avversari.sh' _ "$T/hub" > "$T/a.out" 2>&1 & PIDS+=($!)
sessione_nuova bash -c 'cd "$1" && exec bash tools/giri-avversari.sh' _ "$T/hub" > "$T/b.out" 2>&1 & PIDS+=($!)
wait
for x in a b; do
  V=$(grep -m1 '^VERDETTO:' "$T/$x.out")
  [ "$V" = "VERDETTO: 0 aggirati non riconosciuti" ] && ok "batteria $x in parallelo: $V" \
    || ko "batteria $x in parallelo: ${V:-nessun verdetto} — $(grep '^AGGIRA' "$T/$x.out" | head -3 | tr '\n' ' ')"
done
[ -z "$(git -C "$T/hub" status --porcelain)" ] && ok "dopo due batterie l'albero e' pulito" || ko "albero sporco dopo due batterie: $(git -C "$T/hub" status --porcelain | head -3 | tr '\n' ' ')"

# 2. kill -9 a meta': l'albero resta pulito
sessione_nuova bash -c 'cd "$1" && exec bash tools/giri-avversari.sh' _ "$T/hub" > "$T/k.out" 2>&1 & KP=$!; PIDS+=($KP)
SPORCO=""
for i in $(seq 1 40); do
  sleep 0.25
  [ -n "$(git -C "$T/hub" status --porcelain)" ] && { SPORCO=$(git -C "$T/hub" status --porcelain | head -2 | tr '\n' ' '); break; }
done
{ kill -9 -- "-$KP"; wait "$KP"; } 2>/dev/null; sleep 1   # il GRUPPO: anche la batteria nel clone
[ -z "$SPORCO" ] && [ -z "$(git -C "$T/hub" status --porcelain)" ] \
  && ok "durante la batteria e dopo un kill -9 l'albero resta pulito" || ko "la batteria scrive nell'albero: ${SPORCO:-$(git -C "$T/hub" status --porcelain | head -2 | tr '\n' ' ')}"
# (V4#4): il clone della batteria uccisa sta DENTRO la cartella del banco (lo toglie la pulizia), non in /tmp
[ -n "$(find "$TMPDIR" -mindepth 2 -maxdepth 2 -name hub -type d 2>/dev/null | head -1)" ] \
  && ok "il clone della batteria uccisa resta nella cartella del banco, non in /tmp" || ko "il clone della batteria uccisa non e' sotto \$TMPDIR del banco: finisce in /tmp"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
