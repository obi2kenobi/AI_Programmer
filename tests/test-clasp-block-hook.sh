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
echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -qi "produzione\|NEGATO" \
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

jq -e '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.command | contains("clasp-block"))' "$SETTINGS" >/dev/null 2>&1 \
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
echo "$CTX" | grep -q "mirror-boundaries" && ok "REPO-Q: push GENERATO in un mirror → avviso mirror-boundaries" || ko "REPO-Q: nessun avviso mirror sul push generato"
D=$(decide7 'clasp push')
[ "$D" = "deny" ] && ok "REPO-Q: nel mirror la forma nuda resta NEGATA (il deny vince sull'avviso)" || ko "REPO-Q: forma nuda nel mirror passa ($D)"
rm -f "$SB7/.mirror-boundaries"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
