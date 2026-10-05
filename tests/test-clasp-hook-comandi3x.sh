#!/bin/bash
# test-clasp-hook-comandi3x.sh — il gancio «clasp push MAI» riconosce i NOMI di clasp 3.x che deployano?
# Uso: bash tests/test-clasp-hook-comandi3x.sh [percorso/del/clasp-block-hook.sh]   (default: il gancio dell'hub)
# Fonte dei nomi: README di @google/clasp 3.x («create-deployment», «update-deployment <id>» al posto di «deploy -i <id>», «deploy» resta alias).
# PARITA: cio' che oggi il gancio fa (push/deploy negati, lettura che passa, citazioni che passano).
# CORREZIONE: cio' che oggi NON fa (create-deployment e update-deployment passano). Riga finale unica: attese eseguite: N/M · fallite: K
set -uo pipefail
HOOK="${1:-$(cd "$(dirname "$0")/.." && pwd)/tools/clasp-block-hook.sh}"
M=30
echo "gancio letto: $HOOK"
ESEGUITE=0; FALLITE=0
decisione() {
  local out; out="$(jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK")"
  if [ -z "$out" ]; then echo passa; else jq -r '.hookSpecificOutput.permissionDecision // "passa"' <<<"$out"; fi
}
attesa() {   # attesa <deny|passa> <comando> <perche>
  ESEGUITE=$((ESEGUITE+1)); local got; got="$(decisione "$2")"
  if [ "$got" = "$1" ]; then echo "ok    [$1] $2 — $3"; else FALLITE=$((FALLITE+1)); echo "FALLITA [atteso $1, trovato $got] $2 — $3"; fi
}
# PARITA
attesa deny  "clasp push"                               "push"
attesa deny  "npx clasp push"                           "push via npx"
attesa deny  "clasp deploy -d x"                        "deploy"
attesa deny  "clasp deploy -i AKfycb"                   "deploy -i (2.x)"
attesa deny  "bash -c 'clasp deploy'"                   "deploy dentro bash -c"
attesa deny  "for i in 1; do clasp push; done"          "push in un ciclo"
attesa passa "clasp pull"                               "lettura"
attesa passa "clasp versions"                           "lettura"
attesa passa "clasp deployments"                        "elenco (2.x)"
attesa passa "clasp list-deployments"                   "elenco (3.x)"
attesa passa "git commit -m 'mai clasp create-deployment'" "una citazione non e un comando"
attesa passa "grep 'clasp update-deployment' docs"      "una ricerca non e un comando"
# CORREZIONE (rosse col gancio di oggi)
attesa deny  "clasp create-deployment"                  "3.x: crea un deployment"
attesa deny  "clasp create-deployment -d x"             "3.x con opzione"
attesa deny  "clasp create-deployment --deploymentId abcd1234" "3.x: redeploy"
attesa deny  "clasp update-deployment abcd1234"         "3.x: aggiorna un deployment (era deploy -i)"
attesa deny  "npx @google/clasp create-deployment"      "3.x via npx"
attesa deny  "npx @google/clasp@3 update-deployment x"  "3.x via npx con versione"
attesa deny  "bash -c 'clasp create-deployment'"        "3.x dentro bash -c"
attesa deny  "for i in 1; do clasp update-deployment x; done" "3.x in un ciclo"
attesa deny  "CI=1 clasp create-deployment"             "3.x con variabile davanti"
attesa deny  "cd gas && clasp create-deployment"        "3.x dopo cd"
attesa deny  "clasp undeploy abcd1234"                 "cancella un deployment: agisce sulla produzione"
attesa deny  "clasp delete-deployment abcd1234"         "3.x: cancella un deployment"
attesa deny  "clasp run-function main"                  "3.x: esegue una funzione in produzione"
attesa deny  "npx clasp run main"                       "2.x: esegue una funzione in produzione (via npx)"
attesa deny  "bash -c 'clasp undeploy x'"               "undeploy dentro bash -c"
attesa passa "npm run build"                            "npm run non e clasp run"
attesa passa "git commit -m 'il clasp run era vietato'" "una citazione non e un comando"
attesa passa "clasp status"                             "lettura"
echo "attese eseguite: $ESEGUITE/$M · fallite: $FALLITE"
[ "$ESEGUITE" -eq "$M" ] || echo ">>> ESEGUITE MENO DI QUELLE DICHIARATE"
# (2026-10-05, report della notte): verdetto canonico per il gate (gate_banchi pretende
# «N OK, 0 FAIL»: il solo «attese eseguite» era un verde senza verdetto, e la issue #197
# se lo rigirava ogni ciclo) e via di fallimento VISIBILE (il meta-audit D39 cerca un
# ko in codice: i contatori soli non bastano all'uditore).
ko() { echo "FAIL $1"; }
echo "$ESEGUITE OK, $FALLITE FAIL"
if [ "$FALLITE" -ne 0 ] || [ "$ESEGUITE" -ne "$M" ]; then
  ko "clasp-block: $FALLITE attese fallite su $ESEGUITE (dichiarate $M)"
  exit 1
fi
