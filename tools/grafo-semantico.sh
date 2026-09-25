#!/bin/bash
# ⚠ QUESTO TOOL SCRIVE: spinge un ramo night/grafo-<data> e apre una PR in BOZZA (mai main, mai merge)
# grafo-semantico.sh — il pass SEMANTICO del grafo (documenti, pattern, prosa), fatto dalla notte
# col cervello locale (decisione di Luca, D1 2026-09-23: «la notte, Ollama»). Il grafo AST lo tiene
# fresco il giorno (tools/graphify-spina.sh, gratis); questo aggiunge cio' che l'AST non vede —
# i concetti dei .md — e lo porta in una PR che decide il giorno.
#
# Uso: tools/grafo-semantico.sh <owner/repo> <cartella-di-lavoro>
#   La copia di lavoro resta in <cartella>/grafo-<repo> fra una notte e l'altra: la CACHE di
#   graphify (graphify-out/cache, locale) rende incrementali le notti dopo la prima.
# Modello: $MODELLO (lo stesso del turno), una richiesta alla volta (Ollama e' uno solo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:?uso: grafo-semantico.sh <owner/repo> <cartella-di-lavoro>}"
BASE="${2:?uso: grafo-semantico.sh <owner/repo> <cartella-di-lavoro>}"
MODEL="${MODELLO:-qwen3.8-27b:iq3s}"
# (2026-09-25, settimo ventaglio, V3 R2): UNA data per pass, quella del segno del turno (GRAFO_DATA). Ramo, commit e
# titolo la prendevano ciascuno a fine pass: un pass partito il 25 e finito dopo mezzanotte apriva il ramo del 26,
# e il pass del 26 moriva al push. Lanciato a mano, senza turno, vale la data di adesso.
DATA="${GRAFO_DATA:-$(date +%F)}"
W="$BASE/grafo-${REPO##*/}"
log() { echo "[$(date '+%F %T')] grafo-semantico $REPO: $*"; }

log "inizio (modello $MODEL, copia $W)"
if [ -d "$W/.git" ]; then
  git -C "$W" fetch -q origin || log "fetch fallito — provo con quello che c'e'"
  git -C "$W" checkout -q -f main 2>/dev/null || git -C "$W" checkout -q -f master 2>/dev/null
  git -C "$W" reset -q --hard "@{u}" || { log "copia non allineabile al remoto — salto (dichiarato)"; exit 1; }
  log "copia esistente allineata al remoto (la cache resta)"
else
  gh repo clone "$REPO" "$W" -- -q || { log "clone fallito — salto"; exit 1; }
  log "clonata"
fi
cd "$W" || exit 1
BASE_REF=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo origin/main)   # per la lente sicurezza
# shellcheck source=../night-shift/lib.sh
source "$HERE/night-shift/lib.sh"   # lente_pr

# le regole del grafo e il merge-driver: la spina (senza stage, nessun update a vuoto se assente)
bash "$HERE/tools/graphify-spina.sh" "$W" >/dev/null

T0=$(date +%s)
if ! graphify extract . --backend ollama --model "$MODEL" --max-concurrency 1 >> "$W/graphify-out/.semantico.log" 2>&1; then
  log "extract FALLITO dopo $(( $(date +%s) - T0 ))s — dettagli in $W/graphify-out/.semantico.log"
  exit 1
fi
log "extract riuscito in $(( $(date +%s) - T0 ))s"

git add graphify-out/.gitignore graphify-out/.gitattributes graphify-out/graph.json 2>/dev/null
if git diff --cached --quiet; then
  log "grafo invariato: nessuna PR"
  exit 0
fi
BR="night/grafo-$DATA"
git checkout -q -B "$BR"
git commit -qm "chore: grafo semantico notturno $DATA (graphify extract, $MODEL)" || { log "commit fallito"; exit 1; }
# (2026-09-25, settimo ventaglio, V1 R3): il cancello delle forme PRIMA del push, come gli altri quattro push della
# notte (lib.sh forme_prima_del_push, T5#3). graph.json lo scrive un modello: una forma di segreto arrivava sul remoto
# e la lente la vedeva solo dopo. Nel log la sola riga di sintesi, mai le righe del reperto.
FORME=$(forme_prima_del_push "$W" "$BASE_REF") || { log "$(head -1 <<<"$FORME")"; exit 1; }
git push -q origin "$BR" 2>/dev/null || { log "push di $BR fallito (ramo gia' esistente? mai forzato)"; exit 1; }
# (2026-09-24, quinto ventaglio, R5 R4): il corpo prometteva «il merge unisce i grafi» — vero solo dove la spina
# ha registrato il driver in .git/config; un clone nuovo o il bottone di GitHub vanno in conflitto (provato: rc 1)
URL=$(gh pr create --draft --head "$BR" --title "chore: grafo semantico $DATA" \
  --body "Pass semantico notturno del grafo (graphify extract --backend ollama, modello $MODEL). Solo graphify-out/. Il merge unisce i grafi (merge=graphify) SOLO in una copia dove tools/graphify-spina.sh ha registrato il driver (git config merge.graphify.driver): fondila li' con git merge, non dal bottone di GitHub, che il driver non lo conosce e da' conflitto su graph.json." 2>&1 | tail -1)
case "$URL" in
  https://*) log "PR in bozza: $URL"; log "$(lente_pr "$W" "$BASE_REF" "$BR" "$URL")" ;;  # D2: lente sicurezza automatica
  *) log "ramo $BR spinto MA la PR non e' stata creata ($URL)"; exit 1 ;;
esac
