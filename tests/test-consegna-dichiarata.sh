#!/bin/bash
# test-consegna-dichiarata.sh — nel commit del turno entrano le modifiche e i file NUOVI DICHIARATI, non
# ogni file che si trova nella copia (2026-09-24, notte dei giri, T5#2b). I punti di consegna dove
# scrive night-shift/agente.sh facevano `git add -A`: un file «di passaggio» nuovo (ad es. con dati
# letti) entrava nel commit e nel push. Ora agente.sh dichiara ogni file che crea con `write`, e
# aggiungi_consegna (night-shift/lib.sh) aggiunge solo quelli, dicendo nel log cosa lascia fuori.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null -c commit.gpgsign=false "$@"; }
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"

R="$T/r"; mkdir -p "$R"; g -C "$R" init -q -b main
echo "uno" > "$R/a.js"; g -C "$R" add -A; g -C "$R" commit -qm base

command -v aggiungi_consegna >/dev/null || { ko "aggiungi_consegna non esiste in night-shift/lib.sh"; echo; echo "$PASS OK, $FAIL FAIL"; exit 1; }
echo "due" >> "$R/a.js"                                    # modifica a un file tracciato
echo "test nuovo" > "$R/nuovo.test.js"                     # nuovo, dichiarato dall'agente
dichiara_file_nuovo "$R" nuovo.test.js
echo "dati letti di passaggio" > "$R/note-debug.txt"       # nuovo, NON dichiarato
echo "test generato" > "$R/generato.sh"                    # nuovo, dichiarato dal chiamante
OUT=$(aggiungi_consegna "$R" generato.sh 2>&1)
IDX=$(git -C "$R" diff --cached --name-only | sort | tr '\n' ' ')
[ "$IDX" = "a.js generato.sh nuovo.test.js " ] && ok "nel commit: la modifica e i due file dichiarati ($IDX)" || ko "nell'indice: '$IDX'"
grep -c "note-debug.txt" <<<"$OUT" >/dev/null && ok "il file non dichiarato resta fuori, e il log lo dice" || ko "file non dichiarato taciuto: $OUT"
[ ! -s "$(git -C "$R" rev-parse --absolute-git-dir)/agente-file-nuovi" ] && ok "la dichiarazione si consuma con la consegna" || ko "la dichiarazione resta per la consegna dopo"
SPOSTATO=$(find "$R/.git/consegna-fuori" -name note-debug.txt 2>/dev/null | head -1)
[ ! -e "$R/note-debug.txt" ] && [ -n "$SPOSTATO" ] && [ "$(cat "$SPOSTATO")" = "dati letti di passaggio" ] \
  && ok "il file escluso si sposta dentro .git (mai cancellato) e non ricompare alla consegna dopo" || ko "file escluso: in copia $([ -e "$R/note-debug.txt" ] && echo resta || echo tolto), in .git ${SPOSTATO:-assente}"

# i punti di consegna che seguono agente.sh usano aggiungi_consegna, non git add -A
NS="$HERE/night-shift/night-shift.sh"
grep -c 'ERR_CONSEGNA=$(cd "$DIR" && aggiungi_consegna' "$NS" >/dev/null && ok "consegna della caccia: aggiungi_consegna" || ko "consegna della caccia: ancora git add -A"
grep -cE 'aggiungi_consegna "\$DIR" .*TEST_FILE' "$NS" >/dev/null && ok "consegna della cascata solver→agente: aggiungi_consegna col test generato" || ko "consegna della cascata: ancora git add -A"
grep -c "grep 'NON dichiarato' <<<\"\$ERR_CONSEGNA\" | while IFS= read -r l; do log" "$NS" >/dev/null && ok "caccia: cio' che resta fuori va nel log anche quando la consegna riesce" || ko "caccia: l'esclusione si perde nella variabile d'errore"
grep -cE 'aggiungi_consegna "\$DIR" .*\| while IFS= read -r l; do log' "$NS" >/dev/null && ok "cascata: cio' che resta fuori va nel log" || ko "cascata: l'esclusione non arriva al log"
grep -c 'dichiara_file_nuovo' "$HERE/night-shift/agente.sh" >/dev/null && ok "agente.sh dichiara i file che crea" || ko "agente.sh non dichiara i file che crea"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
