#!/bin/bash
# giri-ignoranti.sh — la batteria delle sonde IGNORANTI: le domande che farebbe
# uno straniero scortese, senza rispetto per le convenzioni del repo. Nata dai
# 100 giri ignoranti del 2026-08-28, che hanno trovato ciò che le lenti educate
# non vedevano: caratteri alieni nei testi, numeri claims marciti, oracoli che
# muoiono di traceback, documenti porta-d'ingresso mai linkati, flag
# implementati ma non documentati nell'uso.
#
# Ogni sonda è deterministica e riporta una riga. Esce 1 se c'è almeno un
# finding: il verdetto è sempre sull'ultima riga.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
FINDINGS=0
sonda() { # sonda <esito 0|1> <descrizione>
  if [ "$1" -eq 0 ]; then echo "OK   $2"
  else echo "FIND $2"; FINDINGS=$((FINDINGS+1)); fi
}

# S1 — caratteri alieni: nessun CJK/cirillico/arabo nei testi tracciati
#   (classe reale: due corruzioni trovate, una in SAL-ARCHIVIO e una scritta
#   da un agente stesso — entrambe parole italiane con glifi CJK in mezzo)
ALIENI=$(git -C "$HERE" grep -lP '[\x{4E00}-\x{9FFF}\x{0400}-\x{04FF}\x{0600}-\x{06FF}]' \
  -- '*.md' '*.sh' '*.py' 2>/dev/null | grep -v SAL-ARCHIVIO.md || true)
[ -z "$ALIENI" ] && sonda 0 "S1 nessun carattere alieno nei testi" || sonda 1 "S1 caratteri alieni: $ALIENI"

# S2 — numeri claims vs realtà: ogni "<N> test|pattern|agenti" nei doc di testa
#   deve corrispondere ai file veri (i numeri nei doc marciscono in silenzio)
check_numero() { # check_numero <file> <claim-regex> <reale>
  local file="$1" rx="$2" reale="$3" trovato
  trovato=$(grep -oE "[0-9]+ $rx" "$file" 2>/dev/null | grep -oE '^[0-9]+' | sort -u | tail -1)
  [ -z "$trovato" ] && return 0   # nessun claim numerico: niente da verificare
  [ "$trovato" = "$reale" ]
}
N_TEST=$(ls "$HERE"/tests/test-*.sh 2>/dev/null | wc -l | tr -d ' ')
N_PAT=$(ls "$HERE"/patterns/*.md 2>/dev/null | grep -v README | wc -l | tr -d ' ')
N_AG=$(ls "$HERE"/.claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
check_numero "$HERE/README.md" "test" "$N_TEST" \
  && check_numero "$HERE/README.md" "pattern" "$N_PAT" \
  && check_numero "$HERE/README.md" "agenti\?" "$N_AG" \
  && check_numero "$HERE/AGENTS.md" "test" "$N_TEST" \
  && check_numero "$HERE/AGENTS.md" "pattern" "$N_PAT" \
  && sonda 0 "S2 numeri claims coerenti (test=$N_TEST pattern=$N_PAT agenti=$N_AG)" \
  || sonda 1 "S2 numero claim marcio (reale: test=$N_TEST pattern=$N_PAT agenti=$N_AG)"

# S3 — nessun oracolo muore di Traceback con input assente/spazzatura:
#   la famiglia dice "uso:", il traceback nudo è per gli umani una sparatoria
TB=0
for f in "$HERE"/tools/*.py; do
  OUT=$(python3 "$f" </dev/null 2>&1 & PID=$!; sleep 0.9; kill $PID 2>/dev/null; wait $PID 2>/dev/null)
  echo "$OUT" | grep -q "Traceback" && { echo "     · $(basename "$f"): traceback con input assente"; TB=1; }
done
# caso header spazzatura per i tool CSV a stdin
OUT=$(printf 'a,b\n1,x\n' | python3 "$HERE/tools/scadenzario_aging.py" 2>&1)
echo "$OUT" | grep -q "Traceback" && { echo "     · scadenzario_aging: traceback con header spazzatura"; TB=1; }
[ "$TB" -eq 0 ] && sonda 0 "S3 nessun oracolo muore di traceback su input spazzatura" || sonda 1 "S3 traceback nudi su input spazzatura"

# S4 — docs di radice orfani: ogni docs/*.md deve essere citato da qualche altro
#   file (un documento che nessuno linka è una porta che non porta da nessuna parte)
ORFANI=""
for d in "$HERE"/docs/*.md; do
  b=$(basename "$d")
  [ "$b" = "README.md" ] && continue
  # grep -c . conta le righe NON vuote (grep -v -c . conterebbe quelle vuote: sempre 0)
  CITE=$(git -C "$HERE" grep -lF "$b" -- '*.md' '*.sh' 2>/dev/null | grep -vc "^docs/$b" || true)
  [ "${CITE:-0}" -eq 0 ] && ORFANI="$ORFANI $b"
done
[ -z "$ORFANI" ] && sonda 0 "S4 nessun doc di radice orfano" || sonda 1 "S4 doc mai citati:$ORFANI"

# S5 — i flag implementati sono documentati nell'uso: per ogni `--parola)` in un
#   case, l'intestazione del tool deve citarla (il benvenuto insegnava --standard
#   che lo script non documentava: il novizio fidati dell'uso e sbaglia)
FLAG=0
for s in "$HERE"/tools/*.sh; do
  while IFS= read -r fl; do
    [ -z "$fl" ] && continue
    head -30 "$s" | grep -q -- "$fl" || { echo "     · $(basename "$s"): $fl implementato ma non nell'uso"; FLAG=1; }
  done < <(grep -oE '^\s+--[a-z-]+\)' "$s" | tr -d ' \)' | sort -u)
done
[ "$FLAG" -eq 0 ] && sonda 0 "S5 ogni flag implementato è documentato nell'uso" || sonda 1 "S5 flag implementati non documentati"

# S6 — i path `così` citati nel README esistono davvero (la porta d'ingresso non
#   può puntare a porte inesistenti)
ROTTO=""
while IFS= read -r ref; do
  [ -e "$HERE/$ref" ] || ROTTO="$ROTTO $ref"
done < <(grep -oE '`(docs|tools|patterns|night-shift|llm|tests)/[A-Za-z0-9_./-]+`' "$HERE/README.md" | tr -d '`' | sort -u)
[ -z "$ROTTO" ] && sonda 0 "S6 tutti i path citati nel README esistono" || sonda 1 "S6 path citati nel README inesistenti:$ROTTO"

echo ""
echo "VERDETTO: $FINDINGS finding"
[ "$FINDINGS" -eq 0 ]
