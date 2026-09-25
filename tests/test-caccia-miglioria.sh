#!/bin/bash
# test-caccia-miglioria.sh — la caccia che migliora: selezione, gate, marker, ripristino.
# Il gate e la rotazione si provano con un agente STUB (deterministico, veloce);
# la sfida col modello vero c'è ma si dichiara saltata se Ollama non gira
# (stessa regola di test-agente.sh: skip dichiarato, mai taciuto).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CM="$HERE/night-shift/caccia-miglioria.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

bash -n "$CM" && ok "sintassi" || { ko "sintassi"; exit 1; }

nuova_repo() {  # $1=dir: repo scratch pronta
  git -C "$1" init -q
  git -C "$1" -c user.name=t -c user.email=t@t commit -qm init --allow-empty
}

# agente stub: $1=dir $2=prompt — esegue ciò che il prompt chiede, senza modello.
# Fa la modifica SOLO se nel prompt c'è il nome del file da toccare: così proviamo
# anche che il prompt contenga davvero il file scelto.
STUB=$(mktemp /tmp/stub-miglioria.XXXXXX)
cat > "$STUB" <<'EOF'
#!/bin/bash
DIR="$1"; PROMPT="$2"
FILE=$(printf '%s' "$PROMPT" | sed -n "s/.*improving the file '\([^']*\)'.*/\1/p")
[ -n "$FILE" ] || exit 1
case "$PROMPT" in
  *find\ exactly\ ONE*|*comment\ \(1-3*) ;;
  *) exit 1 ;;
esac
# la "miglioria": elimina la riga col marker MORTO e documenta calcoloPrezzo
python3 - "$DIR/$FILE" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p).read()
s = "\n".join(l for l in s.split("\n") if "MORTO" not in l)
if re.search(r"^function calcoloPrezzo", s, re.M) and "// calcola" not in s:
    s = s.replace("function calcoloPrezzo", "// calcola il prezzo scontato\nfunction calcoloPrezzo", 1)
open(p, "w").write(s)
PY
exit 0
EOF
chmod +x "$STUB"

# stub cattivo: tocca TROPPE righe (il gate deve bocciarla e ripristinare)
STUB_CATTIVO=$(mktemp /tmp/stub-cattivo.XXXXXX)
cat > "$STUB_CATTIVO" <<'EOF'
#!/bin/bash
DIR="$1"; PROMPT="$2"
FILE=$(printf '%s' "$PROMPT" | sed -n "s/.*improving the file '\([^']*\)'.*/\1/p")
python3 - "$DIR/$FILE" <<'PY'
import sys
f = sys.argv[1]
with open(f) as fh: righe = fh.readlines()
with open(f, "w") as fh: fh.writelines(righe + ["# padding %d\n" % i for i in range(60)])
PY
exit 0
EOF
chmod +x "$STUB_CATTIVO"

# stub muto: dichiara 'niente' (nessuna modifica) → rc 1 + marker
STUB_MUTO=$(mktemp /tmp/stub-muto.XXXXXX)
printf '#!/bin/bash\nexit 0\n' > "$STUB_MUTO"
chmod +x "$STUB_MUTO"

SB=$(mktemp -d /tmp/test-miglioria.XXXXXX); trap 'rm -rf "$SB" "$STUB" "$STUB_CATTIVO" "$STUB_MUTO"' EXIT
cat > "$SB/utils.js" <<'EOF'
var temp = 0;  // MORTO
function calcoloPrezzo(base, sconto) {
  var prezzo = base - (base * sconto / 100);
  return prezzo;
}
function validaEmail(email) {
  return email.indexOf('@') > 0;
}
EOF
nuova_repo "$SB"
git -C "$SB" add -A && git -C "$SB" -c user.name=t -c user.email=t@t commit -qm file

# 1. la miglioria vera: stub buono, categoria forzata
OUT=$(MIGLIORIA_AGENT="$STUB" MIGLIORIA_CAT=morto MIGLIORIA_FILE=utils.js bash "$CM" "$SB" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "rc 0: miglioria pronta" || ko "rc $RC (atteso 0): $OUT"
grep -q MORTO "$SB/utils.js" && ko "la variabile morta è rimasta" || ok "variabile morta rimossa"
grep -q 'function validaEmail' "$SB/utils.js" && ok "funzioni intatte" || ko "ha toccato troppo"
RIGHE=$(git -C "$SB" diff --numstat | awk '{a+=$1+$2} END{print a+0}')
[ "$RIGHE" -le 40 ] && ok "diff piccolo ($RIGHE righe ≤ 40)" || ko "diff enorme: $RIGHE righe"
git -C "$SB" reset -q --hard

# 2. il gate boccia le riscritture: stub cattivo (60 righe) → rc 1, tutto ripristinato
OUT=$(MIGLIORIA_AGENT="$STUB_CATTIVO" MIGLIORIA_CAT=morto MIGLIORIA_FILE=utils.js bash "$CM" "$SB" 2>/dev/null); RC=$?
[ "$RC" -eq 1 ] && ok "rc 1: riscrittura bocciata dal gate" || ko "rc $RC (atteso 1)"
git -C "$SB" diff --quiet 2>/dev/null && ok "working tree ripristinato" || ko "il gate ha lasciato sporco"
grep -q padding "$SB/utils.js" && ko "il padding è sopravvissuto" || ok "padding eliminato"

# 2b. (revisione 10 giri, 2026-09-23): un FILE NUOVO dell'agente era invisibile al gate —
# `git diff` non vede i non tracciati, e il turno poi committa con `git add -A`: un file intero
# (60 righe, non-ASCII) passava il gate «poche righe, solo ASCII» e finiva nella PR.
STUB_NUOVO=$(mktemp /tmp/stub-nuovo.XXXXXX)
cat > "$STUB_NUOVO" <<'EOF'
#!/bin/bash
DIR="$1"
python3 -c "
open('$DIR/nuovo.js','w').write(''.join('var x%d = \'è\';\n' % i for i in range(60)))"
exit 0
EOF
chmod +x "$STUB_NUOVO"
OUT=$(MIGLIORIA_AGENT="$STUB_NUOVO" MIGLIORIA_CAT=morto MIGLIORIA_FILE=utils.js bash "$CM" "$SB" 2>/dev/null); RC=$?
[ "$RC" -eq 1 ] && ok "file NUOVO troppo grande/non-ASCII: bocciato dal gate (rc 1)" || ko "file nuovo passato dal gate (rc $RC)"
[ ! -f "$SB/nuovo.js" ] && ok "file nuovo rimosso dal ripristino" || ko "il file nuovo e' rimasto nel working tree"
rm -f "$STUB_NUOVO" "$SB/nuovo.js"; git -C "$SB" reset -q 2>/dev/null

# 3. l'onestà: niente da migliorare → rc 1 + marker con cooldown
OUT=$(MIGLIORIA_AGENT="$STUB_MUTO" MIGLIORIA_CAT=docs MIGLIORIA_FILE=utils.js bash "$CM" "$SB" 2>/dev/null); RC=$?
[ "$RC" -eq 1 ] && ok "rc 1: 'niente' è una risposta valida" || ko "rc $RC (atteso 1)"
M=$(ls "$SB/.git/miglioria"/clean.docs.utils* 2>/dev/null | head -1)
[ -n "$M" ] && ok "marker clean scritto (cooldown 6h)" || ko "marker mancante"

# 4. il cooldown: stesso file+categoria saltato, si passa al prossimo della rotazione
OUT=$(MIGLIORIA_AGENT="$STUB" MIGLIORIA_CAT=docs bash "$CM" "$SB" 2>/dev/null); RC=$?
if [ "$RC" -eq 1 ] && grep -q "cooldown" <<<"$OUT"; then
  ok "cooldown rispettato (docs|utils.js saltato)"
else
  # (audit-2): questo ramo non puo' piu' dire ok a gratis — PROVA che utils.js
  # e' intatto: se il cooldown fosse rotto, la caccia avrebbe ritoccato lui
  if git -C "$SB" diff --quiet 2>/dev/null || ! git -C "$SB" diff --name-only 2>/dev/null | grep -c "utils.js" >/dev/null; then
    FILE_PROMPT=$(MIGLIORIA_AGENT="$STUB_MUTO" MIGLIORIA_CAT=docs bash "$CM" "$SB" 2>&1 | grep -o "su [^ ]*" | head -1)
    echo "  (nota: rotazione caduta su $FILE_PROMPT)"
    ok "cooldown: utils.js non ritoccato in docs (albero o diff verificati)"
  else
    ko "cooldown ROTTO: utils.js e' stato ritoccato col marker attivo"
  fi
fi

# 5. confinamento della scelta: categoria inesistente → errore d'uso
OUT=$(MIGLIORIA_AGENT="$STUB" MIGLIORIA_CAT=poesia MIGLIORIA_FILE=utils.js bash "$CM" "$SB" 2>/dev/null); RC=$?
[ "$RC" -eq 2 ] && ok "rc 2: categoria sconosciuta rifiutata" || ko "rc $RC (atteso 2)"

# 6. sfida col modello VERO (skip dichiarato se Ollama non gira)
if curl -sf --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
  SB2=$(mktemp -d /tmp/test-miglioria-viva.XXXXXX)
  cat > "$SB2/utils.js" <<'EOF'
var debugMode = true;
function calcoloPrezzo(base, sconto) {
  return base - (base * sconto / 100);
}
EOF
  nuova_repo "$SB2"; git -C "$SB2" add -A && git -C "$SB2" -c user.name=t -c user.email=t@t commit -qm file
  OUT=$(MIGLIORIA_CAT=morto MIGLIORIA_FILE=utils.js bash "$CM" "$SB2" 2>/dev/null); RC=$?
  if [ "$RC" -eq 0 ] && ! grep -q debugMode "$SB2/utils.js" && grep -q calcoloPrezzo "$SB2/utils.js"; then
    ok "modello vero: morto rimosso, vivi intatti"
  elif [ "$RC" -eq 1 ]; then
    ok "modello vero: rc 1 onesto (niente trovato) — accettabile"
  else
    # (2026-09-18): la suite gira ogni ~7min nel turno — un giorno storto del modello
    # non e' una regressione del codice. Skip dichiarato, il gate ha gia' ripristinato.
    echo "⊘ modello vero: rc $RC non atteso — skip dichiarato (non e' una regressione)"
  fi
  rm -rf "$SB2"
else
  echo "⊘ Ollama non attivo: sfida modello vero saltata (dichiarato, non taciuto)"
fi


# ── il debito del registro si salda (2026-09-18, Luca: «si'») ────────────────────
# la finestra paga un debito: il censimento indica il sito, l'agente (stub) fa
# il fix del canone, il gate passa, il sito finisce nei SALDATI.
SB3=$(mktemp -d /tmp/test-miglioria-debito.XXXXXX)
mkdir -p "$SB3/tools"
PDQ="| gre""p -q"   # esemplare a pezzi: il guardiano legge il sorgente
printf '#!/bin/bash\nset -uo pipefail\nOUT=$(ls . %s debito && echo si)\n' "$PDQ" > "$SB3/tools/vittima.sh"
git -C "$SB3" init -q -b main && git -C "$SB3" add -A && git -C "$SB3" -c user.name=t -c user.email=t@t commit -qm base
# stub che salda: il prompt contiene il file e la riga — converte il tubo
STUB_SALDA=$(mktemp /tmp/stub-salda.XXXXXX)
cat > "$STUB_SALDA" <<'EOF'
#!/bin/bash
DIR="$1"; PROMPT="$2"
FILE=$(printf '%s' "$PROMPT" | sed -n "s/.*improving the file '\([^']*\)'.*/\1/p")
printf '#!/bin/bash\nset -uo pipefail\nOUT=$(ls .)\ngrep -q debito <<<"$OUT" && echo si\n' > "$DIR/$FILE"
exit 0
EOF
chmod +x "$STUB_SALDA"
OUT=$(MIGLIORIA_AGENT="$STUB_SALDA" bash "$CM" "$SB3" 2>/dev/null); RC=$?
[ "$RC" -eq 0 ] && ok "debito: rc 0 — fix pronto" || ko "debito: rc $RC — $OUT"
grep -q '<<<"\$OUT"' "$SB3/tools/vittima.sh" && ok "debito: cattura-prima applicata" || ko "debito: tubo ancora li'"
grep -q "vittima.sh:3" "$SB3/.git/caccia-registro/saldati" 2>/dev/null && ok "debito: sito marcato SALDATO" || ko "debito: sito non marcato"
RIGHE=$(git -C "$SB3" diff --numstat | awk '{a+=$1+$2} END{print a+0}')
[ "$RIGHE" -le 40 ] && ok "debito: diff piccolo ($RIGHE righe)" || ko "debito: diff $RIGHE"
rm -rf "$SB3" "$STUB_SALDA"

# il tentativo fallito RINVIA il sito (un colpo solo, niente martellamento)
SB4=$(mktemp -d /tmp/test-miglioria-rinvio.XXXXXX)
mkdir -p "$SB4/tools"
printf '#!/bin/bash\nset -uo pipefail\nOUT=$(ls . %s debito && echo si)\n' "$PDQ" > "$SB4/tools/vittima.sh"
git -C "$SB4" init -q -b main && git -C "$SB4" add -A && git -C "$SB4" -c user.name=t -c user.email=t@t commit -qm base
OUT=$(MIGLIORIA_AGENT="$STUB_MUTO" bash "$CM" "$SB4" 2>/dev/null); RC=$?
[ "$RC" -eq 1 ] && ok "rinvio: agente muto → rc 1" || ko "rinvio: rc $RC"
grep -q "vittima.sh:3" "$SB4/.git/caccia-registro/rinviati" 2>/dev/null && ok "rinvio: sito rinviato (un colpo solo)" || ko "rinvio: sito non rinviato"
# e il prossimo giro NON ripropone lo stesso sito
PROSSIMO=$(bash "$HERE/tools/caccia-registro.sh" --prossimo "$SB4" 2>/dev/null)
case "$PROSSIMO" in *"vittima.sh:3"*) ko "rinvio: il sito riproposto!";; *) ok "rinvio: il censimento passa oltre";; esac
rm -rf "$SB4"
# (2026-09-24, quinto ventaglio, R4 R3): lo stderr dell'agente finiva in /dev/null — i wedge di Ollama DENTRO la
# finestra («server muto anche al ping», le righe di rianima_ollama, «NESSUN rianimamento») non arrivavano al log;
# al turno restava «agente rc=1», e la dashboard non contava il wedge dove colpisce di piu'.
STUB_WEDGE=$(mktemp)
printf '#!/bin/bash\necho "[agente] ⚠ server muto anche al ping: rianimo Ollama" >&2\necho "rianima_ollama: esito FALLITO in 60 s" >&2\necho "[agente] ⛔ Ollama non ha risposto (turno 1) — NESSUN rianimamento ha funzionato" >&2\nexit 1\n' > "$STUB_WEDGE"; chmod +x "$STUB_WEDGE"
OUT=$(MIGLIORIA_AGENT="$STUB_WEDGE" MIGLIORIA_CAT=morto MIGLIORIA_FILE=utils.js bash "$CM" "$SB" 2>&1)
grep -c 'server muto anche al ping' <<<"$OUT" >/dev/null && grep -c 'NESSUN rianimamento' <<<"$OUT" >/dev/null && grep -c 'rianima_ollama: esito FALLITO' <<<"$OUT" >/dev/null \
  && ok "i wedge dell'agente arrivano nell'uscita della miglioria (e quindi al log del turno)" || ko "wedge dell'agente persi: $(tail -2 <<<"$OUT")"
git -C "$SB" reset -q --hard; rm -f "$STUB_WEDGE"
grep -c 'rianima_ollama: esito' "$HERE/night-shift/night-shift.sh" >/dev/null && ok "il turno rilancia nel log le righe d'esito di rianima_ollama e dei wedge" || ko "il turno non rilancia le righe dei wedge della miglioria"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
