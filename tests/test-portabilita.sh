#!/bin/bash
# test-portabilita.sh — la lente della portabilita' (test del sistema completo 2026-09-20,
# D22). Il sistema nasce sul Mac ma gira ANCHE nelle sessioni cloud (Linux, bash 5): li'
# `stat -f %m` non esiste (ogni lock e cooldown risultava «scaduto»), `sed -i ''` legge ''
# come script (i siti rinviati non venivano mai depennati), `date -v` non esiste (tre attese
# di un test cadevano per il calendario), e `${#ARR[@]:-0}` e' una «bad substitution» su
# bash >= 4 (ciclo-vivo moriva: 0 finding per un crash). Ogni forma BSD/mac-only negli
# script e nei test deve avere accanto la sua alternativa o passare da un helper portabile.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# la lente non guarda se stessa: i suoi pattern contengono le forme che cerca
FILES=$(ls "$HERE"/night-shift/*.sh "$HERE"/tools/*.sh "$HERE"/tests/*.sh "$HERE"/llm/*.sh "$HERE"/.githooks/* 2>/dev/null | grep -v '/test-portabilita.sh$')
# righe di CODICE (non commenti) che contengono la forma
righe_con() { # $1=pattern grep -E
  grep -nE "$1" $FILES 2>/dev/null | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#' || true
}

# stat -f %m: ammesso SOLO dentro mtime() di lib.sh (che ha il fallback GNU accanto)
S=$(righe_con 'stat -f %m' | grep -v 'night-shift/lib.sh:' || true)
[ -z "$S" ] && ok "stat -f %m solo dentro mtime() di lib.sh" || ko "stat -f %m nudo (Linux: ogni eta' = adesso):"$'\n'"$S"
grep -q 'stat -c %Y' "$HERE/night-shift/lib.sh" && ok "mtime() ha il fallback GNU (stat -c %Y)" || ko "mtime() senza fallback GNU"

# sed -i '': mai nudo (GNU sed lo legge come script)
S=$(righe_con "sed -i '' " || true)
[ -z "$S" ] && ok "nessun sed -i '' nudo (usare sedi/suffisso attaccato o file temporaneo)" || ko "sed -i '' BSD-only:"$'\n'"$S"

# date -v: solo con un'alternativa GNU sulla stessa riga (|| date -d …) o via python3
S=$(righe_con 'date -v' | grep -v 'date -d' || true)
[ -z "$S" ] && ok "nessun date -v senza alternativa GNU" || ko "date -v BSD-only:"$'\n'"$S"

# ${#ARR[@]:-0}: bad substitution su bash >= 4
S=$(righe_con '\$\{#[A-Za-z_]+\[@\]:-' || true)
[ -z "$S" ] && ok "nessuna forma \${#ARR[@]:-0} (bad substitution su bash 4+)" || ko "bad substitution latente:"$'\n'"$S"

# md5 nudo (macOS): su Linux esiste solo md5sum — ammesso solo nei file che provano `command -v md5`
S=$(righe_con '(\||xargs) *md5\b' | grep -v 'md5sum' | while IFS= read -r R; do F=${R%%:*}; grep -q 'command -v md5' "$F" || echo "$R"; done)
[ -z "$S" ] && ok "nessun md5 nudo senza fallback (Linux: solo md5sum)" || ko "md5 mac-only senza fallback (impronta vuota, confronto sempre vero):"$'\n'"$S"

# timeout(1) nudo: macOS non lo ha (la suite del 21/9 era rossa sul Mac per «command not found») — si usa ai_timeout
S=$(righe_con '(^|[ (;&|=])timeout [0-9]' | grep -v 'ai_timeout' | grep -v 'tools/test-modelli-notturni.sh:' || true)
[ -z "$S" ] && ok "nessun timeout(1) nudo (macOS: solo ai_timeout di llm/_timeout.sh)" || ko "timeout nudo, assente su macOS:"$'\n'"$S"

# la forma portabile e' eseguibile qui, su questa bash
source "$HERE/night-shift/lib.sh"
T=$(mktemp); M=$(mtime "$T"); rm -f "$T"
[ "$M" -gt 1700000000 ] 2>/dev/null && ok "mtime() restituisce un epoch vero su questa macchina ($M)" || ko "mtime() rotto qui: '$M'"
mtime /nonesiste/xyz >/dev/null 2>&1 && ko "mtime() su file assente dovrebbe tornare 1" || ok "mtime() su file assente torna 1 (il chiamante decide)"


# grep -P: il grep di macOS (BSD) non ce l'ha — "invalid option", il controllo muore
# zitto e il finding passa per verde (E-037: teatro di parser). \d → [0-9] con -E,
# \r → $'\r' letterale, range unicode → perl -CSD. git grep -P e' un altro binario: lecito.
S=$(righe_con 'grep -[a-zA-Z]*P[a-zA-Z]* ' | grep -vE 'git (grep|-C)' || true)
[ -z "$S" ] && ok "nessun grep -P nudo (BSD: invalid option, il controllo muore zitto)" || ko "grep -P non portabile (E-037):"$'\n'"$S"

# realpath --relative-to / readlink -f: GNU (revisione 10 giri, 2026-09-23 — risolvi-issue.sh
# mandava al modello il path ASSOLUTO sul Mac). La via portabile e' os.path di python3.
S=$(righe_con 'realpath --relative-to|readlink -f ' || true)
[ -z "$S" ] && ok "nessun realpath --relative-to / readlink -f (GNU): python3 os.path" || ko "path GNU-only:"$'\n'"$S"

# (2026-09-23, notte dei giri, T3#3): il sed del Mac non e' «enhanced» — `\s` `\w` `\b` dentro
# un'espressione sed valgono lettere letterali, e il flag `I` della sostituzione e' «bad flag». Su
# morning-gate.sh il motivo NON-VERIFICABILE usciva vuoto o intero. Le classi POSIX valgono ovunque.
S=$(righe_con "sed [^|]*\\\\[sSwWb]|sed [^|]*s/[^/]*/[^/]*/[a-zA-Z]*I" || true)
[ -z "$S" ] && ok "nessun \\s/\\w/\\b o flag I in un'espressione sed (BSD sed: letterali o «bad flag»)" || ko "sed GNU-only:"$'\n'"$S"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
