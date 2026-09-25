#!/bin/bash
# test-claude-md-snello.sh — CLAUDE.md resta un file che il modello SEGUE (D8, decisione di Luca
# 2026-09-23: «a», sezioni del solo hub marcate e tolte agli installatori; e «procedi con tutte le
# correzioni» dopo la verifica sulla documentazione ufficiale di Claude Code).
#
# Le misure vengono dalla documentazione (code.claude.com/docs/en/memory, /best-practices):
#   - «target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce
#     adherence» → le righe VISIBILI al modello (i commenti HTML a blocco si tolgono prima
#     dell'iniezione: la storia delle regole ci vive senza costare contesto) restano sotto 200;
#   - «If you emphasize many lines, none of them stands out» → enfasi su pochissime righe;
#   - una regola del solo hub copiata in una repo privata e' dannosa (report BusinessPlan: 77%
#     dei riferimenti pendenti nel cliente) → i blocchi <!-- solo-hub --> non arrivano ai satelliti.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CM="$HERE/CLAUDE.md"; SAT="$HERE/tools/claude-md-satellite.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# cio' che il modello vede: il file senza i commenti HTML a blocco (fuori dai blocchi di codice)
visibile() { awk '/^```/{c=!c} !c && /^<!--/{h=1} !h{print} h && /-->[[:space:]]*$/{h=0}' "$1"; }

# 1. lunghezza: sotto le 200 righe visibili
N=$(visibile "$CM" | grep -c .)
[ "$N" -lt 200 ] && ok "CLAUDE.md: $N righe visibili al modello (< 200, documentazione ufficiale)" || ko "CLAUDE.md: $N righe visibili (>= 200: aderenza ridotta)"
# la storia non si butta: vive nei commenti HTML
[ "$(grep -c '^<!--' "$CM")" -ge 10 ] && ok "le provenienze delle regole restano, nei commenti HTML ($(grep -c '^<!--' "$CM") blocchi)" || ko "la storia delle regole e' sparita (meno di 10 commenti)"

# 2. enfasi su poche righe
E=$(visibile "$CM" | grep -cE 'IMPORTANT|No exceptions|binding|vincolante|!!!')
[ "$E" -le 1 ] && ok "enfasi su $E righe (una regola enfatizzata spicca solo se e' sola)" || ko "enfasi su $E righe: nessuna spicca piu'"

# 3. i blocchi del solo hub: bilanciati, e sono quelli confermati da Luca
A=$(grep -c '^<!-- solo-hub -->$' "$CM"); C=$(grep -c '^<!-- /solo-hub -->$' "$CM")
[ "$A" -ge 1 ] && [ "$A" -eq "$C" ] && ok "marcatori solo-hub bilanciati ($A blocchi)" || ko "marcatori solo-hub sbilanciati ($A aperture, $C chiusure)"
DENTRO=$(awk '/^<!-- solo-hub -->$/{f=1} /^<!-- \/solo-hub -->$/{f=0} f' "$CM")
MANCA=""
for S in "Public repo, private work" "When to delegate" "Never delegate" "Full method" "Goal loops" 'calls the LLMs'; do
  grep -qF "$S" <<<"$DENTRO" || MANCA="$MANCA [$S]"
done
[ -z "$MANCA" ] && ok "dentro i blocchi solo-hub: le sezioni confermate (§7 LLM, delega, metodo, goal loop, repo pubblico)" || ko "sezioni confermate fuori dai blocchi:$MANCA"

# 4. la versione per i satelliti: senza il solo-hub, senza citazioni a file che li' non esistono
OUT=$(bash "$SAT" "$CM"); RC=$?
[ $RC -eq 0 ] && [ -n "$OUT" ] && ok "claude-md-satellite: produce la versione per i satelliti" || ko "claude-md-satellite fallito (rc=$RC)"
grep -qE '^<!-- /?solo-hub -->$|Public repo, private work|calls the LLMs' <<<"$OUT" && ko "il solo-hub arriva ai satelliti" || ok "nessun blocco solo-hub nella versione per i satelliti"
grep -qE '`(night-shift/|llm/|docs/system\.md|loops/)' <<<"$OUT" && ko "la versione satellite cita file del solo hub: $(grep -oE '`(night-shift/|llm/|docs/system\.md|loops/)[^`]*`' <<<"$OUT" | sort -u | tr '\n' ' ')" \
  || ok "la versione satellite non cita night-shift/, llm/, docs/system.md, loops/"
MANCA=""
for S in "settimo patto" "sesto patto" "cinque patti" "## 1. Process Rules" "## 2. Code Rules" "## 3. Communication Rules" "## 4. Git Rules" "## 5. Error Handling" "## 6. Project-Specific Context" "graphify" "minimal-code ladder" "Three strikes" "Patterns before reinventing" "clasp"; do
  grep -qF "$S" <<<"$OUT" || MANCA="$MANCA [$S]"
done
[ -z "$MANCA" ] && ok "le regole universali arrivano tutte ai satelliti (anche il divieto di clasp push)" || ko "regole universali perse nella versione satellite:$MANCA"

# 5. marcatori sbilanciati: lo stripper si rifiuta, mai un CLAUDE.md a meta'
printf '# x\n<!-- solo-hub -->\nsegreto\n' > "$T/rotto.md"
OUT=$(bash "$SAT" "$T/rotto.md" 2>/dev/null); RC=$?
[ $RC -ne 0 ] && [ -z "$OUT" ] && ok "marcatori sbilanciati: rifiuto (rc=$RC), nessuna uscita parziale" || ko "marcatori sbilanciati accettati (rc=$RC)"

# 6. gli installatori installano la versione satellite, e il confronto di deriva usa quella
for F in tools/bootstrap-app.sh tools/garante-standard.sh tools/sync-repo.sh night-shift/morning-gate.sh; do
  grep -q 'claude-md-satellite.sh' "$HERE/$F" && ok "$F usa claude-md-satellite.sh" || ko "$F copia o confronta il CLAUDE.md dell'hub intero"
done
grep -qE 'cp "\$(HERE|HUB)/CLAUDE.md"' "$HERE/tools/bootstrap-app.sh" "$HERE/tools/garante-standard.sh" \
  && ko "resta un cp del CLAUDE.md intero dell'hub" || ok "nessun installatore copia piu' il CLAUDE.md intero"

# (2026-09-23, notte dei giri): con uno spazio finale o un CRLF sulla riga del marcatore la regex non
# combaciava — il blocco solo-hub arrivava ai satelliti, rc 0, senza errore. Ora il marcatore regge
# gli spazi e il CR, e una riga che somiglia a un marcatore ma non lo e' e' un errore, non un testo.
SAT=$(mktemp -d)
printf 'regola comune\n<!-- solo-hub --> \nSOLO DELL HUB\n<!-- /solo-hub -->\r\nfine\n' > "$SAT/spazi.md"
OUT=$(bash "$HERE/tools/claude-md-satellite.sh" "$SAT/spazi.md" 2>&1); RC=$?
[ "$RC" -eq 0 ] && ! grep -q "SOLO DELL HUB" <<<"$OUT" && ok "marcatore con spazio finale o CRLF: il blocco solo-hub non esce" \
  || ko "marcatore con spazio/CRLF: il blocco arriva al satellite (rc=$RC)"
printf 'regola comune\n<!--solo-hub-->\nSOLO DELL HUB\n<!-- /solo-hub -->\n' > "$SAT/storto.md"
OUT=$(bash "$HERE/tools/claude-md-satellite.sh" "$SAT/storto.md" 2>&1); RC=$?
[ "$RC" -ne 0 ] && ! grep -q "SOLO DELL HUB" <<<"$OUT" && ok "marcatore storto (<!--solo-hub-->): errore, nessuna uscita" \
  || ko "marcatore storto passato come testo (rc=$RC)"
rm -rf "$SAT"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
