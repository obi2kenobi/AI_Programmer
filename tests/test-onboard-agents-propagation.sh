#!/bin/bash
# test-onboard-agents-propagation.sh — 5° ciclo, set 1 giro 5: stesso gap del bootstrap
# ma per l'onboarding di repo esistenti. Merge PRUDENTE: mai sovrascrivere un agente che
# il progetto avesse già con lo stesso nome (potrebbe essere una personalizzazione
# locale) — solo aggiungere quelli mancanti.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q 'if \[ ! -f "\$WORK/.claude/agents/\$agent_name" \]' "$HERE/tools/onboard-repo.sh" \
  && ok "onboard-repo.sh contiene la logica di merge per-agente (mai sovrascrive)" \
  || ko "logica di merge agenti non trovata in onboard-repo.sh"

merge_agents() {
  local work="$1" agenti_aggiunti=0
  mkdir -p "$work/.claude/agents"
  for agent_file in "$HERE"/.claude/agents/*.md; do
    local agent_name; agent_name="$(basename "$agent_file")"
    if [ ! -f "$work/.claude/agents/$agent_name" ]; then
      cp "$agent_file" "$work/.claude/agents/$agent_name"
      agenti_aggiunti=$((agenti_aggiunti+1))
    fi
  done
  echo "$agenti_aggiunti"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# caso 1: repo senza nessun agente -> tutti arrivano
WORK1="$TMP/repo-vuota"
N1=$(merge_agents "$WORK1")
N_HUB=$(find "$HERE/.claude/agents" -maxdepth 1 -mindepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
[ "$N1" -eq "$N_HUB" ] && ok "repo senza agenti: tutti i $N_HUB arrivano" \
  || ko "repo vuota: arrivati $N1 su $N_HUB"

# caso 2: repo con un agente già personalizzato -> non viene toccato, gli altri arrivano
WORK2="$TMP/repo-con-personalizzazione"
mkdir -p "$WORK2/.claude/agents"
echo "PERSONALIZZATO DAL PROGETTO" > "$WORK2/.claude/agents/contabilita-analitica.md"
N2=$(merge_agents "$WORK2")
[ "$N2" -eq "$((N_HUB-1))" ] && ok "repo con contabilita-analitica personalizzato: arrivano solo gli altri $((N_HUB-1))" \
  || ko "conteggio sbagliato: arrivati $N2, attesi $((N_HUB-1))"
[ "$(cat "$WORK2/.claude/agents/contabilita-analitica.md")" = "PERSONALIZZATO DAL PROGETTO" ] \
  && ok "l'agente personalizzato NON è stato sovrascritto" \
  || ko "l'agente personalizzato è stato sovrascritto (bug di merge)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
