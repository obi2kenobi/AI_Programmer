#!/bin/bash
# test-usage-summary.sh — 4° ciclo, SET 3 giro 2. llm/_usage.sh (Set 1 del ciclo
# precedente) scrive un log dei cervelli di giorno ma nulla lo leggeva — i dati
# entravano e non uscivano mai come insight, la stessa asimmetria "notte ha memoria,
# giorno no" che quel giro aveva chiuso solo a metà (scrittura sì, lettura no). Verifica
# llm/usage-summary.sh su un log sintetico con aritmetica derivata a mano, e che una riga
# malformata non faccia fallire il riepilogo (solo la ignori, dichiarandolo).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$HERE/llm/usage-summary.sh" ] && ok "llm/usage-summary.sh esiste ed è eseguibile" \
  || ko "llm/usage-summary.sh assente o non eseguibile"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/usage.log" <<'EOF'
2026-08-23T00:00:01Z ask-opus rc=0 dur=3s prompt_chars=142
2026-08-23T00:01:02Z ask-opus rc=0 dur=5s prompt_chars=88
2026-08-23T00:02:03Z ask-opus rc=1 dur=1s prompt_chars=200
2026-08-23T00:03:04Z ask-glm rc=0 dur=10s prompt_chars=300
2026-08-23T00:04:05Z ask-qwen rc=2 dur=0s prompt_chars=0
riga completamente rotta senza il formato giusto
EOF

OUT=$(bash "$HERE/llm/usage-summary.sh" "$TMP/usage.log")

# a mano: ask-opus 3 chiamate, 2 successi (rc=0) -> 66.7%; durata media (3+5+1)/3 = 3.0
echo "$OUT" | grep -qE '^ask-opus\s+3\s+2\s+66\.7%\s+3\.0s' \
  && ok "ask-opus: 3 chiamate, 2 successi (66.7%), durata media 3.0s" \
  || ko "ask-opus: riga inattesa — $(echo "$OUT" | grep ask-opus)"

# ask-glm: 1 chiamata, 1 successo -> 100.0%, durata media 10.0
echo "$OUT" | grep -qE '^ask-glm\s+1\s+1\s+100\.0%\s+10\.0s' \
  && ok "ask-glm: 1 chiamata, 1 successo (100.0%), durata media 10.0s" \
  || ko "ask-glm: riga inattesa — $(echo "$OUT" | grep ask-glm)"

# ask-qwen: 1 chiamata, 0 successi (rc=2, non configurato) -> 0.0%
echo "$OUT" | grep -qE '^ask-qwen\s+1\s+0\s+0\.0%\s+0\.0s' \
  && ok "ask-qwen: 1 chiamata, 0 successi (rc=2 non configurato -> 0.0%)" \
  || ko "ask-qwen: riga inattesa — $(echo "$OUT" | grep ask-qwen)"

echo "$OUT" | grep -q "1 riga/e nel log non riconosciute" \
  && ok "la riga malformata è dichiarata scartata, non fa fallire il riepilogo" \
  || ko "nessuna dichiarazione sulla riga malformata"

# nessun log -> errore chiaro, non un crash python
NOLOG_RC=0
bash "$HERE/llm/usage-summary.sh" "$TMP/non-esiste.log" >/dev/null 2>&1 || NOLOG_RC=$?
[ "$NOLOG_RC" -ne 0 ] && ok "log assente: fallisce con un messaggio chiaro, non un crash silenzioso" \
  || ko "log assente: dovrebbe fallire con rc!=0"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
