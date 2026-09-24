#!/bin/bash
# test-night-shift-design-gate.sh — set 2 giro 5: due messaggi dedicati ("SENZA sezione
# ## Design"/"## Territorio") erano dead code — verificato con simulazione: quando una
# sezione manca del tutto, il controllo di QUALITÀ (lunghezza/pattern) intercettava sempre
# prima, perché la stringa estratta da una sezione assente è vuota (lunghezza 0 < 80,
# nessun pattern trovato). Replica qui la sequenza REALE (estratta da night-shift.sh
# tramite grep, non ridigitata a mano, per non disallinearsi in futuro).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

# (2026-09-23, notte dei giri — il debito «banchi che rifanno a mano»): qui c'era una COPIA della
# sequenza del turno. Con il gate spento in night-shift/night-shift.sh il banco restava verde. Ora
# il cancello vive in night-shift/lib.sh cancello_design e il banco chiama QUELLA funzione;
# classify() traduce soltanto il motivo nelle etichette storiche dei casi qui sotto.
source "$HERE/night-shift/lib.sh"
declare -F cancello_design >/dev/null || { ko "cancello_design non definita in night-shift/lib.sh"; echo "$PASS OK, $FAIL FAIL"; exit 1; }
classify() {
  local M; M=$(cancello_design "$1")
  case "$M" in
    "") echo "PASSA" ;;
    territorio-assente) echo "SENZA-TERRITORIO" ;;
    design-assente) echo "SENZA-DESIGN" ;;
    design-povero*) echo "DESIGN-POVERO" ;;
    design-senza-fonte) echo "DESIGN-SENZA-RIFERIMENTO" ;;
    territorio-vago) echo "TERRITORIO-SENZA-FILE" ;;
    *) echo "IGNOTO:$M" ;;
  esac
}

# il turno usa la funzione (non una copia sua), e l'issue scartata non va avanti
grep -q 'MOTIVO=$(cancello_design "$BODY")' "$HERE/night-shift/night-shift.sh" \
  && ok "night-shift.sh decide il cancello con lib.sh cancello_design (la funzione provata qui)" \
  || ko "night-shift.sh non usa cancello_design: questo banco proverebbe una copia"

RISULTATO=$(classify "## Commessa
fai qualcosa")
[ "$RISULTATO" = "SENZA-TERRITORIO" ] && ok "issue senza nessuna sezione: rilevata come SENZA Territorio (bug corretto)" \
  || ko "issue senza sezioni: classificata come $RISULTATO"

RISULTATO=$(classify "## Territorio
tools/foo.js righe 1-10")
[ "$RISULTATO" = "SENZA-DESIGN" ] && ok "issue con solo Territorio: rilevata come SENZA Design (bug corretto)" \
  || ko "issue senza Design: classificata come $RISULTATO"

DESIGN_CON_RIFERIMENTO="Segue la lezione dell'11 ore descritta in SAL.md sul territorio grande, qui applicata a questa commessa specifica scritta per il turno"
RISULTATO=$(classify "## Design
$DESIGN_CON_RIFERIMENTO

## Territorio
qualcosa senza estensione")
[ "$RISULTATO" = "TERRITORIO-SENZA-FILE" ] && ok "Design presente e valido, Territorio senza file: rilevato correttamente" \
  || ko "caso Territorio-senza-file: classificato come $RISULTATO"

RISULTATO=$(classify "## Design
$DESIGN_CON_RIFERIMENTO

## Territorio
tools/foo.js righe 1-10")
[ "$RISULTATO" = "PASSA" ] && ok "issue completa e valida: passa il gate" \
  || ko "issue valida bloccata: $RISULTATO"

# --- set 2, giro 6: la sola lunghezza non basta, serve un riferimento reale ---
DESIGN_RIEMPIMENTO="Questo cambiamento serve per migliorare un poco le cose in generale secondo me penso sicuramente forse davvero"
RISULTATO=$(classify "## Design
$DESIGN_RIEMPIMENTO

## Territorio
tools/foo.js righe 1-10")
[ "$RISULTATO" = "DESIGN-SENZA-RIFERIMENTO" ] && ok "Design lungo ma senza riferimento reale: BLOCCATO (bug corretto, prima passava)" \
  || ko "prosa di riempimento non bloccata: $RISULTATO"

for CASO in \
  "con-link:Vedi https://github.com/owner/repo/issues/42 per il contesto completo di questa richiesta, scritto per intero qui sopra" \
  "con-issue:Segue la discussione dell'issue #42 sul territorio grande, applicata identica anche a questa commessa scritta qui" \
  "con-file:La logica attuale dentro tools/foo.js non gestisce questo caso limite descritto con precisione, la commessa lo risolve"
do
  ETICHETTA="${CASO%%:*}"; TESTO="${CASO#*:}"
  RISULTATO=$(classify "## Design
$TESTO

## Territorio
tools/foo.js righe 1-10")
  [ "$RISULTATO" = "PASSA" ] && ok "Design $ETICHETTA: passa il gate" || ko "Design $ETICHETTA: bloccato erroneamente ($RISULTATO)"
done

# (2026-09-24, terzo ventaglio, V3): la skill audit-commessa controllava solo `## Design` e `## Commessa`,
# e promuoveva commesse che questo cancello poi respinge (territorio-assente). La skill usa il cancello
# vero, non una lista sua — in tutti e due gli specchi.
for SK in "$HERE/.claude/skills/audit-commessa/SKILL.md" "$HERE/.opencode/skills/audit-commessa/SKILL.md"; do
  grep -c 'cancello_design' "$SK" >/dev/null && ok "$(basename "$(dirname "$(dirname "$(dirname "$SK")")")")/audit-commessa usa cancello_design" \
    || ko "$SK: la struttura si giudica con una lista sua, non col cancello del turno"
done

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
