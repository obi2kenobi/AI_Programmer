#!/bin/bash
# test-skill-reminder-hook.sh — la skill giusta si RICORDA quando l'agente tocca il suo terreno
# (decisione di Luca, D3 2026-09-23: «a» — promemoria su cio' che l'agente tocca, non sulle parole
# della richiesta). Il debito del 2026-08-24: nella sessione sulla dashboard GAS `verifica-visiva`
# e `dev-critic` non si sono attivate, pur con la description che calzava alla lettera — il solo
# matching per description non basta.
# Le regole (una per terreno, nessuna lista scritta nel hook):
#   .html in un progetto GAS (appsscript.json risalendo) → verifica-visiva
#   .gs/.js in un progetto GAS                           → gas-sviluppo
#   un calcolo: .py citato dall'agente contabilita-analitica (il registro degli oracoli) → controllo-gestione
# Una volta per skill per sessione: il promemoria che si ripete diventa rumore.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HERE/tools/skill-reminder-hook.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T" /tmp/ai-programmer-skill-reminder.test-sr-*' EXIT

# un progetto finto: con le skill dell'hub, un GAS dentro, e l'agente degli oracoli
P="$T/prog"; mkdir -p "$P/.claude" "$P/gas/dash" "$P/altro" "$P/tools"
cp -r "$HERE/.claude/skills" "$HERE/.claude/agents" "$P/.claude/"
echo '{}' > "$P/gas/appsscript.json"
chiama() { # chiama <sessione> <file> → additionalContext (vuoto se silenzio)
  printf '{"session_id":"%s","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1" "$2" \
    | CLAUDE_PROJECT_DIR="$P" bash "$HOOK" 2>/dev/null | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null
}

C=$(chiama test-sr-1 "$P/gas/dash/Dashboard.html")
grep -q 'verifica-visiva' <<<"$C" && ok ".html in un progetto GAS → verifica-visiva" || ko ".html GAS senza promemoria: '$C'"
grep -qF "$(sed -n 's/^description: //p' "$HERE/.claude/skills/verifica-visiva/SKILL.md" | cut -c1-40)" <<<"$C" \
  && ok "il promemoria porta la description della skill (dalla SKILL.md, una fonte)" || ko "description non derivata dalla SKILL.md"
C=$(chiama test-sr-1 "$P/gas/Codice.gs")
grep -q 'gas-sviluppo' <<<"$C" && ok ".gs in un progetto GAS → gas-sviluppo" || ko ".gs GAS senza promemoria: '$C'"
C=$(chiama test-sr-1 "$P/tools/valorizzazione_magazzino.py")
grep -q 'controllo-gestione' <<<"$C" && ok "un calcolo (oracolo citato da contabilita-analitica) → controllo-gestione" || ko "calcolo senza promemoria: '$C'"

# rumore: una volta per skill per sessione; una sessione nuova lo ridice
C=$(chiama test-sr-1 "$P/gas/dash/Altra.html")
[ -z "$C" ] && ok "stessa skill, stessa sessione: silenzio" || ko "promemoria ripetuto nella stessa sessione: '$C'"
C=$(chiama test-sr-2 "$P/gas/dash/Altra.html")
grep -q 'verifica-visiva' <<<"$C" && ok "sessione nuova: il promemoria torna" || ko "sessione nuova senza promemoria"

# fuori dal terreno: silenzio
C=$(chiama test-sr-3 "$P/altro/pagina.html")
[ -z "$C" ] && ok ".html fuori da un progetto GAS: silenzio" || ko ".html non-GAS ha ricevuto promemoria: '$C'"
C=$(chiama test-sr-3 "$P/tools/bc_index.py")
[ -z "$C" ] && ok "un .py che non e' un calcolo: silenzio" || ko ".py non-calcolo ha ricevuto promemoria: '$C'"

# la skill che manca nella repo non si suggerisce
rm -rf "$P/.claude/skills/gas-sviluppo"
C=$(chiama test-sr-4 "$P/gas/Codice.gs")
[ -z "$C" ] && ok "skill assente nella repo: nessun suggerimento a vuoto" || ko "suggerita una skill che qui non c'e': '$C'"

# viaggia: e' un hook dichiarato (copia-hook --elenco lo porta nelle repo installate)
bash "$HERE/tools/copia-hook.sh" --elenco | grep -qx 'tools/skill-reminder-hook.sh' \
  && ok "skill-reminder-hook e' un hook dichiarato" || ko "skill-reminder-hook non dichiarato in settings.json"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
