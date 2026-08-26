#!/bin/bash
# metodo-reminder-hook.sh — 2026-08-26, il problema di Luca: «invoco AI_Programmer
# all'inizio e spesso viene dimenticato o usato in parte». Finché il metodo dipende
# dall'invocazione iniziale, dipende dalla memoria della sessione — e il SAL lo
# dice da tempo: l'unico correttivo che rompe quello schema è l'hook. Questo hook
# rende il metodo STRUTTURALE, non mentale: due eventi, zero invocazioni.
#
#   UserPromptSubmit — a OGNI prompt dell'utente (non solo al primo): un digest
#     compatto del metodo + l'aggancio dinamico se il prompt parla di calcoli.
#   SessionStart     — all'apertura: la porta d'ingresso (dove sta il metodo).
#
# Costo: 3-6 righe di contesto per prompt. Non blocca mai (non può: questi
# eventi non hanno permissionDecision — possono solo aggiungere contesto).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
INPUT="$(cat)"
EVENT="$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)"

if [ "$EVENT" = "SessionStart" ]; then
  jq -n --arg ctx "STANDARD DI SVILUPPO ATTIVO (AI_Programmer — non serve invocarlo, vale da sé):
1) Esegui, non dedurre: ogni ipotesi meccanica si prova eseguendo, col comando riportato.
2) Prima di una formula di business: oracolo in tools/*.py o formula minata file:riga — MAI indovinata (docs/mappa-dominio-gas-src.md).
3) Prima di correggere: il banco (PARITÀ+CORREZIONE), riga-verdetto 'attese eseguite: N/M · fallite: K' (verifica con tools/verifica_banco.py).
4) Scarto mai silenzioso, assente≠zero, clasp MAI, segreti mai (nemmeno citati).
5) Task da una sessione: si fa e basta col metodo; territorio grande: METHOD.md dice la strada.
Il metodo in una pagina: METHOD.md. Le famiglie misurate: .claude/skills/gas-sviluppo/references/famiglie-difetti.md." \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
  exit 0
fi

# UserPromptSubmit (default): digest minimo + aggancio se il prompt tocca calcoli/dati
HINT=""
if echo "$PROMPT" | grep -qiE 'calcol|formula|fattur|magazzin|margine|scostament|cespit|scadenz|leasing|rating|bilanci|valorizz'; then
  HINT=" · questo prompt tocca un calcolo: prima gli oracoli in tools/*.py (docs/mappa-dominio-gas-src.md), la formula non si indovina"
fi
if echo "$PROMPT" | grep -qiE 'corregg|sistem|fix|bug'; then
  HINT="$HINT · prima di correggere: il banco, e la domanda di dominio in cima"
fi
jq -n --arg ctx " metodo attivo: esegui-non-dedurre · oracolo prima della formula · banco prima della correzione · SAL prima del passo successivo${HINT}" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
