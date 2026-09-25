#!/bin/bash
# test-a-capo-finale.sh — una riga aggiunta a un file che non finisce con un a capo si incolla all'ultima
# (2026-09-24, sesto ventaglio, S2 R2). Tre strumenti lo facevano: copia-hook (la .gitignore: «node_modules»
# diventava «node_modules.campo-rem» e smetteva di essere ignorato), installa-citati (il gate GAS finiva
# dentro l'ultimo commento di .night-verify), iscrivi-coda (la repo gia' in coda si fondeva con la nuova).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

mkdir -p "$T/gi"; printf 'node_modules' > "$T/gi/.gitignore"
bash "$HERE/tools/copia-hook.sh" --residui "$T/gi" >/dev/null 2>&1
grep -qx 'node_modules' "$T/gi/.gitignore" && grep -qx '.campo-rem' "$T/gi/.gitignore" \
  && ok "copia-hook: il residuo va su una riga sua, node_modules resta ignorato" || ko "copia-hook: .gitignore = $(tr '\n' '|' < "$T/gi/.gitignore")"

git init -q "$T/gas"; echo 'function f(){}' > "$T/gas/a.gs"; git -C "$T/gas" add a.gs
printf '# Verifiche dichiarate' > "$T/gas/.night-verify"
bash "$HERE/tools/installa-citati.sh" "$T/gas" --solo-mancanti >/dev/null 2>&1
grep -qx 'bash tools/gas-gate.sh' "$T/gas/.night-verify" && ok "installa-citati: il gate GAS e' un comando, non la coda di un commento" \
  || ko "installa-citati: .night-verify = $(tr '\n' '|' < "$T/gas/.night-verify")"

printf 'luca/vecchia feat' > "$T/repos.conf"
bash "$HERE/tools/iscrivi-coda.sh" "$T/repos.conf" luca/nuova feat >/dev/null 2>&1
grep -qx 'luca/vecchia feat' "$T/repos.conf" && grep -qx 'luca/nuova feat' "$T/repos.conf" \
  && ok "iscrivi-coda: la repo nuova ha la sua riga, quella in coda resta" || ko "iscrivi-coda: repos.conf = $(tr '\n' '|' < "$T/repos.conf")"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
