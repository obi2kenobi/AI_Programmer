#!/bin/bash
# ask-opus.sh — delega un compito al cervello OPUS (Claude) via Claude Code headless.
# Contratto comune ai wrapper llm/ask-*: prompt come argomento, contesto via stdin,
# risposta su stdout. Exit 0 ok / 1 errore / 2 via non configurata (auth assente —
# armonizzato con ask-glm.sh, che distingue da tempo "non configurato" da "errore").
#
# NOTA (verificata 2026-08-21, macOS): l'autenticazione di Claude Code vive nel Keychain
# macOS: funziona dal terminale dell'utente e da launchd, non da una shell sandboxed SUL MAC.
# Non generalizza a ogni sandbox: una sessione cloud (Claude Code on the web/agent SDK) ha
# la sua auth propria e QUI risponde davvero (verificato 2026-08-22, nuovo ciclo 10 giri —
# vedi tests/test-ask-wrappers.sh, che ora accetta entrambi gli esiti).
# Variabili: ASK_MODEL (default: modello predefinito di Claude Code) · ASK_TIMEOUT secondi (600)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

PROMPT="${1:-}"
[ -z "$PROMPT" ] && { echo "uso: ask-opus.sh \"prompt\" [stdin opzionale]" >&2; exit 1; }

# giro 10/10 (set 1): traccia locale minima — il notturno ha SAL.md+gate.csv, i
# cervelli di giorno non lasciavano nulla. Vedi llm/_usage.sh.
source "$HERE/_usage.sh"
trap 'log_ask_usage ask-opus "${#PROMPT}"' EXIT

# CORREZIONE (set 1 "armonizza gli agenti", 2026-08-22): il ciclo precedente aveva
# attribuito un hang osservato di oltre 2 minuti a "claude -p ricorsivo lento".
# Riprodotto dal vivo ora: la causa vera è `[ ! -t 0 ] && STDIN_DATA=$(cat)` — in
# alcuni contesti non interattivi stdin non è un terminale ma NON emette EOF subito
# (nessun dato in arrivo, il descrittore resta aperto): `cat` blocca a tempo
# indefinito. `-t 0` da solo non basta a distinguere "arriva davvero un contenuto
# in pipe" da "non c'è nulla ma non è un terminale". Annotato come errore della
# nota precedente, non un nuovo difetto del sistema — SAL.md ne porta la traccia.
STDIN_DATA=""
[ ! -t 0 ] && STDIN_DATA=$(timeout 5 cat 2>/dev/null || true)
[ -n "$STDIN_DATA" ] && PROMPT="$PROMPT

---
$STDIN_DATA"

MODEL_ARGS=()
[ -n "${ASK_MODEL:-}" ] && MODEL_ARGS=(--model "$ASK_MODEL")
TIMEOUT="${ASK_TIMEOUT:-600}"

# ASK_TIMEOUT era documentato nell'header ma non implementato — nessun limite su
# `claude -p`. Aggiunto come difesa in profondità (oltre al fix dello stdin sopra):
# anche una chiamata vera al cervello deve avere un limite. set +e locale per
# leggere l'exit code senza far esplodere set -e sull'assegnazione (stesso
# tranello del giro 7 del ciclo precedente).
set +e
OUT=$(timeout "$TIMEOUT" claude -p "$PROMPT" "${MODEL_ARGS[@]}" 2>&1)
RC=$?
set -e
if [ "$RC" -eq 124 ]; then
  echo "ask-opus: timeout dopo ${TIMEOUT}s (claude -p non ha risposto in tempo — ASK_TIMEOUT per allungarlo)" >&2
  exit 1
elif [ "$RC" -ne 0 ]; then
  echo "ask-opus: $OUT" >&2
  # armonizzazione (set 1 "armonizza gli agenti"): ask-glm.sh usa exit 2 per "via
  # non configurata", distinto da un errore generico (exit 1) — qui tornava sempre
  # 1, indistinguibile programmaticamente da qualsiasi altro fallimento. Un
  # chiamante (es. il banco avversariale con ADVERSARY=opus) non poteva reagire
  # diversamente a "manca l'auth" rispetto a "claude ha fallito per altro".
  grep -qiE "not logged in|not authenticated|please (run|use) .?(claude )?login|invalid api key|no credentials" <<<"$OUT" \
    && exit 2
  exit 1
fi
echo "$OUT"
