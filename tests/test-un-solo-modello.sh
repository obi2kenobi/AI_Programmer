#!/bin/bash
# test-un-solo-modello.sh — lente nata dal giro 19 dell'analisi profonda (2026-09-20).
#
# La decisione (2026-09-19, Luca, citata in night-shift/revisore.sh:35): UN SOLO modello
# locale, qwen2.5-coder:14b — il 27b generale faceva 0/3 in 442 s anche da solo. Ma la
# decisione viveva in alcuni default e non in altri: night-shift/install.sh controllava
# (e chiedeva di scaricare, 17 GB) il 27b che nessun turno usa piu'; llm/ask-qwen.sh —
# il cervello che il morning-gate chiama per il banco avversariale — partiva ancora col
# 27b; tests/test-revisore.sh cercava il 27b per decidere se fare la sfida vera.
# Tre posti, tre risposte diverse alla domanda «che modello usiamo?».
#
# La lente: ogni letterale qwen* in una riga di CODICE (non commento) degli script di
# night-shift/, llm/, tools/ e tests/ deve essere il MODEL_TAG dichiarato in
# night-shift/night-shift.sh. Un modello diverso e' un default divergente: si dice.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# (revisione 10 giri, 2026-09-23): MODEL_TAG e' `"${MODELLO:-<default>}"` — si confronta
# il DEFAULT; prima il TAG era la stringa `${MODELLO:-...}` e ogni riga risultava divergente.
TAG=$(grep -oE '^MODEL_TAG="[^"]+"' "$HERE/night-shift/night-shift.sh" | cut -d'"' -f2 | sed -E 's/^\$\{[A-Z_]+:-(.*)\}$/\1/')
[ -n "$TAG" ] && ok "MODEL_TAG dichiarato nel turno: $TAG" || { ko "MODEL_TAG assente in night-shift/night-shift.sh"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

# righe di codice (non commento) con un letterale qwen<qualcosa con una cifra>
DIVERGENTI=$(grep -nE 'qwen[A-Za-z0-9.:_-]*[0-9][A-Za-z0-9.:_-]*' "$HERE"/night-shift/*.sh "$HERE"/llm/*.sh "$HERE"/tools/*.sh "$HERE"/tests/*.sh 2>/dev/null \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' \
  | grep -v "test-un-solo-modello.sh" \
  | while IFS= read -r RIGA; do
      FILE=${RIGA%%:*}; RESTO=${RIGA#*:}; NUM=${RESTO%%:*}; CONTENUTO=${RESTO#*:}
      # i token si cercano nel CONTENUTO, non nel nome del file (llm/ask-qwen.sh contiene "qwen")
      for TOK in $(echo "$CONTENUTO" | grep -oE 'qwen[A-Za-z0-9.:_-]*[0-9][A-Za-z0-9.:_-]*' | sort -u); do
        [ "$TOK" = "$TAG" ] || echo "${FILE#"$HERE"/}:$NUM usa $TOK"
      done
    done)
if [ -z "$DIVERGENTI" ]; then
  ok "ogni default di modello nel codice e' $TAG (un solo modello)"
else
  ko "default di modello divergenti da $TAG:"
  echo "$DIVERGENTI" | sed 's/^/     /'
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
