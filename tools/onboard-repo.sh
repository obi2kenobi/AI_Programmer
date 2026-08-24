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

WORK="$HOME/night-shift-work/${REPO##*/}"
[ -d "$WORK/.git" ] || gh repo clone "$REPO" "$WORK" -- --depth=50 -q

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

CONF="$HERE/night-shift/repos.conf"
[ -f "$CONF" ] || cp "$HERE/night-shift/repos.conf.example" "$CONF"
grep -q "^$REPO\b" "$CONF" || { echo "$REPO $TYPE" >> "$CONF"; echo "aggiunta a repos.conf"; }

echo ""
echo "Fatto: $REPO è nel sistema. Prima issue con label night-shift e la notte lavora."
