#!/bin/bash
# profilo.sh — carica il profilo del turno (una dichiarazione, zero default
# sparsi). Ogni chiave dichiarata diventa una variabile d'ambiente per il ciclo;
# le chiavi mancanti restano ai default del codice (dichiarati come fallback).
#
# (audit-4, 2026-09-23): la prima versione sovrascriveva HERE del chiamante —
# disinnescava metà turno. Ora: variabili _PROF_ private, unset a fine lavoro,
# e allowlist esplicita delle chiavi ammesse (niente PATH/IFS/LD_PRELOAD).
#
# Uso: source tools/profilo.sh [nome-profilo]   (default: notturno)
# Stampa: "profilo: N chiavi caricate da <file>" su stderr
NOME="${1:-notturno}"
_PROF_HERE="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
_PROF_FILE="${_PROF_HERE}/profiles/${NOME}.conf"
_PROF_N=0
_PROF_OK="MODELLO THINK SONDA_SEC SONDA_ROUND AGENTE_TIMEOUT AGENTE_MAX_TURNI CICLO_MIN_SEC GATE_MAX_RIGHE GATE_MAX_FILE CENSORE_MAX_RIGHE CENSORE_MAX_FILE CENSORE_QUARANTENA_MIN CENSORE_BUDGET_GIORNO CACCIATORIA_COOLDOWN_SEC IMPARA_ORA"
if [ -f "$_PROF_FILE" ]; then
  while IFS='=' read -r _prof_k _prof_v; do
    case "$_prof_k" in \#*|"") continue ;; esac
    # allowlist: SOLO le chiavi che il turno conosce
    case " $_PROF_OK " in *" $_prof_k "*) ;; *) continue ;; esac
    [ -z "$_prof_v" ] && continue
    export "$_prof_k=$_prof_v"
    _PROF_N=$((_PROF_N+1))
  done < "$_PROF_FILE"
fi
echo "profilo: $_PROF_N chiavi caricate da profiles/$NOME.conf" >&2
unset _PROF_HERE _PROF_FILE _PROF_N _prof_k _prof_v _PROF_OK NOME
