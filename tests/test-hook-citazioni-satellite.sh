#!/bin/bash
# test-hook-citazioni-satellite.sh — i promemoria degli hook non mandano l'agente a file che nella repo
# non ci sono (2026-09-24, notte dei giri, T1#4). In un satellite i messaggi di metodo-reminder e del
# cancello clasp citavano strumenti che vivono solo nell'hub (tools/*.py, docs/mappa-dominio-gas-src.md,
# tools/verifica_banco.py, tools/bc_index.py, tools/prepara-deploy.sh, METHOD.md): l'agente cercava il
# nulla. Ora un file assente si dice «nell'hub AI_Programmer»; nell'hub il messaggio resta com'era.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/sat/tools"; cp "$HERE"/tools/*-hook.sh "$T/sat/tools/"

messaggi() { # messaggi <cartella>: tutto cio' che gli hook dicono all'agente, in una volta
  ( cd "$1" && {
    echo '{"hook_event_name":"SessionStart"}' | bash tools/metodo-reminder-hook.sh
    echo '{"hook_event_name":"UserPromptSubmit","prompt":"calcola il margine dai dati BC e correggi il bug"}' | bash tools/metodo-reminder-hook.sh
    echo '{"tool_name":"Bash","tool_input":{"command":"bash tools/deploy-ora.sh X"}}' | bash tools/clasp-block-hook.sh
  } 2>/dev/null ) | jq -r '.. | strings' 2>/dev/null
}
# i percorsi citati: ogni token che somiglia a un file del repo, e se dopo c'e' la nota «nell'hub»
controlla() { # controlla <cartella> → le citazioni a file assenti e NON annotate
  messaggi "$1" | python3 -c '
import re, os, sys
cart = sys.argv[1]; t = sys.stdin.read()
pat = re.compile(r"((?:tools|docs|night-shift|llm)/[A-Za-z0-9_*./-]+|METHOD\.md)(\s*\(nell.hub AI_Programmer\))?")
import glob
for m in pat.finditer(t):
    p = m.group(1).rstrip(".),")
    esiste = glob.glob(os.path.join(cart, p)) if "*" in p else os.path.exists(os.path.join(cart, p))
    if not esiste and not m.group(2):
        print(p)
' "$1" | sort -u
}
FUORI=$(controlla "$T/sat")
[ -z "$FUORI" ] && ok "satellite: ogni file citato dagli hook c'e', o e' detto «nell'hub»" || ko "satellite: citati e assenti: $(tr '\n' ' ' <<<"$FUORI")"
FUORI_HUB=$(controlla "$HERE")
[ -z "$FUORI_HUB" ] && ok "hub: ogni file citato dagli hook esiste" || ko "hub: citati e assenti: $(tr '\n' ' ' <<<"$FUORI_HUB")"
messaggi "$HERE" | grep -c "nell.hub AI_Programmer" >/dev/null && ko "hub: la nota «nell'hub» compare anche nell'hub" || ok "hub: nessuna nota «nell'hub» (i file sono qui)"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
