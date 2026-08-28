#!/bin/bash
# sync-repo.sh — 2026-08-24, report dal campo su REPO-G (F2): onboard-repo.sh e
# bootstrap-app.sh sono A UN COLPO SOLO — copiano al momento dell'onboarding, e
# da lì ogni repo diverge silenziosamente mentre l'hub aggiorna CLAUDE.md
# (4 aggiunte in un solo ciclo). Questo strumento chiude il buco nella forma
# minima richiesta dal report: "un diff + copia basta per iniziare".
#
# Uso: tools/sync-repo.sh <owner/repo>            → verifica e riporta il drift
#      tools/sync-repo.sh <owner/repo> --pr       → apre una PR di solo CLAUDE.md
#      tools/sync-repo.sh --from-local <dir>      → stesso confronto su una copia locale (per i test)
# Esiti: 0 allineato · 1 divergente (o errore) · il verdetto è sempre sulla riga finale.
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
  gh api "repos/$REPO/contents/CLAUDE.md" --jq .content 2>/dev/null | base64 -d > "$TMP/CLAUDE.md" \
    || { echo "sync-repo: impossibile leggere CLAUDE.md da $REPO (repo privata senza accesso, o gh assente)"; exit 1; }
  DEST=""
fi

if diff -q "$HUB_CLAUDE" "$TMP/CLAUDE.md" >/dev/null 2>&1; then
  echo "sync-repo: ALLINEATO — CLAUDE.md ${REPO:-del progetto locale} coincide con quello dell'hub"
  exit 0
fi

# bug reale (revisione 14 lenti, 2026-08-28): "$HUB_CLAUDE.md" invece di "$HUB_CLAUDE"
# (già .../CLAUDE.md) — cercava CLAUDE.md.md, inesistente: entrambi i diff sotto
# fallivano silenziosamente su stderr, DIFF_LINES restava sempre 0 e il blocco di
# dettaglio vuoto — la funzione principale dello strumento (mostrare il drift) non
# funzionava mai, pur restando l'exit code corretto per caso.
DIFF_LINES=$(diff "$TMP/CLAUDE.md" "$HUB_CLAUDE" | grep -c '^[<>]')
echo "sync-repo: DIVERGENTE — CLAUDE.md ${REPO:-locale} dista $DIFF_LINES righe da quello dell'hub (l'hub è la fonte: regole ereditate)"
echo "  (l'hub ha sezioni che il progetto non riceve mai dall'onboarding in poi — F2 del report sul campo)"
diff "$TMP/CLAUDE.md" "$HUB_CLAUDE" | head -20 | sed 's/^/  /'

# --standard: il sistema intero, non solo CLAUDE.md — lo standard non è un'opzione
# che si dichiara, è un insieme di file che devono esserci (METHOD.md §"Lo standard")
if [ "$STANDARD" -eq 1 ] && [ -n "$REPO" ]; then
  gh repo clone "$REPO" "$TMP/work" -- -q --depth 1 2>/dev/null || { echo "sync-repo: clone fallito"; exit 1; }
  cd "$TMP/work"
  COPIATI=0
  # bug reale (revisione 14 lenti, 2026-08-28): mancavano .opencode/skills (root cause
  # della divergenza trovata da 3 lenti indipendenti — le 9 skill "viaggiavano" solo
  # all'onboarding iniziale, mai più dopo) e patterns/ (stesso gap: un pattern nuovo
  # aggiunto dopo l'onboarding non raggiungeva più le repo già onboardate). Corretto in
  # due filoni indipendenti concorrenti; unificato: patterns/ (in entrambi) + .opencode/skills
  # (solo in questo filone, mancava ancora sull'altro).
  for ITEM in CLAUDE.md .claude/skills .claude/agents .claude/settings.json .opencode/agent .opencode/skills patterns docs/campo .opencode/plugins; do
    [ -e "$HERE/$ITEM" ] || continue
    mkdir -p "$(dirname "$ITEM")"
    cp -r "$HERE/$ITEM" "$ITEM"
    git add "$ITEM" 2>/dev/null && COPIATI=$((COPIATI+1))
  done
  mkdir -p tools
  for H in metodo-reminder-hook.sh pattern-reminder-hook.sh; do
    cp "$HERE/tools/$H" "tools/$H" && git add "tools/$H"
  done
  if git diff --cached --quiet; then
    echo "sync-repo --standard: GIÀ A STANDARD — $REPO ha tutto (CLAUDE.md, skills, agenti, hook)"
    exit 0
  fi
  BR="claude/standard-$(date +%Y%m%d)"
  git checkout -q -b "$BR"
  git -c user.email=sync@hub -c user.name=sync-repo commit -qm "chore: adotta lo standard AI_Programmer (CLAUDE.md, skill, agenti, hook) — sync-repo.sh --standard"
  git push -q -u origin "$BR" 2>/dev/null || { echo "sync-repo: push fallito"; exit 1; }
  gh pr create --fill --title "chore: adotta lo standard AI_Programmer" 2>&1 | tail -1
  echo "sync-repo --standard: PR aperta su $BR ($COPIATI gruppi di file aggiornati)"
  exit 0
fi

if [ "$CON_PR" -eq 1 ] && [ -n "$REPO" ]; then
  BR="claude/sync-claude-md-$(date +%Y%m%d)"
  gh repo clone "$REPO" "$TMP/work" -- -q --depth 1 2>/dev/null || { echo "sync-repo: clone fallito"; exit 1; }
  cd "$TMP/work"
  git checkout -q -b "$BR"
  cp "$HUB_CLAUDE" CLAUDE.md
  git add CLAUDE.md
  git -c user.email=sync@hub -c user.name=sync-repo commit -qm "chore: riallinea CLAUDE.md all'hub (regole ereditate) — tools/sync-repo.sh"
  git push -q -u origin "$BR" 2>/dev/null || { echo "sync-repo: push fallito"; exit 1; }
  gh pr create --fill --title "chore: riallinea CLAUDE.md all'hub" 2>&1 | tail -1
fi
exit 1
