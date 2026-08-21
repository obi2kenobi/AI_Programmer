#!/bin/bash
# ask-opus.sh — delega un compito al cervello OPUS (Claude) via Claude Code headless.
# Contratto comune ai wrapper llm/ask-*: prompt come argomento, contesto via stdin,
# risposta su stdout. Exit 0 ok / 1 errore.
#
# NOTA (verificata 2026-08-21): l'autenticazione di Claude Code vive nel Keychain macOS:
# funziona dal terminale dell'utente e da launchd, NON da shell sandboxed.
# Variabili: ASK_MODEL (default: modello predefinito di Claude Code) · ASK_TIMEOUT secondi (600)
set -euo pipefail

PROMPT="${1:-}"
[ -z "$PROMPT" ] && { echo "uso: ask-opus.sh \"prompt\" [stdin opzionale]" >&2; exit 1; }

STDIN_DATA=""
[ ! -t 0 ] && STDIN_DATA=$(cat)
[ -n "$STDIN_DATA" ] && PROMPT="$PROMPT

---
$STDIN_DATA"

MODEL_ARGS=()
[ -n "${ASK_MODEL:-}" ] && MODEL_ARGS=(--model "$ASK_MODEL")

OUT=$(claude -p "$PROMPT" "${MODEL_ARGS[@]}" 2>&1) || { echo "ask-opus: $OUT" >&2; exit 1; }
echo "$OUT"
