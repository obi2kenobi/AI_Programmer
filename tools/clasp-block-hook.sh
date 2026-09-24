#!/bin/bash
# clasp-block-hook.sh — il DENTE della regola «clasp push MAI» (giri avversari
# 2026-08-28, attacco B8/F1: la regola viveva solo nei promemoria — nessun
# blocco tecnico, un agente confuso poteva deployare in produzione).
# PreToolUse su Bash: `clasp push` e `clasp deploy` vengono NEGATI davvero
# (permissionDecision: deny). I comandi che toccano credenziali ricevono un
# CONTESTO di avviso (advisory: leggere le proprie credenziali a volte è
# legittimo — dipende da cosa se ne fa). Tutto il resto: silenzio.
#
# Il deploy è dell'umano: questa è l'unica regola del sistema che da oggi
# non dipende dalla memoria dell'agente.
set -uo pipefail
# dove <percorso>: il percorso, e se nella repo non c'e' (un satellite) la nota che vive nell'hub
# (2026-09-24, notte dei giri, T1#4: nei satelliti i promemoria mandavano l'agente a file assenti)
dove() {   # con un * si guarda se il glob trova qualcosa, senza si guarda il percorso
  case "$1" in *\**) compgen -G "$PWD/$1" >/dev/null 2>&1 ;; *) [ -e "$PWD/$1" ] ;; esac \
    && printf '%s' "$1" || printf "%s (nell'hub AI_Programmer)" "$1"
}
# (2026-09-23, giro A1 della notte): senza jq il cancello era APERTO (`|| exit 0`), e senza JSON
# solo `exit 2` blocca (documentazione degli hook di Claude Code). Senza jq: MODO PRUDENTE — un
# grep sull'input grezzo nega push/deploy/deploy-ora con exit 2; tutto il resto passa. Puo'
# negare a torto una citazione (niente spoglio senza jq): meglio un falso rosso che un cancello aperto.
if ! command -v jq >/dev/null 2>&1; then
  GREZZO="$(cat)"
  if grep -qE 'clasp[^"]*[^a-z](push|deploy)([^a-z]|$)|deploy-ora' <<<"$GREZZO"; then
    echo "NEGATO (clasp-block-hook, jq ASSENTE: modo prudente): clasp push/deploy e deploy-ora sono dell'umano. Installa jq per il cancello completo." >&2
    exit 2
  fi
  exit 0
fi

INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0
TOOL="$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
[ "$TOOL" = "Bash" ] || exit 0

# Che cos'è un'INVOCAZIONE di clasp (una definizione, usata da entrambi i rami sotto:
# prima viveva copiata in due grep che potevano divergere).
#   SEP  — a inizio comando o dopo un separatore shell. Dal campo REPO-E 2026-09-01:
#          il grep libero negava un `git commit` il cui MESSAGGIO citava la forma
#          vietata (falso positivo 2 volte in una sessione). L'ancora resta.
#   RUN  — un runner noto davanti al comando, con le sue opzioni. Dal campo (REPO-V,
#          progetto GAS nuovo, 2026-09-03): l'ancora da sola lasciava passare
#          `npx clasp push`, perché `npx ` è uno spazio e non un separatore — ed è LA
#          forma normale di invocare clasp dove non è installato globalmente. Il
#          cancello passava tutte le sue attese ed era comunque scavalcabile.
#   BIN  — percorso al binario (./node_modules/.bin/clasp) e scope del pacchetto
#          (@google/clasp).
# NON coperti, per scelta dichiarata: prefissi di ambiente (`env FOO=1 clasp push`),
# `sudo`, alias di shell. Riconoscerli vorrebbe dire accettare un comando arbitrario
# davanti a clasp, e riaprirebbe il falso positivo appena difeso. Questo è un cancello
# contro l'errore, non contro un aggressore (attese e limiti: tests/test-clasp-block-hook.sh).
# (revisione 10 giri, 2026-09-23): SEP accettava solo inizio riga e ; & | — undici forme
# comuni della shell passavano: il LOOP generato (`for …; do clasp push; done`, la forma
# dell'incidente REPO-Q), `(…)`, `{ …; }`, `if …; then …`, e i prefissi che eseguono il
# comando che segue (time, nohup, exec, xargs). Ora SEP riconosce anche ( { e le parole della
# shell che aprono un comando. I prefissi ARBITRARI (env, sudo) restano fuori, per la ragione
# detta sotto.
# (2026-09-23, giro A1 della notte): 17 forme comuni passavano ancora, provate eseguendo — le parole
# che ESEGUONO il comando che segue (if, !, while, until, timeout N, command, nice, watch, xargs con
# opzioni, find -execdir, parallel), le opzioni di clasp PRIMA del sottocomando (`clasp -A f push`),
# e `deploy` combaciava con `deployments`, che elenca soltanto. Tre pezzi: PREF, OPT, FINE.
PREF='(do|then|else|elif|if|while|until|!|time|nohup|exec|command|watch([[:space:]]+-[^[:space:]]+)*|nice([[:space:]]+-n[[:space:]]*-?[0-9]+|[[:space:]]+-[0-9]+)?|timeout([[:space:]]+-[^[:space:]]+([[:space:]]+[0-9.]+[smhd]?)?)*[[:space:]]+[0-9.]+[smhd]?|xargs([[:space:]]+-[^[:space:]]+([[:space:]]+[0-9]+)?)*|-exec(dir)?|parallel([[:space:]]+-[^[:space:]]+)*)'
SEP="(^|[;&|({][[:space:]]*|(^|[;&|({][[:space:]]*|[[:space:]])${PREF}[[:space:]]+)"
RUN='((npx|bunx|npm[[:space:]]+exec|pnpm[[:space:]]+dlx|yarn[[:space:]]+dlx)[[:space:]]+(-{1,2}[A-Za-z0-9-]+[[:space:]]+)*)?'
BIN='([A-Za-z0-9_./-]*/)?(@google/)?'
OPT='([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:];&|][^[:space:];&|]*)?)*'
FINE='([[:space:];&|)"'"'"']|$)'
INVOCAZIONE="${SEP}${RUN}${BIN}clasp${OPT}[[:space:]]+(push|deploy)${FINE}"
# `bash -c "…"` (e sh/zsh/dash): le virgolette sono DATI per lo spoglio qui sotto, ma
# l'interprete le ESEGUE — si guarda il comando intero, con l'invocazione dentro le virgolette.
SHC="(^|[;&|({[:space:]])(ba|z|da)?sh[[:space:]]+(-[A-Za-z]+[[:space:]]+)*-[A-Za-z]*c[[:space:]]+[\"']([^\"']*[;&|({][[:space:]]*)?${RUN}${BIN}clasp${OPT}[[:space:]]+(push|deploy)${FINE}"

# (report REPO-I 2026-09-19, H7 — due buchi misurati eseguendo):
#   a) `npm run push` non contiene la stringa clasp e PASSAVA — ed e' la via che
#      i documenti del progetto insegnano. Ora il cancello risolve gli script di
#      package.json: se il comando risolto contiene l'invocazione, nega.
#   b) due grep in SOLA LETTURA erano negati perche' la STRINGA DI RICERCA
#      conteneva 'npx clasp push' — il runner dentro le virgolette combaciava con
#      RUN. Le stringa quotate sono DATI, non invocazioni: si spogliano prima del
#      match. (Dichiarato non coperto: `bash scripts/deploy.sh` richiederebbe
#      leggere script arbitrari — la via lunga sta nella P6 del report.)
# (D27, test del sistema completo 2026-09-20): anche i BACKTICK sono dati — il comando che
# scriveva il report di campo (heredoc con `npx clasp push` citato come forma vietata)
# e' stato NEGATO. Stesso falso positivo di REPO-E in una forma nuova.
# (revisione 10 giri, 2026-09-23): lo spoglio lavorava PER RIGA (sed) — uno span fra backtick
# che va a capo non si toglieva, e il SAL che documentava le forme vietate e' stato negato.
# Ora l'a capo diventa `;` (e' un separatore della shell: «cd x⏎clasp push» resta negato),
# poi si tolgono i backtick (anche su piu' righe), poi le virgolette. Il controllo `bash -c`
# guarda il comando SENZA backtick ma CON le virgolette: fra backtick e' un dato citato.
# (2026-09-23, sì di Luca): il CORPO di un heredoc e' dato, non comando. Misurato due volte in una
# sessione: un heredoc che scriveva un file (python che riscrive CLAUDE.md, `cat >> SAL.md`)
# citava la regola «(… MAI)» fra parentesi e veniva NEGATO: l'a capo diventa `;`, la `(` e' un
# separatore, e il testo del file sembrava un'invocazione. Il corpo si toglie — tranne quando
# resta prudente tenerlo: la riga del heredoc nutre una SHELL (`bash <<EOF`, `cat <<EOF | sh`:
# quel corpo si esegue), la riga ha piu' di un heredoc, o il heredoc non si chiude mai.
# `<<<` (herestring) non e' un heredoc. Banco: tests/test-clasp-block-hook.sh, casi «heredoc».
senza_heredoc() {
  awk -v Q="'" '
    function scrivi_buf() { printf "%s", buf; buf = "" }
    dentro {
      t = $0; if (trattino) sub(/^\t+/, "", t)
      if (t == delim) { dentro = 0; buf = ""; next }
      buf = buf $0 "\n"; next
    }
    {
      print
      riga = $0; n = 0; resto = riga; re = "<<-?[ \t]*[\"" Q "]?[A-Za-z_][A-Za-z0-9_]*"
      while (match(resto, re)) {
        prima = (RSTART > 1) ? substr(resto, RSTART - 1, 1) : ""
        op = substr(resto, RSTART, RLENGTH)
        if (prima != "<" && substr(op, 3, 1) != "<") { n++; trovato = op }
        resto = substr(resto, RSTART + RLENGTH)
      }
      if (n != 1) next
      if (riga ~ /(^|[;&|({ \t])(ba|z|da)?sh([ \t]|$)/) next
      trattino = (substr(trovato, 3, 1) == "-")
      d = trovato; sub(/^<<-?[ \t]*/, "", d); gsub("[\"" Q "]", "", d)
      delim = d; dentro = 1; buf = ""
    }
    END { if (dentro) scrivi_buf() }
  '
}
CMD_H=$(printf '%s\n' "$CMD" | senza_heredoc)
CMD_UNA=$(printf '%s' "$CMD_H" | tr '\n' ';')
CMD_NOBT=$(printf '%s' "$CMD_UNA" | sed "s/\`[^\`]*\`//g")
CMD_STRIPPED=$(printf '%s' "$CMD_NOBT" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")

# NEGATO davvero: scrittura in produzione senza staging e senza rollback
if grep -qE "$INVOCAZIONE" <<<"$CMD_STRIPPED" || grep -qE "$SHC" <<<"$CMD_NOBT"; then
  jq -n --arg r "NEGATO (clasp-block-hook): clasp push/deploy scrive in PRODUZIONE senza staging né rollback. La regola è del metodo AI_Programmer: il deploy è dell'umano, che prima confronta col vivo (clasp clone + diff). Se il push è davvero giusto, lo fa Luca a mano." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

# (2026-09-23, giro A7 della notte): deploy-ora e' il GESTO di Luca, dal suo terminale — un agente
# non lo invoca. Prima `echo si | bash tools/deploy-ora.sh X` passava questo cancello (vede solo il
# comando esterno) e deploiava. Si nega l'invocazione, non la citazione: `grep deploy-ora …` passa.
DEPLOY_ORA="${SEP}${RUN}((ba|z|da)?sh[[:space:]]+)?([A-Za-z0-9_./~-]*/)?deploy-ora(\.sh)?([[:space:]]|;|$)"
if grep -qE "$DEPLOY_ORA" <<<"$CMD_STRIPPED"; then
  jq -n --arg r "NEGATO (clasp-block-hook): deploy-ora e' il gesto del deploy di Luca, dal suo terminale — un agente non lo invoca (il deploy e' dell'umano). Prepara il pacchetto con $(dove tools/prepara-deploy.sh) e lascialo a lui." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

# H7a: la via documentata — npm run push / npm run deploy — risolta da package.json
if [ -f "$PWD/package.json" ] && grep -qE '(npm|yarn|pnpm|bun)[[:space:]]+(run|run-script)[[:space:]]+[A-Za-z0-9_.:-]+' <<<"$CMD_STRIPPED"; then
  for SCR in $(printf '%s' "$CMD_STRIPPED" | grep -oE '(npm|yarn|pnpm|bun)[[:space:]]+(run|run-script)[[:space:]]+[A-Za-z0-9_.:-]+' | awk '{print $NF}' | sort -u); do
    RISOLTO=$(jq -r --arg s "$SCR" '.scripts[$s] // empty' "$PWD/package.json" 2>/dev/null)
    [ -z "$RISOLTO" ] && continue
    if grep -qE "$INVOCAZIONE" <<<"$RISOLTO"; then
      jq -n --arg r "NEGATO (clasp-block-hook): npm run $SCR risolve in \`$RISOLTO\` — clasp push/deploy scrive in PRODUZIONE senza staging né rollback. Il deploy è dell'umano (report REPO-I, H7: la via documentata era proprio quella non presidiata)." \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
      exit 0
    fi
  done
fi

# (dal campo REPO-Q 2026-09-02: l'agente ha GENERATO un loop di clasp push
# che includeva directory dichiarate clone-di-sola-lettura nel CLAUDE.md del
# repo — Luca l'ha eseguito e ha sovrascritto 2 progetti sviluppati altrove.
# La guardia ora verifica anche il caso GENERAZIONE)
if grep -qE "$INVOCAZIONE" <<<"$CMD"; then
  MB="$PWD/.mirror-boundaries"
  if [ -f "$MB" ]; then
    jq -n --arg c "ATTENZIONE: questa directory ha .mirror-boundaries (cloni di sola lettura). Un clasp push qui sovrascriverebbe progetti sviluppati altrove. Verifica PRIMA di eseguire." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
    exit 0
  fi
fi

# (Q27, 2026-09-23): qui e sopra `grep … <<<"$X"`, mai `echo "$X" | grep -q` — sotto pipefail, su un
# comando di molte righe il produttore moriva di SIGPIPE e l'avviso taceva (5 su 5, tests/test-e002-codice.sh)
# ADVISORY: comandi che leggono/passano credenziali — possibili e a volte
# legittimi, ma chi li lancia deve sapere cosa sta toccando
if grep -qE 'clasp\.json|credenziali|\.env|printenv|secret|token[_ =]|refresh_token' <<<"$CMD"; then
  jq -n --arg c "Questo comando tocca credenziali: mai nel diff, mai nei log, mai in chat (pattern segreto-come-impronta). Se stai solo LEGGENDO per verificare un'impronta, ok — ma l'output resta locale." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
  exit 0
fi

exit 0
