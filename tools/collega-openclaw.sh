#!/bin/bash
# collega-openclaw.sh — installa il metodo AI_Programmer nella workspace OpenClaw
# Un comando, tutto al posto. Da lanciare su qualunque macchina nuova.
set -euo pipefail
HUB="$(cd "$(dirname "$0")/.." && pwd)"
WS="${1:-$HOME/openclaw-lab}"
mkdir -p "$WS"  # 15/11: su macchina nuova la workspace non esiste ancora — il cp del METODO falliva al passo 1
echo "=== Installazione metodo AI_Programmer in $WS ==="

# 1. METODO
cp "$HUB/METHOD.md" "$WS/METODO-AI-PROGRAMMER.md"
echo "✓ METHOD.md → METODO-AI-PROGRAMMER.md"

# 2. TOOL nel PATH della workspace
mkdir -p "$WS/tools"
for t in verifica-diff.sh verifica-doc.sh esame-modello.mjs; do
  [ -f "$HUB/tools/$t" ] && cp "$HUB/tools/$t" "$WS/tools/" && echo "✓ tools/$t"
done
mkdir -p "$WS/tools/esame-casi"
for f in "$HUB/tools/esame-casi/"*.txt; do
  [ -f "$f" ] && cp "$f" "$WS/tools/esame-casi/" 2>/dev/null
done
[ -d "$HUB/tools/llmwiki" ] && cp -r "$HUB/tools/llmwiki" "$WS/tools/" && echo "✓ tools/llmwiki/"
mkdir -p "$WS/tests" && cp "$HUB/tests/test-grafo-salute.sh" "$WS/tests/" 2>/dev/null && echo "✓ tests/test-grafo-salute.sh"

# 3. PROFILES
mkdir -p "$WS/profiles"
for p in mini.sh max.sh; do
  [ -f "$HUB/profiles/$p" ] && cp "$HUB/profiles/$p" "$WS/profiles/" && echo "✓ profiles/$p"
done

# 4. CHECKLIST (se non esiste già)
[ -f "$HUB/CHECKLIST-REVISIONE.md" ] && [ ! -f "$WS/CHECKLIST-REVISIONE.md" ] && cp "$HUB/CHECKLIST-REVISIONE.md" "$WS/" && echo "✓ CHECKLIST-REVISIONE.md"

# 5. AGENTS.md: aggiorna i luoghi
AGENTS="$WS/AGENTS.md"
if [ -f "$AGENTS" ] && ! grep -q "I LUOGHI" "$AGENTS"; then
cat >> "$AGENTS" <<'AG'

## I LUOGHI (registro anti "non esiste")
- I TOOL: $WS/tools/ (verifica-diff, verifica-doc, esame-modello, llmwiki)
- Le REPO: $WS/<repo>/
- I DIARI e REPORT: $WS/ (root)
- Le DECISIONI che aspettano Luca: $WS/DECISIONI-DOVUTE.md
- Il METODO: $WS/METODO-AI-PROGRAMMER.md (vincolante, leggerlo a inizio sessione)
Prima di dire "non esiste": chiediti DOVE non hai guardato.
AG
echo "✓ AGENTS.md aggiornato coi luoghi"
fi

# 6. Report diagnostico finale
echo ""
echo "=== INSTALLAZIONE COMPLETATA ==="
echo "File installati:"
find "$WS/tools" "$WS/profiles" "$WS/METODO-AI-PROGRAMMER.md" -type f 2>/dev/null | wc -l | awk '{print "  "$1" file tool/metodo"}'
echo ""
echo "Per il turno notturno: source $WS/profiles/mini.sh (o max.sh)"
echo "Per l'esame di un cervello nuovo: node $WS/tools/esame-modello.mjs --help"
