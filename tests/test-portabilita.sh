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

# (2026-09-24, terzo ventaglio, V1#4): dentro `$( )`, un heredoc seguito sulla stessa riga da una
# redirezione E da un operatore (`<<'X' 2>/dev/null || true`) e' un errore di sintassi A RUNTIME su bash
# 5.2 — `bash -n` passa. L'auto-esame dell'hub moriva li' ogni notte, in silenzio, e saltava fixer, banco,
# censore e caccia. La premessa si misura qui; nel codice, il delimitatore chiude la riga.
printf 'X=$(cd / && python3 - <<%sE%s 2>/dev/null || true\nprint(1)\nE\n)\n' "'" "'" > "${TMPDIR:-/tmp}/premessa-heredoc.$$"
if grep -c "syntax error" <<<"$(bash "${TMPDIR:-/tmp}/premessa-heredoc.$$" 2>&1)" >/dev/null; then   # non in pipe: sotto pipefail il rc 1 di bash la renderebbe falsa
  ok "premessa: su questa bash ($BASH_VERSION) la forma rompe davvero a runtime"
else
  ok "premessa: su questa bash ($BASH_VERSION) la forma non rompe — il cricchetto resta, perche' su 5.2 si'"
fi
rm -f "${TMPDIR:-/tmp}/premessa-heredoc.$$"
# (2026-09-24, sesto ventaglio, S5 R2): era `S=$(python3 - $FILES <<'PYHD' … PYHD )` — la bash 3.2 del Mac non
# analizza un heredoc con apici e parentesi sbilanciati DENTRO $( ): il banco intero usciva rc 2 («unexpected
# EOF»), e la lente della portabilita' non girava proprio sul Mac. L'heredoc sta fuori, l'uscita in un file.
USCITA_PY=$(mktemp)
python3 - $FILES > "$USCITA_PY" <<'PYHD'
import re, sys
# dentro $( … ) sulla stessa riga: <<[-] DELIMITATORE (anche fra apici) seguito da qualcosa che non e' nulla
pat = re.compile(r"""(?<!\\)\$\([^)]*<<-?\s*(['"]?)([A-Za-z_]\w*)\1(.*)$""")   # \$( e' testo, non una sostituzione
for f in sys.argv[1:]:
    if "/tests/" in f: continue
    for n, riga in enumerate(open(f, errors="ignore"), 1):
        if riga.lstrip().startswith("#"): continue
        m = pat.search(riga.rstrip("\n"))
        if m and m.group(3).strip():
            print(f"{f}:{n}:{riga.strip()[:120]}")
PYHD
S=$(cat "$USCITA_PY"); rm -f "$USCITA_PY"
[ -z "$S" ] && ok "nessun heredoc dentro \$( ) con altro dopo il delimitatore (errore a runtime su bash 5.2)" || ko "heredoc in \$( ) con redirezione/operatore dopo il delimitatore:"$'\n'"$S"

# (2026-09-24, sesto ventaglio, S5 R2): nessuno lanciava `bash -n` con la bash del Mac — questo stesso banco non si
# analizzava con la 3.2 e nessuno lo vedeva. Ogni script del repo si analizza con /bin/bash (sul Mac e' la 3.2.57) e
# con la bash di BASH_MAC, se c'e' (una 3.2 compilata, per provarlo fuori dal Mac).
ROTTI=""
for B in /bin/bash ${BASH_MAC:-}; do
  [ -x "$B" ] || continue
  for f in "$HERE"/tests/*.sh "$HERE"/tools/*.sh "$HERE"/night-shift/*.sh "$HERE"/llm/*.sh "$HERE"/.githooks/*; do
    "$B" -n "$f" 2>/dev/null || ROTTI="$ROTTI ${f#"$HERE"/}($("$B" -c 'echo $BASH_VERSION' | cut -d. -f1-2))"
  done
done
[ -z "$ROTTI" ] && ok "S5 R2: ogni script si analizza con /bin/bash$([ -n "${BASH_MAC:-}" ] && echo " e con $BASH_MAC")" || ko "S5 R2: script che la bash non analizza:$ROTTI"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
