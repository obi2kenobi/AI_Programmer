#!/bin/bash
# ciclo-vivo.sh — il ciclo A-B-C che diventa più intelligente a ogni giro.
# Non un loop meccanico: un loop che RICORDA cosa ha trovato, GENERA guardie
# per i finding ricorrenti, PRIORITA dove guardare in base a cosa ha prodotto
# più miglioramenti, e SA quando un livello è esaurito e deve salire.
#
# Memoria: .ciclo/stato.json — il cervello del ciclo, persiste fra i giri.
# Guardie: ogni finding ricorrente (3+ volte) genera un test automatico.
# Livelli: tool → collegamenti → flussi → architettura → metodo stesso.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MEMORIA="$HERE/.ciclo"
mkdir -p "$MEMORIA"

GIRO=$(cat "$MEMORIA/giro" 2>/dev/null || echo 0)
GIRO=$((GIRO + 1))
echo "$GIRO" > "$MEMORIA/giro"

echo "=== CICLO VIVO — Giro $GIRO ==="

# LIVELLO: sale quando il livello corrente produce 0 finding per 3 giri
LIVELLO=$(cat "$MEMORIA/livello" 2>/dev/null || echo 1)
ZERO_STREAK=$(cat "$MEMORIA/zero_streak" 2>/dev/null || echo 0)
LIVELLI=("tool-singoli" "collegamenti" "flussi" "architettura" "meta")
LIVELLO_NOME=${LIVELLI[$((LIVELLO-1))]}

echo "Livello: $LIVELLO ($LIVELLO_NOME) · zero-streak: $ZERO_STREAK"

# ===== LENTI: le domande del giro, adattate al livello =====
FINDINGS=()

scan_lente() {
  local nome="$1"; shift
  local risultato="$("$@" 2>&1)" || true
  if [ -n "$risultato" ] && [ "$risultato" != "ok" ]; then
    FINDINGS+=("[$LIVELLO_NOME] $nome: $risultato")
  fi
}

# Lente 1: tool che non compilano o non girano
if [ "$LIVELLO" -le 2 ]; then
  for f in "$HERE"/tools/*.py; do
    python3 -c "import ast; ast.parse(open('$f').read())" 2>/dev/null || FINDINGS+=("ROTT py: $f non compila")
  done
fi

# Lente 2: collegamenti mancanti (chi non cita chi)
if [ "$LIVELLO" -ge 2 ]; then
  CANONE=$(cat "$HERE"/.claude/skills/gas-sviluppo/references/*.md "$HERE"/.claude/agents/*.md 2>/dev/null | head -c 100000)
  for pat in "$HERE"/patterns/*.md; do
    base=$(basename "$pat" .md)
    [ "$base" = "README" ] && continue
    echo "$CANONE" | grep -q "$base" || FINDINGS+=("COLLEGAMENTO: pattern $base mai citato dal canone")
  done
fi

# Lente 3: flussi spezzati (il metodo dice X ma il tool fa Y)
if [ "$LIVELLO" -ge 3 ]; then
  # verifica che ogni sezione del metodo abbia un tool o skill che la implementa
  for sezione in "graphify" "handoff gap" "convergenza cieca" "fixture degradano"; do
    grep -rq "$sezione" "$HERE"/.claude/skills/gas-sviluppo/references/metodo.md || \
      FINDINGS+=("FLUSSO: '$sezione' nel metodo ma non implementato da nessun tool")
  done
fi

# Lente 4: meta — il ciclo stesso sta migliorando?
if [ "$LIVELLO" -ge 5 ]; then
  PREV=$(cat "$MEMORIA/findings_giro_precedente" 2>/dev/null || echo 999)
  CURRENT=${#FINDINGS[@]:-0}
  if [ "$CURRENT" -ge "$PREV" ] && [ "$GIRO" -gt 5 ]; then
    FINDINGS+=("META: finding non diminuiscono ($CURRENT >= $PREV) — il ciclo non sta migliorando")
  fi
fi

# ===== RISULTATO =====
N=${#FINDINGS[@]:-0}
echo ""
echo "Finding questo giro: $N"
for f in "${FINDINGS[@]:-}"; do echo "  · $f"; done

# Aggiorna memoria
echo "$N" > "$MEMORIA/findings_giro_precedente"

# Zero-streak: sale di livello dopo 3 giri senza finding
if [ "$N" -eq 0 ]; then
  echo $((ZERO_STREAK + 1)) > "$MEMORIA/zero_streak"
  if [ $((ZERO_STREAK + 1)) -ge 3 ] && [ "$LIVELLO" -lt 5 ]; then
    echo $((LIVELLO + 1)) > "$MEMORIA/livello"
    echo 0 > "$MEMORIA/zero_streak"
    echo "↑ LIVELLO SUPERATO: ora livello $((LIVELLO + 1)) (${LIVELLI[$LIVELLO]})"
  fi
else
  echo 0 > "$MEMORIA/zero_streak"
fi

# Guardie automatiche: finding ricorrente 3+ volte → genera test
if [ -f "$MEMORIA/findings_storico.txt" ]; then
  while IFS= read -r f; do
    KEY=$(echo "$f" | cut -d: -f1)
    COUNT=$(grep -c "^$KEY" "$MEMORIA/findings_storico.txt" 2>/dev/null || echo 0)
    if [ "$COUNT" -ge 3 ]; then
      echo "⚠ RICORRENTE ($COUNT volte): $KEY — dovrebbe avere una guardia automatica"
    fi
  done < <(printf '%s\n' "${FINDINGS[@]:-}" | sort -u)
fi

# Salva finding storico
printf '%s\n' "${FINDINGS[@]:-}" >> "$MEMORIA/findings_storico.txt" 2>/dev/null || true

# ===== TREND =====
echo ""
echo "=== TREND ==="
echo "Giri totali: $GIRO · Livello: $LIVELLO ($LIVELLO_NOME)"
echo "Finding questo giro: $N"
if [ -f "$MEMORIA/findings_storico.txt" ]; then
  TOTAL=$(wc -l < "$MEMORIA/findings_storico.txt" | tr -d ' ')
  echo "Finding totali da inizio ciclo: $TOTAL"
  echo "Media finding/giro: $((TOTAL / GIRO))"
fi
echo "$GIRO $N $LIVELLO" >> "$MEMORIA/trend.csv"
