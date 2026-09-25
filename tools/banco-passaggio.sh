#!/bin/bash
# banco-passaggio.sh — IL BANCO DI FINE PASSAGGIO: quello che si esegue quando un
# loop chiude o un goal è raggiunto, PRIMA di dichiarare finito. Non un test in
# più: la sequenza completa dei banchi, con il verdetto su una riga.
#
#   1. suite completa (tests/test-*.sh)
#   2. batteria ignorante (giri-ignoranti.sh)
#   3. batteria avversaria (giri-avversari.sh)          [skip con --veloce]
#   4. banco delle mutazioni (mutation-tests.sh)        [skip con --veloce]
#   5. privacy (privacy-check.sh)
#   6. un giro del ciclo-vivo
#   7. COPERTURA DELLE MODIFICHE: ogni file di CODICE cambiato rispetto a
#      origin/main deve essere presidiato da almeno un test che lo cita, o
#      dichiarato con giustificazione in tools/banco-passaggio.esclusioni.
#      È la «verifica del codice appena scritto»: il file nuovo che nessun test
#      guarda è esattamente quello che regge il prossimo incidente.
#
# Uso: bash tools/banco-passaggio.sh [--veloce]
# Esce 0 solo se TUTTO tiene. Il verdetto è sempre sull'ultima riga.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"
VELOCE=0; SOLO=0
[ "${1:-}" = "--veloce" ] && VELOCE=1
[ "${1:-}" = "--solo-copertura" ] && SOLO=1
FALLITI=0

step() { echo ""; echo "== $1 =="; }
# cambiati: i file di CODICE toccati — i SPORCHI (modificati e nuovi) UNITI ai commit del ramo su
# origin/main. (Q30, 2026-09-23, notte dei giri): era un'alternativa — con un solo file sporco i
# commit del ramo non si guardavano piu' — e senza origin/main il diff falliva nel 2>/dev/null:
# «0 file cambiati, tutti presidiati» con un tool nuovo committato e senza test. Ora e' l'unione, e
# origin/main assente si dichiara DEGRADATO (si giudicano solo i file sporchi).
cambiati() {
  local filtro='^(tools|night-shift|llm)/[a-zA-Z0-9_.-]+\.(sh|py|js)$' sporchi ramo=""
  sporchi=$(git -c core.quotePath=false status --porcelain 2>/dev/null | awk '{print $NF}')
  if git rev-parse -q --verify origin/main >/dev/null 2>&1; then
    ramo=$(git diff --name-only origin/main...HEAD 2>/dev/null)
  else
    echo "  DEGRADATO: origin/main assente — la copertura giudica solo i file sporchi, non i commit del ramo" >&2
  fi
  printf '%s\n%s\n' "$sporchi" "$ramo" | grep -E "$filtro" | sort -u || true
}

if [ "$SOLO" -eq 1 ]; then
  # solo il banco 7: per il test di se stesso e per i controlli rapidi a metà giro
  CAMBIATI=$(cambiati)
  SCOPERTI=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -qF "$f" tools/banco-passaggio.esclusioni 2>/dev/null && continue
    b=$(basename "$f")
    grep -rqlF "$b" tests/ 2>/dev/null || { echo "SCOPERTO: $f — nessun test lo cita"; SCOPERTI=$((SCOPERTI+1)); }
  done <<< "$CAMBIATI"
  N_CAM=$(echo "$CAMBIATI" | grep -c . || true)
  [ "$SCOPERTI" -eq 0 ] && echo "copertura: $N_CAM file di codice cambiati, tutti presidiati"
  echo "VERDETTO: $([ "$SCOPERTI" -eq 0 ] && echo OK || echo "$SCOPERTI scoperti")"
  [ "$SCOPERTI" -eq 0 ]
  exit $?
fi

step "1/7 suite completa"
P=0; F=0
for t in tests/test-*.sh; do
  bash "$t" >/dev/null 2>&1 && P=$((P+1)) || { F=$((F+1)); echo "  ROSSO: $(basename "$t")"; }
done
echo "  $P passano, $F rossi"
[ "$F" -eq 0 ] || FALLITI=$((FALLITI+1))

step "2/7 batteria ignorante"
BP_LOG=$(mktemp -d /tmp/bp.XXXXXX)   # path UNICI per run: due banchi sovrapposti non si calpestano le prove
if bash tools/giri-ignoranti.sh >"$BP_LOG/ignoranti.log" 2>&1; then
  echo "  0 finding"
else
  echo "  FINDING:"; grep "^FIND" "$BP_LOG/ignoranti.log" | sed 's/^/  /'
  FALLITI=$((FALLITI+1))
fi

if [ "$VELOCE" -eq 0 ]; then
  step "3/7 batteria avversaria"
  if bash tools/giri-avversari.sh >"$BP_LOG/avversari.log" 2>&1; then
    echo "  0 aggirati ($(grep -c '^TIENE' "$BP_LOG/avversari.log") tengono)"
  else
    echo "  AGGIRATI:"; grep "^AGGIRA" "$BP_LOG/avversari.log" | sed 's/^/  /'
    FALLITI=$((FALLITI+1))
  fi

  step "4/7 banco mutazioni (i test provati contro se stessi)"
  if bash tools/mutation-tests.sh >"$BP_LOG/mutazioni.log" 2>&1; then
    echo "  $(grep -oE '[0-9]+ test reagiscono' "$BP_LOG/mutazioni.log") — nessun teatro"
  else
    echo "  TEATRI:"; grep "^TEATRO" "$BP_LOG/mutazioni.log" | sed 's/^/  /'
    FALLITI=$((FALLITI+1))
  fi
else
  echo "(--veloce: avversari e mutazioni saltati)"
fi

step "5/7 privacy"
if bash tools/privacy-check.sh >"$BP_LOG/privacy.log" 2>&1; then
  echo "  pulito"
else
  head -3 "$BP_LOG/privacy.log" | sed 's/^/  /'
  FALLITI=$((FALLITI+1))
fi

step "6/7 un giro del ciclo-vivo"
OUT=$(bash tools/ciclo-vivo.sh 2>&1) || true
N=$(echo "$OUT" | grep -m1 "^Finding questo giro:" | awk '{print $4}')
L=$(cat .ciclo/livello 2>/dev/null || echo 1)
echo "  livello $L · finding: ${N:-?}"
# (Q30, 2026-09-23): se ciclo-vivo muore senza la riga «Finding questo giro:», N e' vuoto e
# `${N:-0}` lo faceva valere 0 — verde. Senza verdetto non c'e' verde.
if [ -z "$N" ]; then
  echo "  ⛔ ciclo-vivo non ha dato il verdetto (morto? ultima riga: $(tail -1 <<<"$OUT" | cut -c1-80))"
  FALLITI=$((FALLITI+1))
elif [ "$N" -ne 0 ] 2>/dev/null; then
  grep "^  · " <<<"$OUT" | head -5 | sed 's/^/  /'; FALLITI=$((FALLITI+1))
fi

step "7/7 copertura delle modifiche (il codice appena scritto)"
# i file di CODICE cambiati rispetto a origin/main; SAL, DEBITI, docs e report
# sono documentazione, non code: esclusi per contratto (le giustificazioni
# aggiuntive stanno in tools/banco-passaggio.esclusioni, una per riga: path # perché)
# git diff NON vede i file non tracciati — che sono il codice appena scritto
# per antonomasi (provato a mano: un tools/nuovo.py non compariva). Si usa
# status --porcelain: modificati + nuovi, tutto in una lista.
CAMBIATI=$(cambiati)
SCOPERTI=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  grep -qF "$f" tools/banco-passaggio.esclusioni 2>/dev/null && continue
  b=$(basename "$f")
  if ! grep -rqlF "$b" tests/ 2>/dev/null; then
    echo "  SCOPERTO: $f — nessun test lo cita"
    SCOPERTI=$((SCOPERTI+1))
  fi
done <<< "$CAMBIATI"
N_CAM=$(echo "$CAMBIATI" | grep -c . || true)
[ "$SCOPERTI" -eq 0 ] && echo "  $N_CAM file di codice cambiati, tutti presidiati" \
  || FALLITI=$((FALLITI+1))

echo ""
echo "================ BANCO DI FINE PASSAGGIO ================"
echo "banchi falliti: $FALLITI"
echo "VERDETTO: $([ "$FALLITI" -eq 0 ] && echo 'PASSAGGIO CHIUSO — tutto tiene' || echo 'NON CHIUDERE: '"$FALLITI"' banchi in rosso')"
[ "$FALLITI" -eq 0 ]
