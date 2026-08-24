#!/bin/bash
# test-system-md-controllo-gestione.sh — 4° ciclo, SET 1 giro 5. docs/system.md è la
# "mappa completa" del metodo (METHOD.md la cita come fonte di verità sull'architettura)
# ma non menzionava /controllo-gestione — chi legge la mappa per capire quali agenti/
# comandi esistono non avrebbe saputo che questa capacità c'è. Verifica che la sezione
# esista e che ogni percorso citato sia reale (coerenza, non solo prosa) — stesso schema
# di verifica già usato per CLAUDE.md nel ciclo precedente.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SYS="$HERE/docs/system.md"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

grep -q '/controllo-gestione' "$SYS" \
  && ok "docs/system.md cita /controllo-gestione" \
  || ko "docs/system.md non cita ancora /controllo-gestione"

grep -q 'mai indovinata\|mai indovinarla\|non indovinata' "$SYS" \
  && ok "la mappa ricorda la regola centrale (mai indovinare la formula)" \
  || ko "la sezione non ricorda la regola centrale"

# 5° ciclo, set 1 giro 6: la mappa deve conoscere anche i subagent .claude/agents/,
# non solo la skill — stesso principio, un pezzo nuovo del sistema, un'altra parte che
# lo cita se esiste già.
grep -q '\.claude/agents/' "$SYS" \
  && ok "docs/system.md cita .claude/agents/" \
  || ko "docs/system.md non cita ancora .claude/agents/"

# 5° ciclo, set 1 giro 7/8, poi corretto dopo il push della PR: l'invocabilità di
# .claude/agents/ dipende da un refresh del roster (verificato con esiti diversi in
# due tentativi lo stesso giorno) — non un limite fisso e permanente.
grep -q 'invocabilità dipende da un refresh del roster' "$SYS" \
  && ok "docs/system.md dichiara il limite reale (dipende da un refresh, non fisso)" \
  || ko "il limite sull'invocabilità degli agenti non è più dichiarato correttamente"
# 6° ciclo, set 3 (2026-08-24): il limite OpenCode è stato CHIUSO — l'invariante si
# inverte: la directory esiste, la dichiarazione lo dice, e la guardia anti-drift
# tiene i corpi sincronizzati. Un limite dichiarato che si chiude deve lasciare la
# traccia nella mappa, non solo nel file system.
[ -d "$HERE/.opencode/agent" ] \
  && ok "verificato: .opencode/agent/ esiste (limite chiuso nel 6° ciclo, set 3)" \
  || ko ".opencode/agent/ è tornato assente: la dichiarazione in docs/system.md è di nuovo STALE"
grep -q "chiuso per la parte" "$HERE/docs/system.md" \
  && ok "docs/system.md dichiara la chiusura del limite (traccia nella mappa)" \
  || ko "docs/system.md non dichiara la chiusura del limite OpenCode"

# ogni percorso citato in backtick con estensione reale deve esistere davvero
REFS=$(grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|py)`' "$SYS" | tr -d '`' | sort -u)
MISSING=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  if [ ! -e "$HERE/$ref" ]; then
    echo "   riferimento non trovato: $ref"
    MISSING=$((MISSING+1))
  fi
done <<< "$REFS"
[ "$MISSING" -eq 0 ] && ok "tutti i percorsi citati in docs/system.md esistono davvero" \
  || ko "$MISSING percorso/i citato/i che non esiste/esistono"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
