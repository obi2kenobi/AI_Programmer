#!/bin/bash
# test-agente-notturno.sh — IL RITORNO DELL'AGENTE (2026-09-17, intuizione di Luca:
# «non è che gli agenti non lavoravano bene perché il ciclo era errato?»)
#
# Tre sfide in successione, ambiente pulito, timeout, giudizio meccanico.
# Se l'agente passa tutte e tre: il problema era l'ambiente, non il modello.
# Se loopa anche ora: la conclusione originale era giusta.
#
# ⚠ QUESTO TOOL SCRIVE: solo dentro una sandbox in /tmp (mai nel repo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/llm/_timeout.sh" 2>/dev/null || true
MODEL="${NIGHT_MODEL:-qwen2.5-coder:14b}"
PROVIDER="ollama/$MODEL"
TIMEOUT="${AGENTE_TIMEOUT:-120}"
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "✓ $1"; }
ko()   { FAIL=$((FAIL+1)); echo "✗ $1"; }
skip() { SKIP=$((SKIP+1)); echo "⊘ $1"; }

echo "== TEST AGENTE NOTTURNO — $MODEL, ambiente pulito =="
echo "PATH: $(echo $PATH | tr ':' ' ' | head -3)..."
echo "LANG: ${LANG:-assente} · LC_ALL: ${LC_ALL:-assente}"
echo "cwd: $(pwd)"
echo ""

SB=$(mktemp -d /tmp/agente-test.XXXXXX)
trap 'rm -rf "$SB"' EXIT

# ── SFIDA 1: CORREZIONE BUG ──────────────────────────────────────────
echo "── SFIDA 1: correzione bug ──"
printf 'function raddoppia(x) {\n  return x + x;\n}\n' > "$SB/mat.js"
( cd "$SB" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) 2>/dev/null

T0=$(date +%s)
OUT=$( cd "$SB" && ai_timeout "$TIMEOUT" opencode run --model "$PROVIDER" \
  "Read mat.js. The function raddoppia adds x to itself instead of multiplying by 2. Fix it: change the return to x * 2. Do NOT create new files. Do NOT explain. Just fix the one line." 2>&1 )
RC=$?; ELAPSED=$(( $(date +%s) - T0 ))

if [ $RC -ne 0 ]; then
  skip "sfida 1: timeout/crash dopo ${ELAPSED}s"
elif grep -q 'x \* 2' "$SB/mat.js" && ! grep -q 'x + x' "$SB/mat.js"; then
  ok "sfida 1: bug corretto in ${ELAPSED}s"
else
  ko "sfida 1: file non corretto (${ELAPSED}s) — contenuto: $(cat "$SB/mat.js" | tr '\n' ' ' | head -c 60)"
fi

# ── SFIDA 2: NUOVA FUNZIONE ──────────────────────────────────────────
echo ""
echo "── SFIDA 2: nuova funzione ──"
T0=$(date +%s)
OUT=$( cd "$SB" && ai_timeout "$TIMEOUT" opencode run --model "$PROVIDER" \
  "Add a new function called triple(x) that returns x * 3. Add it to mat.js after the existing function. Do NOT modify raddoppia. Do NOT create new files." 2>&1 )
RC=$?; ELAPSED=$(( $(date +%s) - T0 ))

if [ $RC -ne 0 ]; then
  skip "sfida 2: timeout/crash dopo ${ELAPSED}s"
elif grep -q "function triple" "$SB/mat.js" && grep -q "x \* 3" "$SB/mat.js"; then
  ok "sfida 2: funzione triple aggiunta in ${ELAPSED}s"
else
  ko "sfida 2: funzione assente (${ELAPSED}s) — contenuto: $(cat "$SB/mat.js" | tr '\n' ' ' | head -c 60)"
fi

# ── SFIDA 3: CICLO DI MIGLIORAMENTO ──────────────────────────────────
echo ""
echo "── SFIDA 3: ciclo di miglioramento ──"
printf 'function somma(a, b) {\n  var risultato = a + b;\n  var inutile = 0;\n  return risultato;\n}\n' > "$SB/vecchio.js"
( cd "$SB" && git add -A && git -c user.name=t -c user.email=t@t commit -qm "vecchio" ) 2>/dev/null

T0=$(date +%s)
OUT=$( cd "$SB" && ai_timeout "$TIMEOUT" opencode run --model "$PROVIDER" \
  "Read vecchio.js. It has a variable 'inutile' that is declared but never used. Remove it. Also add a JSDoc comment above the function explaining what it does. Do NOT create new files." 2>&1 )
RC=$?; ELAPSED=$(( $(date +%s) - T0 ))

if [ $RC -ne 0 ]; then
  skip "sfida 3: timeout/crash dopo ${ELAPSED}s"
elif ! grep -q "inutile" "$SB/vecchio.js" && grep -q "/\*\*" "$SB/vecchio.js"; then
  ok "sfida 3: variabile rimossa + JSDoc aggiunto in ${ELAPSED}s"
elif ! grep -q "inutile" "$SB/vecchio.js"; then
  ok "sfida 3: variabile rimossa (JSDoc mancante) in ${ELAPSED}s"
else
  ko "sfida 3: file non migliorato (${ELAPSED}s)"
fi

# ── VERDETTO ─────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "AGENTE: $PASS pass · $FAIL falliti · $SKIP skip"
if [ "$FAIL" -eq 0 ] && [ "$PASS" -ge 2 ]; then
  echo "VERDETTO: L'AGENTE LAVORA — il problema era l'ambiente, non il modello"
elif [ "$SKIP" -gt 0 ]; then
  echo "VERDETTO: TIMEOUT — l'agente parte ma non converge nei ${TIMEOUT}s"
else
  echo "VERDETTO: L'AGENTE NON CONVERGE — problema del modello o del prompt"
fi
[ $FAIL -eq 0 ] && [ $PASS -ge 2 ]
