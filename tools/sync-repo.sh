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

# (2026-09-24, quarto ventaglio, Q2 R6): «push fallito» e basta — il motivo finiva in 2>/dev/null, e un ramo del
# giorno gia' spinto in un ciclo precedente (PR non creata) si ritentava a ogni ciclo senza dirlo. Ora il motivo
# (con eventuali credenziali nell'URL mascherate) e, se il ramo e' gia' sul remoto, il gesto che manca.
spingi() {
  local err
  err=$(git push -q -u origin "$1" 2>&1) && return 0
  echo "sync-repo: push fallito — $( { grep -E '^(remote:|error:| ! )' <<<"$err" || tail -3 <<<"$err"; } | head -5 | sed 's#://[^/@[:space:]]*@#://«credenziali»@#g' | tr '\n' ' ' | cut -c1-240)"
  git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1 \
    && echo "  il ramo $1 e' gia' sul remoto (spinto in un ciclo precedente): se manca la PR, gh pr create --head $1"
  return 1
}
# (2026-09-24, quarto ventaglio, Q2 R6): senza guardia, un mktemp fallito (TMPDIR inesistente) lasciava TMP
# vuoto e i file finivano alla radice — da root, nel container, /CLAUDE.md e /claude-satellite.md
TMP=$(mktemp -d) && [ -d "$TMP" ] || { echo "sync-repo: mktemp fallito (TMPDIR=${TMPDIR:-non impostato}?) — mi fermo, nessun file scritto"; exit 1; }
trap 'rm -rf "$TMP"' EXIT
# (D8, Luca 2026-09-23): il CLAUDE.md che si confronta e si installa e' la versione per i
# satelliti — senza i blocchi del solo hub (tools/claude-md-satellite.sh). Marcatori rotti: stop.
HUB_CLAUDE="$TMP/claude-satellite.md"
bash "$HERE/tools/claude-md-satellite.sh" > "$HUB_CLAUDE" || { echo "sync-repo: CLAUDE.md dell'hub con marcatori solo-hub rotti — mi fermo"; exit 1; }

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
# (Q2 R1): la lista si cattura PRIMA, col suo rc — senza jq `copia-hook --elenco` esce 1, dentro `< <(…)` il
# rc si perdeva, nessun hook veniva confrontato e l'uscita diceva «e gli hook pure»
ELENCO_HOOK=$(bash "$HERE/tools/copia-hook.sh" --elenco 2>&1) || { echo "sync-repo: hook NON derivabili ($(tail -1 <<<"$ELENCO_HOOK")) — non posso dire allineato"; exit 1; }
while IFS= read -r H; do
  [ -n "$H" ] || continue
  if [ -n "$LOCAL_DIR" ]; then
    # da copia locale: file li', file qui — confronto diretto
    if ! diff -q "$HERE/$H" "$LOCAL_DIR/$H" >/dev/null 2>&1; then HOOK_DIV="$HOOK_DIV $H"; fi
  fi
done <<<"$ELENCO_HOOK"  # (revisione 10 giri: una derivazione sola)
if [ -n "$HOOK_DIV" ]; then
  echo "sync-repo: DIVERGENTE — CLAUDE.md coincide ma gli HOOK no:$HOOK_DIV"
  exit 1
fi
if diff -q "$HUB_CLAUDE" "$TMP/CLAUDE.md" >/dev/null 2>&1; then
  # (Q2 R1): in remoto gli hook non si confrontano (solo --from-local): lo si dice, non «e gli hook pure»
  if [ -n "$LOCAL_DIR" ]; then HOOK_ESITO="e gli hook pure"; else HOOK_ESITO="hook NON confrontati: solo --from-local li legge"; fi
  echo "sync-repo: ALLINEATO — CLAUDE.md ${REPO:-del progetto locale} coincide con quello dell'hub ($HOOK_ESITO)"
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

# fondi_settings <settings-del-satellite> <settings-dell-hub> (Q13): riscrive il primo con la fusione.
# Oggetti fusi chiave per chiave (prima le chiavi del satellite), array uniti senza doppioni,
# scalari: vince lo standard; .hooks e' tutto dell'hub. Gli hook del satellite che cadono si dicono.
fondi_settings() {
  local sat="$1" hub="$2" fuso persi
  fuso=$(jq -n --slurpfile s "$sat" --slurpfile h "$hub" '
    def unione(a; b): reduce (a + b)[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
    def fondi(a; b):
      if (a|type) == "object" and (b|type) == "object" then
        reduce ((a|keys_unsorted) + (b|keys_unsorted))[] as $k ({}; if has($k) then . else .[$k] = fondi(a[$k]; b[$k]) end)
      elif (a|type) == "array" and (b|type) == "array" then unione(a; b)
      elif b == null then a else b end;
    fondi($s[0]; $h[0]) | if $h[0].hooks then .hooks = $h[0].hooks else . end') \
    || { echo "sync-repo: settings.json del satellite illeggibile (JSON?) — non lo fondo alla cieca"; return 1; }
  persi=$(jq -rn --slurpfile s "$sat" --slurpfile h "$hub" \
    '([$s[0].hooks // {} | .. | .command? // empty] - [$h[0].hooks // {} | .. | .command? // empty])[]')
  [ -n "$persi" ] && echo "sync-repo --standard: ⚠ hook del satellite NON portati (gli hook sono dello standard): $persi"
  printf '%s\n' "$fuso" > "$sat"
}

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
  # (audit-3, 2026-09-23): patterns/ e' poi USCITO dalla lista — e' un registro PER REPO,
  # e il sync aveva sovrascritto quello di un satellite (12 ancore morte). Viaggia solo
  # .opencode/skills; lo presidia tests/test-sync-repo-standard-item-list.sh.
    # (Q15, 2026-09-23, giro A8 della notte): le lenti con i loro dati, gli strumenti citati, i
  # guardiani del commit, il formato del report di campo, il garante e lo scheletro dello STATO
  # (DEBITI, REGISTRO) vivevano qui in liste a mano — e bootstrap e onboard non le vedevano. Ora
  # una lista sola, in tools/installa-citati.sh, per tutti e tre. La storia delle singole voci
  # (report REPO-E, REPO-F, REPO-I, Budget Vendite, D13, Q13) e' scritta la'.
  SCRITTI=$(bash "$HERE/tools/installa-citati.sh" "$PWD") || { echo "sync-repo: installazione degli strumenti citati fallita — lo standard NON è completo"; exit 1; }
  while IFS= read -r P; do
    [ -n "$P" ] && git add "$P" 2>/dev/null && COPIATI=$((COPIATI+1))
  done <<< "$SCRITTI"
  cp "$HUB_CLAUDE" CLAUDE.md && git add CLAUDE.md 2>/dev/null && COPIATI=$((COPIATI+1))  # D8: versione satellite
  for ITEM in .claude/skills .claude/agents .claude/settings.json .opencode/agent .opencode/skills .opencode/plugins; do
    [ -e "$HERE/$ITEM" ] || continue
    case "$ITEM" in
      .claude/settings.json)
        # (Q13): si sovrascriveva intero — i permessi e le scelte del satellite sparivano. Ora si
        # FONDE: gli hook sono dello standard (quelli dell'hub), il resto e' l'unione, e gli
        # hook del satellite che cadono si dicono.
        if [ -f "$ITEM" ] && ! cmp -s "$HERE/$ITEM" "$ITEM"; then
          fondi_settings "$ITEM" "$HERE/$ITEM" || exit 1
          git add "$ITEM" 2>/dev/null && COPIATI=$((COPIATI+1))
          continue
        fi ;;
    esac
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
  # (il garante viaggia con gli strumenti citati: tools/installa-citati.sh)
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
  spingi "$BR" || exit 1
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
  spingi "$BR" || exit 1
  gh pr create --head "$BR" --fill --title "chore: riallinea CLAUDE.md all'hub" 2>&1 | tail -1
fi
exit 1
