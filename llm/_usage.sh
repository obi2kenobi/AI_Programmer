#!/bin/bash
# _usage.sh — traccia minima locale delle chiamate ai cervelli (sourced, non eseguito).
#
# Gap reale (set 1 "armonizza gli agenti", 2026-08-22): il turno notturno lascia
# traccia in SAL.md + metrics/gate.csv (principio L4 MEMORIA — "le decisioni future
# le decidono i dati accumulati"). I cervelli di giorno (ask-opus/ask-glm/ask-qwen
# chiamati a mano) non lasciavano NESSUNA traccia — asimmetria di memoria fra notte
# e giorno. Un file LOCALE (mai versionato, come repos.conf/repos.key), best-effort:
# non deve mai far fallire il wrapper che lo usa.
#
# Uso: dopo aver validato PROMPT, registrare `trap 'log_ask_usage <nome> "${#PROMPT}"' EXIT`
USAGE_LOG="${ASK_USAGE_LOG:-$HOME/.ai-programmer-usage.log}"
_USAGE_START=$(date +%s)

log_ask_usage() {
  local rc=$? brain="$1" prompt_len="${2:-0}" dur
  dur=$(( $(date +%s) - _USAGE_START ))
  printf '%s %s rc=%s dur=%ss prompt_chars=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$brain" "$rc" "$dur" "$prompt_len" >> "$USAGE_LOG" 2>/dev/null || true
}
