#!/bin/bash
# test-design-doc-graphify.sh — 4° ciclo, SET 2 "progettare" giro 2. graphify è già
# regola universale in CLAUDE.md §7 ("Navigazione before reading") e installato per
# l'agente notturno (.opencode/skills/graphify/), ma /design-doc — il momento in cui un
# agente di giorno deve capire "cosa cambia concretamente" in un codebase per generare
# opzioni — non lo citava affatto: la regola generale non arrivava al passo specifico
# che più ne beneficia. Verifica il rimando, e che ricordi il limite noto del grafo
# (orientamento sì, semantica delle chiamate no) invece di spacciarlo per un oracolo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DD="$HERE/.claude/skills/design-doc/SKILL.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q "graphify" "$DD" \
  && ok "design-doc cita graphify per orientarsi nel codebase" \
  || ko "design-doc non cita graphify"

grep -q "AGENTS.md" "$DD" \
  && ok "design-doc rimanda ad AGENTS.md (dove vive la regola operativa completa)" \
  || ko "design-doc non rimanda ad AGENTS.md"

grep -qE "non.*oracolo|non è un oracolo|non fidarti del grafo" "$DD" \
  && ok "il limite del grafo (calls non risolto) è ricordato, non nascosto" \
  || ko "manca l'avvertenza sul limite del grafo — rischio di trattarlo come oracolo"

[ -f "$HERE/AGENTS.md" ] && grep -q "graphify" "$HERE/AGENTS.md" \
  && ok "AGENTS.md citato esiste davvero e parla di graphify" \
  || ko "AGENTS.md non esiste o non parla di graphify — citazione senza presidio"

# 5° ciclo, set 2 giro 2: deve esistere un percorso quando graphify NON è installato —
# caso reale di questa sessione (graphify-out/ assente), non ipotetico.
grep -qi "NON esiste" "$DD" \
  && ok "design-doc dichiara un fallback per quando graphify-out/graph.json non esiste" \
  || ko "design-doc non dice cosa fare senza graphify — un vuoto reale in questa sessione"

grep -q "Explore" "$DD" \
  && ok "il fallback cita l'agente Explore per territori ampi/nomi non noti" \
  || ko "il fallback non cita Explore"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
