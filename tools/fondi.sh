#!/bin/bash
# fondi.sh — wrapper OPZIONALE di merge sopra il revisore forte.
#
# Le quattro condizioni (fondibilita', lente, banco, censore) non si leggono
# piu' da commenti separati e senza data: TUTTE devono valere sullo stesso
# headRefOid in UNA chiamata fresca a night-shift/revisore.sh. Quello e' il
# solo componente che sa fare checkout staccato, prove sandboxed e giudizio.
#
# SPENTO di default: FONDI_AUTO=1 lo attiva. Le PR giorno/* e night/issue-*
# sono la corsia ordinaria; una PR claude/* di sync puo' entrare SOLO quando
# il chiamante dichiara FONDI_CLASSE=standard (riallineo gia' verificato).
# Uso: fondi.sh <dir-repo> <n-pr>. Esce 0=fusa, 1=NO, 2=spento/indisponibile.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:?uso: fondi.sh <dir> <n-pr>}"; N="${2:?}"

if [ "${FONDI_AUTO:-0}" != "1" ]; then
  echo "FONDI: NO — auto-merge spento di default; la PR resta al revisore forte" >&2
  exit 2
fi

REVISORE=""
if [ -f "$HERE/night-shift/revisore.sh" ]; then
  REVISORE="$HERE/night-shift/revisore.sh"
elif [ -f "${AI_PROGRAMMER_HUB:-/inesistente}/night-shift/revisore.sh" ]; then
  REVISORE="${AI_PROGRAMMER_HUB%/}/night-shift/revisore.sh"
elif [ -f "$HOME/night-shift-work/AI_Programmer/night-shift/revisore.sh" ]; then
  REVISORE="$HOME/night-shift-work/AI_Programmer/night-shift/revisore.sh"
else
  echo "FONDI: NO — revisore.sh assente (né locale né nell'hub): nessun fallback debole" >&2
  exit 2
fi

REPO=$(cd "$DIR" && git remote get-url origin 2>/dev/null | sed -e 's#.*github.com[:/]##' -e 's#\.git$##')
[ -n "$REPO" ] || { echo "FONDI: NO — origin non GitHub" >&2; exit 2; }
PR_JSON=$(gh pr view "$N" --repo "$REPO" --json headRefOid,headRefName,mergeable,state,isDraft 2>/dev/null) || PR_JSON=""
[ -n "$PR_JSON" ] || { echo "FONDI: NO — PR #$N illeggibile"; exit 1; }
HEAD_OID=$(jq -r '.headRefOid // empty' <<<"$PR_JSON")
BRANCH=$(jq -r '.headRefName // empty' <<<"$PR_JSON")
STATE=$(jq -r '.state // empty' <<<"$PR_JSON")
MERGEABLE=$(jq -r '.mergeable // empty' <<<"$PR_JSON")
IS_DRAFT=$(jq -r '.isDraft // empty' <<<"$PR_JSON")
[ -n "$HEAD_OID" ] && [ "$HEAD_OID" != "null" ] || { echo "FONDI: NO — headRefOid assente"; exit 1; }
if [ "$STATE" != "OPEN" ] || [ "$MERGEABLE" != "MERGEABLE" ]; then
  echo "FONDI: NO — PR #$N non fondibile (state=$STATE, mergeable=$MERGEABLE)"
  exit 1
fi
case "$BRANCH" in
  giorno/*|night/issue-*) ;;
  claude/*)
    [ "${FONDI_CLASSE:-}" = "standard" ] || { echo "FONDI: NO — PR claude/* non standard resta al cancelliere"; exit 1; } ;;
  *) echo "FONDI: NO — branch $BRANCH fuori dalle corsie di questo wrapper"; exit 1 ;;
esac

echo "1. PR: APERTA e FONDIBILE — commit $HEAD_OID"
# Review SEMPRE fresca: un commento vecchio non puo' approvare un commit nuovo.
# Il revisore legge da solo lo SHA remoto; se questo cambia dopo la review, il
# --match-head-commit sotto rifiuta il merge invece di fondere codice diverso.
REV_OUT=$(GIORNO_PARERE=1 GIORNO_SUBITO=1 bash "$REVISORE" "$DIR" "$N" 2>&1); REV_RC=$?
printf '%s\n' "$REV_OUT" | grep -aE 'PARERE:|prove:|guardia:|censore:' | tail -12 || true
if [ "$REV_RC" -ne 4 ] || ! grep -qE '(^|\] )PARERE: APPROVA( |$)' <<<"$REV_OUT"; then
  echo "FONDI: NO — nessuna approvazione fresca sul commit della PR (revisore rc=$REV_RC)"
  exit 1
fi
echo "2-4. prove: VERDI nella chiamata del revisore (banco sandboxed + lente + censore)"

if [ "$IS_DRAFT" = "true" ]; then
  READY_OUT=$(gh pr ready "$N" --repo "$REPO" 2>&1) || {
    echo "FONDI: NO — PR approvata ma promozione da bozza rifiutata: $(tail -1 <<<"$READY_OUT" | cut -c1-140)"; exit 1; }
fi
ESITO_MERGE=$(gh pr merge "$N" --repo "$REPO" --merge --match-head-commit "$HEAD_OID" 2>&1) || {
  echo "FONDI: NO — GitHub ha rifiutato il merge sul commit $HEAD_OID: $(tail -1 <<<"$ESITO_MERGE" | cut -c1-140)"; exit 1; }
tail -1 <<<"$ESITO_MERGE"
echo "FONDI: SI — PR #$N fusa sul commit $HEAD_OID dopo review fresca; post-merge obbligatorio sul ramo di default"
