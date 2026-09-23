#!/bin/bash
# test-hook-percorso-assoluto.sh — gli hook di .claude/settings.json valgono da QUALUNQUE cartella
# (revisione 10 giri, 2026-09-23 — decisione di Luca: «sì, cambia gli hook»).
#
# Il difetto, riprodotto: i comandi erano path RELATIVI (`tools/clasp-block-hook.sh`). Con la
# sessione in una sottocartella lo script non si trovava, l'hook usciva 127 e — errore non
# bloccante per Claude Code — il comando passava: il cancello clasp FALLIVA APERTO. Ora ogni
# comando parte da "$CLAUDE_PROJECT_DIR" (la variabile che Claude Code passa agli hook).
# E la lista degli hook si DERIVA in un posto solo (tools/copia-hook.sh --elenco): i sette
# lettori che estraevano `^tools/.*\.sh$` dal primo campo avrebbero perso gli hook in silenzio.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$HERE/.claude/settings.json"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
command -v jq >/dev/null 2>&1 || { ko "jq assente: il banco non puo' leggere settings.json"; echo "$PASS OK, $FAIL FAIL"; exit 1; }

# 1. ogni comando parte dalla radice del progetto, mai dalla cartella corrente
CMDS=$(jq -r '.hooks | to_entries[] | .value[]? | .hooks[]? | .command' "$SETTINGS")
RELATIVI=$(grep -v '^"\$CLAUDE_PROJECT_DIR"/' <<<"$CMDS" || true)
[ -n "$CMDS" ] && [ -z "$RELATIVI" ] && ok "ogni comando degli hook parte da \"\$CLAUDE_PROJECT_DIR\"/ ($(grep -c . <<<"$CMDS") comandi)" \
  || ko "comandi relativi alla cartella corrente:"$'\n'"$RELATIVI"

# 2. il cancello clasp MORDE da una sottocartella (la forma esatta del difetto)
CLASP_CMD=$(jq -r '.hooks.PreToolUse[]?.hooks[]? | select(.command | contains("clasp-block")) | .command' "$SETTINGS" | head -1)
D=$( (cd "$HERE/night-shift" && printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npx clasp push"}}' \
      | CLAUDE_PROJECT_DIR="$HERE" sh -c "$CLASP_CMD") | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
[ "$D" = "deny" ] && ok "da night-shift/ il cancello clasp NEGA (prima: 127, fallito aperto)" || ko "da una sottocartella il cancello non nega (decisione: '$D')"

# 3. la lista derivata e' completa: uno script per ogni hook dichiarato, e ognuno esiste
ELENCO=$(bash "$HERE/tools/copia-hook.sh" --elenco "$SETTINGS")
ATTESI=$(grep -oE 'tools/[A-Za-z0-9_.-]+\.sh' <<<"$CMDS" | sort -u)
[ -n "$ELENCO" ] && [ "$ELENCO" = "$ATTESI" ] && ok "copia-hook --elenco: $(grep -c . <<<"$ELENCO") hook, gli stessi nominati dai comandi" \
  || ko "copia-hook --elenco '$ELENCO' ≠ attesi '$ATTESI'"
MANCA=""; while IFS= read -r H; do [ -x "$HERE/$H" ] || MANCA="$MANCA $H"; done <<<"$ELENCO"
[ -z "$MANCA" ] && ok "ogni hook dell'elenco esiste ed e' eseguibile" || ko "hook dell'elenco assenti:$MANCA"

# 4. un settings.json di una repo con la forma VECCHIA (relativa) si legge ancora
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
printf '{"hooks":{"PreToolUse":[{"hooks":[{"command":"tools/mio-hook.sh --x"}]}]}}' > "$T/s.json"
[ "$(bash "$HERE/tools/copia-hook.sh" --elenco "$T/s.json")" = "tools/mio-hook.sh" ] \
  && ok "forma relativa di una repo satellite: letta ancora (compatibilita')" || ko "forma relativa non piu' letta"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
