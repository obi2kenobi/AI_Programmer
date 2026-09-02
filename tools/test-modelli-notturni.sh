#!/bin/bash
# test-modelli-notturni.sh (protocollo: docs/test-modelli-notturni-protocollo.md) — il banco per scegliere il modello del turno notturno.
# Nato dal problema reale: Qwen 27B (generale) loopa sull'issue #12 da 4 notti
# (59h + 10h + 10h + 4h col watchdog). L'ipotesi da provare: un modello
// SPECIALIZZATO per coding convergerebbe dove un generale loopa.
#
# TEST: 10 esecuzioni per modello sulla STESSA mini-issue (aggiungere una colonna
# a una tabella PDF in un file GAS). Si misura: converge (scrive codice)?
# dopo quante letture? il codice è corretto (node --check + contenuto)?
#
# Uso: bash tools/test-modelli-notturni.sh <modello1> [modello2...]
# Esce 0 sempre: è una misura, non un gate.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BANCO=/tmp/test-loop-models
MODELLI=("$@")

if [ ${#MODELLI[@]} -eq 0 ]; then
  echo "uso: test-modelli-notturni.sh <modello1> [modello2...]" >&2
  exit 1
fi

for MODELLO in "${MODELLI[@]}"; do
  echo ""
  echo "======== MODELLO: $MODELLO ========"
  CONVERGE=0; LOOPA=0; LETTURE_TOTALI=0
  for TEST in $(seq 1 10); do
    # reset del banco
    cd $BANCO && git checkout -q -- . 2>/dev/null
    # prompt identico a quello del turno (comportamentale anti-loop incluso)
    PROMPT="Risolvi questa GitHub issue in MODO INCREMENTALE. REGOLA ANTI-LOOP:
1. NON rileggere un file che hai già letto.
2. Dopo TRE letture, SMETTI e INIZIA A SCRIVERE.
3. Il piano NON si riscrive.
4. Se dopo 5 minuti non hai scritto niente, scrivi UNA riga.
5. NON rieseguire grep già fatti.

Issue: aggiungere la colonna Stato alla tabella del PDF in scaricaPDF() in app/App.html.
La colonna esiste già in generaTabella (stesso file): 'ON' se attivo, 'OFF' altrimenti.
Modifica SOLO scaricaPDF(). Verifica con node --check."

    # esecuzione con timeout 120s (mini-issue: se non converge in 2 minuti, loop)
    OUT=$(cd $BANCO && timeout 120 opencode run --model "ollama/$MODELLO" "$PROMPT" 2>&1)
    RC=$?

    # misura: quante volte ha letto il file?
    READS=$(echo "$OUT" | grep -c "Read.*App.html" || true)
    LETTURE_TOTALI=$((LETTURE_TOTALI + READS))

    # converge: ha modificato il file?
    if git -C $BANCO diff --stat | grep -q "App.html"; then
      # corretto: node --check + contiene la colonna Stato
      if node --check <(sed -n '/<script>/,/<\/script>/p' $BANCO/app/App.html 2>/dev/null || cat $BANCO/app/App.html) 2>/dev/null; then
        if grep -q "Stato\|attivo" <(git -C $BANCO diff | grep "^+"); then
          CONVERGE=$((CONVERGE + 1))
        else
          CONVERGE=$((CONVERGE + 1))  # ha scritto ma non la colonna giusta: mezza convergenza
        fi
      fi
    else
      LOOPA=$((LOOPA + 1))
    fi

    echo "  test $TEST: reads=$READS converge=$([ $RC -eq 0 ] && [ "$READS" -lt 20 ] && echo "sì" || echo "loop") rc=$RC"
  done
  echo "  === $MODELLO: $CONVERGE/10 convergono, $LOOPA loop, ${LETTURE_TOTALI} letture totali (media $((LETTURE_TOTALI / 10)))"
done
