#!/bin/bash
# test-giorno.sh — l'harness del GIORNO: pre-push (lente deterministica + dipendenze),
# tools/giorno.sh (consegna/lente/parere/bilancino), la riga del giorno nel digest.
# Tutto offline: bare remote per il push vero, GH_BIN stubbato, LENTE_STUB per il
# cervello. Domanda di Luca (2026-10-09): «deve essere un harness più per il giorno
# che per la notte — lenti, agenti e sistemi anche di giorno».
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GP="$HERE/tools/giorno.sh"
PP="$HERE/tools/pre-push.sh"
MD="$HERE/night-shift/morning-digest.sh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH" LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -f "$GP" ] && bash -n "$GP" && ok "sintassi giorno.sh" || ko "sintassi giorno.sh"
[ -f "$PP" ] && bash -n "$PP" && ok "sintassi pre-push.sh" || ko "sintassi pre-push.sh"
[ -f "$HERE/.githooks/pre-push" ] && ok "hook pre-push installato nell'hub (.githooks)" || ko "hook pre-push installato nell'hub (.githooks)"

SB=$(mktemp -d /tmp/test-giorno.XXXXXX)
trap 'rm -rf "$SB"' EXIT
export GIORNO_LOG="$SB/giorno.log"

# stub gh: registra le chiamate e risponde da PR creata — PRIMO in PATH, cosi' lo
# vedono sia giorno.sh sia l'gh letterale dentro lente_pr (lib.sh)
GHSTUB_DIR="$SB/bin"; mkdir -p "$GHSTUB_DIR"
cat > "$GHSTUB_DIR/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "${GHSTUB_REGISTRO:-/tmp/gh-stub.reg}"
case "$1 $2" in
  "pr create") echo "https://github.com/obi2kenobi/FINTO/pull/999" ;;
  "pr comment") echo "https://github.com/obi2kenobi/FINTO/issues/999#comment" ;;
  "issue create") echo "https://github.com/obi2kenobi/FINTO/issues/77" ;;
  *) echo "ok-stub" ;;
esac
EOF
chmod +x "$GHSTUB_DIR/gh"
export GHSTUB_REGISTRO="$SB/gh-regist"
export PATH="$GHSTUB_DIR:$PATH"

# stub lente (il cervello dice sempre sicuro)
LENTE_STUB="$SB/lente-stub"
printf '#!/bin/bash\ncat >/dev/null\necho \x27{"sicuro": true, "rilievi": []}\x27\n' > "$LENTE_STUB"
chmod +x "$LENTE_STUB"
export LENTE_STUB

nuova_repo() {  # $1=dir $2=bare-remote: repo con origin e origin/HEAD a posto
  git init -q --bare "$2"
  git -C "$1" init -q -b main
  git -C "$1" -c user.name=t -c user.email=t@t commit -qm init --allow-empty
  git -C "$1" remote add origin "$2"
  git -C "$1" push -q -u origin main 2>/dev/null
  git -C "$1" remote set-head origin main >/dev/null 2>&1
  git -C "$1" config advice.pushUpdateRejected false
}

# ── fixture: repo + bare remote ──────────────────────────────────────────────────
R="$SB/repo"; REM="$SB/remote.git"; mkdir -p "$R"; nuova_repo "$R" "$REM"
printf 'function alpha(x) {\n  return x + 1;\n}\n' > "$R/a.js"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm file

# ── pre-push: pulito passa, sporco blocca, hub assente dichiara ──────────────────
PP_OUT=$(cd "$R" && bash "$PP" <<< "refs/heads/main $(git -C "$R" rev-parse HEAD) refs/heads/main $(git -C "$R" rev-parse origin/main)" 2>&1); PP_RC=$?
[ "$PP_RC" -eq 0 ] && ok "pre-push: commit pulito passa" || ko "pre-push: commit pulito passa (rc=$PP_RC: $PP_OUT)"

# i finti segreti si COSTRUISCONO a runtime (pattern di test-lente-sicurezza):
# il letterale nel sorgente matcherebbe le SHAPES del pre-commit — giusto cosi'
TOK_A="ghp_$(printf 'a%.0s' $(seq 1 36))"
TOK_B="ghp_$(printf '0%.0s' $(seq 1 36))"
K_AN="sk-ant-api03-$(printf 'b%.0s' $(seq 1 24))"
printf 'const TOKEN = "%s";\n' "$TOK_A" > "$R/segreto.js"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm sporco
PP_OUT=$(cd "$R" && bash "$PP" <<< "refs/heads/main $(git -C "$R" rev-parse HEAD) refs/heads/main $(git -C "$R" rev-parse origin/main)" 2>&1); PP_RC=$?
if [ "$PP_RC" -ne 0 ] && grep -q "forme di segreto" <<<"$PP_OUT"; then
  ok "pre-push: il segreto BLOCCA il push (deterministico, zero GPU)"
else ko "pre-push: il segreto BLOCCA il push (rc=$PP_RC)"; fi
git -C "$R" reset -q --hard HEAD~1

# hub assente (satellite senza copia locale): dichiara e passa, non bricks
PP_OUT=$(cd "$R" && AI_PROGRAMMER_HUB="$SB/non-esiste" bash "$HERE/.githooks/pre-push" <<< "" 2>&1); PP_RC=$?
if [ "$PP_RC" -eq 0 ] && grep -qi "SALTATO" <<<"$PP_OUT"; then
  ok "pre-push delegato: hub assente = avviso dichiarato, push non bloccato"
else ko "pre-push delegato: hub assente = avviso dichiarato (rc=$PP_RC: $PP_OUT)"; fi

# dipendenze non pinnate: AVVISO nel pre-push, mai blocco
printf 'requests\npandas\n' > "$R/requirements.txt"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm req
PP_OUT=$(cd "$R" && bash "$PP" <<< "refs/heads/main $(git -C "$R" rev-parse HEAD) refs/heads/main $(git -C "$R" rev-parse origin/main)" 2>&1); PP_RC=$?
if [ "$PP_RC" -eq 0 ] && grep -qi "dipendenz" <<<"$PP_OUT"; then
  ok "pre-push: dipendenze non pinnate = avviso (non blocco)"
else ko "pre-push: dipendenze non pinnate = avviso (rc=$PP_RC: $PP_OUT)"; fi
git -C "$R" reset -q --hard HEAD~1

# ── giorno lente: il rapporto esce, il segreto è RILIEVI senza cervello ──────────
printf 'function beta(y) {\n  return y * 2;\n}\n' > "$R/b.js"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm b
GL=$(bash "$GP" lente "$R" "origin/main" 2>&1); GL_RC=$?
[ "$GL_RC" -eq 0 ] && grep -q "PULITA" <<<"$GL" && ok "giorno lente: diff pulito = PULITA (cervello stubbato)" || ko "giorno lente: diff pulito = PULITA (rc=$GL_RC: $GL)"
printf 'const K = "%s";\n' "$K_AN" > "$R/chiave.js"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm chiave
GL=$(bash "$GP" lente "$R" "origin/main" 2>&1); GL_RC=$?
[ "$GL_RC" -eq 1 ] && grep -q "RILIEVI" <<<"$GL" && ok "giorno lente: segreto = RILIEVI (uno basta, cervello non consultato)" || ko "giorno lente: segreto = RILIEVI (rc=$GL_RC)"
git -C "$R" reset -q --hard HEAD~1
grep -q "GIORNO.*lente" "$GIORNO_LOG" && ok "giorno lente: la riga è nel log del giorno" || ko "giorno lente: la riga è nel log del giorno"

# ── giorno consegna: end-to-end (commit, trailer, gate, push, PR, lente, log) ────
printf '// documenta alpha\n' >> "$R/a.js"
printf 'dato di passaggio\n' > "$R/scratch-non-dichiarato.txt"
GCO=$(bash "$GP" consegna "$R" "documenta alpha" 2>&1); GCO_RC=$?
if [ "$GCO_RC" -eq 0 ] && grep -q "pull/999" <<<"$GCO"; then
  ok "giorno consegna: rc 0 con PR (stub) — pipeline completa"
else ko "giorno consegna: rc 0 con PR (rc=$GCO_RC: $GCO)"; fi
BR_G=$(git -C "$R" branch --show-current)
case "$BR_G" in giorno/*) ok "giorno consegna: consegna su ramo giorno/* ($BR_G), mai su main"; ;; *) ko "giorno consegna: ramo giorno/* (trovato $BR_G)"; ;; esac
MSGC=$(git -C "$R" log -1 --format='%B')
grep -q "Turno: giorno" <<<"$MSGC" && ok "giorno consegna: il commit dichiara il turno (trailer)" || ko "giorno consegna: il commit dichiara il turno (trailer)"
git -C "$R" rev-parse -q --verify "refs/remotes/origin/$BR_G" >/dev/null 2>&1 && ok "giorno consegna: il ramo è spinto sull'origin" || ko "giorno consegna: il ramo è spinto sull'origin"
STATC=$(git -C "$R" show --stat --format= HEAD)
grep -q "scratch-non-dichiarato" <<<"$STATC" && ko "giorno consegna: il file nuovo NON dichiarato resta FUORI dal commit" || ok "giorno consegna: il file nuovo NON dichiarato resta FUORI dal commit"
grep -q "pr create" "$GHSTUB_REGISTRO" && grep -q "pr comment" "$GHSTUB_REGISTRO" && ok "giorno consegna: PR creata E commento lente pubblicato (come la notte)" || ko "giorno consegna: PR creata E commento lente (registro: $(cat "$GHSTUB_REGISTRO" 2>/dev/null | tr '\n' ';'))"
grep -q "GIORNO.*consegna.*pull/999" "$GIORNO_LOG" && ok "giorno consegna: la riga è nel log del giorno" || ko "giorno consegna: la riga è nel log del giorno"
git -C "$R" checkout -q main && git -C "$R" branch -D "$BR_G" -q

# ── consegna con file DICHIARATI: i nuovi dichiarati ENTRANO, gli altri fuori ──
: > "$GHSTUB_REGISTRO"
printf 'function gamma(g) {\n  return g * 3;\n}\n' > "$R/gamma.js"
printf 'annotazione di passaggio\n' > "$R/passaggio.txt"
GC2=$(bash "$GP" consegna "$R" "aggiunge gamma dichiarato" gamma.js 2>&1); GC2_RC=$?
if [ "$GC2_RC" -eq 0 ]; then
  STAT2=$(git -C "$R" show --stat --format= HEAD)
  grep -q "gamma.js" <<<"$STAT2" && ok "consegna: il file nuovo DICHIARATO entra nel commit" || ko "consegna: il file dichiarato entra"
  if grep -q "passaggio.txt" <<<"$STAT2"; then ko "consegna: il non dichiarato resta fuori"; else ok "consegna: il non dichiarato resta fuori"; fi
else ko "consegna con file dichiarati (rc=$GC2_RC: $GC2)"; fi
BR2=$(git -C "$R" branch --show-current); git -C "$R" checkout -q main; git -C "$R" branch -D "$BR2" -q 2>/dev/null; rm -f "$R/passaggio.txt"

# ── consegna --tutto: l'albero intero di un progetto nuovo in UN colpo ─────────
: > "$GHSTUB_REGISTRO"
mkdir -p "$R/nuovo/sotto"
printf 'x = 1\n' > "$R/nuovo/a.py"; printf 'y = 2\n' > "$R/nuovo/sotto/b.py"; printf 'z = 3\n' > "$R/nuovo/c.py"
sleep 1   # il ramo giorno/<secondo>: due consegne nello stesso secondo collidono (edge dichiarato nel tool)
GC3=$(bash "$GP" consegna "$R" "bootstrap --tutto" --tutto 2>&1); GC3_RC=$?
if [ "$GC3_RC" -eq 0 ]; then
  STAT3=$(git -C "$R" show --stat --format= HEAD)
  grep -q "nuovo/a.py" <<<"$STAT3" && grep -q "nuovo/sotto/b.py" <<<"$STAT3" && ok "consegna --tutto: anche le sottodirectory entrano (il caso prima-consegna)" || ko "consegna --tutto: sottodirectory dentro (stat: $STAT3)"
  grep -q "dichiaro TUTTO" <<<"$GC3" && ok "consegna --tutto: la responsabilita' e' dichiarata nel log" || ko "consegna --tutto: dichiarazione nel log"
else ko "consegna --tutto (rc=$GC3_RC: $GC3)"; fi
BR3=$(git -C "$R" branch --show-current); git -C "$R" checkout -q main; git -C "$R" branch -D "$BR3" -q 2>/dev/null

# ── il banco del repo decide: rosso = consegna fermata SOFT ────────────────────
printf '#!/bin/bash\necho "attese eseguite: 1/2 fallite: 1" >&2\nexit 1\n' > "$R/.night-verify"
printf '// modifica che il banco boccera'\''\n' >> "$R/a.js"
GB=$(bash "$GP" consegna "$R" "questa non deve passare" .night-verify 2>&1); GB_RC=$?
if [ "$GB_RC" -ne 0 ] && grep -q "ROSSO" <<<"$GB"; then
  ok "banco rosso: consegna FERMATA prima del push (soft, lavoro in albero)"
else ko "banco rosso: consegna fermata (rc=$GB_RC: $GB)"; fi
if git -C "$R" show HEAD:a.js 2>/dev/null | grep -q "boccera"; then ko "banco rosso: il commit sporco NON esiste"; else ok "banco rosso: il commit sporco NON esiste (sciolto)"; fi
grep -q "boccera" "$R/a.js" && ok "banco rosso: il lavoro NON e' distrutto" || ko "banco rosso: il lavoro NON e' distrutto"
printf '#!/bin/bash\necho "attese eseguite: 2/2 fallite: 0"\nexit 0\n' > "$R/.night-verify"
sleep 1
GB2=$(bash "$GP" consegna "$R" "questa passa col banco verde" .night-verify 2>&1); GB2_RC=$?
[ "$GB2_RC" -eq 0 ] && grep -q "banco verde" <<<"$GB2" && ok "banco verde: la consegna passa e LO DICE" || ko "banco verde: consegna passa (rc=$GB2_RC: $GB2)"
BRB=$(git -C "$R" branch --show-current); git -C "$R" checkout -q main; git -C "$R" branch -D "$BRB" -q 2>/dev/null; rm -f "$R/.night-verify"

# ── giorno consegna con SEGRETO: si ferma PRIMA del push, lavoro non distrutto ───
# (il segreto in un file TRACCATO: come file nuovo non dichiarato verrebbe messo
#  fuori da aggiungi_consegna PRIMA del commit — quella e' un'altra guardia, gia' provata)
SHA_PRIMA=$(git -C "$R" rev-parse HEAD)
printf 'const T2 = "%s";\n' "$TOK_B" >> "$R/b.js"
GCS=$(bash "$GP" consegna "$R" "importa segreto" 2>&1); GCS_RC=$?
BR_S=$(git -C "$R" branch --show-current)
if [ "$GCS_RC" -ne 0 ] && grep -q "forme di segreto" <<<"$GCS"; then
  ok "giorno consegna: il segreto ferma la consegna PRIMA del push"
else ko "giorno consegna: il segreto ferma la consegna (rc=$GCS_RC: $GCS)"; fi
BJSC=$(git -C "$R" show "HEAD:b.js" 2>/dev/null || true)
if grep -q ghp_ <<<"$BJSC"; then ko "giorno consegna: il commit sporco NON esiste"; else ok "giorno consegna: il commit sporco NON esiste (soft-reset)"; fi
grep -q ghp_ "$R/b.js" && ok "giorno consegna: il lavoro NON è distrutto (reset soft, non hard come la notte)" || ko "giorno consegna: il lavoro NON è distrutto"
git -C "$R" checkout -q main; git -C "$R" branch -D "$BR_S" -q 2>/dev/null; git -C "$R" reset -q --hard

# ── giorno parere: il censore consultabile a comando (D10: parere, mai fusione) ──
grep -q "revisore.sh" "$GP" && ok "giorno parere: cablato sul revisore (il censore del giorno)" || ko "giorno parere: cablato sul revisore"
grep -q "GIOFIUGI\|--no-merge\|mai la fusione\|parere" "$GP" && ok "giorno parere: il contratto dichiara parere-mai-fusione" || ko "giorno parere: il contratto dichiara parere-mai-fusione"

# ── consegna con .md fuori stile: il rilievo viene ANNOTATO sulla riga della PR ──
: > "$GHSTUB_REGISTRO"
printf "# Nota\n\nLa pagina e' pronta ma il testo e' così così\n" > "$R/nota-accenti.md"
sleep 1
GCA=$(bash "$GP" consegna "$R" "nota con accenti" nota-accenti.md 2>&1); GCA_RC=$?
if [ "$GCA_RC" -eq 0 ] && grep -q "le annoto SULLA RIGA" <<<"$GCA"; then
  ok "consegna: i rilievi prosa vengono annotati sulla PR (R4, cerchio reviewdog)"
else ko "consegna: annotazioni in consegna (rc=$GCA_RC: $GCA)"; fi
REG_A=$(cat "$GHSTUB_REGISTRO" 2>/dev/null)
if grep -q "pulls/" <<<"$REG_A" && grep -q "path=nota-accenti.md" <<<"$REG_A"; then
  ok "consegna: l'annotazione porta path e riga (endpoint commenti PR)"
elif grep -q "annotazioni saltate: origin non e' GitHub" <<<"$GCA"; then
  ok "consegna: origin non GitHub = annotazioni saltate DICHIARATE (il banco gira su bare locali)"
else ko "consegna: payload annotazione ($REG_A)"; fi
BRA=$(git -C "$R" branch --show-current); git -C "$R" checkout -q main; git -C "$R" branch -D "$BRA" -q 2>/dev/null

# ── parere del giorno sulle PR del giorno (debito del flusso reale chiuso) ─────
grep -q "GIORNO_PARERE=1 bash" "$GP" && ok "parere: il giorno CHIEDE il parere (GIORNO_PARERE=1 al revisore)" || ko "parere: il giorno chiede il parere"
grep -q 'GIORNO_PARERE:-0' "$HERE/night-shift/revisore.sh" && ok "revisore: i rami giorno/* passano SOLO su richiesta, in modo PARERE (mai fusione)" || ko "revisore: cancello GIORNO_PARERE"
grep -q "non e' night/\*" "$HERE/night-shift/revisore.sh" && ok "revisore: senza richiesta i rami giorno/* restano RIFIUTATI (la notte non li tocca)" || ko "revisore: il rifiuto resta"

# ── handoff: il passamano giorno→notte (issue [handoff], corpo pulito) ──────────
: > "$GHSTUB_REGISTRO"
HU=$(bash "$GP" handoff "$R" "verificare PATCH-ODA in staging" "il giorno ha lasciato il test a metà: rigenerare e provare. Contatto: luca.rossi@example.com" 2>&1); HU_RC=$?
if [ "$HU_RC" -eq 0 ] && grep -q "handoff" <<<"$HU"; then
  ok "handoff: rc 0 con URL"
else ko "handoff: rc 0 con URL (rc=$HU_RC: $HU)"; fi
REG_H=$(cat "$GHSTUB_REGISTRO" 2>/dev/null)
grep -q "label create handoff" <<<"$REG_H" && ok "handoff: l'etichetta viene creata (o tollerata)" || ko "handoff: l'etichetta viene creata"
grep -q "issue create" <<<"$REG_H" && grep -q -- "--label handoff" <<<"$REG_H" && ok "handoff: issue creata CON etichetta handoff" || ko "handoff: issue creata con etichetta (registro: $REG_H)"
grep -q "\[handoff\] verificare PATCH-ODA" <<<"$REG_H" && ok "handoff: il titolo porta il prefisso [handoff]" || ko "handoff: il titolo porta il prefisso [handoff]"
if grep -q "luca.rossi@example.com" <<<"$REG_H"; then ko "handoff: l'email del corpo NON arriva all'issue (cancello destinazioni)"; else ok "handoff: l'email del corpo NON arriva all'issue (cancello destinazioni)"; fi
grep -q "GIORNO.*handoff" "$GIORNO_LOG" && ok "handoff: la riga è nel log del giorno" || ko "handoff: la riga è nel log del giorno"

# ── bilancino del giorno: le righe del log diventano conto ───────────────────────
printf '[GIORNO 2026-10-09 10:00:00] REPO repo: consegna → url1 · PULITA\n[GIORNO 2026-10-09 11:00:00] REPO repo: lente · PULITA\n[GIORNO 2026-10-09 12:00:00] REPO altro: parere PR #3\n[GIORNO 2026-10-09 13:00:00] REPO altro: handoff → url-h\n[GIORNO 2026-10-08 09:00:00] REPO vecchio: consegna → url0\n' > "$GIORNO_LOG"
BIL=$(GIORNO_DATA=2026-10-09 bash "$GP" bilancino 2>&1)
grep -q "repo: 1 consegne\|repo.*1 consegne" <<<"$BIL" && grep -q "1 lenti" <<<"$BIL" && grep -q "1 handoff" <<<"$BIL" && ok "bilancino giorno: consegne, lenti e handoff contati per repo" || ko "bilancino giorno: consegne, lenti e handoff contati (uscita: $BIL)"
grep -q "altro" <<<"$BIL" && ! grep -q "vecchio" <<<"$BIL" && ok "bilancino giorno: solo il giorno chiesto (ieri non contamina)" || ko "bilancino giorno: solo il giorno chiesto"

# ── digest: la riga del giorno c'è ───────────────────────────────────────────────
grep -q "GIORNO DI IERI" "$MD" && ok "digest: la sezione GIORNO DI IERI esiste" || ko "digest: la sezione GIORNO DI IERI esiste"

# ── skill: il giorno è scopribile dagli agenti (LLM-agnostico) ───────────────────
[ -f "$HERE/.claude/skills/giorno/SKILL.md" ] && ok "skill giorno in .claude/skills (Claude Code la vede)" || ko "skill giorno in .claude/skills"
[ -f "$HERE/.opencode/skills/giorno/SKILL.md" ] && ok "skill giorno in .opencode/skills (opencode la vede)" || ko "skill giorno in .opencode/skills"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
