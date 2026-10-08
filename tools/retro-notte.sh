#!/bin/bash
# retro-notte.sh — la retrospettiva del COME, non del COSA.
#
# (2026-10-08, furto dichiarato dalla skill /retro di Matt Pocock — video di
# Dario Fontanel, 6/10/2026: dopo il lavoro, non «cosa ho fatto» ma «com'e'
# andato farlo». Noi non ce la copiamo: la nostra sessione e' il TURNO, e il
# turno ha un LOG che si possiede gia'. Quindi la nostra retro e' scavo
# deterministico nel log, non un prompt a un modello.)
#
# Tre passate (le tre domande della /retro tradotte in firma di log):
#   1. NAVIGAZIONE — quanto attrito a TROVARE i file (territorio risolto per
#      nome = il percorso diretto non bastava; nessun file letto = fallito)
#   2. ATTRITO SENZA GUARDIA — le firme che hanno morso stanotte, e per ognuna:
#      ha una voce nel REGISTRO degli errori? Chi morde senza guardia registrata
#      e' il lavoro del giorno (registrarla o curarla alla radice)
#   3. REGOLE IN PROSA — le regole dei canoni (CLAUDE.md, AGENTS.md) che non
#      hanno un cancello meccanico mappato (docs/regole-cancelli.md): sono
#      promemoria che vivono di memoria dell'agente — candidate a diventare
#      hook/gate (la mossa che gia' facciamo ad hoc: clasp, segreti, mirror).
#
# La retro FA DOMANDE, non cambia niente: l'uscita e' un report che il digest
# della mattina include (sezione LA RETRO) e che il giorno legge e decide.
#
# Uso: retro-notte.sh [data-YYYY-MM-DD]   (default: ieri)
#   RETRO_LOG=path — log alternativo (banchi); default night-shift.log e .1
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${1:-$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F 2>/dev/null || date +%F)}"
declare -a LOGGI
if [ -n "${RETRO_LOG:-}" ]; then
  LOGGI=("$RETRO_LOG")
else
  LOGGI=("$HOME/night-shift.log" "$HOME/night-shift.log.1")
fi

# il tranciato di stanotte: solo le righe della data (cattura-prima, E-002)
IL_LOG=$(mktemp "${TMPDIR:-/tmp}/retro-log.XXXXXX")
trap 'rm -f "$IL_LOG"' EXIT
for f in "${LOGGI[@]}"; do
  [ -f "$f" ] && grep -a "^\[$DATA " "$f" >> "$IL_LOG" 2>/dev/null
done
N_RIGHE=$(grep -c . "$IL_LOG" 2>/dev/null || true); N_RIGHE=${N_RIGHE:-0}

conta() { grep -ac "$1" "$IL_LOG" 2>/dev/null || true; }
in_registro() { grep -qi "$1" "$HERE/docs/errori/REGISTRO.md" 2>/dev/null; }

echo "## LA RETRO del $DATA (il come, non il cosa)"
echo
if [ "$N_RIGHE" -eq 0 ]; then
  echo "Nessuna riga del $DATA nei log del turno — niente da retrospettare (il turno e' girato?)."
  exit 0
fi
echo "Letto il tranciato del turno: $N_RIGHE righe."
echo

# ── 1. NAVIGAZIONE ────────────────────────────────────────────────────────────
NAV_FALLBACK=$(conta "risolto per nome in")
NAV_FALITI=$(conta "nessun file del Territorio letto")
NAV_GIAFARE=$(conta "GIA' IMPLEMENTATA")
echo "### 1. Navigazione (trovare i file)"
echo "- territorio trovato solo PER NOME (il percorso dichiarato non bastava): $NAV_FALLBACK"
echo "- territorio irrisolto, run sprecata: $NAV_FALITI"
echo "- issue che descriveva codice gia' scritto (mappa e tracker divergenti): $NAV_GIAFARE"
if [ "$NAV_FALITI" -gt 0 ] || [ "$NAV_FALLBACK" -gt 3 ]; then
  echo "- domanda per il giorno: le issue dichiarano i percorsi GIUSTI? (un fallback che lavora ogni notte e' una mappa da aggiustare)"
fi
echo

# ── 2. ATTRITO SENZA GUARDIA ─────────────────────────────────────────────────
# firma nel log | parola da cercare nel REGISTRO (vuota = guardia attiva per costruzione)
echo "### 2. Attrito di stanotte, e chi ha una guardia"
while IFS='|' read -r FIRMA PAROLA; do
  FIRMA="${FIRMA:-}"; PAROLA="${PAROLA:-}"
  [ -z "$FIRMA" ] && continue
  N=$(conta "$FIRMA")
  [ "$N" -eq 0 ] && continue
  if [ -z "$PAROLA" ]; then
    echo "- $N × «${FIRMA}» (guardia attiva: conta come VINCITA del meccanismo)"
    continue
  fi
  if in_registro "$PAROLA"; then
    echo "- $N × «${FIRMA}» — con voce di registro (guardia nota)"
  else
    echo "- $N × «${FIRMA}» — **SENZA voce di registro: il giorno registra o cura**"
  fi
done <<'FIRME'
risolto per nome in|territorio
nessun file del Territorio letto|territorio
non ha risposto in JSON|E-057
verdetto ripescato|
WATCHDOG scattato|non-converge
non converge da|non-converge
anche l'agente non ha converto|non-converge
Ollama non ha risposto|ollama
AGENTE FALLITO|ollama
VERIFICA ROSSA|night-verify
FIRME
echo

# ── 3. REGOLE IN PROSA ───────────────────────────────────────────────────────
echo "### 3. Regole dei canoni senza cancello meccanico mappato"
MAPPA="$HERE/docs/regole-cancelli.md"
N_REGOLE=0; N_MAPPA=0; CANDIDATE=""
for CANONE in CLAUDE.md AGENTS.md; do
  [ -f "$HERE/$CANONE" ] || continue
  while IFS= read -r RIGA_REGOLA; do
    [ -z "$RIGA_REGOLA" ] && continue
    N_REGOLE=$((N_REGOLE+1))
    CHIAVE=$(printf '%s' "$RIGA_REGOLA" | cut -c1-40)
    if [ -f "$MAPPA" ] && grep -qF "$CHIAVE" "$MAPPA"; then
      N_MAPPA=$((N_MAPPA+1))
    else
      CANDIDATE="$CANDIDATE
- $RIGA_REGOLA"
    fi
  done < <(grep -hE '^- \*\*' "$HERE/$CANONE" 2>/dev/null | sed 's/^- \*\*//; s/\*\*.*//' | sed 's/ *—.*//' | grep -vE '^\s*$' || true)
done
echo "Regole censite: $N_REGOLE · con cancello mappato: $N_MAPPA · candidate: $((N_REGOLE-N_MAPPA))"
N_MOSTRATE=0
while IFS= read -r CAND; do
  [ -z "$CAND" ] && continue
  [ "$N_MOSTRATE" -ge 6 ] && { echo "- … (le altre nel report completo: bash tools/retro-notte.sh)"; break; }
  echo "$CAND — può diventare cancello?"
  N_MOSTRATE=$((N_MOSTRATE+1))
done <<<"$CANDIDATE"
echo
echo "La retro fa domande; il giorno decide. (Fonte: skill /retro di M. Pocock, via D. Fontanel 6/10/2026 — la mossa e' nostra: prompt → scavo nel log.)"
