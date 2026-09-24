#!/bin/bash
# onboard-repo.sh — porta una repo ESISTENTE dentro il sistema:
# label night-shift, .night-verify, iscrizione alla coda locale.
# Uso: onboard-repo.sh owner/repo [tipo_commit]
#
# PERCORSO CLOUD/IBRIDO (review §4.1, 2026-08-21; spostato qui in testa al file dal
# 4° ciclo, set 3, giro 6, 2026-08-23 — docs/system.md dice "in testa a questo file"
# ma il blocco viveva nelle ultime righe, dopo l'intero script, mai visto da chi legge
# l'inizio prima di eseguire): una sessione cloud (es. Claude Code remoto) NON ha `gh`
# CLI (questo script lo chiama sotto, riga per riga) né accesso a `repos.conf` (locale
# del Mac per design). Cosa può fare da sola: commit di file (es. `.night-verify`) via
# tool MCP GitHub. Cosa resta manuale sul Mac del proprietario:
#   - creare la label night-shift (i tool MCP disponibili non la creano)
#   - aggiungere la repo a night-shift/repos.conf
# Un agente cloud che esegue l'onboarding deve DIRLO all'utente, non tacere i passi
# rimasti — e non può eseguire questo script direttamente (nessun `gh`).
set -euo pipefail

REPO="${1:?uso: onboard-repo.sh owner/repo [tipo_commit]}"
TYPE="${2:-chore}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

gh auth status >/dev/null 2>&1 || { echo "gh non autenticato"; exit 1; }
gh repo view "$REPO" >/dev/null 2>&1 || { echo "repo non trovata: $REPO"; exit 1; }

# SECRET-SCAN (review §4.3): DOPO il clone, PRIMA di toccare la repo. I tre casi sono
# distinti e detti chiaramente (finding del test PEFC 2026-08-21: prima stava prima del
# clone e un errore veniva riportato come "gitleaks assente" — tre bug in uno)
gh label create night-shift --description "Lavorata dal turno di notte (modello locale)" --color 5D3FD3 -R "$REPO" >/dev/null 2>&1 \
  && echo "label night-shift creata" || echo "label già presente"

# (2026-09-24, sesto ventaglio, S2 R1 e S4 R3): si lavorava in $HOME/night-shift-work/<repo>, la copia del TURNO —
# se c'era, niente fetch e niente ritorno su main: il turno la lascia sul ramo della PR notturna, e lo standard
# finiva dentro quella PR; e un file rimasto non tracciato da un giro interrotto valeva «gia' presente», e non
# arrivava mai. Ora l'onboard ha un clone suo, fresco, del ramo di default: «presente» vuol dire presente
# sull'origin, e il push va li'. La copia del turno non si tocca.
TMP_ONBOARD=$(mktemp -d)
trap 'rm -rf "$TMP_ONBOARD"' EXIT
WORK="$TMP_ONBOARD/${REPO##*/}"
gh repo clone "$REPO" "$WORK" -- --depth=50 -q || { echo "⛔ clone di $REPO fallito"; exit 1; }

if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --source "$WORK" --no-banner >/dev/null 2>&1; then
    echo "secret-scan: pulito"
  else
    echo "⛔ gitleaks ha trovato segreti nella repo — risolverli PRIMA di continuare (procedura: mirror + filter-repo, vedi SAL 2026-08-21)"
    exit 1
  fi
else
  echo "⚠ gitleaks NON INSTALLATO (brew install gitleaks): secret-scan saltato — installalo e riesegui"
fi
if [ ! -f "$WORK/.night-verify" ]; then
  cat > "$WORK/.night-verify" <<'EOF'
# Verifiche dichiarate del turno di notte (una riga per comando, eseguite dal morning-gate).
# Esempi: node tools/test.js · pnpm test
# Se questo progetto non ha NESSUN modo di verificare in automatico (es. webapp GAS, la
# verifica passa dal deploy umano): dichiaralo esplicitamente, non lasciare vuoto —
#   # NON-VERIFICABILE: <motivo>
EOF
  git -C "$WORK" add .night-verify
  git -C "$WORK" commit -q -m "chore: .night-verify per il gate del mattino (onboarding sistema)"
  git -C "$WORK" push -q
  echo ".night-verify creato e spinto"
else
  echo ".night-verify già presente, intoccato"
fi

# Template issue night-shift con Design obbligatorio (miglioramento #1, 2026-08-21)
if [ ! -f "$WORK/.github/ISSUE_TEMPLATE/night-shift.md" ]; then
  mkdir -p "$WORK/.github/ISSUE_TEMPLATE"
  cp "$HERE/.github/ISSUE_TEMPLATE/night-shift.md" "$WORK/.github/ISSUE_TEMPLATE/night-shift.md" 2>/dev/null \
    && git -C "$WORK" add .github && git -C "$WORK" commit -q -m "chore: template issue night-shift (Design obbligatorio)" && git -C "$WORK" push -q \
    && echo "template issue creato e spinto" || echo "⚠ template non copiato (hub senza template)"
fi

# Vocabolario di dominio (aggiunta 2026-08-21): seed solo se assente, mai sovrascritto.
if [ ! -f "$WORK/docs/GRAMMATICA_DOMINIO.md" ]; then
  mkdir -p "$WORK/docs"
  cp "$HERE/docs/GRAMMATICA_DOMINIO_TEMPLATE.md" "$WORK/docs/GRAMMATICA_DOMINIO.md" \
    && git -C "$WORK" add docs/GRAMMATICA_DOMINIO.md && git -C "$WORK" commit -q -m "chore: template vocabolario di dominio" && git -C "$WORK" push -q \
    && echo "GRAMMATICA_DOMINIO.md creato e spinto" || echo "⚠ template vocabolario non copiato"
fi

# gap reale (set 3 "flusso delle idee", 2026-08-22): le skill del hub (dev-critic,
# audit-commessa, verifica-visiva, design-doc, brainstorming, goal) non arrivavano MAI a
# una repo onboardata — solo le regole (mai copiate qui nemmeno loro, a differenza di
# bootstrap-app.sh: un repo esistente potrebbe avere un CLAUDE.md proprio, non si sovrascrive)
# e i template. Copia solo le skill MANCANTI, una per una — mai sovrascrive una skill che il
# progetto avesse già personalizzato con lo stesso nome.
SKILLS_AGGIUNTE=0
mkdir -p "$WORK/.claude/skills"
for skill_dir in "$HERE"/.claude/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  if [ ! -d "$WORK/.claude/skills/$skill_name" ]; then
    cp -r "$skill_dir" "$WORK/.claude/skills/$skill_name"
    git -C "$WORK" add ".claude/skills/$skill_name"
    SKILLS_AGGIUNTE=$((SKILLS_AGGIUNTE+1))
  fi
done
if [ "$SKILLS_AGGIUNTE" -gt 0 ]; then
  git -C "$WORK" commit -q -m "chore: $SKILLS_AGGIUNTE skill del hub propagate (onboarding sistema)"
  git -C "$WORK" push -q
  echo "$SKILLS_AGGIUNTE skill del hub aggiunte e spinte"
else
  echo "skill del hub già tutte presenti, intoccate"
fi

# bug reale (revisione 14 lenti, 2026-08-28): stesso schema per lo specchio OpenCode
# (.opencode/skills/) — mai propagato, root cause della divergenza trovata da 3 lenti
# indipendenti (le 9 skill "viaggiavano" solo una tantum, mai risincronizzate).
OPENCODE_SKILLS_AGGIUNTE=0
mkdir -p "$WORK/.opencode/skills"
for skill_dir in "$HERE"/.opencode/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  if [ ! -d "$WORK/.opencode/skills/$skill_name" ]; then
    cp -r "$skill_dir" "$WORK/.opencode/skills/$skill_name"
    git -C "$WORK" add ".opencode/skills/$skill_name"
    OPENCODE_SKILLS_AGGIUNTE=$((OPENCODE_SKILLS_AGGIUNTE+1))
  fi
done
if [ "$OPENCODE_SKILLS_AGGIUNTE" -gt 0 ]; then
  git -C "$WORK" commit -q -m "chore: $OPENCODE_SKILLS_AGGIUNTE skill OpenCode del hub propagate (onboarding sistema)"
  git -C "$WORK" push -q
  echo "$OPENCODE_SKILLS_AGGIUNTE skill OpenCode del hub aggiunte e spinte"
else
  echo "skill OpenCode del hub già tutte presenti, intoccate"
fi

# gap reale (set 3 "flusso delle idee"): stesso ragionamento per patterns/ (CLAUDE.md §7,
# "prima di scrivere infrastruttura, controlla patterns/") — merge per-file, mai sovrascrive
# un pattern che il progetto avesse già con lo stesso nome.
PATTERNS_AGGIUNTI=0
mkdir -p "$WORK/patterns"
for pattern_file in "$HERE"/patterns/*.md; do
  pattern_name="$(basename "$pattern_file")"
  if [ ! -f "$WORK/patterns/$pattern_name" ]; then
    cp "$pattern_file" "$WORK/patterns/$pattern_name"
    git -C "$WORK" add "patterns/$pattern_name"
    PATTERNS_AGGIUNTI=$((PATTERNS_AGGIUNTI+1))
  fi
done
if [ "$PATTERNS_AGGIUNTI" -gt 0 ]; then
  git -C "$WORK" commit -q -m "chore: $PATTERNS_AGGIUNTI pattern del hub propagati (onboarding sistema)"
  git -C "$WORK" push -q
  echo "$PATTERNS_AGGIUNTI pattern del hub aggiunti e spinti"
else
  echo "pattern del hub già tutti presenti, intoccati"
fi

# gap reale (5° ciclo, set 1 giro 5, 2026-08-23): stesso ragionamento per .claude/agents/
# (i subagent Claude Code, distinti dalle skill) — mai propagato, stesso schema esatto già
# corretto sopra per .claude/skills/ e patterns/, mai applicato a questa terza cartella.
AGENTS_AGGIUNTI=0
# 6° ciclo, set 3 (2026-08-24): stesso merge prudente per gli specchi OpenCode
# (.opencode/agent/) — la notte usa quelli; mai sovrascrivere una personalizzazione
# locale, solo aggiungere i mancanti
# 2026-08-26, «standard non opzione»: gli HOOK arrivano solo se il progetto non
# ne ha di propri (merge prudente, stesso criterio degli agenti)
if [ ! -f "$WORK/.claude/settings.json" ]; then
  cp "$HERE/.claude/settings.json" "$WORK/.claude/settings.json"
  git -C "$WORK" add ".claude/settings.json"
  mkdir -p "$WORK/tools"
  # bug reale (revisione 14 lenti, 2026-08-28): questi due cp non avevano il controllo
  # [ ! -f ... ] che OGNI altro merge di questo script ha (skill, pattern, agenti) —
  # contraddiceva il commento due righe sopra ("mai sovrascrivere una personalizzazione
  # locale, solo aggiungere i mancanti"). Un progetto che avesse già i propri hook
  # personalizzati (ma non ancora .claude/settings.json) li vedeva sovrascritti in silenzio.
  # (giro 20, 2026-09-20 — D28, D29, provati in tests/test-onboard-repo.sh): qui si leggeva
  # SOLO .hooks.PreToolUse — settings.json dichiara tools/metodo-reminder-hook.sh su
  # UserPromptSubmit/SessionStart/Stop, e la repo riceveva un settings.json che punta a uno
  # script inesistente. Poi `git add tools/*hook*.sh`: il glob lo espandeva la shell nella
  # cartella di CHI LANCIA (l'hub), includendo tools/copia-hook.sh che nella repo non c'e' —
  # pathspec non corrisposto, git add non aggiungeva NIENTE. E il commit lo faceva, per
  # caso, la sezione degli agenti: repo con gli agenti gia' tutti presenti = hook mai spinti.
  # Ora: tutti gli eventi (stesso filtro di tools/copia-hook.sh), add per percorso esplicito,
  # commit e push propri.
  HOOK_AGGIUNTI=0
  while IFS= read -r H; do
    [ -n "$H" ] || continue
    if [ ! -f "$WORK/$H" ]; then
      mkdir -p "$WORK/$(dirname "$H")"
      cp "$HERE/$H" "$WORK/$H" && chmod +x "$WORK/$H" && git -C "$WORK" add "$H" && HOOK_AGGIUNTI=$((HOOK_AGGIUNTI+1))
    fi
  done < <(bash "$HERE/tools/copia-hook.sh" --elenco 2>/dev/null)  # (revisione 10 giri: una derivazione sola)
  # (2026-09-24, quinto ventaglio, R2 R6): e la seconda meta' di copia-hook — i residui nella .gitignore
  bash "$HERE/tools/copia-hook.sh" --residui "$WORK" | while IFS= read -r P; do git -C "$WORK" add "$P"; done
  git -C "$WORK" commit -q -m "chore: settings.json e $HOOK_AGGIUNTI hook del metodo (onboarding sistema)"
  git -C "$WORK" push -q
  echo "settings.json e $HOOK_AGGIUNTI hook aggiunti e spinti (gli hook gia' presenti nel progetto: intoccati)"
fi
# (giro 20, 2026-09-20 — stessa famiglia di D29): gli specchi finivano nell'indice e il commit
# lo faceva solo la sezione degli agenti Claude, se aveva qualcosa da aggiungere. Commit proprio.
OPENCODE_AGENTI_AGGIUNTI=0
mkdir -p "$WORK/.opencode/agent"
for agent_file in "$HERE"/.opencode/agent/*.md; do
  agent_name="$(basename "$agent_file")"
  if [ ! -f "$WORK/.opencode/agent/$agent_name" ]; then
    cp "$agent_file" "$WORK/.opencode/agent/$agent_name"
    git -C "$WORK" add ".opencode/agent/$agent_name"
    OPENCODE_AGENTI_AGGIUNTI=$((OPENCODE_AGENTI_AGGIUNTI+1))
  fi
done
if [ "$OPENCODE_AGENTI_AGGIUNTI" -gt 0 ]; then
  git -C "$WORK" commit -q -m "chore: $OPENCODE_AGENTI_AGGIUNTI specchio/i OpenCode del hub propagato/i (onboarding sistema)"
  git -C "$WORK" push -q
  echo "$OPENCODE_AGENTI_AGGIUNTI specchio/i OpenCode aggiunto/i e spinto/i"
fi
mkdir -p "$WORK/.claude/agents"
for agent_file in "$HERE"/.claude/agents/*.md; do
  agent_name="$(basename "$agent_file")"
  if [ ! -f "$WORK/.claude/agents/$agent_name" ]; then
    cp "$agent_file" "$WORK/.claude/agents/$agent_name"
    git -C "$WORK" add ".claude/agents/$agent_name"
    AGENTS_AGGIUNTI=$((AGENTS_AGGIUNTI+1))
  fi
done
if [ "$AGENTS_AGGIUNTI" -gt 0 ]; then
  git -C "$WORK" commit -q -m "chore: $AGENTS_AGGIUNTI agente/i del hub propagato/i (onboarding sistema)"
  git -C "$WORK" push -q
  echo "$AGENTS_AGGIUNTI agente/i del hub aggiunto/i e spinto/i"
else
  echo "agenti del hub già tutti presenti, intoccati"
fi

# (Q15, 2026-09-23, giro A8 della notte): gli strumenti che lo standard CITA (settimo patto,
# REGISTRO, guardiani del commit, formato del report di campo) non arrivavano mai a una repo
# onboardata. Stessa lista di sync-repo e bootstrap (tools/installa-citati.sh), col merge
# prudente di questo script: solo i mancanti, niente sovrascritto. Commit e push propri.
CITATI_SCRITTI=$(bash "$HERE/tools/installa-citati.sh" "$WORK" --solo-mancanti) \
  || { echo "⛔ installazione degli strumenti citati fallita"; exit 1; }
if [ -n "$CITATI_SCRITTI" ]; then
  while IFS= read -r P; do git -C "$WORK" add "$P"; done <<< "$CITATI_SCRITTI"
  git -C "$WORK" commit -q -m "chore: strumenti citati dallo standard (onboarding sistema)"
  git -C "$WORK" push -q
  echo "$(grep -c . <<< "$CITATI_SCRITTI") strumento/i citato/i dallo standard aggiunto/i e spinto/i (i gia' presenti: intoccati)"
else
  echo "strumenti citati dallo standard gia' tutti presenti, intoccati"
fi

# NIGHT_REPOS_CONF: override per i banchi (giro 20 — la prima prova end-to-end ha iscritto due
# repo finte nella coda VERA dell'hub; stesso gesto di HUB_METRICS nel morning-gate)
CONF="${NIGHT_REPOS_CONF:-$HERE/night-shift/repos.conf}"
[ -f "$CONF" ] || cp "$HERE/night-shift/repos.conf.example" "$CONF"
bash "$HERE/tools/iscrivi-coda.sh" "$CONF" "$REPO" "$TYPE"   # T6#6: confronto esatto, un gesto solo

echo ""
echo "Fatto: $REPO è nel sistema. Prima issue con label night-shift e la notte lavora."
