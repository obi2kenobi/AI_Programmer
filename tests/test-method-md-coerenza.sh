#!/bin/bash
# test-method-md-coerenza.sh — 4° ciclo, SET 3 giro 5. METHOD.md ("il metodo in una
# pagina") documentava il registro esiti della notte (gate-esito.sh/gate-summary.sh)
# ma non quello del giorno (llm/usage-summary.sh, costruito al Set 3 giro 2) — la
# porta d'ingresso al sistema non elencava uno strumento già esistente. Nessun test
# copriva mai METHOD.md, a differenza di docs/system.md (coperto dal Set 1 giro 5).
# Verifica che ogni percorso citato in backtick esista davvero — stesso schema del
# test già scritto per docs/system.md.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MD="$HERE/METHOD.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "llm/usage-summary.sh" "$MD" \
  && ok "METHOD.md cita il registro del giorno (llm/usage-summary.sh)" \
  || ko "METHOD.md non cita il registro del giorno"

grep -q "repos-index.md" "$MD" \
  && ok "METHOD.md cita l'indice dei codici anonimi" \
  || ko "METHOD.md non cita l'indice dei codici"

REFS=$(grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|py)`' "$MD" | tr -d '`' | sort -u)
MISSING=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  case "$ref" in
    *"<"*) continue ;;
    # citato dentro un commento CORREZIONE come esempio storico di riferimento
    # rimosso perché non esisteva mai — non un riferimento vivo, non va verificato
    "docs/stato-2026-08-22.md") continue ;;
  esac
  if [ ! -e "$HERE/$ref" ]; then
    echo "   riferimento non trovato: $ref"
    MISSING=$((MISSING+1))
  fi
done <<< "$REFS"
[ "$MISSING" -eq 0 ] && ok "tutti i percorsi citati in METHOD.md esistono davvero" \
  || ko "$MISSING percorso/i citato/i che non esiste/esistono"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
