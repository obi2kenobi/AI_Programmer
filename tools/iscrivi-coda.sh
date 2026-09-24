#!/bin/bash
# iscrivi-coda.sh — iscrive una repo nella coda della notte (night-shift/repos.conf), una volta sola.
# (2026-09-24, notte dei giri, T6#6): i due installatori avevano ognuno la sua regex, sbagliata in modo
# opposto — onboard-repo (`^$REPO\b`) dava luca/app per presente se c'era luca/app-v2, e il punto del
# nome faceva da jolly: la repo non entrava mai, in silenzio; bootstrap-app (`^login/nome$`) non
# combaciava mai con «login/nome feat» e aggiungeva un doppione a ogni giro. Qui il confronto e'
# ESATTO sul primo campo di ogni riga non commentata, e ogni esito si dice.
#
# Uso: iscrivi-coda.sh <repos.conf> <owner/repo> <tipo>
# Esce 0 (aggiunta, o gia' presente), 1 (argomenti o scrittura).
set -uo pipefail
CONF="${1:?uso: iscrivi-coda.sh <repos.conf> <owner/repo> <tipo>}"
REPO="${2:?uso: iscrivi-coda.sh <repos.conf> <owner/repo> <tipo>}"
TIPO="${3:?uso: iscrivi-coda.sh <repos.conf> <owner/repo> <tipo>}"
# (2026-09-24, quarto ventaglio, Q2 R4): col login GitHub illeggibile il bootstrap passava «/nome», e il turno
# poi falliva il clone ogni notte, lontano dalla causa. Si iscrive solo la forma owner/repo.
[[ "$REPO" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]] || { echo "coda: «$REPO» non e' owner/repo — non iscritta" >&2; exit 1; }

if [ -f "$CONF" ] && awk -v r="$REPO" '$1 !~ /^#/ && $1 == r {trovata=1} END {exit !trovata}' "$CONF"; then
  echo "coda: $REPO gia' iscritta in $CONF — niente da aggiungere"
  exit 0
fi
# (2026-09-24, sesto ventaglio, S2 R2): senza a capo finale la riga nuova si incollava all'ultima
[ -s "$CONF" ] && [ -n "$(tail -c1 "$CONF")" ] && echo >> "$CONF"
echo "$REPO $TIPO" >> "$CONF" || { echo "coda: scrittura fallita in $CONF" >&2; exit 1; }
echo "coda: $REPO iscritta in $CONF ($TIPO)"
