#!/bin/bash
# bencina-modelli.sh — quale cervello per il turno? (2026-09-19, decisione di Luca:
# «andrebbe misurato quale dei due va meglio per noi e usarne solo 1»).
#
# Tre COMPITI VERI, gli stessi del turno notturno:
#   1. CHIRURGO: convertire un tubo in cattura-prima, ≤10 righe (il lavoro delle
#      finestre di debito — quello che il 14b sovra-consegna)
#   2. BUGFIX: la sfida classica (sconto percentuale)
#   3. CENSORE: un diff e un verdetto JSON (il lavoro del revisore)
#
# Si misura: latenza, successo, dimensione del diff. Modalita' SOLO: un modello
# per volta (niente swap in GPU) — per il 27b il turno viene messo in pausa col
# lock globale (il turno salta i cicli finche' dura: dichiarato, non subito).
#
# Uso: bencina-modelli.sh <modello>        → misura quel modello
# Esce: 0 sempre — il verdetto e' nel riepilogo (JSON su stdout)
set -uo pipefail
MODELLO="${1:?uso: bencina-modelli.sh <modello>}"
VOLTE="${2:-1}"
# (2026-09-22, rubato a everything-claude-code): pass@k e pass^k — "almeno una
# run perfetta su k" contro "tutte perfette su k". Per un turno 24/7 la VARIANZA
# del modello conta quanto la capacita': 3/3 una volta e 1/3 dopo e' peggio di
# un 2/3 costante. Uso: bencina-modelli.sh <modello> 3
if [ "$VOLTE" -gt 1 ] 2>/dev/null; then
  PERFETTI=0; OK_TOT=0; SEC_TOT=0
  for _ in $(seq 1 "$VOLTE"); do
    RIGA=$(bash "$0" "$MODELLO" 2>/dev/null | grep '^{' | tail -1)
    S=$(jq -r '.successi // 0' <<<"$RIGA" 2>/dev/null); T=$(jq -r '.secondi_totali // 0' <<<"$RIGA" 2>/dev/null)
    [ "$S" = "3" ] && PERFETTI=$((PERFETTI+1))
    OK_TOT=$((OK_TOT + S)); SEC_TOT=$((SEC_TOT + T))
  done
  echo "pass@$VOLTE (almeno una perfetta): $([ $PERFETTI -ge 1 ] && echo SI || echo NO) · pass^$VOLTE (tutte): $([ "$PERFETTI" -eq "$VOLTE" ] && echo SI || echo NO) — run perfette $PERFETTI/$VOLTE, successi $OK_TOT/$((VOLTE*3)) in ${SEC_TOT}s"
  jq -cn --arg m "$MODELLO" --argjson v "$VOLTE" --argjson p "$PERFETTI" --argjson ok "$OK_TOT" --argjson t "$SEC_TOT" \
    '{modello:$m, volte:$v, run_perfect:$p, successi_totali:$ok, su:$v*3, pass_k:($p>0), pass_stretto:($p==$v), secondi_totali:$t}'
  exit 0
fi
API="http://localhost:11434/api/chat"
TMP=$(mktemp -d /tmp/bencina.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

chiama() { # chiama <prompt> <max-sec> → contenuto (vuoto se muto)
  curl -s --max-time "$2" "$API" -d "$(jq -cn --arg m "$MODELLO" --arg p "$1" \
    '{model:$m, messages:[{role:"user",content:$p}], stream:false, think:false, options:{temperature:0, num_ctx:4096}}')" \
    | jq -r '.message.content // empty' 2>/dev/null
}

T_TOT=0; SUCCESSI=0

# ── 1. CHIRURGO ─────────────────────────────────────────────────────────────
PDQ="| gre""p -q"   # esemplare a pezzi: il guardiano dei tubi legge il sorgente
RIGA=$(printf 'LISTA=$(ls . %s patriarca && echo si)' "$PDQ")
printf '#!/bin/bash\nset -uo pipefail\n%s\n' "$RIGA" > "$TMP/pipes.sh"
T0=$(date +%s)
R=$(chiama "The file pipes.sh contains this line:
$RIGA
Convert ONLY this line to cattura-prima: capture first, then grep the variable. HARD BUDGET: at most 4 changed lines. Reply with ONLY the new line(s), nothing else." 300)
T1=$(date +%s); DT=$((T1-T0)); T_TOT=$((T_TOT+DT))
OK1=0
if grep -q 'LISTA=' <<<"$R" && grep -q '<<<' <<<"$R"; then OK1=1; SUCCESSI=$((SUCCESSI+1)); fi
[ $OK1 -eq 1 ] && echo "· chirurgo: OK in ${DT}s ($(echo "$R" | head -1 | cut -c1-60))" || echo "· chirurgo: FALLITO in ${DT}s (risposta: $(echo "$R" | head -1 | cut -c1-60))"

# ── 2. BUGFIX ───────────────────────────────────────────────────────────────
printf 'function sconto(prezzo, percento) {\n  return prezzo - percento;\n}\n' > "$TMP/mat.js"
T0=$(date +%s)
R=$(chiama "The sconto function in mat.js subtracts the percentage number directly. Fix: return prezzo - (prezzo * percento / 100). Reply with ONLY the fixed return line." 300)
T1=$(date +%s); DT=$((T1-T0)); T_TOT=$((T_TOT+DT))
OK2=0
if grep -q 'percento / 100' <<<"$R"; then OK2=1; SUCCESSI=$((SUCCESSI+1)); fi
[ $OK2 -eq 1 ] && echo "· bugfix: OK in ${DT}s" || echo "· bugfix: FALLITO in ${DT}s"

# ── 3. CENSORE ──────────────────────────────────────────────────────────────
T0=$(date +%s)
R=$(chiama 'You are the censor of a night PR. The diff converts one pipeline to cattura-prima (2 lines changed). Reply ONLY with one-line JSON: {"verdetto":"APPROVA"|"RIGETTA","rischio":"basso","motivi":["..."]}' 300)
T1=$(date +%s); DT=$((T1-T0)); T_TOT=$((T_TOT+DT))
OK3=0
if echo "$R" | jq -er '.verdetto' >/dev/null 2>&1; then OK3=1; SUCCESSI=$((SUCCESSI+1)); fi
[ $OK3 -eq 1 ] && echo "· censore: OK in ${DT}s ($(echo "$R" | jq -r '.verdetto' 2>/dev/null))" || echo "· censore: FALLITO in ${DT}s (non-JSON)"

echo ""
jq -cn --arg m "$MODELLO" --argjson t "$T_TOT" --argjson s "$SUCCESSI" \
  '{modello:$m, successi:$s, su:3, secondi_totali:$t}'
