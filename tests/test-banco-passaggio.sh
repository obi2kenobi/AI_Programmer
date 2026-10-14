#!/bin/bash
# test-banco-passaggio.sh — il banco di fine passaggio sotto prova (esso stesso
# è «codice appena scritto»: il banco 7 lo aveva SCOPERTO, questo test è la
# risposta). Si usa --solo-copertura: il banco intero in suite costerebbe
# minuti a ogni .night-verify — qui si prova il contratto del banco 7, che è
# la parte nuova: vede i file NUOVI non tracciati, li segnala, e le esclusioni
# giustificate chiudono.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BANCO="$HERE/tools/banco-passaggio.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "OK   $1"; }
ko() { FAIL=$((FAIL+1)); echo "FAIL $1"; }

[ -x "$BANCO" ] && ok "il banco è eseguibile" || ko "banco non eseguibile"
bash -n "$BANCO" && ok "sintassi del banco" || ko "sintassi rotta"
grep -q -- "--solo-copertura" "$BANCO" && ok "esiste la via rapida --solo-copertura" || ko "manca --solo-copertura"

# il banco 7 VEDRE un tool nuovo che nessun test cita (git diff non li vedeva:
# i non tracciati sono il caso tipico del codice appena scritto — provato a mano)
# il nome del probe è unico a RUNTIME ($$): il nome letterale dentro QUESTO file
# renderebbe il probe «coperto» dal test stesso (scoperto così: il banco diceva
# presidiato perché questo test cita il nome — auto-copertura circolare)
PROBE="tools/_scoperto_$$_prova.py"
printf '#!/usr/bin/env python3\nprint("prova")\n' > "$HERE/$PROBE"
OUT=$(bash "$BANCO" --solo-copertura 2>&1); RC=$?
[ $RC -ne 0 ] && grep -qF "$PROBE" <<<"$OUT" \
  && ok "tool nuovo non coperto: visto e dichiarato, il banco non chiude" \
  || ko "tool nuovo non coperto NON visto (rc=$RC)"
rm -f "$HERE/$PROBE"

# esclusione giustificata: il banco chiude (dichiarato, non dimenticato)
# (revisione 10 giri, 2026-09-23): il ripristino era `git checkout --` sul file — cancellava
# anche le modifiche NON committate di chi ci stava lavorando. Ora si salva il contenuto e
# si rimette com'era (anche se il test muore a meta': trap).
ESCL="$HERE/tools/banco-passaggio.esclusioni"
ESCL_COPIA=$(mktemp); cp "$ESCL" "$ESCL_COPIA"
trap 'cp "$ESCL_COPIA" "$ESCL"; rm -f "$ESCL_COPIA" "$HERE/$PROBE"' EXIT
printf '%s # esiste solo dentro questo test, giustificato qui\n' "$PROBE" >> "$ESCL"
printf '#!/usr/bin/env python3\nprint("prova")\n' > "$HERE/$PROBE"
OUT=$(bash "$BANCO" --solo-copertura 2>&1); RC=$?
[ $RC -eq 0 ] && ok "esclusione giustificata: il banco chiude" \
  || { echo "$OUT" | tail -2 | sed 's/^/    /'; ko "esclusione ignorata"; }
rm -f "$HERE/$PROBE"
cp "$ESCL_COPIA" "$ESCL"
cmp -s "$ESCL_COPIA" "$ESCL" && ok "esclusioni rimesse esattamente com'erano (anche con modifiche non committate)" \
  || ko "il file delle esclusioni non e' tornato com'era"

# dopo la pulizia il banco torna verde (il repo vero non ha scoperti)
OUT=$(bash "$BANCO" --solo-copertura 2>&1); RC=$?
[ $RC -eq 0 ] && ok "pulito: copertura OK ($(echo "$OUT" | head -1))" || { echo "$OUT" | sed 's/^/    /'; ko "copertura rossa su repo pulito"; }

# (Q30, 2026-09-23, notte dei giri): senza origin/main `git diff origin/main...HEAD` falliva nel
# 2>/dev/null e la copertura diceva «0 file di codice cambiati, tutti presidiati»: un tool NUOVO,
# committato e senza test, passava. E con un solo file sporco i commit del ramo non si guardavano
# piu' (il fallback era un'alternativa, non un'unione). Si prova in una repo senza origin/main.
BP=$(mktemp -d)
git -C "$BP" init -q; mkdir -p "$BP/tools" "$BP/tests"
git -C "$BP" -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
BASE_BP=$(git -C "$BP" rev-parse HEAD)
cp "$BANCO" "$BP/tools/"; : > "$BP/tools/banco-passaggio.esclusioni"
printf '#!/bin/bash\necho nuovo\n' > "$BP/tools/nuovo.sh"
git -C "$BP" add -A; git -C "$BP" -c user.name=t -c user.email=t@t commit -qm nuovo
OUT=$(cd "$BP" && bash tools/banco-passaggio.sh --solo-copertura 2>&1); RC=$?
grep -q "DEGRADATO" <<<"$OUT" && ok "senza origin/main la copertura si dichiara DEGRADATA" \
  || ko "senza origin/main nessun avviso: $(tail -2 <<<"$OUT" | tr '\n' ' ')"
printf 'x\n' > "$BP/tools/sporco.sh"; git -C "$BP" add tools/sporco.sh; git -C "$BP" -c user.name=t -c user.email=t@t commit -qm sporco
git -C "$BP" update-ref refs/remotes/origin/main "$BASE_BP"
printf 'y\n' >> "$BP/tools/sporco.sh"
OUT=$(cd "$BP" && bash tools/banco-passaggio.sh --solo-copertura 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "tools/nuovo.sh" <<<"$OUT" \
  && ok "un file sporco non nasconde i commit del ramo: il tool nuovo senza test e' SCOPERTO" \
  || ko "copertura: con un file sporco il tool committato senza test passa (rc=$RC): $(grep -E 'SCOPERTO|presidiati' <<<"$OUT" | tr '\n' ' ')"
rm -rf "$BP"
grep -q 'ciclo-vivo non ha dato il verdetto' "$BANCO" && ok "banco 6: un ciclo-vivo senza verdetto e' rosso (non «0 finding»)" \
  || ko "banco 6: un ciclo-vivo morto (N vuoto) conta come verde"

# Passo 3/7 (debito 2026-10-14): su un albero sporco la batteria avversaria esce 2 («albero sporco») e il passo,
# che cercava solo righe `^AGGIRA`, stampava «AGGIRATI:» a vuoto contando un fallito senza dire perche'. Ora si
# distingue: rc 0 verde · rc 2 NON partita (con la sua riga) · altro rc = aggirati, e se non c'e' nessuna riga
# AGGIRA l'ultima riga del log si mostra comunque. Si prova col solo passo 3 (--solo-avversari), nel repo di prova:
# la batteria VERA col suo rifiuto vero sull'albero sporco, e batterie finte per gli altri esiti.
AV=$(mktemp -d); git -C "$AV" init -q; mkdir -p "$AV/tools"
cp "$BANCO" "$AV/tools/"; cp "$HERE/tools/giri-avversari.sh" "$AV/tools/"
git -C "$AV" add -A; git -C "$AV" -c user.name=t -c user.email=t@t commit -qm base
printf 'sporco\n' > "$AV/nuovo-non-tracciato.txt"
OUT=$(cd "$AV" && timeout 120 bash tools/banco-passaggio.sh --solo-avversari 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "NON partita" <<<"$OUT" && grep -q "albero sporco" <<<"$OUT" && ! grep -q "AGGIRATI" <<<"$OUT" \
  && ok "passo 3: albero sporco = batteria NON partita, col suo motivo (non «AGGIRATI» a vuoto)" \
  || ko "passo 3 su albero sporco (rc=$RC): $(tail -3 <<<"$OUT" | tr '\n' ' ')"
rm -f "$AV/nuovo-non-tracciato.txt"
printf '#!/bin/bash\necho "AGGIRA #7 attacco finto"\necho "VERDETTO: 1 aggirati non riconosciuti"\nexit 1\n' > "$AV/tools/giri-avversari.sh"
OUT=$(cd "$AV" && timeout 120 bash tools/banco-passaggio.sh --solo-avversari 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "AGGIRATI (rc=1)" <<<"$OUT" && grep -q "AGGIRA #7" <<<"$OUT" \
  && ok "passo 3: un attacco aggirato si elenca e fallisce" || ko "passo 3 con AGGIRA (rc=$RC): $(tail -3 <<<"$OUT" | tr '\n' ' ')"
printf '#!/bin/bash\necho "esplosa a meta: errore strano"\nexit 1\n' > "$AV/tools/giri-avversari.sh"
OUT=$(cd "$AV" && timeout 120 bash tools/banco-passaggio.sh --solo-avversari 2>&1); RC=$?
[ "$RC" -ne 0 ] && grep -q "errore strano" <<<"$OUT" \
  && ok "passo 3: rosso senza righe AGGIRA mostra comunque l'ultima riga (mai muto)" || ko "passo 3 rosso muto (rc=$RC): $(tail -3 <<<"$OUT" | tr '\n' ' ')"
printf '#!/bin/bash\necho "TIENE #1 x"\nexit 0\n' > "$AV/tools/giri-avversari.sh"
OUT=$(cd "$AV" && timeout 120 bash tools/banco-passaggio.sh --solo-avversari 2>&1); RC=$?
[ "$RC" -eq 0 ] && grep -q "0 aggirati" <<<"$OUT" && ok "passo 3: batteria verde = 0 aggirati, rc 0" || ko "passo 3 verde (rc=$RC): $(tail -3 <<<"$OUT" | tr '\n' ' ')"
rm -rf "$AV"

echo ""
echo "$PASS OK, $FAIL FAIL"
[ $FAIL -eq 0 ]
