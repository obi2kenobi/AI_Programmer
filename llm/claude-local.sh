#!/bin/bash
# claude-local.sh — Claude Code come harness sul CERVELLO LOCALE (Qwen via Wayfinder).
#
# Verificato dal vivo (2026-08-21): l'endpoint Anthropic-compatibile inbound del gateway
# risponde (test "capitale Italia" → Roma, servito da locale). `wayfinder-router connect
# claude` NON è automatizzato in questa build (risponde "unsupported client"): la ricetta
# manuale è questa e funziona.
#
# Uso:  claude-local.sh            # Claude Code interattivo sul modello locale
#       claude-local.sh -p "..."   # headless
# Requisito: il gateway com.luca.wayfinder attivo (curl -s 127.0.0.1:8088/healthz)
set -euo pipefail

curl -sf --max-time 3 http://127.0.0.1:8088/healthz >/dev/null 2>&1 \
  || { echo "gateway Wayfinder non attivo (launchctl kickstart com.luca.wayfinder o avvialo)" >&2; exit 1; }

export ANTHROPIC_BASE_URL="http://127.0.0.1:8088"
export ANTHROPIC_AUTH_TOKEN="wayfinder-local"
exec claude "$@"
