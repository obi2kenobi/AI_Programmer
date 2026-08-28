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
echo "$LIVELLO" > "$MEMORIA/livello"   # il file esiste sempre: lo stato del ciclo è osservabile
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
# NIENTE `echo "$CANONE" | grep -q`: con pipefail attivo, se grep -q trova la corrispondenza
# presto esce subito ed echo riceve SIGPIPE → la pipeline fallisce (141) e un pattern
# CITATO viene segnalato come mancante. Falso positivo scoperto il 2026-08-28: il giro
# segnalava 34-39 pattern non citati quando quelli veri erano 33. Si greppe direttamente
# i file: niente pipe, niente truncation, esito deterministico.
if [ "$LIVELLO" -ge 2 ]; then
  CANONE_FILES=("$HERE"/.claude/skills/gas-sviluppo/references/*.md "$HERE"/.claude/agents/*.md)
  for pat in "$HERE"/patterns/*.md; do
    base=$(basename "$pat" .md)
    [ "$base" = "README" ] && continue
    grep -qF "$base" ${CANONE_FILES[@]+"${CANONE_FILES[@]}"} 2>/dev/null || \
      FINDINGS+=("COLLEGAMENTO: pattern $base mai citato dal canone")
  done
fi

# Lente 3: flussi spezzati (il metodo dice X ma il tool fa Y)
# Logica corretta: una sezione PRESENTE nel metodo deve avere un tool o skill che la
# implementa. Se la sezione non è nel metodo non c'è niente da verificare — la versione
# precedente segnalava proprio in quel caso, con il messaggio opposto a ciò che faceva.
# La ricerca del backing NON include references/ (il metodo stesso): cercare lì rende
# la lente circolare — ogni sezione troverebbe sempre se stessa.
if [ "$LIVELLO" -ge 3 ]; then
  # verifica che ogni sezione del metodo abbia un tool o skill che la implementa
  for sezione in "graphify" "handoff gap" "convergenza cieca" "fixture degradano"; do
    grep -rq "$sezione" "$HERE"/.claude/skills/gas-sviluppo/references/metodo.md || continue
    grep -rql "$sezione" "$HERE"/tools "$HERE"/.claude/agents "$HERE"/.claude/skills/*/SKILL.md 2>/dev/null || \
      FINDINGS+=("FLUSSO: '$sezione' nel metodo ma non implementato da nessun tool")
  done
fi

# Lente 4: architettura — gli invarianti strutturali dell'hub. Nata il 2026-08-28:
# dopo 100 giri questo livello era VUOTO (tre passes gratis e si saliva), e nel
# frattempo gli specchi agenti driftavano davvero mentre il test anti-drift
# confrontava due stream vuoti (pattern confronto-non-vuoto).
if [ "$LIVELLO" -ge 4 ]; then
  # 4a. specchio skills: ogni skill di .claude vive anche in .opencode (graphify
  #     esclusa: è nativa di OpenCode) e nessuna orfana vive solo nello specchio
  for d in "$HERE"/.claude/skills/*/; do
    n=$(basename "$d"); [ "$n" = "graphify" ] && continue
    [ -d "$HERE/.opencode/skills/$n" ] || FINDINGS+=("ARCH: skill $n assente dallo specchio .opencode")
  done
  for d in "$HERE"/.opencode/skills/*/; do
    n=$(basename "$d")
    [ -d "$HERE/.claude/skills/$n" ] || FINDINGS+=("ARCH: skill $n orfana: vive solo in .opencode")
  done
  # 4b. specchio agenti: corpo identico per contratto (stessa estrazione del test di
  #     sync) CON asserzione non-vuoto: diff vuoto==vuoto passerebbe sempre
  corpo_agent() {
    sed '1,/^---$/d' "$1" | grep -v '^<!-- Specchio' | grep -v '^     ' | sed '/^-->$/d'
  }
  for a in "$HERE"/.claude/agents/*.md; do
    nome=$(basename "$a" .md); o="$HERE/.opencode/agent/$nome.md"
    if [ ! -f "$o" ]; then FINDINGS+=("ARCH: agente $nome senza specchio .opencode"); continue; fi
    NC=$(corpo_agent "$a" | grep -c . || true); NO=$(corpo_agent "$o" | grep -c . || true)
    if [ "${NC:-0}" -eq 0 ] || [ "${NO:-0}" -eq 0 ]; then
      FINDINGS+=("ARCH: corpo agente $nome estratto VUOTO — il confronto non varrebbe niente")
    elif ! diff <(corpo_agent "$a") <(corpo_agent "$o") >/dev/null 2>&1; then
      FINDINGS+=("ARCH: corpo agente $nome diverge dallo specchio (drift giorno/notte)")
    fi
  done
  # 4c. copertura: ogni tool .py ha un test con nome equivalente (trattini bassi = trattini)
  for t in "$HERE"/tools/*.py; do
    b=$(basename "$t" .py | tr '_' '-')
    ls "$HERE"/tests/test-*.sh 2>/dev/null | tr '_' '-' | grep -q "$b" || \
      FINDINGS+=("ARCH: tool $(basename "$t") senza test")
  done
  # 4d. indice pattern: ogni file sta nel registro patterns/README.md e viceversa
  for p in "$HERE"/patterns/*.md; do
    b=$(basename "$p" .md); [ "$b" = "README" ] && continue
    grep -q "($b.md)" "$HERE"/patterns/README.md || \
      FINDINGS+=("ARCH: pattern $b assente dal registro patterns/README.md")
  done
fi

# Lente 5: meta — il ciclo stesso sta migliorando?
# Regressione = finding IN AUMENTO rispetto al giro prima. Lo steady-state a zero è
# SUCCESSO, non stallo: la versione precedente (CURRENT >= PREV) segnalava pure 0 >= 0
# e al livello 5 oscillava 1,0,1,0 all'infinito — 96 giri su 100 a misurare il
# proprio bug invece del sistema (dato del 2026-08-28, 100 giri).
if [ "$LIVELLO" -ge 5 ]; then
  PREV=$(cat "$MEMORIA/findings_giro_precedente" 2>/dev/null || echo 999)
  CURRENT=${#FINDINGS[@]}
  if [ "$CURRENT" -gt "$PREV" ] && [ "$GIRO" -gt 5 ]; then
    FINDINGS+=("META: finding in AUMENTO ($PREV → $CURRENT) — peggioramento: guardare cosa è cambiato")
  fi
fi

# ===== RISULTATO =====
N=${#FINDINGS[@]:-0}
echo ""
echo "Finding questo giro: $N"
for f in "${FINDINGS[@]:-}"; do echo "  · $f"; done

# Aggiorna memoria
echo "$N" > "$MEMORIA/findings_giro_precedente"

# Zero-streak: sale di livello dopo 3 giri senza finding. Al livello MASSIMO non
# si resta fermi: dopo 3 giri puliti si torna al livello 1 (il CUORE). Un ciclo
# fermo al 5 verifica solo il 5 per sempre: le lenti 1-4 invecchiano in silenzio
# mentre le fondamenta marciscono — il battito è ripartire dal basso.
if [ "$N" -eq 0 ]; then
  echo $((ZERO_STREAK + 1)) > "$MEMORIA/zero_streak"
  if [ $((ZERO_STREAK + 1)) -ge 3 ] && [ "$LIVELLO" -lt 5 ]; then
    echo $((LIVELLO + 1)) > "$MEMORIA/livello"
    echo 0 > "$MEMORIA/zero_streak"
    echo "↑ LIVELLO SUPERATO: ora livello $((LIVELLO + 1)) (${LIVELLI[$LIVELLO]})"
  elif [ $((ZERO_STREAK + 1)) -ge 3 ] && [ "$LIVELLO" -eq 5 ]; then
    echo 1 > "$MEMORIA/livello"
    echo 0 > "$MEMORIA/zero_streak"
    echo "↺ CUORE: pulito a tutti i livelli — torno al livello 1 per ricontrollare le fondamenta"
  fi
else
  echo 0 > "$MEMORIA/zero_streak"
fi

# Guardie automatiche: finding ricorrente 3+ volte → ACCODATO su file perché diventi
# un test. La versione precedente lo SOLO STAMPava: la promessa "guardia automatica"
# non produceva nessuna guardia (e nessuno la generava il mattino dopo).
if [ -f "$MEMORIA/findings_storico.txt" ] && [ "$N" -gt 0 ]; then
  mkdir -p "$MEMORIA/guardie"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    KEY=$(echo "$f" | cut -d: -f1)
    COUNT=$(grep -c "^$KEY" "$MEMORIA/findings_storico.txt" 2>/dev/null); COUNT=${COUNT:-0}
    if [ "$COUNT" -ge 3 ]; then
      echo "⚠ RICORRENTE ($COUNT volte): $KEY — guardia richiesta, accodata"
      SLUG=$(echo "$KEY" | tr -cs 'a-zA-Z0-9' '-' | tr 'A-Z' 'a-z' | sed 's/^-//;s/-$//')
      echo "$(date +%F) giro=$GIRO volte=$COUNT · $f" >> "$MEMORIA/guardie/da-generare-$SLUG.txt"
    fi
  done < <(printf '%s\n' ${FINDINGS[@]+"${FINDINGS[@]}"} | sort -u)
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
