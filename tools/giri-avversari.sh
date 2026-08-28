#!/bin/bash
# giri-avversari.sh — 100 attacchi che provano a contestare il sistema: forzare
# le regole, aggirare le difese, imbrogliare le lenti. Ogni attacco: mutazione
# → difesa → verdetto TIENE/AGGIRATO → revert. Gli AGGIRATI sono i finding.
#
# Categorie: A mutazioni che i test devono prendere (25) · B bypass degli hook
# (8) · C gaming delle lenti e delle sonde (10) · D input ostili agli oracoli
# (25) · E privacy che riaffiora (7) · F regole senza denti (5) · G copertura
# residue (20).
#
# Il campione dell'attacco C7 usa --flag-segreto come flag di PROVA: documentato
# qui appunto perché la sonda S5 dei giri ignoranti legge ogni --parola) implementata.
#
# Esce 1 se c'è anche un solo AGGIRATO non riconosciuto: la lista ACK sono i
# limiti dichiarati e accettati (documentati, non nascosti).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"

# Un attacco si fa solo su ALBERO PULITO: i checkout di ripristino altrimenti
# cancellano lavoro non committato ( successo davvero il 2026-08-28: due fix
# persi e riapplicati a mano prima di capirlo).
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard | head -1)" ]; then
  echo "⛔ albero sporco: committa (o stash) prima di attaccare" >&2
  exit 2
fi
restore_tutto() {
  git checkout -- . 2>/dev/null
  chmod +x tools/*.sh 2>/dev/null
  rm -f .campo-rem tools/_sleep_malvagio.py /tmp/avv-*.md /tmp/avv-*.py /tmp/avv-*.sh /tmp/avv-*.json /tmp/avv-*.csv /tmp/avv-*.txt /tmp/avv-*.bak /tmp/avv-lib.bak 2>/dev/null
  rm -rf .ciclo 2>/dev/null
}
trap restore_tutto EXIT

TENGONO=0; AGGIRATI=0; ACK=0; ATT=0

ack() { ACK=$((ACK+1)); echo "ACK  #$ATT $1"; }
tiene() { TENGONO=$((TENGONO+1)); echo "TIENE #$ATT $1"; }
aggirato() { AGGIRATI=$((AGGIRATI+1)); echo "AGGIRA #$ATT $1"; }
att() { ATT=$((ATT+1)); }
difesa_test() {
  bash "$1" >/dev/null 2>&1 && aggirato "$2" || tiene "$2"
  git checkout -- . 2>/dev/null   # ogni attacco parte dall'albero integro: i verdetti non a cascata
  chmod +x tools/*.sh 2>/dev/null
}
rev() { git checkout -- "$1" 2>/dev/null; true; }

echo "=== CAT A — mutazioni che i test DEVONO prendere ==="

att; python3 -c "
import re
p='.claude/skills/gas-sviluppo/references/metodo.md'; s=open(p).read()
s = s.replace(\"L'onore del NON VERIFICATO\", \"L'onore del NASCOSTO\")
open(p,'w').write(s)"
difesa_test tests/test-canone-integrita.sh "A1 sezione portante rinominata nel canone"

att; echo svuotato > .claude/skills/gas-sviluppo/references/metodo.md
difesa_test tests/test-canone-integrita.sh "A2 canone svuotato"

att; python3 -c "
bt = chr(96)
p='.claude/skills/gas-sviluppo/references/metodo.md'; s=open(p).read()
open(p,'w').write(s + '\n**Meta**: ' + bt + 'pippo-rosso-finto' + bt + '\n')"
difesa_test tests/test-canone-integrita.sh "A3 indice che cita pattern inesistente"

att; mv patterns/watchdog-guardato.md /tmp/avv-pattern.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -q "S7" <<<"$OUT_BAT" && tiene "A4 pattern file cancellato (S7 lo vede)" || aggirato "A4 pattern cancellato, nessuna difesa rosso"
mv /tmp/avv-pattern.md patterns/watchdog-guardato.md

att; sed -i '' 's|night-shift/lib.sh:run_guarded|night-shift/INESISTENTE:run_guarded|' patterns/watchdog-guardato.md
difesa_test tests/test-patterns-ancore-esistono.sh "A5 àncora pattern rotta"

att; sed -i '' 's|^description: .*$|description: ""|' .claude/agents/revisore-gas.md
difesa_test tests/test-agents-structure.sh "A6 agente senza description"

att; sed -i '' '/^mode: subagent/d' .opencode/agent/revisore-gas.md
difesa_test tests/test-opencode-agent-sync.sh "A7 specchio agente senza mode"

att; printf '\nRIGA AVVERSARIA DI DRIFT\n' >> .opencode/agent/revisore-gas.md
difesa_test tests/test-opencode-agent-sync.sh "A8 drift corpo specchio agente"

att; python3 -c "
import json
s = json.load(open('.claude/settings.json')); s['hooks']['PreToolUse']=[]
json.dump(s, open('.claude/settings.json','w'), indent=2)"
difesa_test tests/test-pattern-reminder-hook.sh "A9 hook rimosso da settings"

att; chmod -x tools/pattern-reminder-hook.sh
difesa_test tests/test-pattern-reminder-hook.sh "A10 hook non eseguibile"

att; mv tools/margine_documento.py /tmp/avv-oracolo.py
difesa_test tests/test-margine-documento.sh "A11 oracolo cancellato"
mv /tmp/avv-oracolo.py tools/margine_documento.py

att; sed -i '' 's/margine = importo_v - importo_a/margine = importo_v + importo_a/' tools/margine_documento.py
difesa_test tests/test-margine-documento.sh "A12 aritmetica oracolo invertita (riga vera)"

att; python3 - <<'EOF'
p = 'tools/scadenzario_aging.py'; s = open(p).read()
old = 'if tipo.startswith("Fornitore"):'
assert old in s; open(p, 'w').write(s.replace(old, 'if False and tipo.startswith("Fornitore"):'))
EOF
difesa_test tests/test-scadenzario-aging.sh "A13 fix segno fornitore disattivato"

att; sed -i '' 's/--standard) STANDARD=1/--tutto) STANDARD=1/' tools/sync-repo.sh
difesa_test tests/test-sync-repo-standard-item-list.sh "A14 --standard rimosso da sync-repo"

att; python3 -c "
import re
p='CLAUDE.md'; s=open(p).read()
open(p,'w').write(re.sub(r'(?m)^.*clasp.*$', '', s))"
difesa_test tests/test-claude-md-gate-conventions.sh "A15 regola clasp tolta da CLAUDE.md"

att; mv docs/campo/README.md /tmp/avv-campo-readme.md
difesa_test tests/test-report-campo.sh "A16 formato report campo cancellato"
mv /tmp/avv-campo-readme.md docs/campo/README.md

att; mv .gitattributes /tmp/avv-ga
difesa_test tests/test-claude-md-gate-conventions.sh "A17 union merge driver rimosso"
mv /tmp/avv-ga .gitattributes

att; rm -rf .claude/skills/design-doc
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -q "S8" <<<"$OUT_BAT" && tiene "A18 skill cancellata (pavimento S8)" || aggirato "A18 skill cancellata invisibile"
git checkout -- .claude/skills 2>/dev/null; true

att; sed -i '' 's/<!-- SAL-INDICE: generato/<!-- MARKER-SOSTITUITO: generato/' SAL.md
difesa_test tests/test-sal-indice-ancore.sh "A19 marker indice SAL sostituito"

att; printf 'sk-ANTHROPIC-FAKE1234567890abcd\n' >> docs/campo/2026-08-28-sd-dashboard-dossier.md
bash tools/privacy-check.sh >/dev/null 2>&1 && aggirato "A20 segreto generico piantato: privacy-check non ne vede la FORMA" || tiene "A20 forma di segreto piantata vista (shaping)"
git checkout -- docs/campo/2026-08-28-sd-dashboard-dossier.md 2>/dev/null; true

echo ""
echo "=== CAT B — bypass degli hook ==="

att; OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"credenziali_BC.rtf"}}' | bash tools/pattern-reminder-hook.sh)
echo "$OUT" | grep -qi "pattern" && tiene "B1 maiuscole/underscore nel path sensibile" || aggirato "B1 path sensibile camuffato non riconosciuto"

att; OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"Il mio token di accesso.txt"}}' | bash tools/pattern-reminder-hook.sh)
echo "$OUT" | grep -qi "pattern\|secret" && tiene "B2 percorso sensibile in italiano naturale" || aggirato "B2 sensibile in italiano non riconosciuto"

att; OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cat ~/.clasp.json | grep refresh"}}' | bash tools/clasp-block-hook.sh)
echo "$OUT" | grep -q . && tiene "B3 comando bash che tocca credenziali riceve avviso" || aggirato "B3 comando con credenziali: hook muto"

att; OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | bash tools/pattern-reminder-hook.sh)
[ -z "$OUT" ] && tiene "B4 path innocuo: silenzio corretto" || aggirato "B4 path innocuo produce rumore"

att; echo '{"tool_name":"NotebookEdit","tool_input":{"file_path":"credenziali BC.rtf"}}' | bash tools/pattern-reminder-hook.sh | grep -q . \
  && tiene "B5 tool fuori matcher risponde comunque" || ack "B5 tool fuori matcher (NotebookEdit): l'hook non spara — gap strutturale della piattaforma, compensato dal dente clasp su Bash"

att; OUT=$(echo '{"hook_event_name":"UserPromptSubmit","prompt":"calculate the warehouse valuation please"}' | bash tools/metodo-reminder-hook.sh)
echo "$OUT" | grep -qi "oracol\|calcol" && tiene "B6 prompt di calcolo in INGLESE aggancia lo stesso gli oracoli" || aggirato "B6 prompt inglese: aggancio oracoli non scatta"

att; echo "$(date +%s)" > .campo-rem 2>/dev/null
OUT=$(echo '{"hook_event_name":"Stop"}' | bash tools/metodo-reminder-hook.sh)
[ -z "$OUT" ] && ack "B7 .campo-rem sopprime il promemoria campo per 1h (anti-spam by design: dopo ri-suona)" || tiene "B7 soppressione campo limitata"
rm -f .campo-rem

att; OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp push"}}' | bash tools/clasp-block-hook.sh)
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 \
  && tiene "B8 un deny reale esiste e funziona (clasp push NEGATO)" \
  || aggirato "B8 NESSUN deny funzionante: tutte le regole sono advisory"

echo ""
echo "=== CAT C — gaming di lenti e sonde ==="

att; python3 -c "
p='.claude/skills/gas-sviluppo/references/metodo.md'; s=open(p).read()
comment = '<!-- ' + ' '.join('pattern-x' + str(i) for i in range(200)) + ' -->'
open(p,'w').write(s + '\n' + comment + '\n')"
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 2 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
echo "$OUT" | grep -q "COLLEGAMENTO.*pattern-x1\b" && aggirato "C1 lente 2 non guarda nei commenti HTML (gaming possibile)" || tiene "C1 lente 2 resiste ai commenti HTML"
git checkout -- .claude/skills/gas-sviluppo/references/metodo.md; rm -rf .ciclo

att; printf '#!/usr/bin/env python3\n' > tools/test.py
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 4 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
echo "$OUT" | grep -q "ARCH: tool test.py senza test" && tiene "C2 tool omonimo del prefisso test non passa gratis" || aggirato "C2 tools/test.py passa la lente copertura per coincidenza di nome"
rm tools/test.py; rm -rf .ciclo

att; printf '\n`tools/` e `docs/`\n' >> DEBITI.md
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 4 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
echo "$OUT" | grep -q "ARCH: DEBITI" && tiene "C3 DEBITI che cita directory generiche segnalato" || aggirato "C3 lente DEBITI accetta ref a directory (non a file)"
git checkout -- DEBITI.md; rm -rf .ciclo

att; printf 'riga spuria che contiene la parola gate\n' > docs/campo/2026-08-28-attacco-gate.md
OUT=$(bash tools/campo-triage.sh 2>&1)
echo "$OUT" | grep -q "non processato" && tiene "C4 report finto con nome-parola non conta come processato" || aggirato "C4 campo-triage conta processato per coincidenza di parola in SAL"
rm docs/campo/2026-08-28-attacco-gate.md

att; printf 'Il sistema ha 999 test e 999 pattern.\n' >> METHOD.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -q "S2" <<<"$OUT_BAT" && tiene "C5 numero marcio in METHOD.md preso da S2" || aggirato "C5 S2 non legge METHOD.md: numero marcio invisibile"
git checkout -- METHOD.md

att; printf '自身的\n' >> SAL-ARCHIVIO.md
bash tools/giri-ignoranti.sh 2>/dev/null | grep -q "S1" && tiene "C6 carattere alieno in archivio preso" || ack "C6 S1 esclude SAL-ARCHIVIO.md (scelta: l'archivio è storico, bonificato alla rotazione)"
git checkout -- SAL-ARCHIVIO.md

att; printf '#!/bin/bash\n# finto tool per attacco\nx=1\nwhile [ -z "$1" ]; do :; done\ncase "$1" in\n  --flag-segreto) : ;;\nesac\n' > /tmp/avv-finto.sh
head -30 /tmp/avv-finto.sh | grep -q "flag-segreto" && ack "C7 S5 legge 30 righe: il campione rientra (limite dichiarato: uso oltre riga 30 non visto)" || aggirato "C7 S5 finestra uso sbagliata"
rm -f /tmp/avv-finto.sh

att; : > patterns/vuoto-finto.md
bash tests/test-patterns-ancore-esistono.sh >/dev/null 2>&1 && aggirato "C8 pattern VUOTO passa il test àncore (nessun contenuto richiesto)" || tiene "C8 pattern vuoto respinto"
rm patterns/vuoto-finto.md

att; F=$(ls docs/bc/endpoints | head -1); rm "docs/bc/endpoints/$F"; python3 tools/bc_index.py >/dev/null 2>&1
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 4 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
echo "$OUT" | grep -q "ARCH: endpoints" && tiene "C9 endpoint cancellato + indice rigenerato: lente vede il calo" || ack "C9 endpoint cancellato E indice rigenerato insieme: i conti tornano (limite dichiarato: la lente conta, non pesa i contenuti)"
git checkout -- docs/bc; rm -rf .ciclo

att; printf '#!/usr/bin/env python3\nimport time\ntime.sleep(2)\nraise RuntimeError("boom ritardato")\n' > tools/_sleep_malvagio.py
OUT=$(bash tools/giri-ignoranti.sh 2>/dev/null | grep -c "S3")
[ "${OUT:-0}" -ge 1 ] && tiene "C10 oracolo lento-che-crasha preso lo stesso" || aggirato "C10 S3 uccide a 0.9s: un oracolo che crasha dopo 2s passerebbe"
rm tools/_sleep_malvagio.py

echo ""
echo "=== CAT D — input ostili agli oracoli (spazzatura silenziosa = aggirato) ==="

classifica() {
  local out="$1" rc="$2" d="$3"
  if [ "$rc" -ne 0 ] || echo "$out" | grep -qi "uso:\|traceback\|errore"; then tiene "$d (muore/si dichiara: rc=$rc)"
  elif echo "$out" | grep -qi "nan\|inf"; then aggirato "$d — spazzatura SILENZIOSA: $out"
  else tiene "$d (output onesto)"; fi
}

att; OUT=$(printf 'codice,qty_bc,costo_finale,qty_fisica,stato\nX,abc,10,5,Contato\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D1 riconciliazione qty_bc=abc"

att; OUT=$(printf 'codice,qty_bc,costo_finale,qty_fisica,stato\nX,10,abc,5,Contato\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D2 riconciliazione costo=abc"

att; OUT=$(printf '\xef\xbb\xbfcodice,qty_bc,costo_finale,qty_fisica,stato\nX,10,5,5,Contato\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D3 riconciliazione con BOM"

att; OUT=$(printf 'tipo,importo\ngiorni,x\n' | python3 tools/scadenzario_aging.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D4 scadenzario header a metà"

att; OUT=$(printf 'giorni,tipo,importo\n,Cliente,nan\n' | python3 tools/scadenzario_aging.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D5 scadenzario importo=nan"

att; OUT=$(printf 'giorni,tipo,importo\n5,Cliente,1e999\n' | python3 tools/scadenzario_aging.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D6 scadenzario importo=inf"

att; OUT=$(echo '{"canone_base":1000,"data_inizio":"2027-01-01","data_fine":"2026-01-01","data_riferimento":"2026-06-01","spread":1,"euribor_stipula":0.5,"euribor_corrente":1.5}' > /tmp/avv-l.json; python3 tools/leasing_amministrativo.py /tmp/avv-l.json 2>&1); RC=$?
classifica "$OUT" "$RC" "D7 leasing date invertite"

att; OUT=$(echo '{"canone_base":1000,"data_inizio":"2026-01-01","data_fine":"2027-01-01","spread":"1,5","euribor_stipula":0.5,"euribor_corrente":1.5}' > /tmp/avv-l2.json; python3 tools/leasing_amministrativo.py /tmp/avv-l2.json 2>&1); RC=$?
classifica "$OUT" "$RC" "D8 leasing spread con virgola italiana"

att; OUT=$(echo '{"pn":0,"ricavi":0,"patrimonio":0,"debiti_tributari":0,"perdite_precedenti":0}' | python3 tools/indici_crisi.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D9 indici crisi con tutto zero"

att; OUT=$(echo '{"categoria":"X","cespiti":[]}' | python3 tools/rollforward_cespiti.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D10 rollforward senza cespiti"

att; OUT=$(echo 'not json at all' | python3 tools/indici_crisi.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D11 indici crisi input non-JSON"

att; OUT=$(python3 tools/scostamento_standard_effettivo.py abc </dev/null 2>&1); RC=$?
classifica "$OUT" "$RC" "D12 scostamento costo=abc"

att; OUT=$(printf 'nr,fornitore,ordine_nr,importo\nF1,F,{},1\n' > /tmp/avv-f.csv; printf '{}' > /tmp/avv-c.json; python3 tools/accuratezza_fatture_acquisto.py /tmp/avv-c.json /tmp/avv-f.csv /dev/null 2>&1); RC=$?
classifica "$OUT" "$RC" "D13 accuratezza importo={}"

att; OUT=$(printf 'vendite,acquisti\n' > /tmp/avv-v.csv; printf 'x\n' > /tmp/avv-a.csv; python3 tools/margine_documento.py /tmp/avv-v.csv /tmp/avv-a.csv 2>&1); RC=$?
classifica "$OUT" "$RC" "D14 margine CSV con una sola colonna"

att; OUT=$(printf 'a;b;c\n1;2;3\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D15 riconciliazione CSV a punto-e-virgola"

att; OUT=$(mkdir -p /tmp/avv-vuota && python3 tools/gas_qualita.py /tmp/avv-vuota 2>&1); RC=$?
classifica "$OUT" "$RC" "D16 gas_qualita su cartella vuota"

att; OUT=$(printf 'riga senza verdetto\n' > /tmp/avv-b.txt; python3 tools/verifica_banco.py /tmp/avv-b.txt 2>&1); RC=$?
classifica "$OUT" "$RC" "D17 verifica_banco senza riga verdetto"

att; OUT=$( : > /tmp/avv-b2.txt; python3 tools/verifica_banco.py /tmp/avv-b2.txt 2>&1); RC=$?
classifica "$OUT" "$RC" "D18 verifica_banco file vuoto"

att; OUT=$(printf 'cliente,importo\nA,nan\n' | python3 tools/rating_dso_clienti.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D19 rating con importo nan"

att; OUT=$(printf 'bu,amount\nX,1e999\n' | python3 tools/bilancio_bu.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D20 bilancio con inf"

att; OUT=$(echo '{"canone_base":-1000,"data_inizio":"2026-01-01","data_fine":"2027-01-01","spread":1,"euribor_stipula":0.5,"euribor_corrente":1.5}' > /tmp/avv-l3.json; python3 tools/leasing_amministrativo.py /tmp/avv-l3.json 2>&1); RC=$?
classifica "$OUT" "$RC" "D21 leasing canone negativo"

att; OUT=$(echo '{"pn":"abc","ricavi":1}' | python3 tools/indici_crisi.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D22 indici crisi pn=abc"

att; OUT=$(printf 'codice,qty_bc,costo_finale,qty_fisica,stato\nX,-10,5,-20,Contato\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D23 riconciliazione negativi fisici"

att; OUT=$(printf 'giorni,tipo,importo\nabc,Cliente,100\n' | python3 tools/scadenzario_aging.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D24 scadenzario giorni=abc"

att; OUT=$(printf '\n\n\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D25 riconciliazione solo righe vuote"

echo ""
echo "=== CAT E — privacy: il passato che riaffiora ==="

att; grep -rlP '[\x{AC00}-\x{D7AF}]' --include='*.md' docs/ 2>/dev/null | head -1 | grep -q . && aggirato "E1 caratteri hangul nei report" || tiene "E1 nessun hangul nei report"

att; grep -oE 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' night-shift/repos-index.md docs/*.md 2>/dev/null | grep -v "obi2kenobi/AI_Programmer" | head -1 | grep -q . && aggirato "E2 URL github di repo privata fuori dal hub" || tiene "E2 nessun URL di repo privata"

att; head -2 metrics/gate.csv 2>/dev/null | grep -viE 'repo-[a-n]|data|giro|gate|,|^$' | grep -q . && aggirato "E3 gate.csv con contenuto fuori schema REPO-*" || tiene "E3 gate.csv a schema REPO-*"

att; grep -oE "REPO-[A-Za-z0-9]+" night-shift/repos-index.md | grep -vE "^REPO-[A-N]$" | head -1 | grep -q . && aggirato "E4 repos-index con codici fuori schema" || tiene "E4 repos-index solo codici REPO-[A-N]"

att; git ls-files | grep -qE '\.(env|key|pem)$|id_rsa|^\.env' && aggirato "E5 file segreto tracciato (nome)" || tiene "E5 nessun file segreto tracciato"

att; grep -rnE 'sk-ANTHROPIC|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{12}|BEGIN [A-Z ]*PRIVATE KEY' llm/ tools/ 2>/dev/null | grep -vE "privacy-check.sh|giri-avversari.sh" | head -1 | grep -q . && aggirato "E6 letterale segreto negli script" || tiene "E6 nessun letterale segreto negli script"

att; git log --all --oneline | wc -l | tr -d ' ' | grep -q "^0$" && aggirato "E7 storia git assente?" || tiene "E7 storia git presente (privacy-check la presidia con pickaxe)"

echo ""
echo "=== CAT F — regole senza denti ==="

att; OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp push"}}' | bash tools/clasp-block-hook.sh)
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 && tiene "F1 clasp push NEGATO davvero (il dente esiste)" || aggirato "F1 'clasp push MAI' resta solo un promemoria"

att; python3 -c "
import json
s = json.load(open('.claude/settings.json'))
print(any('clasp-block' in h.get('command','') for m in s['hooks'].get('PreToolUse',[]) for h in m.get('hooks',[])))" | grep -q True && tiene "F2 il dente è registrato in settings.json" || aggirato "F2 clasp ignorato dagli hook"

att; git ls-files | grep -q "^gas-src/" && aggirato "F3 cartella gas-src tracciata nell'hub" || tiene "F3 nessuna cartella gas-src tracciata"

att; grep -q "merge=union" .gitattributes && tiene "F4 union merge driver dichiarato per SAL e campo" || aggirato "F4 union merge driver assente"

att; grep -q "shellcheck" .night-verify 2>/dev/null && tiene "F5 .night-verify dichiara shellcheck" || aggirato "F5 .night-verify senza shellcheck (AGENTS lo promette)"

echo ""
echo "=== CAT G — copertura residue ==="

att; python3 -c "
import re
p='.claude/skills/gas-sviluppo/references/metodo.md'; s=open(p).read()
s = re.sub(r'## Graphify[\s\S]*?(?=\n## )', '', s, count=1)
open(p,'w').write(s)"
difesa_test tests/test-canone-integrita.sh "G1 sezione Graphify cancellata dal canone"

att; printf 'import sys\nsys.exit(0)\n' > tools/gas_qualita.py
difesa_test tests/test-gas-qualita-rilevatore.sh "G2 rilevatore neutralizzato (exit 0 sempre)"

att; sed -i '' 's/attese eseguite/attese fatte/' tools/verifica_banco.py
difesa_test tests/test-verifica-banco.sh "G3 parser verdetto banco rotto"

att; printf 'token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ12\n' >> llm/README.md
bash tools/privacy-check.sh >/dev/null 2>&1 && aggirato "G4 token GitHub piantato: privacy-check non ne vede la FORMA" || tiene "G4 forma di token GitHub piantata vista (shaping)"
git checkout -- llm/README.md

att; python3 -c "
p='night-shift/lib.sh'; s=open(p).read()
open('/tmp/avv-lib.bak','w').write(s)
open(p,'w').write(s.replace('gate_allowlist_ok', 'gate_allowlist_BROKEN'))"
[ -f tests/test-lib.sh ] && { bash tests/test-lib.sh >/dev/null 2>&1 && aggirato "G5 lib.sh allowlist rotta passa test-lib.sh" || tiene "G5 lib.sh allowlist presidiata da test-lib.sh"; } || aggirato "G5 test-lib.sh assente"
cp /tmp/avv-lib.bak night-shift/lib.sh

att; sed -i '' 's/## Registro/## RegistrX/' patterns/README.md
bash tools/giri-ignoranti.sh >/dev/null 2>&1 && aggirato "G6 registro pattern decapitato invisibile alle sonde" || tiene "G6 registro pattern presidiato"
git checkout -- patterns/README.md

att; printf 'REPO-%s\n' 'Z' >> night-shift/repos-index.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -q "S9" <<<"$OUT_BAT" && tiene "G7 codice REPO fuori schema visto da S9" || aggirato "G7 repos-index senza presidio dello schema"
git checkout -- night-shift/repos-index.md

att; sed -i '' 's/ .opencode\/plugins//' tools/sync-repo.sh
difesa_test tests/test-sync-repo-standard-item-list.sh "G8 item propagazione rimosso dalla lista sync"

att; sed -i '' 's/report dal campo/report dal campX/g' CLAUDE.md
bash tests/test-report-campo.sh >/dev/null 2>&1 && aggirato "G9 formato report degradato passa" || tiene "G9 formato report presidiato"

att; python3 -c "
p='.claude/skills/gas-sviluppo/references/famiglie-difetti.md'; s=open(p).read()
lines = [l for l in s.split('\n') if 'test finti' not in l.lower()]
open(p,'w').write('\n'.join(lines))"
difesa_test tests/test-canone-integrita.sh "G10 famiglia difetti cancellata dal catalogo"

att; python3 -c "
p='tools/bc_index.py'; s=open(p).read()
open(p,'w').write(s.replace('endpoint', 'endpooint', 5))"
difesa_test tests/test-bc-index.sh "G11 bc_index corrotto"

att; sed -i '' "s/onore del NON VERIFICATO/onore del NON VERIFICATX/" .claude/skills/gas-sviluppo/references/metodo.md
difesa_test tests/test-canone-integrita.sh "G12 sezione onore degradata"

att; ack "G13 piantare un NOME reale richiede conoscere repos.key (locale, gitignored): il gate dichiara DEGRADATO quando non può giudicare, non mente"

att; python3 -c "
p='tools/metodo-reminder-hook.sh'; s=open(p).read()
open(p,'w').write(s.replace('docs/campo/', 'docs/campX/'))"
bash tests/test-hook-sal-promemoria.sh >/dev/null 2>&1 && aggirato "G14 hook campo degradato (percorso rotto) passa" || tiene "G14 hook campo presidiato"

att; python3 -c "
p='.opencode/skills/gas-sviluppo/SKILL.md'
s=open(p).read(); open(p,'w').write(s.replace('metodo', 'metodX', 3))"
bash tests/test-opencode-skills-sync.sh >/dev/null 2>&1 && aggirato "G15 skill opencode drift passa" || tiene "G15 specchio skill presidiato"

att; sed -i '' 's/verdetto/verdettX/g' tools/campo-triage.sh
bash tools/campo-triage.sh >/dev/null 2>&1; RC=$?
[ $RC -ne 0 ] && tiene "G16 campo-triage rotto fallisce" || ack "G16 campo-triage con parola cambiata esce 0: la parte che conta (contare i file) non usa quella parola"
git checkout -- tools/campo-triage.sh

att; rm .night-verify
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -q "S8" <<<"$OUT_BAT" && tiene "G17 .night-verify cancellato visto da S8" || aggirato "G17 .night-verify senza presidio"
git checkout -- .night-verify 2>/dev/null; true

att; ack "G18 il PROSA di AGENTS.md non ha guardia riga-per-rigola: presidiati i numeri (S2), i file promessi (S8) e le convenzioni gate — la prosa vive di revisione"

att; rm docs/MANUALE-OPERATIVO.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "S4|S6" <<<"$OUT_BAT" && tiene "G19 manuale cancellato visto (S4/S6)" || aggirato "G19 manuale tornato orfano/invisibile"
git checkout -- docs/MANUALE-OPERATIVO.md

att; sed -i '' 's/sync-repo.sh/sync-repX.sh/g' docs/benvenuto-collaboratori.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -q "S6" <<<"$OUT_BAT" && tiene "G20 comando rotto nel benvenuto visto da S6" || aggirato "G20 comando rotto nel benvenuto invisibile"
git checkout -- docs/benvenuto-collaboratori.md

echo ""
echo "================ RESOCONTO ================"
echo "Attacchi: $ATT · TENGONO: $TENGONO · AGGIRATI: $AGGIRATI · ACK (limite dichiarato): $ACK"
echo "VERDETTO: $AGGIRATI aggirati non riconosciuti"
[ "$AGGIRATI" -eq 0 ]
