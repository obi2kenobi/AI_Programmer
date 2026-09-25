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
# NOTA DI CHIAREZZA (lente S2): questo file è VOLONTARIAMENTE povero di commenti
# per attacco — ogni attacco si autodescrive nel verdetto echo e nel messaggio
# TIENE/AGGIRA che è l'output utente. La densità qui misurerebbe il rumore, non
# la chiarezza: escluso dal pavimento con questa giustificazione, non in silenzio.
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
# (2026-09-23, notte dei giri, T2#1): gli attacchi mutavano l'ALBERO VERO e usavano percorsi fissi in
# /tmp — due batterie insieme davano AGGIRA falsi (una si riprendeva il file dell'altra), un kill -9 a
# meta' lasciava gli attacchi nel repo. Ora la batteria si rilancia in un CLONE usa e getta dell'albero
# (pulito: e' uguale a HEAD), con una cartella temporanea sua; la memoria di ciclo-vivo (.ciclo, non
# versionata) ci entra in copia. L'albero vero non si tocca mai.
if [ -z "${GIRI_AVVERSARI_NEL_CLONE:-}" ]; then
  CLONE=$(mktemp -d)
  git clone -q "$HERE" "$CLONE/hub" || { echo "⛔ clone per la batteria non riuscito" >&2; rm -rf "$CLONE"; exit 2; }
  [ -d .ciclo ] && cp -a .ciclo "$CLONE/hub/"
  echo "(batteria in un clone usa e getta: $CLONE/hub — l'albero vero non si tocca)"
  GIRI_AVVERSARI_NEL_CLONE=1 bash "$CLONE/hub/tools/giri-avversari.sh" "$@"; RC=$?
  rm -rf "$CLONE"
  exit $RC
fi
# i file di passaggio degli attacchi: una cartella per batteria, mai /tmp condivisa. Si cancella SOLO se
# porta il nome che le da' questa riga (E-044: un sabotaggio con AVVT=/tmp ha fatto rm -rf /tmp)
AVVT=$(mktemp -d "${TMPDIR:-/tmp}/giri-avversari.XXXXXX")
# (revisione 10 giri, 2026-09-23): l'uscita faceva `rm -rf .ciclo` — cioe' cancellava la
# memoria PERSISTENTE di tools/ciclo-vivo.sh (livello, serie di giri puliti, storico dei
# finding) a ogni giro d'attacchi. Si salva prima e si rimette com'era.
CICLO_BAK=$(mktemp -d)
[ -d .ciclo ] && cp -a .ciclo "$CICLO_BAK/"
restore_tutto() {
  git checkout -- . 2>/dev/null
  chmod +x tools/*.sh 2>/dev/null
  rm -f .campo-rem tools/_sleep_malvagio.py 2>/dev/null
  case "$AVVT" in */giri-avversari.??????) rm -rf "$AVVT" ;; esac
  rm -rf .ciclo 2>/dev/null
  [ -d "$CICLO_BAK/.ciclo" ] && cp -a "$CICLO_BAK/.ciclo" .ciclo
  rm -rf "$CICLO_BAK"
}
trap restore_tutto EXIT

TENGONO=0; AGGIRATI=0; ACK=0; ATT=0

ack() { ACK=$((ACK+1)); echo "ACK  #$ATT $1"; }
tiene() { TENGONO=$((TENGONO+1)); echo "TIENE #$ATT $1"; }
aggirato() { AGGIRATI=$((AGGIRATI+1)); echo "AGGIRA #$ATT $1"; }
att() { ATT=$((ATT+1)); }
# sedi: `sed -i` portabile (D22, test del sistema completo 2026-09-20): `sed -i ''` e' solo
# BSD, su GNU legge '' come script. Il suffisso attaccato vale per entrambi; il .bak si toglie.
sedi() { local f="${!#}"; sed -i.portabile-bak "$@" && rm -f "$f.portabile-bak"; }  # ${!#} = ultimo argomento (21/9: SC2124 su "${@: -1}")
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

att; mv patterns/watchdog-guardato.md "$AVVT"/avv-pattern.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S7 " <<<"$OUT_BAT" && tiene "A4 pattern file cancellato (S7 lo vede)" || aggirato "A4 pattern cancellato, nessuna difesa rosso"
mv "$AVVT"/avv-pattern.md patterns/watchdog-guardato.md

att; sedi 's|night-shift/lib.sh:run_guarded|night-shift/INESISTENTE:run_guarded|' patterns/watchdog-guardato.md
difesa_test tests/test-patterns-ancore-esistono.sh "A5 àncora pattern rotta"

att; sedi 's|^description: .*$|description: ""|' .claude/agents/revisore-gas.md
difesa_test tests/test-agents-structure.sh "A6 agente senza description"

att; sedi '/^mode: subagent/d' .opencode/agent/revisore-gas.md
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

att; mv tools/margine_documento.py "$AVVT"/avv-oracolo.py
difesa_test tests/test-margine-documento.sh "A11 oracolo cancellato"
mv "$AVVT"/avv-oracolo.py tools/margine_documento.py

att; sedi 's/margine = importo_v - importo_a/margine = importo_v + importo_a/' tools/margine_documento.py
difesa_test tests/test-margine-documento.sh "A12 aritmetica oracolo invertita (riga vera)"

att; python3 - <<'EOF'
p = 'tools/scadenzario_aging.py'; s = open(p).read()
old = 'if tipo.startswith("Fornitore"):'
assert old in s; open(p, 'w').write(s.replace(old, 'if False and tipo.startswith("Fornitore"):'))
EOF
difesa_test tests/test-scadenzario-aging.sh "A13 fix segno fornitore disattivato"

att; sedi 's/--standard) STANDARD=1/--tutto) STANDARD=1/' tools/sync-repo.sh
difesa_test tests/test-sync-repo-standard-item-list.sh "A14 --standard rimosso da sync-repo"

att; python3 -c "
import re
p='CLAUDE.md'; s=open(p).read()
open(p,'w').write(re.sub(r'(?m)^.*clasp.*$', '', s))"
difesa_test tests/test-claude-md-gate-conventions.sh "A15 regola clasp tolta da CLAUDE.md"

att; mv docs/campo/README.md "$AVVT"/avv-campo-readme.md
difesa_test tests/test-report-campo.sh "A16 formato report campo cancellato"
mv "$AVVT"/avv-campo-readme.md docs/campo/README.md

att; mv .gitattributes "$AVVT"/avv-ga
difesa_test tests/test-claude-md-gate-conventions.sh "A17 union merge driver rimosso"
mv "$AVVT"/avv-ga .gitattributes

att; rm -rf .claude/skills/design-doc
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S8 " <<<"$OUT_BAT" && tiene "A18 skill cancellata (pavimento S8)" || aggirato "A18 skill cancellata invisibile"
git checkout -- .claude/skills 2>/dev/null; true

att; sedi 's/<!-- SAL-INDICE: generato/<!-- MARKER-SOSTITUITO: generato/' SAL.md
difesa_test tests/test-sal-indice-ancore.sh "A19 marker indice SAL sostituito"

# (2026-09-25, settimo ventaglio, V5 R3): A20 e G4 leggono la riga «FORMA DI SEGRETO», non l'rc. Nel clone della batteria
# manca repos.key e privacy-check esce 1 («GATE DEGRADATO») anche pulito: con le forme sabotate diceva TIENE lo stesso.
# La pianta di A20 era «sk-ANTHROPIC-FAKE…», che non e' una forma (le SHAPES cercano sk-ant- con 20 caratteri): l'rc
# nascondeva che privacy-check non l'aveva mai vista. Ora una forma vera, composta a runtime.
att; printf 'sk-an%s-%s\n' 't' 'FINTAfintaFINTAfinta0123' >> docs/campo/2026-08-28-sd-dashboard-dossier.md
PC=$(bash tools/privacy-check.sh 2>&1 >/dev/null); grep -c 'FORMA DI SEGRETO' <<<"$PC" >/dev/null && tiene "A20 forma di segreto piantata vista (shaping)" || aggirato "A20 segreto generico piantato: privacy-check non ne vede la FORMA"
git checkout -- docs/campo/2026-08-28-sd-dashboard-dossier.md 2>/dev/null; true

echo ""
echo "=== CAT B — bypass degli hook ==="

att; OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"credenziali_BC.rtf"}}' | bash tools/pattern-reminder-hook.sh)
grep -qi "pattern" <<<"$OUT" && tiene "B1 maiuscole/underscore nel path sensibile" || aggirato "B1 path sensibile camuffato non riconosciuto"

att; OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"Il mio token di accesso.txt"}}' | bash tools/pattern-reminder-hook.sh)
grep -qi "pattern\|secret" <<<"$OUT" && tiene "B2 percorso sensibile in italiano naturale" || aggirato "B2 sensibile in italiano non riconosciuto"

att; OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"cat ~/.clasp.json | grep refresh"}}' | bash tools/clasp-block-hook.sh)
if grep -q . <<<"$OUT"; then tiene "B3 comando bash che tocca credenziali riceve avviso"; else aggirato "B3 comando con credenziali: hook muto"; fi

att; OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | bash tools/pattern-reminder-hook.sh)
[ -z "$OUT" ] && tiene "B4 path innocuo: silenzio corretto" || aggirato "B4 path innocuo produce rumore"

att; echo '{"tool_name":"NotebookEdit","tool_input":{"file_path":"credenziali BC.rtf"}}' | bash tools/pattern-reminder-hook.sh | grep -c . >/dev/null \
  && tiene "B5 tool fuori matcher risponde comunque" || ack "B5 tool fuori matcher (NotebookEdit): l'hook non spara — gap strutturale della piattaforma, compensato dal dente clasp su Bash"

att; OUT=$(echo '{"hook_event_name":"UserPromptSubmit","prompt":"calculate the warehouse valuation please"}' | bash tools/metodo-reminder-hook.sh)
grep -qi "oracol\|calcol" <<<"$OUT" && tiene "B6 prompt di calcolo in INGLESE aggancia lo stesso gli oracoli" || aggirato "B6 prompt inglese: aggancio oracoli non scatta"

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
grep -q "COLLEGAMENTO.*pattern-x1\b" <<<"$OUT" && aggirato "C1 lente 2 non guarda nei commenti HTML (gaming possibile)" || tiene "C1 lente 2 resiste ai commenti HTML"
git checkout -- .claude/skills/gas-sviluppo/references/metodo.md; rm -rf .ciclo

att; printf '#!/usr/bin/env python3\n' > tools/test.py
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 4 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
grep -q "ARCH: tool test.py" <<<"$OUT" && tiene "C2 tool omonimo del prefisso test non passa gratis" || aggirato "C2 tools/test.py passa la lente copertura per coincidenza di nome"
rm tools/test.py; rm -rf .ciclo

att; printf '\n`tools/` e `docs/`\n' >> DEBITI.md
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 4 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
grep -q "ARCH: DEBITI" <<<"$OUT" && tiene "C3 DEBITI che cita directory generiche segnalato" || aggirato "C3 lente DEBITI accetta ref a directory (non a file)"
git checkout -- DEBITI.md; rm -rf .ciclo

att; printf 'riga spuria che contiene la parola gate\n' > docs/campo/2026-08-28-attacco-gate.md
OUT=$(bash tools/campo-triage.sh 2>&1)
grep -q "non processato" <<<"$OUT" && tiene "C4 report finto con nome-parola non conta come processato" || aggirato "C4 campo-triage conta processato per coincidenza di parola in SAL"
rm docs/campo/2026-08-28-attacco-gate.md

att; printf 'Il sistema ha 999 test e 999 pattern.\n' >> METHOD.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S2 " <<<"$OUT_BAT" && tiene "C5 numero marcio in METHOD.md preso da S2" || aggirato "C5 S2 non legge METHOD.md: numero marcio invisibile"
git checkout -- METHOD.md

att; CJK=$(python3 -c "print(chr(0x81ea)+chr(0x8eab)+chr(0x7684))")
printf '%s\n' "$CJK" >> SAL-ARCHIVIO.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S1 " <<<"$OUT_BAT" && tiene "C6 carattere alieno in archivio preso" || ack "C6 S1 esclude SAL-ARCHIVIO.md (scelta: l'archivio è storico, bonificato alla rotazione)"
git checkout -- SAL-ARCHIVIO.md

att; printf '#!/bin/bash\n# finto tool per attacco\nx=1\nwhile [ -z "$1" ]; do :; done\ncase "$1" in\n  --flag-segreto) : ;;\nesac\n' > "$AVVT"/avv-finto.sh
head -30 "$AVVT"/avv-finto.sh | grep -c "flag-segreto" >/dev/null && ack "C7 S5 legge 30 righe: il campione rientra (limite dichiarato: uso oltre riga 30 non visto)" || aggirato "C7 S5 finestra uso sbagliata"
rm -f "$AVVT"/avv-finto.sh

att; : > patterns/vuoto-finto.md
bash tests/test-patterns-ancore-esistono.sh >/dev/null 2>&1 && aggirato "C8 pattern VUOTO passa il test àncore (nessun contenuto richiesto)" || tiene "C8 pattern vuoto respinto"
rm patterns/vuoto-finto.md

att; F=$(ls docs/bc/endpoints | head -1); rm "docs/bc/endpoints/$F"; python3 tools/bc_index.py >/dev/null 2>&1
rm -rf .ciclo; mkdir -p .ciclo; echo 3 > .ciclo/giro; echo 4 > .ciclo/livello
OUT=$(bash tools/ciclo-vivo.sh 2>&1)
grep -q "ARCH: endpoints" <<<"$OUT" && tiene "C9 endpoint cancellato + indice rigenerato: lente vede il calo" || ack "C9 endpoint cancellato E indice rigenerato insieme: i conti tornano (limite dichiarato: la lente conta, non pesa i contenuti)"
git checkout -- docs/bc; rm -rf .ciclo

att; printf '#!/usr/bin/env python3\nimport time\ntime.sleep(2)\nraise RuntimeError("boom ritardato")\n' > tools/_sleep_malvagio.py
OUT=$(bash tools/giri-ignoranti.sh 2>/dev/null | grep -cE "^FIND +S3 ")
[ "${OUT:-0}" -ge 1 ] && tiene "C10 oracolo lento-che-crasha preso lo stesso" || aggirato "C10 S3 uccide a 0.9s: un oracolo che crasha dopo 2s passerebbe"
rm tools/_sleep_malvagio.py

echo ""
echo "=== CAT D — input ostili agli oracoli (spazzatura silenziosa = aggirato) ==="

classifica() {
  local out="$1" rc="$2" d="$3"
  # (2026-09-24, quinto ventaglio, R3 R5): un traceback contava come «tiene»; per il contratto D32 e' un difetto
  if grep -qi "traceback" <<<"$out"; then aggirato "$d — traceback invece di un rifiuto dichiarato (D32): $(tail -1 <<<"$out")"
  elif [ "$rc" -ne 0 ] || grep -qi "uso:\|errore" <<<"$out"; then tiene "$d (muore/si dichiara: rc=$rc)"
  elif grep -qi "nan\|inf" <<<"$out"; then aggirato "$d — spazzatura SILENZIOSA: $out"
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

att; OUT=$(echo '{"canone_base":1000,"data_inizio":"2027-01-01","data_fine":"2026-01-01","data_riferimento":"2026-06-01","spread":1,"euribor_stipula":0.5,"euribor_corrente":1.5}' > "$AVVT"/avv-l.json; python3 tools/leasing_amministrativo.py "$AVVT"/avv-l.json 2>&1); RC=$?
classifica "$OUT" "$RC" "D7 leasing date invertite"

att; OUT=$(echo '{"canone_base":1000,"data_inizio":"2026-01-01","data_fine":"2027-01-01","spread":"1,5","euribor_stipula":0.5,"euribor_corrente":1.5}' > "$AVVT"/avv-l2.json; python3 tools/leasing_amministrativo.py "$AVVT"/avv-l2.json 2>&1); RC=$?
classifica "$OUT" "$RC" "D8 leasing spread con virgola italiana"

# (2026-09-24, quinto ventaglio, R3 R5): D9 mandava i nomi del vecchio messaggio d'uso, che il tool non legge —
# la risposta era «campi mancanti» e il tutto-zero non arrivava mai al calcolo. Ora i dieci campi veri.
att; OUT=$(echo '{"pn":0,"ricavi":0,"oneriFin":0,"passivoTot":0,"debPrev":0,"debTrib":0,"cashFlow":0,"attivo":0,"attCorrenti":0,"passCorrenti":0}' | python3 tools/indici_crisi.py 2>&1); RC=$?
if grep -c '^NOTA: denominatore nullo' <<<"$OUT" >/dev/null; then tiene "D9 indici crisi con tutto zero: arriva al calcolo e dice i denominatori nulli (rc=$RC)"
elif [ "$RC" -eq 0 ]; then aggirato "D9 indici crisi con tutto zero — un verdetto senza dire i denominatori nulli: $(tail -1 <<<"$OUT")"
else classifica "$OUT" "$RC" "D9 indici crisi con tutto zero"; fi

att; OUT=$(echo '{"categoria":"X","cespiti":[]}' | python3 tools/rollforward_cespiti.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D10 rollforward senza cespiti"

att; OUT=$(echo 'not json at all' | python3 tools/indici_crisi.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D11 indici crisi input non-JSON"

att; OUT=$(python3 tools/scostamento_standard_effettivo.py abc </dev/null 2>&1); RC=$?
classifica "$OUT" "$RC" "D12 scostamento costo=abc"

att; OUT=$(printf 'nr,fornitore,ordine_nr,importo\nF1,F,{},1\n' > "$AVVT"/avv-f.csv; printf '{}' > "$AVVT"/avv-c.json; python3 tools/accuratezza_fatture_acquisto.py "$AVVT"/avv-c.json "$AVVT"/avv-f.csv /dev/null 2>&1); RC=$?
classifica "$OUT" "$RC" "D13 accuratezza importo={}"

att; OUT=$(printf 'vendite,acquisti\n' > "$AVVT"/avv-v.csv; printf 'x\n' > "$AVVT"/avv-a.csv; python3 tools/margine_documento.py "$AVVT"/avv-v.csv "$AVVT"/avv-a.csv 2>&1); RC=$?
classifica "$OUT" "$RC" "D14 margine CSV con una sola colonna"

att; OUT=$(printf 'a;b;c\n1;2;3\n' | python3 tools/riconciliazione_magazzino.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D15 riconciliazione CSV a punto-e-virgola"

att; OUT=$(mkdir -p "$AVVT"/avv-vuota && python3 tools/gas_qualita.py "$AVVT"/avv-vuota 2>&1); RC=$?
classifica "$OUT" "$RC" "D16 gas_qualita su cartella vuota"

att; OUT=$(printf 'riga senza verdetto\n' > "$AVVT"/avv-b.txt; python3 tools/verifica_banco.py "$AVVT"/avv-b.txt 2>&1); RC=$?
classifica "$OUT" "$RC" "D17 verifica_banco senza riga verdetto"

att; OUT=$( : > "$AVVT"/avv-b2.txt; python3 tools/verifica_banco.py "$AVVT"/avv-b2.txt 2>&1); RC=$?
classifica "$OUT" "$RC" "D18 verifica_banco file vuoto"

att; OUT=$(printf 'cliente,importo\nA,nan\n' | python3 tools/rating_dso_clienti.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D19 rating con importo nan"

att; OUT=$(printf 'bu,amount\nX,1e999\n' | python3 tools/bilancio_bu.py 2>&1); RC=$?
classifica "$OUT" "$RC" "D20 bilancio con inf"

att; OUT=$(echo '{"canone_base":-1000,"data_inizio":"2026-01-01","data_fine":"2027-01-01","spread":1,"euribor_stipula":0.5,"euribor_corrente":1.5}' > "$AVVT"/avv-l3.json; python3 tools/leasing_amministrativo.py "$AVVT"/avv-l3.json 2>&1); RC=$?
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

att; _cp=$(find docs -name '*.md' -print0 2>/dev/null | xargs -0 perl -CSD -ne 'if (/[\x{AC00}-\x{D7AF}]/) { print "$ARGV\n"; close ARGV }' 2>/dev/null | head -1); if grep -q . <<<"$_cp"; then aggirato "E1 caratteri hangul nei report"; else tiene "E1 nessun hangul nei report"; fi

# REPO-CR (Centrale_Rischi) e' PUBBLICA: dichiarata nel repos-index — non e' una leak
att; _cp=$(grep -oE 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' night-shift/repos-index.md docs/*.md 2>/dev/null | grep -vE "obi2kenobi/(AI_Programmer|Centrale_Rischi)" | head -1); if grep -q . <<<"$_cp"; then aggirato "E2 URL github di repo privata fuori dal hub"; else tiene "E2 nessun URL di repo privata"; fi

# (giro 15, 2026-09-20): la vecchia E3 escludeva ogni riga con una virgola — cioe' TUTTE le
# righe di un CSV: non poteva fallire mai (verde senza dati, R2). Ora legge la colonna repo
# di ogni riga dati e pretende un codice anonimo REPO-*.
att; _cp=$(awk -F, 'NR>1 && $2 !~ /^REPO-[A-Za-z0-9]+$/ {print $2}' metrics/gate.csv 2>/dev/null | head -1); if grep -q . <<<"$_cp"; then aggirato "E3 gate.csv con repo fuori schema REPO-*: '$_cp'"; else tiene "E3 gate.csv a schema REPO-* (colonna repo di ogni riga)"; fi

att; _cp=$(grep -oE "REPO-[A-Za-z0-9]+" night-shift/repos-index.md | grep -vE "^REPO-([A-NOPQRSTXZVW]|CR)$" | head -1); if grep -q . <<<"$_cp"; then aggirato "E4 repos-index con codici fuori schema"; else tiene "E4 repos-index solo codici REPO-[A-N]"; fi

att; git ls-files | grep -Ec '\.(env|key|pem)$|id_rsa|^\.env' >/dev/null && aggirato "E5 file segreto tracciato (nome)" || tiene "E5 nessun file segreto tracciato"

att; _cp=$(grep -rnE 'sk-ANTHROPIC|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{12}|BEGIN [A-Z ]*PRIVATE KEY' llm/ tools/ 2>/dev/null | grep -vE "privacy-check.sh|giri-avversari.sh" | head -1); if grep -q . <<<"$_cp"; then aggirato "E6 letterale segreto negli script"; else tiene "E6 nessun letterale segreto negli script"; fi

att; git log --all --oneline | wc -l | tr -d ' ' | grep -c "^0$" >/dev/null && aggirato "E7 storia git assente?" || tiene "E7 storia git presente (privacy-check la presidia con pickaxe)"

echo ""
echo "=== CAT F — regole senza denti ==="

att; OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"clasp push"}}' | bash tools/clasp-block-hook.sh)
echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1 && tiene "F1 clasp push NEGATO davvero (il dente esiste)" || aggirato "F1 'clasp push MAI' resta solo un promemoria"

att; _cp=$(python3 -c "
import json
s = json.load(open('.claude/settings.json'))
print(any('clasp-block' in h.get('command','') for m in s['hooks'].get('PreToolUse',[]) for h in m.get('hooks',[])))"); if grep -q True <<<"$_cp"; then tiene "F2 il dente è registrato in settings.json"; else aggirato "F2 clasp ignorato dagli hook"; fi

att; git ls-files | grep -c "^gas-src/" >/dev/null && aggirato "F3 cartella gas-src tracciata nell'hub" || tiene "F3 nessuna cartella gas-src tracciata"

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

att; sedi 's/attese eseguite/attese fatte/' tools/verifica_banco.py
difesa_test tests/test-verifica-banco.sh "G3 parser verdetto banco rotto"

att; printf 'token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ12\n' >> llm/README.md
PC=$(bash tools/privacy-check.sh 2>&1 >/dev/null); grep -c 'FORMA DI SEGRETO' <<<"$PC" >/dev/null && tiene "G4 forma di token GitHub piantata vista (shaping)" || aggirato "G4 token GitHub piantato: privacy-check non ne vede la FORMA"
git checkout -- llm/README.md

# (2026-09-24, sesto ventaglio, S3 R5): il percorso passa a python come argomento, non incollato nel sorgente —
# con un apice in TMPDIR il ripristino moriva di SyntaxError
att; python3 -c "
import sys
p='night-shift/lib.sh'; s=open(p).read()
open(sys.argv[1] + '/avv-lib.bak','w').write(s)
open(p,'w').write(s.replace('gate_allowlist_ok', 'gate_allowlist_BROKEN'))" "$AVVT"
[ -f tests/test-lib.sh ] && { bash tests/test-lib.sh >/dev/null 2>&1 && aggirato "G5 lib.sh allowlist rotta passa test-lib.sh" || tiene "G5 lib.sh allowlist presidiata da test-lib.sh"; } || aggirato "G5 test-lib.sh assente"
cp "$AVVT"/avv-lib.bak night-shift/lib.sh

att; sedi 's/## Registro/## RegistrX/' patterns/README.md
# verificato a mano: nessuna difesa scatta — ma NIENTE dipende dal titolo della
# sezione (l'hook e S7 parsano le righe '^| [' della tabella, non l'header).
# La sostanza è presidiata, il titolo è prosa: ACK onesto, non un buco.
ack "G6 il titolo '## Registro' è prosa: la sostanza (righe della tabella) è presidiata da S7 e dall'hook"
git checkout -- patterns/README.md

# (Q17): Z e' diventato un codice assegnato; il registro e' congelato — si pianta un codice nuovo
att; printf 'REPO-%s\n' 'NUOVO' >> night-shift/repos-index.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S9 " <<<"$OUT_BAT" && tiene "G7 codice REPO fuori schema visto da S9" || aggirato "G7 repos-index senza presidio dello schema"
git checkout -- night-shift/repos-index.md

att; sedi 's/ .opencode\/plugins//' tools/sync-repo.sh
difesa_test tests/test-sync-repo-standard-item-list.sh "G8 item propagazione rimosso dalla lista sync"

att; sedi 's|docs/campo|docs/campX|g' CLAUDE.md
difesa_test tests/test-report-campo.sh "G9 puntatore campo degradato in CLAUDE.md"

att; python3 -c "
p='.claude/skills/gas-sviluppo/references/famiglie-difetti.md'; s=open(p).read()
lines = s.split('\n')
tenute, tolte = [], 0
for l in lines:
    if l.startswith('- **') and tolte < 4:
        tolte += 1; continue
    tenute.append(l)
open(p,'w').write('\n'.join(tenute))"
difesa_test tests/test-canone-integrita.sh "G10 quattro famiglie cancellate dal catalogo"

att; python3 -c "
p='tools/bc_index.py'; s=open(p).read()
open(p,'w').write(s.replace('endpoint', 'endpooint', 5))"
difesa_test tests/test-bc-index.sh "G11 bc_index corrotto"

att; sedi "s/onore del NON VERIFICATO/onore del NON VERIFICATX/" .claude/skills/gas-sviluppo/references/metodo.md
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

att; sedi 's/verdetto/verdettX/g' tools/campo-triage.sh
bash tools/campo-triage.sh >/dev/null 2>&1; RC=$?
[ $RC -ne 0 ] && tiene "G16 campo-triage rotto fallisce" || ack "G16 campo-triage con parola cambiata esce 0: la parte che conta (contare i file) non usa quella parola"
git checkout -- tools/campo-triage.sh

att; rm .night-verify
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S8 " <<<"$OUT_BAT" && tiene "G17 .night-verify cancellato visto da S8" || aggirato "G17 .night-verify senza presidio"
git checkout -- .night-verify 2>/dev/null; true

att; ack "G18 il PROSA di AGENTS.md non ha guardia riga-per-rigola: presidiati i numeri (S2), i file promessi (S8) e le convenzioni gate — la prosa vive di revisione"

att; rm docs/MANUALE-OPERATIVO.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +(S4|S6) " <<<"$OUT_BAT" && tiene "G19 manuale cancellato visto (S4/S6)" || aggirato "G19 manuale tornato orfano/invisibile"
git checkout -- docs/MANUALE-OPERATIVO.md

att; sedi 's/sync-repo.sh/sync-repX.sh/g' docs/benvenuto-collaboratori.md
OUT_BAT=$(bash tools/giri-ignoranti.sh 2>/dev/null || true)
grep -qE "^FIND +S6 " <<<"$OUT_BAT" && tiene "G20 comando rotto nel benvenuto visto da S6" || aggirato "G20 comando rotto nel benvenuto invisibile"
git checkout -- docs/benvenuto-collaboratori.md

echo ""
echo "================ RESOCONTO ================"
echo "Attacchi: $ATT · TENGONO: $TENGONO · AGGIRATI: $AGGIRATI · ACK (limite dichiarato): $ACK"
echo "VERDETTO: $AGGIRATI aggirati non riconosciuti"
[ "$AGGIRATI" -eq 0 ]
