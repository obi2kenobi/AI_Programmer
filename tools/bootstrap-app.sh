#!/bin/bash
# bootstrap-app.sh — crea una repo nuova DENTRO il sistema: regole ereditate,
# PROJECT.md stub, label night-shift, .night-verify dichiarato.
# Uso: bootstrap-app.sh <nome-repo> [--private]
#
# PERCORSO CLOUD/IBRIDO (4° ciclo, set 3, giro 7, 2026-08-23 — stesso gap già trovato e
# corretto in testa a tools/onboard-repo.sh, mai propagato qui): questo script chiama
# `gh` direttamente in più punti (auth status, repo create, label create, api user) e
# scrive su `night-shift/repos.conf` (locale del Mac per design) — una sessione cloud
# (es. Claude Code remoto, senza `gh` CLI) non può eseguirlo. Un agente cloud a cui
# viene chiesto di creare un nuovo progetto deve DIRLO all'utente, non tentare di
# eseguire questo script e non tacere i passi che restano manuali sul Mac del
# proprietario (repo GitHub, label night-shift, riga in repos.conf).
set -euo pipefail

NAME="${1:?uso: bootstrap-app.sh <nome-repo> [--private] [--dry-run]}"
DRY_RUN=0
for a in "$@"; do [ "$a" = "--dry-run" ] && DRY_RUN=1; done
if [ $DRY_RUN -eq 1 ]; then echo "== DRY RUN: tutto what-if, nessuna scrittura =="; fi
VIS="--public"
[ "${2:-}" = "--private" ] && VIS="--private"

HERE="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/night-shift-work/$NAME"

[ -d "$DEST" ] && { echo "esiste già: $DEST"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh non autenticato"; exit 1; }

mkdir -p "$DEST" && cd "$DEST"
git init -q -b main

# Le regole universali si EREDITANO dal hub: un solo luogo dove vivono.
cp "$HERE/CLAUDE.md" CLAUDE.md
cat > PROJECT.md <<EOF
# PROJECT.md — contesto specifico di $NAME

Sezione per progetto: comandi, validation artifact (regola "Done means proven"),
convenzioni locali. Le regole universali stanno in CLAUDE.md (ereditate dal hub
AI_Programmer: aggiornale LÌ, non qui).
EOF

# Le verifiche dichiarate per il gate del mattino: una riga per comando.
cat > .night-verify <<EOF
# Verifiche dichiarate del turno di notte (una riga per comando, eseguite dal morning-gate).
# Esempi: node tools/test.js · pnpm test · python3 -m pytest
# VUOTO = il gate lo dice ("il silenzio non è un verdetto"): dichiarale appena puoi.
# Se questo progetto non ha NESSUN modo di verificare in automatico (es. webapp GAS, la
# verifica passa dal deploy umano): dichiaralo esplicitamente, non lasciare vuoto —
#   # NON-VERIFICABILE: <motivo>
EOF

# Vocabolario di dominio (aggiunta 2026-08-21): si riempie coi fatti confermati dal business,
# non si scrive vuoto per sempre — ma il posto per scriverlo c'è dal primo commit.
mkdir -p docs
cp "$HERE/docs/GRAMMATICA_DOMINIO_TEMPLATE.md" docs/GRAMMATICA_DOMINIO.md

# gap reale (set 3 "flusso delle idee", 2026-08-22): le skill Claude costruite nel hub
# (dev-critic, audit-commessa, verifica-visiva, design-doc, brainstorming, goal) restavano
# intrappolate lì — CLAUDE.md (le regole) si eredita da sempre, ma gli STRUMENTI che quelle
# regole presuppongono (es. "usa dev-critic prima di...") non arrivavano mai al progetto
# nuovo. Una sessione di giorno sul progetto appena creato non aveva accesso a nessuna skill.
mkdir -p .claude/skills
cp -r "$HERE/.claude/skills/." .claude/skills/

# gap reale (set 3 "flusso delle idee"): patterns/ (trucchi provati, ancorati al codice
# che li usa) non lasciava mai il hub — CLAUDE.md §7 dice "prima di scrivere
# infrastruttura, controlla patterns/" come regola UNIVERSALE, ma il posto dove
# guardare non arrivava al progetto nuovo. Copiato come riferimento locale (di
# sola lettura concettuale: gli ancoraggi restano quelli del hub, non si riscrivono).
mkdir -p patterns
cp -r "$HERE/patterns/." patterns/

# gap reale (5° ciclo, set 1 giro 5, 2026-08-23): stesso ragionamento per .claude/agents/
# (i subagent Claude Code, distinti dalle skill sopra) — mai propagato ai progetti nuovi,
# stesso schema già corretto per .claude/skills/ e patterns/ qui sopra, mai applicato a
# questa terza cartella.
mkdir -p .claude/agents
cp -r "$HERE/.claude/agents/." .claude/agents/
# 6° ciclo, set 3 (2026-08-24): la notte lavora con OpenCode nei progetti — gli agenti
# specchiati (.opencode/agent/) devono arrivare anche lì, stessa quarta cartella della
# stessa famiglia di gap già pagata per skills/agents/patterns
mkdir -p .opencode/agent
cp -r "$HERE/.opencode/agent/." .opencode/agent/
# 2026-08-26, «standard non opzione»: anche gli HOOK viaggiano — il metodo che
# dipende dalla memoria della sessione resta opt-in, quello nell'hook no
cp "$HERE/.claude/settings.json" .claude/settings.json
# bug reale (revisione 14 lenti, 2026-08-28): mancava "mkdir -p tools" prima di questi due
# cp (a differenza di onboard-repo.sh, che la crea prima dello stesso cp) — su un progetto
# bootstrappato da zero senza cartella tools/ preesistente, il cp falliva e il "|| true"
# inghiottiva l'errore: gli hook non venivano MAI installati, e lo script terminava
# comunque con "Fatto" senza alcun avviso — vanificando l'intento dichiarato sopra.
mkdir -p tools
cp "$HERE/tools/metodo-reminder-hook.sh" tools/metodo-reminder-hook.sh 2>/dev/null || true
cp "$HERE/tools/pattern-reminder-hook.sh" tools/pattern-reminder-hook.sh 2>/dev/null || true

# gap reale (4° ciclo, set 1 "agenti", giro 3, 2026-08-23): la label GitHub "night-shift"
# viene creata sotto (riga con `gh label create`) ma il template che insegna la FORMA
# della commessa (## Design/## Forma dei dati/## Territorio, obbligatorie o il turno
# salta l'issue in silenzio) non arrivava mai al progetto nuovo — stesso pattern già
# corretto per .claude/skills/ e patterns/ qui sopra, mai applicato a questo file.
mkdir -p .github/ISSUE_TEMPLATE
cp "$HERE/.github/ISSUE_TEMPLATE/night-shift.md" .github/ISSUE_TEMPLATE/night-shift.md

echo "# $NAME" > README.md
# SECRET-SCAN (review §4.3): gitleaks PRIMA del primo push — la disciplina da sola non basta
command -v gitleaks >/dev/null 2>&1 && { gitleaks detect --source . --no-banner >/dev/null 2>&1 || { echo "⛔ gitleaks ha trovato segreti — risolvere PRIMA del push"; exit 1; }; } || echo "⚠ gitleaks assente (brew install gitleaks): secret-scan saltato"
if [ $DRY_RUN -eq 1 ]; then
  echo "(dry: creerebbe la repo)"
else
  # bug reale (dogfooding, nuovo ciclo 10 giri): la vecchia catena
  # "[ dry ] || git add -A && [ dry ] || git commit" non si fermava se git add
  # falliva — set -e non intercetta un fallimento intermedio dentro una catena
  # &&/||, e git commit veniva eseguito comunque (verificato con simulazione).
  git add -A
  git commit -q -m "feat: repo generata dal sistema AI_Programmer (bootstrap-app)"
  gh repo create "$NAME" $VIS --source . --push -q
fi
gh label create night-shift --description "Lavorata dal turno di notte (modello locale)" --color 5D3FD3 -R "$NAME" >/dev/null 2>&1 || true

# La iscrive alla coda locale (se esiste repos.conf)
CONF="$HERE/night-shift/repos.conf"
if [ -f "$CONF" ] && ! grep -q "^$(gh api user --jq .login)/$NAME\$" "$CONF"; then
  echo "$(gh api user --jq .login)/$NAME feat" >> "$CONF"
  echo "aggiunta a $CONF"
fi

echo ""
echo "Fatto: $NAME è nel sistema."
echo "  prossimo passi: riempi PROJECT.md e .night-verify, poi la prima issue night-shift."
