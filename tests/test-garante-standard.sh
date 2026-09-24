#!/bin/bash
# test-garante-standard.sh — il garante dello standard: installa se manca, e (fase B)
# AVVERTE se il metodo installato diverge dall'hub. Nato con il dente della deriva,
# provato col morso: un metodo installato VECCHIO deve produrre l'avviso.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GARANTE="$HERE/tools/garante-standard.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$GARANTE" ] || { echo "FAIL garante-standard.sh assente"; exit 1; }
bash -n "$GARANTE" && ok "sintassi" || ko "sintassi rotta"

# caso 1: installazione esistente con metodo DIVERSO da quello dell'hub → AVVISO deriva
SB=$(mktemp -d /tmp/garante-t1.XXXXXX)
trap 'rm -rf "$SB" "$SB2"' EXIT
mkdir -p "$SB/.claude/skills/gas-sviluppo/references"
echo '{"hooks":{"SessionStart":[{"hooks":[{"command":"x"}]}]}}' > "$SB/.claude/settings.json"
echo "metodo vecchio" > "$SB/.claude/skills/gas-sviluppo/references/metodo.md"
OUT=$(cd "$SB" && bash "$GARANTE" 2>&1)
if grep -q "DIVERGE" <<<"$OUT"; then
  ok "metodo installato vecchio → avviso deriva (con il comando per aggiornare)"
  grep -q "sync-repo" <<<"$OUT" && ok "l'avviso dice COME aggiornare" || ko "avviso senza rimedio"
else
  ko "deriva del metodo NON vista — il garante e' tornato una-tantum"
fi

# caso 2: installazione esistente con metodo UGUALE → silenzio (nessun falso allarme)
SB2=$(mktemp -d /tmp/garante-t2.XXXXXX)
mkdir -p "$SB2/.claude/skills/gas-sviluppo/references"
echo '{"hooks":{"SessionStart":[{"hooks":[{"command":"x"}]}]}}' > "$SB2/.claude/settings.json"
cp "$HERE/.claude/skills/gas-sviluppo/references/metodo.md" "$SB2/.claude/skills/gas-sviluppo/references/metodo.md"
OUT2=$(cd "$SB2" && bash "$GARANTE" 2>&1)
if [ -z "$OUT2" ]; then
  ok "metodo allineato → silenzio (il garante non urla a vuoto)"
else
  ko "falso allarme su metodo allineato: $(echo "$OUT2" | head -1)"
fi

# caso 3: l'avviso NON tocca i file (diff prima/dopo) — il garante avverte, non sovrascrive
# (giro 27, 2026-09-20): era `xargs md5 | md5` — su Linux md5 non esiste, PRIMA e DOPO erano
# entrambi vuoti e il confronto passava sempre. Impronta portabile: cksum sui contenuti.
impronta() { (cd "$1" && find . -type f | sort | xargs cat 2>/dev/null | cksum); }
PRIMA=$(impronta "$SB")
(cd "$SB" && bash "$GARANTE" >/dev/null 2>&1)
DOPO=$(impronta "$SB")
[ "$PRIMA" = "$DOPO" ] && ok "avviso senza modifiche: il garante non sovrascrive mai" \
  || ko "il garante ha MODIFICATO file esistenti (deve solo avvisare)"

# caso 4 (giro 27 — D34): installazione da zero → OGNI hook dichiarato in settings.json (tutti
# gli eventi, non solo PreToolUse) arriva eseguibile; niente annidamento skills/skills
SB4=$(mktemp -d /tmp/garante-t4.XXXXXX); trap 'rm -rf "$SB" "$SB2" "$SB4" "$SB5"' EXIT
(cd "$SB4" && bash "$GARANTE" >/dev/null 2>&1)
MANCANTI=""
while IFS= read -r H; do
  [ -n "$H" ] || continue
  [ -x "$SB4/$H" ] || MANCANTI="$MANCANTI $H"
done < <(bash "$HERE/tools/copia-hook.sh" --elenco)
[ -z "$MANCANTI" ] && ok "installazione da zero: ogni hook dichiarato (tutti gli eventi) e' installato ed eseguibile" \
  || ko "installazione da zero (D34): hook dichiarati ma assenti:$MANCANTI"
[ -f "$SB4/.claude/settings.json" ] && [ -d "$SB4/.claude/skills/gas-sviluppo" ] && [ ! -d "$SB4/.claude/skills/skills" ] && [ -n "$(ls "$SB4/patterns" 2>/dev/null)" ] \
  && ok "installazione da zero: settings.json e skill al posto giusto, nessun annidamento" \
  || ko "installazione da zero: struttura sbagliata ($(ls "$SB4/.claude" 2>/dev/null | tr '\n' ' '))"

# caso 5 (giro 27): settings.json PROPRIO senza i nostri hook → avviso, MAI sovrascritto
SB5=$(mktemp -d /tmp/garante-t5.XXXXXX)
mkdir -p "$SB5/.claude/skills/mia-skill"
echo '{"hooks":{"PreToolUse":[{"hooks":[{"command":"tools/mio-hook.sh"}]}]}}' > "$SB5/.claude/settings.json"
echo "mia" > "$SB5/.claude/skills/mia-skill/SKILL.md"
P5=$(impronta "$SB5")
OUT5=$(cd "$SB5" && bash "$GARANTE" 2>&1)
[ "$(impronta "$SB5")" = "$P5" ] && grep -q "non lo sovrascrivo" <<<"$OUT5" \
  && ok "settings.json proprio: avviso e nessuna modifica (prima il garante lo sovrascriveva)" \
  || ko "settings.json proprio: toccato o avviso assente — $(head -1 <<<"$OUT5")"

# (2026-09-24, notte dei giri, T1#5): la COPIA del garante che vive in un satellite (ce la porta
# tools/installa-citati.sh) prendeva il satellite per l'hub, perche' ha .claude/skills: dentro il
# satellite taceva («sono l'hub»), e su un'altra repo installava dal satellite — che non ha
# claude-md-satellite.sh ne' copia-hook.sh. L'hub e' la cartella che ha gli strumenti che servono.
SAT=$(mktemp -d); NUOVA=$(mktemp -d)
mkdir -p "$SAT/tools" "$SAT/.claude/skills"; cp "$GARANTE" "$SAT/tools/"
OUT5=$(cd "$NUOVA" && AI_PROGRAMMER_HUB="$HERE" CLAUDE_PROJECT_DIR="$NUOVA" bash "$SAT/tools/garante-standard.sh" 2>&1)
[ -f "$NUOVA/CLAUDE.md" ] && [ -x "$NUOVA/tools/clasp-block-hook.sh" ] \
  && ok "la copia nel satellite installa dall'hub vero (CLAUDE.md e hook presenti)" || ko "la copia nel satellite si crede l'hub: $(tr '\n' ' ' <<<"$OUT5" | cut -c1-160)"
rm -rf "$SAT" "$NUOVA"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
