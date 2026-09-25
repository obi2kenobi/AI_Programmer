#!/bin/bash
# test-bootstrap-hooks-propagation.sh — banco di regressione nato dalla revisione "L'Hub
# Allo Specchio" (14 lenti indipendenti, 2026-08-28): bug reale in bootstrap-app.sh,
# mancava "mkdir -p tools" prima dei cp degli hook — su un progetto bootstrappato da zero
# (nessuna cartella tools/ preesistente, il caso NORMALE per un progetto nuovo) il cp
# falliva silenziosamente (2>/dev/null || true) e gli hook non venivano mai installati,
# senza che lo script desse alcun avviso.
#
# ESTESO dal campo (REPO-V, progetto GAS nuovo, 2026-09-03): il bug successivo, della
# stessa famiglia, che questo banco NON vedeva. La lista degli hook era scritta a mano
# in TRE posti (settings.json, bootstrap-app.sh, sync-repo.sh) e i tre erano divergiti:
# settings.json dichiarava tre hook, i due script ne copiavano due — mancava
# `clasp-block-hook.sh`, cioè l'unico cancello TECNICO del metodo. Il vecchio banco
# elencava a mano gli stessi due hook degli script, quindi SPECCHIAVA il bug invece di
# trovarlo: una guardia allineata al difetto non è una guardia. Ora la lista si DERIVA
# da .claude/settings.json — l'unica fonte che non può divergere da sé stessa — e la
# copia è delegata a tools/copia-hook.sh, provato dal vivo qui sotto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

SETTINGS="$HERE/.claude/settings.json"
DICHIARATI=$(bash "$HERE/tools/copia-hook.sh" --elenco "$SETTINGS")  # (revisione 10 giri: una derivazione sola)
N_DICHIARATI=$(echo "$DICHIARATI" | grep -c .)

[ "$N_DICHIARATI" -ge 3 ] \
  && ok "settings.json dichiara $N_DICHIARATI hook (lista derivata, non scritta a mano)" \
  || ko "settings.json dichiara solo $N_DICHIARATI hook: la derivazione non legge niente"

# La guardia sul buco specifico: il cancello tecnico deve essere fra i dichiarati.
grep -q '^tools/clasp-block-hook\.sh$' <<<"$DICHIARATI" \
  && ok "clasp-block-hook.sh è fra gli hook dichiarati" \
  || ko "clasp-block-hook.sh NON dichiarato in settings.json"

# Delega, non elenco: bootstrap-app.sh non deve più nominare gli hook uno per uno.
grep -q 'copia-hook\.sh' "$HERE/tools/bootstrap-app.sh" \
  && ok "bootstrap-app.sh delega la copia a tools/copia-hook.sh" \
  || ko "bootstrap-app.sh non usa tools/copia-hook.sh: la lista è ancora scritta a mano"

[ -x "$HERE/tools/copia-hook.sh" ] \
  && ok "tools/copia-hook.sh è eseguibile" \
  || ko "tools/copia-hook.sh assente o non eseguibile"

# --- prova dal vivo: stesso scenario del bug originale (nessun tools/ preesistente) ---
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/progetto-nuovo"
COPIATI=$(bash "$HERE/tools/copia-hook.sh" "$TMP/progetto-nuovo" 2>"$TMP/err") \
  && ok "copia-hook.sh esce 0 su un progetto senza tools/ preesistente" \
  || ko "copia-hook.sh fallisce: $(head -2 "$TMP/err")"

while IFS= read -r H; do
  [ -n "$H" ] || continue
  [ -x "$TMP/progetto-nuovo/$H" ] \
    && ok "$H installato ed eseguibile nel progetto nuovo" \
    || ko "$H NON installato nel progetto nuovo (dichiarato in settings.json)"
done <<< "$DICHIARATI"

# (2026-09-20, dalla cura H1): copia-hook ora porta anche le righe .gitignore dei
# residui — l'output puo' contenere una riga in piu' (la .gitignore), mai una in
# meno: gli HOOK copiati devono essere TUTTI i dichiarati
N_HOOK_COPIATI=$(echo "$COPIATI" | grep -c '^tools/.*\.sh$')
[ "$N_HOOK_COPIATI" -eq "$N_DICHIARATI" ] \
  && ok "copia-hook.sh riporta $N_DICHIARATI hook copiati, quanti sono i dichiarati" \
  || ko "copia-hook.sh copia $N_HOOK_COPIATI hook contro $N_DICHIARATI dichiarati"
grep -q '^\.gitignore$' <<<"$COPIATI" \
  && ok "copia-hook.sh porta anche la .gitignore dei residui (cura H1)" \
  || ko "la .gitignore dei residui non viaggia (H1)"

# (2026-09-24, notte dei giri, T6#3): la .gitignore dei residui prendeva ogni `$PWD/.x` nominato dagli
# hook — anche .mirror-boundaries, che e' una DICHIARAZIONE (i cloni di sola lettura: la scrive
# l'utente, la LEGGE tools/clasp-block-hook.sh). Ignorata, non si versiona, e chi clona perde il
# cancello. E i sorgenti degli hook si cercavano relativi alla cartella corrente: lanciato da
# un'altra cartella, nessun residuo, in silenzio.
D2="$TMP/da-altrove"; mkdir -p "$D2"
( cd / && bash "$HERE/tools/copia-hook.sh" "$D2" >/dev/null 2>&1 )
grep -qxF '.campo-rem' "$D2/.gitignore" 2>/dev/null && ok "lanciato da un'altra cartella: il residuo .campo-rem va nella .gitignore" \
  || ko "lanciato da un'altra cartella: residui persi ($(cat "$D2/.gitignore" 2>/dev/null | tr '\n' ' '))"
grep -qxF '.mirror-boundaries' "$D2/.gitignore" 2>/dev/null && ko ".mirror-boundaries (dichiarazione, non residuo) finisce nella .gitignore" \
  || ok ".mirror-boundaries resta versionabile: non e' un residuo"
# un satellite nato prima ha la riga sbagliata: la prossima copia la toglie, e lo dice
D3="$TMP/satellite-vecchio"; mkdir -p "$D3"; printf 'node_modules\n.mirror-boundaries\n.campo-rem\n' > "$D3/.gitignore"
OUT3=$(bash "$HERE/tools/copia-hook.sh" "$D3" 2>&1)
! grep -qxF '.mirror-boundaries' "$D3/.gitignore" && grep -qxF 'node_modules' "$D3/.gitignore" && grep -c "mirror-boundaries" <<<"$OUT3" >/dev/null \
  && ok "satellite vecchio: la riga .mirror-boundaries si toglie (dichiarato), il resto resta" || ko "satellite vecchio: .gitignore = $(tr '\n' ' ' < "$D3/.gitignore")"

# Il guardiano si prova quando deve fallire: un hook dichiarato ma ASSENTE dall'hub deve
# far uscire copia-hook.sh in errore, non copiare il resto e tacere — è esattamente il
# modo in cui il bug originale è passato inosservato (cp che falliva sotto `|| true`).
FALSO_HUB="$TMP/hub-finto"
mkdir -p "$FALSO_HUB/.claude" "$FALSO_HUB/tools"
jq '.hooks.PreToolUse[0].hooks += [{"type":"command","command":"tools/hook-che-non-esiste.sh"}]' \
  "$SETTINGS" > "$FALSO_HUB/.claude/settings.json"
cp "$HERE/tools/copia-hook.sh" "$FALSO_HUB/tools/copia-hook.sh"
while IFS= read -r H; do [ -n "$H" ] && cp "$HERE/$H" "$FALSO_HUB/$H"; done <<< "$DICHIARATI"
# Attesa condizionata all'ESISTENZA dello script: un `bash file-inesistente` esce non-zero
# e questa attesa diventerebbe verde per il motivo sbagliato — «lo stub che mente al
# rovescio», visto dal vivo scrivendo proprio questo banco (era verde con copia-hook.sh
# ancora da scrivere). Il sabotaggio prova il comportamento, non l'assenza.
if [ ! -x "$FALSO_HUB/tools/copia-hook.sh" ]; then
  ko "sabotaggio non eseguibile: copia-hook.sh non esiste (attesa non verificata, non verde)"
elif bash "$FALSO_HUB/tools/copia-hook.sh" "$TMP/dest-sabotata" >/dev/null 2>&1; then
  ko "hook dichiarato e assente: copia-hook.sh è uscito 0 (fallimento silenzioso)"
else
  ok "hook dichiarato e assente: copia-hook.sh fallisce e lo dice (sabotaggio provato)"
fi

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
