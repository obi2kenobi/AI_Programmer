#!/bin/bash
# test-caccia-lente.sh — ogni lente di night-shift/caccia-lente.sh esegue il comando INTERO (2026-09-24,
# notte dei giri, T6#2). Le lenti sono «nome|comando|parole», e il comando contiene a sua volta una pipe
# (`… | tail -25`): `cut -d'|' -f2` lo tagliava alla prima, e quattro lenti su cinque giravano senza il
# loro filtro — il modello leggeva le prime 50 righe invece delle ultime 25. Le parole da cercare
# (terzo campo) finivano nel filtro, e non erano usate da nessuno.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# un hub finto: la lente «sonde» (rotazione 0) chiama tools/giri-ignoranti.sh, qui un finto da 60 righe
mkdir -p "$T/hub/night-shift" "$T/hub/tools" "$T/progetto"
cp "$HERE/night-shift/caccia-lente.sh" "$T/hub/night-shift/"
printf '#!/bin/bash\nfor i in $(seq 1 60); do echo "riga $i"; done\n' > "$T/hub/tools/giri-ignoranti.sh"
echo 0 > "$T/hub/.caccia-rotazione"
OUT=$(NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" 2>&1)
# (sesto ventaglio, rinviati di S3 R6): la lente scrive il percorso quotato con %q (S3 R4); il banco lo cerca uguale.
grep -cF "comando: bash $(printf %q "$T/hub")/tools/giri-ignoranti.sh 2>&1 | tail -25" <<<"$OUT" >/dev/null \
  && ok "la lente esegue il comando intero, pipe interna compresa" || ko "comando tagliato: $(grep -m1 'comando:' <<<"$OUT")"
ATTESO=$(for i in $(seq 36 60); do echo "riga $i"; done | wc -c | tr -d ' ')
grep -cE "\\(($ATTESO|$((ATTESO-1))) bytes" <<<"$OUT" >/dev/null && ok "il modello riceve le ultime 25 righe ($ATTESO byte)" \
  || ko "il modello riceve altro: $(grep -m1 'bytes' <<<"$OUT")"
grep -cF "parole-spia: FIND finding" <<<"$OUT" >/dev/null && ok "le parole da cercare sono quelle dichiarate (terzo campo)" \
  || ko "parole da cercare sbagliate o mai usate: $(grep -m1 'parole' <<<"$OUT")"

# (2026-09-24, terzo ventaglio, V1#6): con il modello muto la lente usciva 1, lo stesso codice di «sana»,
# e il turno scriveva «lente dichiara il sistema sano» e il cooldown della salute. Muta ha il suo codice (3)
# e il turno la dice per quello che e'.
NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 3 ] && ok "modello muto: la lente esce 3, non 1 (sana)" || ko "modello muto: rc=$RC (1 = sana: il muto passa per salute)"
NS="$HERE/night-shift/night-shift.sh"
grep -c '"$CACCIA_RC" -eq 3' "$NS" >/dev/null && grep -c 'LENTE MUTA' "$NS" >/dev/null \
  && ok "il turno ha un ramo per la lente muta (rc 3), distinto da «sana»" || ko "il turno non distingue la lente muta"

# (2026-09-24, quarto ventaglio, Q3 R2): altre due strade portavano ancora a 1 (sana) — lo strumento morto
# senza output, e il modello che risponde 200 con il verdetto vuoto.
printf '#!/bin/bash\nexit 127\n' > "$T/hub/tools/giri-ignoranti.sh"; echo 0 > "$T/hub/.caccia-rotazione"
NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 3 ] && ok "strumento senza output: la lente e' muta (rc 3), non sana" || ko "strumento senza output: rc=$RC"
printf '#!/bin/bash\necho "FIND finding"\n' > "$T/hub/tools/giri-ignoranti.sh"; echo 0 > "$T/hub/.caccia-rotazione"
mkdir -p "$T/bin"; printf '#!/bin/bash\ncat >/dev/null; echo %s\n' "'{\"message\":{\"content\":\"\"}}'" > "$T/bin/curl"; chmod +x "$T/bin/curl"
PATH="$T/bin:$PATH" bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 3 ] && ok "verdetto vuoto (200 senza contenuto): muta (rc 3), non sana" || ko "verdetto vuoto: rc=$RC"
grep -c '"$CACCIA_RC" -eq 2' "$NS" >/dev/null && ok "il turno ha un ramo per la cartella assente (rc 2), non la salute" || ko "rc 2 cade nella salute"

# (2026-09-25, settimo ventaglio, V2 R1): lo strumento dice il suo verdetto nell'rc (giri-ignoranti esce 1 con almeno un
# finding), ma la lente lo guardava solo per 126/127: un «NO» del modello faceva «sistema sano», e il turno apriva la
# finestra delle migliorie su codice appena dichiarato malato. Scelta provvisoria (DEBITI, V2 D1): il verdetto
# deterministico e' il pavimento — il modello non puo' dire «sano» sopra un rc di finding.
printf '#!/bin/bash\ncat >/dev/null; echo %s\n' "'{\"message\":{\"content\":\"1. NO\"}}'" > "$T/bin/curl"; chmod +x "$T/bin/curl"
printf '#!/bin/bash\necho "sonda 2: FINDING grep -c muto"; exit 1\n' > "$T/hub/tools/giri-ignoranti.sh"; echo 0 > "$T/hub/.caccia-rotazione"
OUT=$(PATH="$T/bin:$PATH" bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -c 'vince lo strumento' <<<"$OUT" >/dev/null && ok "V2 R1: strumento rc 1 e modello «NO»: problemi (rc 0), e lo dice" \
  || ko "V2 R1: strumento rc 1 e modello «NO»: rc=$RC ($(grep -m1 'sano\|PROBLEMI' <<<"$OUT"))"
printf '#!/bin/bash\necho "tutto ok"; exit 0\n' > "$T/hub/tools/giri-ignoranti.sh"; echo 0 > "$T/hub/.caccia-rotazione"
PATH="$T/bin:$PATH" bash "$T/hub/night-shift/caccia-lente.sh" "$T/progetto" >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] && ok "strumento rc 0 e modello «NO»: sana (invariato)" || ko "strumento rc 0 e modello «NO»: rc=$RC"

# (2026-09-24, sesto ventaglio, S3 R4): le lenti erano stringhe con $HERE nudo, eseguite con eval — in un percorso
# con lo spazio lo strumento non girava («Is a directory», rc 126) e il modello leggeva quell'errore: poteva dire
# «sistema sano». Ora il percorso e' quotato, e uno strumento che non gira (rc 126/127) e' una lente MUTA.
mkdir -p "$T/hub con spazio/night-shift" "$T/hub con spazio/tools"
cp "$HERE/night-shift/caccia-lente.sh" "$T/hub con spazio/night-shift/"
printf '#!/bin/bash\nfor i in $(seq 1 60); do echo "riga $i"; done\n' > "$T/hub con spazio/tools/giri-ignoranti.sh"; echo 0 > "$T/hub con spazio/.caccia-rotazione"
OUT=$(NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$T/hub con spazio/night-shift/caccia-lente.sh" "$T/progetto" 2>&1)
grep -cE "\(($ATTESO|$((ATTESO-1))) bytes" <<<"$OUT" >/dev/null && ok "S3 R4: con lo spazio nel percorso lo strumento gira e il modello riceve le sue 25 righe" \
  || ko "S3 R4: col percorso con lo spazio il modello riceve altro: $(grep -m1 'bytes\|TOOL' <<<"$OUT")"
rm -f "$T/hub con spazio/tools/giri-ignoranti.sh"; echo 0 > "$T/hub con spazio/.caccia-rotazione"
OUT=$(NIGHT_API_URL=http://127.0.0.1:9/api/chat bash "$T/hub con spazio/night-shift/caccia-lente.sh" "$T/progetto" 2>&1); RC=$?
[ "$RC" -eq 3 ] && grep -ci "non ha girato" <<<"$OUT" >/dev/null && ok "S3 R4: lo strumento assente (rc 127) e' una lente MUTA, detta prima del modello" \
  || ko "S3 R4: strumento non eseguito passato al modello (rc $RC): $(grep -m2 'strumento\|STRUMENTO' <<<"$OUT" | tr '\n' ' ')"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
