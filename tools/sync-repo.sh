#!/bin/bash
# ⚠ QUESTO TOOL SCRIVE: clona la repo di destinazione e committa lo standard aggiornato (PR, mai push su main)
# sync-repo.sh — 2026-08-24, report dal campo su REPO-G (F2): onboard-repo.sh e
# bootstrap-app.sh sono A UN COLPO SOLO — copiano al momento dell'onboarding, e
# da lì ogni repo diverge silenziosamente mentre l'hub aggiorna CLAUDE.md
# (4 aggiunte in un solo ciclo). Questo strumento chiude il buco nella forma
# minima richiesta dal report: "un diff + copia basta per iniziare".
#
# Uso: tools/sync-repo.sh <owner/repo>                 → verifica e riporta il drift
#      tools/sync-repo.sh <owner/repo> --pr            → apre una PR di solo CLAUDE.md
#      tools/sync-repo.sh <owner/repo> --standard      → PR col sistema intero (skill, agenti, hook, formati)
#                                                          — è il comando insegnato in docs/benvenuto-collaboratori.md
#      tools/sync-repo.sh --from-local <dir>      → stesso confronto su una copia locale (per i test)
# Esiti: 0 allineato · 1 divergente (o errore) · il verdetto è sempre sulla riga finale.
# PERCORSO CLOUD/IBRIDO (report Budget Vendite 2026-09-19, difetto 3: questo e'
# IL COMANDO INSEGNATO in docs/benvenuto-collaboratori.md, e da una sessione cloud
# non puo' funzionare — nessun blocco lo diceva, a differenza di onboard-repo.sh):
# una sessione remota NON ha `gh` CLI. Da lì: replicare a mano la lista degli ITEM
# (righe sotto) + copia-hook.sh, e usare --from-local per la verifica. Il clone e
# la PR restano al Mac del proprietario. Un agente cloud deve DIRLO, non morire.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HUB_CLAUDE="$HERE/CLAUDE.md"

REPO=""
LOCAL_DIR=""
CON_PR=0
STANDARD=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pr) CON_PR=1 ;;
    --standard) STANDARD=1 ;;
    --from-local) LOCAL_DIR="$2"; shift ;;
    *) REPO="$1" ;;
  esac
  shift
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ -n "$LOCAL_DIR" ]; then
  [ -f "$LOCAL_DIR/CLAUDE.md" ] || { echo "sync-repo: CLAUDE.md assente in $LOCAL_DIR"; exit 1; }
  cp "$LOCAL_DIR/CLAUDE.md" "$TMP/CLAUDE.md"
  DEST="$LOCAL_DIR"
else
  [ -n "$REPO" ] || { echo "uso: sync-repo.sh <owner/repo> [--pr] | --from-local <dir>"; exit 1; }
  # (D11, test del sistema completo 2026-09-20): una repo VUOTA (mai onboardata, senza
  # CLAUDE.md) faceva morire qui il comando insegnato in docs/benvenuto-collaboratori.md.
  # Con --standard l'assenza e' il caso normale dell'onboarding da zero: si dichiara e si
  # prosegue (il clone sotto fallira' comunque a voce alta se gh manca davvero).
  if REMOTO=$(gh api "repos/$REPO/contents/CLAUDE.md" --jq .content 2>/dev/null) && [ -n "$REMOTO" ]; then
    printf '%s' "$REMOTO" | base64 -d > "$TMP/CLAUDE.md"
  elif [ "$STANDARD" -eq 1 ]; then
    echo "sync-repo: CLAUDE.md ASSENTE su $REPO (o non leggibile) — repo mai onboardata: --standard la porta a standard da zero"
    : > "$TMP/CLAUDE.md"
  else
    echo "sync-repo: impossibile leggere CLAUDE.md da $REPO (ASSENTE, repo privata senza accesso, o gh assente)"; exit 1
  fi
  DEST=""
fi

# (audit 2026-09-23, il canarino v2): il solo CLAUDE.md lasciva divergere gli
# HOOK in silenzio — Magazzino girava col refuso corretto in hub da 4 giorni.
# Il confronto ora include gli hook dichiarati in settings.json: se uno diverge,
# NON siamo allineati, e il turno aprira' il riallineo.
HOOK_DIV=""
while IFS= read -r H; do
  [ -n "$H" ] || continue
  if [ -n "$LOCAL_DIR" ]; then
    # da copia locale: file li', file qui — confronto diretto
    if ! diff -q "$HERE/$H" "$LOCAL_DIR/$H" >/dev/null 2>&1; then HOOK_DIV="$HOOK_DIV $H"; fi
  fi
done < <(jq -r '.hooks | to_entries[] | .value[]? | .hooks[]? | .command' "$HERE/.claude/settings.json" 2>/dev/null \
         | awk '{print $1}' | grep -E '^tools/.*\.sh$' | sort -u)
if [ -n "$HOOK_DIV" ]; then
  echo "sync-repo: DIVERGENTE — CLAUDE.md coincide ma gli HOOK no:$HOOK_DIV"
  exit 1
fi
if diff -q "$HUB_CLAUDE" "$TMP/CLAUDE.md" >/dev/null 2>&1; then
  echo "sync-repo: ALLINEATO — CLAUDE.md ${REPO:-del progetto locale} coincide con quello dell'hub (e gli hook pure)"
  # (D12): il CLAUDE.md e' il canarino, non lo standard. Con --standard si prosegue e si
  # confronta il sistema intero (skill, agenti, hook): prima l'uscita qui rendeva
  # invisibile la deriva di tutto cio' che non e' CLAUDE.md.
  [ "$STANDARD" -eq 1 ] || exit 0
else
  # bug reale (revisione 14 lenti, 2026-08-28): "$HUB_CLAUDE.md" invece di "$HUB_CLAUDE"
  # (già .../CLAUDE.md) — cercava CLAUDE.md.md, inesistente: entrambi i diff sotto
  # fallivano silenziosamente su stderr, DIFF_LINES restava sempre 0 e il blocco di
  # dettaglio vuoto — la funzione principale dello strumento (mostrare il drift) non
  # funzionava mai, pur restando l'exit code corretto per caso.
  DIFF_LINES=$(diff "$TMP/CLAUDE.md" "$HUB_CLAUDE" | grep -c '^[<>]')
  echo "sync-repo: DIVERGENTE — CLAUDE.md ${REPO:-locale} dista $DIFF_LINES righe da quello dell'hub (l'hub è la fonte: regole ereditate)"
  echo "  (l'hub ha sezioni che il progetto non riceve mai dall'onboarding in poi — F2 del report sul campo)"
  diff "$TMP/CLAUDE.md" "$HUB_CLAUDE" | head -20 | sed 's/^/  /'
fi

# --standard: il sistema intero, non solo CLAUDE.md — lo standard non è un'opzione
# che si dichiara, è un insieme di file che devono esserci (METHOD.md §"Lo standard")
if [ "$STANDARD" -eq 1 ] && [ -n "$REPO" ]; then
  gh repo clone "$REPO" "$TMP/work" -- -q --depth 1 2>/dev/null || { echo "sync-repo: clone fallito"; exit 1; }
  # (D14, test del sistema completo 2026-09-20): un `cd` non guardato — se il clone
  # «riesce» senza creare la directory, il ciclo di copia qui sotto gira nella CWD di chi
  # lancia (misurato: 100+ file dello standard copiati e staged DENTRO l'hub). Mai.
  cd "$TMP/work" || { echo "sync-repo: il clone non ha creato $TMP/work — mi fermo, non copio nella directory corrente"; exit 1; }
  COPIATI=0
  # bug reale (revisione 14 lenti, 2026-08-28): mancavano .opencode/skills (root cause
  # della divergenza trovata da 3 lenti indipendenti — le 9 skill "viaggiavano" solo
  # all'onboarding iniziale, mai più dopo) e patterns/ (stesso gap: un pattern nuovo
  # aggiunto dopo l'onboarding non raggiungeva più le repo già onboardate). Corretto in
  # due filoni indipendenti concorrenti; unificato: patterns/ (in entrambi) + .opencode/skills
  # (solo in questo filone, mancava ancora sull'altro).
  # (dal campo REPO-E 2026-09-01: docs/campo/ dell'hub contiene voci storiche di ALTRI
# clienti — si copia SOLO il README come formato, mai le voci: privacy)
# (contromisura REPO-V 7/9): le LENTI DELLO STANDARD viaggiano anche loro — fixture
#  senza provenienza e citazioni file:riga rotte sono i due banchi-verdi-bugiardi del campo
for LENTE in fixture-provenienza.sh cita-verifica.sh debiti-riapertura.sh; do
  [ -f "$HERE/tools/$LENTE" ] && { mkdir -p tools; cp "$HERE/tools/$LENTE" "tools/$LENTE"; git add "tools/$LENTE" 2>/dev/null && COPIATI=$((COPIATI+1)); }
  # (report REPO-F 2026-09-19, difetto 1): la lente viaggia SENZA la sua lista di
  # esclusione (tools/.file-del-target per cita-verifica) — 10 rossi il giorno zero,
  # misurati. La lente senza i suoi dati non e' la lente.
  [ -f "$HERE/tools/.file-del-target" ] && { cp "$HERE/tools/.file-del-target" "tools/.file-del-target"; git add "tools/.file-del-target" 2>/dev/null || true; }
done
# (report REPO-I 2026-09-19, H2): lo standard installava 43 citazioni su 62 che
  # puntavano al nulla nella destinazione — CLAUDE.md cita DEBITI.md, il REGISTRO,
  # debiti-riapertura, privacy-check, test-errori, e nessuno viaggiava. La lente che
  # pretende che le citazioni esistano non puo' essere essa stessa una citazione
  # assente (patterns/citazione-non-presidio). Gli strumenti citati viaggiano.
  # (report Budget Vendite 2026-09-19): il gate di sintassi GAS viaggia — E-028
  # era stata imparata per Python e mai generalizzata al linguaggio dell'hub stesso
  # (audit 2026-09-23): aggiunti fork-stato, presidio e polilivello — citati dallo
  # standard che viaggia (skill/CLAUDE.md) ma mai spediti: il satellite riceveva
  # documenti che puntavano a tool inesistenti (stessa classe del report REPO-I)
  CITATI="DEBITI.md docs/errori/REGISTRO.md docs/ngiri-paralleli.md tools/debiti-riapertura.sh tools/privacy-check.sh tests/test-errori.sh tools/gas-gate.sh tools/py-gate.sh tools/fork-stato.sh tools/presidio.sh tools/polilivello.sh"
  # (D13, 2026-09-20): i GUARDIANI DEL COMMIT viaggiano — .githooks (pre-commit e
  # commit-msg) e tools/pre-commit.sh; l'attivazione resta `git config core.hooksPath .githooks`
  for ITEM in CLAUDE.md .claude/skills .claude/agents .claude/settings.json .opencode/agent .opencode/skills docs/campo/README.md .opencode/plugins .githooks tools/pre-commit.sh $CITATI; do
    [ -e "$HERE/$ITEM" ] || continue
    if [ -d "$HERE/$ITEM" ]; then
      # (2026-09-20, misurato nell'hub durante il test del sistema): `cp -r dir dir` con la
      # destinazione GIA' esistente annida (.claude/skills/skills) — su una repo gia'
      # onboardata ogni riallineo avrebbe creato una copia dentro la copia. Si copia il
      # CONTENUTO nella directory, che si fonde con quello che c'e'.
      mkdir -p "$ITEM"
      cp -r "$HERE/$ITEM/." "$ITEM/"
    else
      mkdir -p "$(dirname "$ITEM")"
      cp "$HERE/$ITEM" "$ITEM"
    fi
    git add "$ITEM" 2>/dev/null && COPIATI=$((COPIATI+1))
  done
  # bug reale dal campo (REPO-V, progetto GAS nuovo, 2026-09-03): qui la lista degli hook
  # era scritta a mano e si era fermata a due, mentre .claude/settings.json — copiato
  # poche righe sopra — ne dichiara tre. Mancava tools/clasp-block-hook.sh: ogni repo
  # portata a standard con questo comando (quello insegnato in
  # docs/benvenuto-collaboratori.md) riceveva un settings.json che punta a uno script
  # inesistente, e restava senza l'unico cancello TECNICO del metodo, quello sul deploy
  # in produzione. La lista ora si DERIVA da settings.json: tools/copia-hook.sh.
  # Nota: l'esito si cattura PRIMA del ciclo. Con `while ... done < <(comando)` il codice
  # di uscita del comando non arriva al while, e un `|| exit` attaccato al done non
  # scatterebbe mai: sarebbe una guardia che non guarda.
  mkdir -p tools
  # (report REPO-F, difetto 5): garante-standard.sh esiste e --standard non lo
  # copiava — la domanda «questa repo e' a standard?» non ha risposta dal dentro
  [ -f "$HERE/tools/garante-standard.sh" ] && { cp "$HERE/tools/garante-standard.sh" "tools/garante-standard.sh"; git add "tools/garante-standard.sh" 2>/dev/null || true; }
  HOOK_COPIATI=$(bash "$HERE/tools/copia-hook.sh" "$PWD") \
    || { echo "sync-repo: copia degli hook fallita — lo standard NON è completo"; exit 1; }
  while IFS= read -r H; do
    [ -n "$H" ] && git add "$H"
  done <<< "$HOOK_COPIATI"
  # (report REPO-F, difetto 2): il blocco .night-verify viveva DENTRO il ramo
  # «non e' cambiato niente» (l'adozione vera non lo eseguiva MAI) e nel ramo
  # raggiungibile scriveva in "$DEST/.night-verify" con $DEST vuoto in modalita'
  # remota — cioe' alla radice del filesystem. La correzione era stata scritta e
  # non aveva mai girato. Ora: SEMPRE, col percorso del clone corrente ($PWD).
  if [ ! -f "$PWD/.night-verify" ]; then
    echo "# Verifiche dichiarate del turno di notte (una riga per comando, eseguite dal morning-gate)." > "$PWD/.night-verify"
    echo "# VUOTO = il gate lo dice. Dichiara i comandi appena puoi." >> "$PWD/.night-verify"
    # (report Budget Vendite): il repo GAS parte col suo gate di sintassi seminato
    _cp=$(git ls-files '*.gs' '*.html' 2>/dev/null)
    if grep -q . <<<"$_cp"; then
      echo "bash tools/gas-gate.sh" >> "$PWD/.night-verify"
    fi
    git add .night-verify 2>/dev/null || true
  fi

  if git diff --cached --quiet; then
    echo "sync-repo --standard: GIÀ A STANDARD — $REPO ha tutto (CLAUDE.md, skills, agenti, hook)"
    exit 0
  fi
  BR="claude/standard-$(date +%Y%m%d)"
  git checkout -q -b "$BR"
  git -c user.email=sync@hub -c user.name=sync-repo commit -qm "chore: adotta lo standard AI_Programmer (CLAUDE.md, skill, agenti, hook) — sync-repo.sh --standard"
  git push -q -u origin "$BR" 2>/dev/null || { echo "sync-repo: push fallito"; exit 1; }
  # (2026-09-19): gh pr create fallito in silenzio lasciava cantare vittoria —
  # la PR si VERIFICA, non si dichiara
  URL_PR=$(gh pr create --head "$BR" --fill --title "chore: adotta lo standard AI_Programmer" 2>&1 | tail -1)
  case "$URL_PR" in
    https://*) echo "sync-repo --standard: PR aperta $URL_PR ($COPIATI gruppi di file aggiornati)" ;;
    *) echo "sync-repo --standard: RAMO $BR spinto MA la PR non e' stata creata ($URL_PR) — creala a mano"; exit 1 ;;
  esac
  exit 0
fi

if [ "$CON_PR" -eq 1 ] && [ -n "$REPO" ]; then
  BR="claude/sync-claude-md-$(date +%Y%m%d)"
  gh repo clone "$REPO" "$TMP/work" -- -q --depth 1 2>/dev/null || { echo "sync-repo: clone fallito"; exit 1; }
  cd "$TMP/work" || { echo "sync-repo: il clone non ha creato $TMP/work — mi fermo"; exit 1; }
  git checkout -q -b "$BR"
  cp "$HUB_CLAUDE" CLAUDE.md
  git add CLAUDE.md
  git -c user.email=sync@hub -c user.name=sync-repo commit -qm "chore: riallinea CLAUDE.md all'hub (regole ereditate) — tools/sync-repo.sh"
  git push -q -u origin "$BR" 2>/dev/null || { echo "sync-repo: push fallito"; exit 1; }
  gh pr create --head "$BR" --fill --title "chore: riallinea CLAUDE.md all'hub" 2>&1 | tail -1
fi
exit 1
