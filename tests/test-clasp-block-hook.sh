#!/bin/bash
# test-clasp-block-hook.sh — il dento della regola «clasp push MAI» (giri
# avversari 2026-08-28, attacco B8/F1): fino a oggi la regola era advisory.
# Verifica che l'hook NEGI davvero clasp push/deploy (permissionDecision deny),
# lasci passare clasp pull/version (lettura), avverta sui comandi con
# credenziali (additionalContext) e taccia su comandi innocui.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/clasp-block-hook.sh"
SETTINGS="$HERE/.claude/settings.json"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$HOOK" ] && ok "l'hook è eseguibile" || ko "tools/clasp-block-hook.sh non è eseguibile"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cd repo && clasp push"}}' | bash "$HOOK")
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && ok "clasp push → permissionDecision deny" || ko "clasp push NON negato"
echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -ic "produzione\|NEGATO" >/dev/null \
  && ok "il deny dice perché" || ko "il deny non spiega"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp deploy -P xxx"}}' | bash "$HOOK")
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && ok "clasp deploy → deny" || ko "clasp deploy NON negato"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp pull"}}' | bash "$HOOK")
[ -z "$OUT" ] && ok "clasp pull (lettura): silenzio, non blocca" || ko "clasp pull disturbato inutilmente"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cat ~/.clasp.json | head -1"}}' | bash "$HOOK")
echo "$OUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 \
  && ok "comando con credenziali → contesto di avviso" || ko "comando con credenziali ignorato"
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && ko "leggere credenziali NEGATO (troppo: deve solo avvisare)" \
  || ok "leggere credenziali non è negato (advisory giusto)"

OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | bash "$HOOK")
[ -z "$OUT" ] && ok "comando innocuo: silenzio" || ko "comando innocuo produce rumore"

OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"x.md","command":"clasp push"}}' | bash "$HOOK")
[ -z "$OUT" ] && ok "tool non-Bash ignorato" || ko "si intromette su tool sbagliati"

# --- CORREZIONE (dal campo, REPO-V, progetto GAS nuovo, 2026-09-03) -----------
# Buco reale trovato installando lo standard su una repo nuova: l'ancora
# `(^|[;&|][[:space:]]*)clasp` accetta clasp solo a inizio comando o dopo un
# separatore shell. `npx ` è uno spazio, non un separatore — e su una macchina
# senza clasp installato globalmente `npx clasp push` è LA forma normale di
# invocarlo. Il cancello passava tutte le attese qui sopra ed era comunque
# scavalcabile: nessuna di esse copriva un runner davanti al comando.
for FORMA in \
  "npx clasp push" \
  "npx clasp deploy" \
  "npx @google/clasp push" \
  "npx --yes clasp push" \
  "bunx clasp push" \
  "pnpm dlx clasp push" \
  "yarn dlx clasp deploy" \
  "./node_modules/.bin/clasp push" \
  "cd progetto && npx clasp push"; do
  OUT=$(jq -n --arg c "$FORMA" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK")
  echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
    && ok ""$FORMA" -> deny" || ko ""$FORMA" NON negato: il cancello si scavalca"
done

# --- PARITÀ della correzione ------------------------------------------------
# La difesa contro il falso positivo già pagata (campo REPO-E 2026-09-01: un
# `git commit` il cui MESSAGGIO citava la forma vietata veniva negato, due volte
# in una sessione) deve restare in piedi DOPO l'allargamento della regex: è
# esattamente l'attesa che un allargamento sciatto romperebbe per prima.
for INNOCUO in \
  'git commit -m "vieta clasp push"' \
  'git log --grep="clasp deploy"' \
  'echo "il deploy è di Luca: clasp push mai"' \
  "npx clasp pull" \
  "npx clasp versions" \
  "grep -rn clasp tools/"; do
  OUT=$(jq -n --arg c "$INNOCUO" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK")
  echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
    && ko ""\$INNOCUO" negato — falso positivo, non scrive in produzione" \
    || ok ""\$INNOCUO" non negato (giusto)"
done

# --- LIMITE DICHIARATO (scarto mai silenzioso) ------------------------------
# Forme NON coperte, per scelta e non per dimenticanza: prefissi di ambiente
# (`env FOO=1 clasp push`), `sudo`, alias di shell, e un percorso assoluto
# arbitrario verso il binario. Coprirle richiederebbe di riconoscere un comando
# arbitrario invece di un runner noto, e ogni allargamento in più riapre il
# falso positivo appena difeso qui sopra. Il cancello è una difesa contro
# l'errore, non contro un aggressore: chi vuole aggirarlo ci riesce comunque,
# e la regola resta scritta in CLAUDE.md per quel caso.

jq -e '.hooks.PreToolUse[] | select(.matcher | split("|") | index("Bash")) | .hooks[] | select(.command | contains("clasp-block"))' "$SETTINGS" >/dev/null 2>&1 \
  && ok "settings.json registra l'hook su Bash" || ko "settings.json non registra clasp-block-hook"



# ── H7 del report REPO-I (2026-09-19): la via documentata e i grep innocenti ──────
SB7=$(mktemp -d /tmp/clasp-h7.XXXXXX); trap 'rm -rf "$SB7"' EXIT
printf '{"scripts":{"push":"clasp push","deploy":"clasp push --force"}}' > "$SB7/package.json"
cp "$HOOK" "$SB7/hook.sh"
decide7() { D=$(echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | (cd "$SB7" && bash hook.sh) | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null); [ -n "$D" ] || D=consentito; printf '%s' "$D"; }
D=$(decide7 'npm run push')
[ "$D" = "deny" ] && ok "H7: npm run push risolto da package.json → NEGATO" || ko "H7: npm run push passa ($D)"
D=$(decide7 'npm run deploy')
[ "$D" = "deny" ] && ok "H7: npm run deploy → NEGATO" || ko "H7: npm run deploy passa ($D)"
D=$(decide7 'npm run test')
[ "$D" = "consentito" ] && ok "H7: npm run test (script pulito) → consentito" || ko "H7: npm run test negato ($D)"
D=$(decide7 "grep 'npx clasp push' docs | wc -l")
[ "$D" = "consentito" ] && ok "H7: grep con la forma nei DATI → consentito (falso positivo curato)" || ko "H7: grep innocente negato ($D)"
D=$(decide7 'npx clasp push')
[ "$D" = "deny" ] && ok "H7: forma diretta resta NEGATA" || ko "H7: forma diretta passa ($D)"

# ── D27 (test del sistema completo 2026-09-20): i backtick sono DATI ─────────────────
# Il comando che scriveva il report di campo (un heredoc che citava le forme vietate fra
# backtick, come fa qualunque .md del canone) e' stato negato: il cancello spogliava solo
# le stringhe fra virgolette. Un .md che DOCUMENTA il divieto deve potersi scrivere.
BT='`'
D=$(decide7 "cat > docs/nota.md <<EOF\nil cancello nega ${BT}npx clasp push${BT} e ${BT}clasp deploy${BT}\nEOF")
[ "$D" = "consentito" ] && ok "D27: forma vietata fra backtick in un heredoc → consentito (sono dati)" || ko "D27: documento che cita la forma fra backtick NEGATO ($D)"
D=$(decide7 "echo ${BT}clasp push${BT}")
[ "$D" = "consentito" ] && ok "D27: backtick semplici → consentito" || ko "D27: backtick semplici negati ($D)"
D=$(decide7 'clasp push')
[ "$D" = "deny" ] && ok "D27: la forma NUDA resta negata dopo lo spoglio dei backtick" || ko "D27: la forma nuda passa ($D)"

# ── Revisione 10 giri (2026-09-23): le forme composte della shell ────────────────────
# L'ancora SEP accettava solo inizio riga e ; & | — undici forme comuni passavano, fra cui
# il LOOP generato (la forma dell'incidente REPO-Q) e `bash -c "…"` (le virgolette sono
# dati per lo spoglio, ma bash -c le ESEGUE).
for F in 'for d in a b; do clasp push; done' 'bash -c "clasp push"' "sh -c 'npx clasp push'" '(clasp push)' \
         'if true; then clasp deploy; fi' 'time clasp push' 'xargs -n1 clasp push' '{ clasp push; }' \
         'nohup clasp push &' 'exec clasp push' 'while true; do npx clasp deploy; done'; do
  D=$(jq -n --arg c "$F" '{tool_name:"Bash",tool_input:{command:$c}}' | (cd "$SB7" && bash hook.sh) | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  [ "$D" = "deny" ] && ok "forma composta NEGATA: $F" || ko "forma composta PASSA: $F"
done
# (revisione 10 giri): il SAL che documentava queste forme e' stato NEGATO — uno span fra
# backtick che va a capo non veniva spogliato (sed lavora per riga), e `bash -c "…"` fra
# backtick e' un dato, non un'esecuzione. Il falso positivo nato dalla cura, curato.
BT='`'
F="cat >> SAL.md <<'EOF'
il LOOP generato (${BT}for d in x; do clasp push;
done${BT}) e ${BT}bash -c \"clasp push\"${BT} erano forme che passavano
EOF"
D=$(jq -n --arg c "$F" '{tool_name:"Bash",tool_input:{command:$c}}' | (cd "$SB7" && bash hook.sh) | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
[ -z "$D" ] && ok "heredoc con forme fra backtick su piu' righe → consentito (sono dati)" || ko "documento che cita le forme su piu' righe NEGATO"
F="cd x
clasp push"
D=$(jq -n --arg c "$F" '{tool_name:"Bash",tool_input:{command:$c}}' | (cd "$SB7" && bash hook.sh) | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
[ "$D" = "deny" ] && ok "a capo e' un separatore: «cd x⏎clasp push» → NEGATO" || ko "a capo come separatore: la seconda riga passa"
# e i falsi positivi gia' difesi restano consentiti
for F in "grep 'npx clasp push' docs" 'git commit -m "vieta clasp push"' 'echo "clasp push"' 'echo done clasp-notes'; do
  D=$(jq -n --arg c "$F" '{tool_name:"Bash",tool_input:{command:$c}}' | (cd "$SB7" && bash hook.sh) | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  [ -z "$D" ] && ok "dati, non invocazione → consentito: $F" || ko "falso positivo: $F → $D"
done

# ── REPO-Q (2026-09-02): GENERARE un push dentro un clone di sola lettura ────────────
# Il DEBITI del 2026-09-03 lo dava per codice morto (stessa condizione del deny). Dopo
# D27 il deny guarda il comando SPOGLIATO, l'avviso quello intero: un comando che SCRIVE
# un push fra virgolette (lo script che l'umano eseguira') passa il deny e riceve l'avviso.
# Revisione 10 giri 2026-09-23: la guardia della lezione REPO-Q non aveva un'attesa.
touch "$SB7/.mirror-boundaries"
CTX=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo '"'"'cd x && clasp push'"'"' > deploy.sh"}}' | (cd "$SB7" && bash hook.sh) | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)
grep -q "mirror-boundaries" <<<"$CTX" && ok "REPO-Q: push GENERATO in un mirror → avviso mirror-boundaries" || ko "REPO-Q: nessun avviso mirror sul push generato"
D=$(decide7 'clasp push')
[ "$D" = "deny" ] && ok "REPO-Q: nel mirror la forma nuda resta NEGATA (il deny vince sull'avviso)" || ko "REPO-Q: forma nuda nel mirror passa ($D)"
rm -f "$SB7/.mirror-boundaries"

# ── (2026-09-23, sì di Luca) il corpo di un HEREDOC e' dato, non comando ─────────────────────────
# Il falso positivo, misurato due volte in una sessione: un heredoc che scriveva un file (python
# che riscrive CLAUDE.md, un `cat >> SAL.md`) citava la regola «(clasp push/deploy MAI…)» e veniva
# NEGATO — l'a capo diventa `;`, la `(` conta come separatore, e il testo del file sembrava un
# comando. Il corpo si toglie prima del confronto; ma se il heredoc NUTRE una shell
# (`bash <<EOF`, `cat <<EOF | sh`) e' codice eseguito, e si guarda come prima.
decideh() { # decideh <comando multi-riga> → deny | consentito
  local D
  D=$(jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  [ -n "$D" ] || D=consentito; printf '%s' "$D"
}
P='clasp'; V='push'   # la forma vietata si compone: il sorgente del banco non la contiene nuda
[ "$(decideh "python3 - <<'PY'
s = '''l'hub: il deploy e' dell'umano (${P} ${V}/deploy MAI)'''
PY")" = "consentito" ] && ok "heredoc di python che CITA la regola fra parentesi: consentito (era il falso positivo)" || ko "heredoc di python che cita la regola: ancora negato"
[ "$(decideh "cat >> SAL.md <<'EOF'
- riga universale aggiunta (${P} ${V} MAI dall'agente)
EOF")" = "consentito" ] && ok "cat >> file <<EOF con la regola nel testo: consentito" || ko "heredoc verso un file: ancora negato"
[ "$(decideh "cat > note.md <<-FINE
	poi a mano (${P} ${V}) dal Mac
	FINE")" = "consentito" ] && ok "heredoc <<- (delimitatore con tab): corpo tolto, consentito" || ko "heredoc <<- non riconosciuto"
# ... ma dove il heredoc e' codice, resta negato
[ "$(decideh "bash <<'EOF'
cd x
${P} ${V}
EOF")" = "deny" ] && ok "bash <<EOF col push nel corpo: NEGATO (la shell lo esegue)" || ko "bash <<EOF col push: passa"
[ "$(decideh "cat <<EOF | sh
${P} ${V}
EOF")" = "deny" ] && ok "cat <<EOF | sh: NEGATO (il corpo va a una shell)" || ko "heredoc in pipe verso sh: passa"
[ "$(decideh "cat > x.txt <<EOF
dato
EOF
${P} ${V}")" = "deny" ] && ok "push DOPO la fine del heredoc: NEGATO" || ko "push dopo il heredoc: passa"
[ "$(decideh "cat > x.txt <<EOF
${P} ${V}")" = "deny" ] && ok "heredoc senza chiusura: il corpo non si toglie (prudenza), NEGATO" || ko "heredoc aperto: passa"
[ "$(decideh "grep -c x <<<\"testo\"
${P} ${V}")" = "deny" ] && ok "<<< (herestring) non e' un heredoc: il push sotto resta NEGATO" || ko "herestring scambiata per heredoc"

# ── (2026-09-23, giro A7 della notte) deploy-ora e' il gesto di LUCA: l'agente non lo invoca ──────
[ "$(decideh "bash tools/deploy-ora.sh repo")" = "deny" ] && ok "bash tools/deploy-ora.sh: NEGATO (il deploy assistito e' dell'umano)" || ko "l'agente puo' invocare deploy-ora"
[ "$(decideh "echo si | bash tools/deploy-ora.sh repo")" = "deny" ] && ok "echo si | deploy-ora: NEGATO" || ko "il si in pipe verso deploy-ora passa il cancello"
[ "$(decideh "./tools/deploy-ora.sh repo")" = "deny" ] && ok "./tools/deploy-ora.sh: NEGATO" || ko "deploy-ora col percorso relativo passa"
[ "$(decideh "grep -n deploy-ora tools/prepara-deploy.sh")" = "consentito" ] && ok "cercare deploy-ora con grep: consentito (e' un argomento, non un'invocazione)" || ko "grep su deploy-ora negato a torto"
[ "$(decideh "bash tools/prepara-deploy.sh repo")" = "consentito" ] && ok "prepara-deploy (solo il pacchetto): consentito" || ko "prepara-deploy negato a torto"

# ── (2026-09-23, giro A1 della notte) SENZA jq il cancello era APERTO: `command -v jq || exit 0` ──
# Solo `exit 2` blocca senza JSON (documentazione degli hook di Claude Code). Senza jq: modo prudente.
NOJQ=$(mktemp -d); for b in bash sh cat printf tr sed grep awk head tail env; do ln -s "$(command -v "$b")" "$NOJQ/$b" 2>/dev/null; done
senza_jq() { printf '%s' "$1" | PATH="$NOJQ" bash "$HOOK" >/dev/null 2>&1; echo $?; }
[ "$(senza_jq '{"tool_name":"Bash","tool_input":{"command":"clasp push"}}')" = "2" ] && ok "senza jq: clasp push NEGATO (exit 2, modo prudente)" || ko "senza jq il cancello e' aperto"
[ "$(senza_jq '{"tool_name":"Bash","tool_input":{"command":"bash tools/deploy-ora.sh r"}}')" = "2" ] && ok "senza jq: deploy-ora NEGATO" || ko "senza jq deploy-ora passa"
[ "$(senza_jq '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}')" = "0" ] && ok "senza jq: un comando innocuo passa" || ko "senza jq tutto e' bloccato"
[ "$(senza_jq '{"tool_name":"Bash","tool_input":{"command":"clasp deployments"}}')" = "0" ] && ok "senza jq: clasp deployments (sola lettura) passa" || ko "senza jq clasp deployments negato"
rm -rf "$NOJQ"

# ── (2026-09-23, giro A1 della notte) le forme della shell che scavalcavano il cancello, provate ─
for FORMA in "if ${P} ${V}; then echo ok; fi" "! ${P} ${V}" "while ${P} ${V}; do sleep 1; done" "until ${P} ${V}; do sleep 1; done" \
             "timeout 600 ${P} ${V}" "timeout -k 5 60 ${P} ${V}" "command ${P} ${V}" "nice ${P} ${V}" "nice -n 10 ${P} ${V}" "watch ${P} ${V}" \
             "cat x | xargs -I{} ${P} ${V}" "xargs -n 1 ${P} ${V}" "find . -name .clasp.json -execdir ${P} ${V} \\;" "parallel ${P} ${V} ::: a b" \
             "${P} -A creds.json ${V}" "${P} --auth creds.json ${V}" "cd x && ${P} -P ./src deploy"; do
  [ "$(decideh "$FORMA")" = "deny" ] && ok "NEGATO: $FORMA" || ko "passa il cancello: $FORMA"
done
[ "$(decideh "${P} deployments")" = "consentito" ] && ok "${P} deployments (elenca soltanto): consentito" || ko "${P} deployments negato a torto (deploy combaciava con deployments)"
[ "$(decideh "${P} pull && ${P} status")" = "consentito" ] && ok "${P} pull e status: consentiti" || ko "lettura negata a torto"

# ── Q5 R3-R4-R6 (2026-09-24, quarto ventaglio, «i ganci come avversario»): forme che PASSAVANO il gancio
# e che, col clasp finto, eseguivano davvero il push (provato dal giro). Sono le vie NORMALI di un
# agente distratto, non di un aggressore: i runner senza `run`, `npm start`, le catene di script, il
# package.json della sottocartella, la shell dopo `/` o attaccata al heredoc, eval e source, il
# sottocomando fra virgolette, il tool Monitor.
SBQ=$(mktemp -d /tmp/clasp-q5.XXXXXX); mkdir -p "$SBQ/sub"
printf '{"scripts":{"dp":"npm run inoltra","inoltra":"npm run push","push":"clasp push","start":"clasp push","test":"echo ok"}}' > "$SBQ/package.json"   # dp → inoltra → push: la catena a due anelli, nell'ordine che un solo giro non risolve
printf '{"scripts":{"rilascia":"clasp deploy"}}' > "$SBQ/sub/package.json"
cp "$HOOK" "$SBQ/hook.sh"
decideq() { # decideq <tool> <comando>
  D=$(jq -cn --arg t "$1" --arg c "$2" '{tool_name:$t, tool_input:{command:$c}}' | (cd "$SBQ" && bash hook.sh) | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  [ -n "$D" ] || D=consentito; printf '%s' "$D"; }
NQ=0; for FORMA in 'pnpm push' 'yarn push' 'bun push' 'npm start' 'npm run dp' 'npm run "push"' \
  'npm --prefix sub run rilascia' 'cd sub && npm run rilascia' 'yarn --cwd sub rilascia' \
  $'bash<<EOF\nclasp push\nEOF' $'/bin/bash <<EOF\nclasp push\nEOF' $'source /dev/stdin <<EOF\nclasp push\nEOF' \
  '/bin/bash -c "clasp push"' 'bash -o pipefail -c "clasp push"' 'bash -c -- "clasp push"' 'bash --norc -c "clasp push"' \
  'eval clasp push' 'eval "clasp push"' 'clasp "push"' "clasp 'deploy'"; do
  D=$(decideq Bash "$FORMA"); [ "$D" = deny ] || { NQ=$((NQ+1)); ko "Q5: passa → $(tr '\n' '~' <<<"$FORMA")"; }
done
[ "$NQ" -eq 0 ] && ok "Q5: 20 forme normali di clasp push/deploy (runner, catene, sottocartelle, shell, eval, virgolette) → NEGATE"
D=$(decideq Monitor 'clasp push'); [ "$D" = deny ] && ok "Q5: il tool Monitor esegue un comando di shell: clasp push → NEGATO" || ko "Q5: Monitor clasp push passa ($D)"
grep -c '"matcher": "Bash|Monitor"' "$SETTINGS" >/dev/null && ok "Q5: il gancio e' registrato anche per Monitor" || ko "Q5: settings.json registra il gancio solo per Bash"
# (2026-09-24, quinto ventaglio, R2 R3): npm risale fino al package.json piu' vicino; il gancio cercava solo da
# $PWD in giu'. In un progetto clasp (package.json alla radice, sorgenti in src/) `cd src && npm run push`
# passava, e npm eseguiva clasp push. Qui: da una sottocartella senza package.json, e col solo campo cwd.
mkdir -p "$SBQ/src"
dsub() { jq -cn --arg c "$1" --arg w "$2" '{tool_name:"Bash", cwd:$w, tool_input:{command:$c}}' \
  | (cd "$3" && env -u CLAUDE_PROJECT_DIR bash "$SBQ/hook.sh") | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null; }
[ "$(dsub 'npm run push' "$SBQ/src" "$SBQ/src")" = deny ] && ok "R2 R3: da src/ senza package.json, npm run push (quello della radice) → NEGATO" \
  || ko "R2 R3: da una sottocartella npm run push passa"
ALTROVE=$(mktemp -d /tmp/clasp-altrove.XXXXXX)
[ "$(dsub 'npm start' "$SBQ/src" "$ALTROVE")" = deny ] && ok "R2 R3: la cartella della sessione si legge dal campo cwd dell'input" \
  || ko "R2 R3: col campo cwd e il gancio lanciato altrove, npm start passa"
[ -z "$(dsub 'npm test' "$SBQ/src" "$SBQ/src")" ] && ok "R2 R3: da src/, npm test resta consentito" || ko "R2 R3: npm test negato a torto da src/"
rmdir "$ALTROVE"
for LECITO in 'npm test' 'npm install' 'npm run test' $'cat <<EOF > note.md\nclasp push resta vietato\nEOF' "grep -rn 'clasp push' docs"; do
  D=$(decideq Bash "$LECITO"); [ "$D" = consentito ] && ok "Q5: consentito → $(tr '\n' '~' <<<"$LECITO")" || ko "Q5: negato a torto → $(tr '\n' '~' <<<"$LECITO")"
done
rm -rf "$SBQ"

# (Q5, 2026-09-24): il gancio che MUORE deve negare, non lasciar passare. Una copia con un crash iniettato
# subito dopo la lettura dell'input (una variabile mai definita, sotto set -u — il difetto vero del giorno).
SBX=$(mktemp -d /tmp/clasp-crash.XXXXXX)
# (2026-09-24, sesto ventaglio, S5 R1): era `sed '/re/a testo'` su una riga sola — il sed del Mac lo rifiuta
# («command a expects \ followed by text»), il crash non si iniettava e la suite si fermava qui. awk c'e' ovunque.
awk '{print} /^trap prudente EXIT$/{print "echo \"$VARIABILE_MAI_DEFINITA_Q5\""}' "$HOOK" > "$SBX/hook.sh"
grep -c 'VARIABILE_MAI_DEFINITA_Q5' "$SBX/hook.sh" >/dev/null || ko "premessa: crash non iniettato (la riga della trappola e' cambiata?)"
jq -cn '{tool_name:"Bash",tool_input:{command:"npx clasp push"}}' | bash "$SBX/hook.sh" >/dev/null 2>&1; RCX=$?
[ "$RCX" -eq 2 ] && ok "gancio morto su clasp push: nega (exit 2, modo prudente)" || ko "gancio morto su clasp push: rc $RCX — il comando passerebbe"
jq -cn '{tool_name:"Bash",tool_input:{command:"ls -la"}}' | bash "$SBX/hook.sh" >/dev/null 2>&1; RCX=$?
[ "$RCX" -eq 0 ] && ok "gancio morto su un comando innocuo: passa (non blocca tutto)" || ko "gancio morto su ls: rc $RCX"
# (2026-09-25, settimo ventaglio, V4 R1): il ramo che nega `npm run <script-con-clasp-push>` e' proprio quello che moriva
# sul Mac (una variabile attaccata a «). Il modo prudente conosceva solo la parola clasp nel comando: `npm run pubblica`
# passava. Ora nega un runner di script quando un package.json vicino ha uno script che fa clasp push/deploy.
mkdir -p "$SBX/gas/src" "$SBX/web"
printf '{"scripts":{"pubblica":"clasp push -f"},"devDependencies":{"@google/clasp":"^2.4"}}\n' > "$SBX/gas/package.json"
printf '{"scripts":{"test":"node t.js"}}\n' > "$SBX/web/package.json"
RCX=$(cd "$SBX/gas/src" && jq -cn '{tool_name:"Bash",tool_input:{command:"npm run pubblica"}}' | bash "$SBX/hook.sh" >/dev/null 2>&1; echo $?)
[ "$RCX" -eq 2 ] && ok "V4 R1: gancio morto, npm run di uno script che fa clasp push: nega" || ko "V4 R1: gancio morto, npm run pubblica passa (rc $RCX)"
RCX=$(cd "$SBX/web" && jq -cn '{tool_name:"Bash",tool_input:{command:"npm run test"}}' | bash "$SBX/hook.sh" >/dev/null 2>&1; echo $?)
[ "$RCX" -eq 0 ] && ok "V4 R1: gancio morto, npm run in un progetto senza clasp: passa" || ko "V4 R1: gancio morto, npm run test negato (rc $RCX)"
NOJQ=$(mktemp -d); for b in bash sh cat printf tr sed grep awk head tail env; do ln -s "$(command -v "$b")" "$NOJQ/$b" 2>/dev/null; done
RCX=$(cd "$SBX/gas/src" && printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm run pubblica"}}' | PATH="$NOJQ" bash "$HOOK" >/dev/null 2>&1; echo $?)
[ "$RCX" -eq 2 ] && ok "V4 R1: senza jq, npm run di uno script che fa clasp push: nega" || ko "V4 R1: senza jq, npm run pubblica passa (rc $RCX)"
rm -rf "$NOJQ"
rm -rf "$SBX"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
