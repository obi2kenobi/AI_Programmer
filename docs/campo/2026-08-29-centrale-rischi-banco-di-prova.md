# Banco di prova AI_Programmer su Centrale_Rischi (200 giri in autonomia)

## Cosa ho usato

Il metodo per intero, su un progetto VERO cominciato ieri come test: polilivello
(prima mossa di comprensione), la lezione dell'architettura a ripresa del loop
2026-08-28, banco-sintetico con runner node vm, PR con prova di parità livello 1,
regola del deploy all'umano. Poi il ritorno delle lezioni al hub.

## Cosa ho improvvisato

Nulla di sostanziale. Una correzione al tool polylivello DURANTE il primo uso esterno
(riga Properties con un avanzo di scrittura: unbound variable) — il tool si è rotto
sul bersaglio vero e si è riparato sul posto, con la provenienza scritta nella riga.

## Il lavoro consegnato (PR #7 su Centrale_Rischi)

L'issue #2 si fermava alla regola «tre tentativi poi architettura» sulla latenza reale.
Consegnata l'architettura: apps-script/Pipeline.gs — OCR una volta, pagine in tab
nascosto, chunk da ≤8 pagine o 4,5 minuti, checkpoint in ScriptProperties, trigger
che rigenera se stesso, retry massimo due per pagina poi dichiarata fallita, abort
umano che non cancella i fatti compiuti. Banco tools/test-pipeline.js: 7 attese, e ha
trovato PRIMA del deploy il bug del cursore (le pagine fallite restavano dietro il
cursore: il retry non sarebbe MAI scattato in produzione). PROJECT.md era fermo al
bootstrap («nessun codice»): aggiornato allo stato reale.

## Cosa il processo ha dimostrato

1. **Il banco prima del deploy non è cerimonia**: il bug del cursore era invisibile
   a occhio (la logica sembrava ovvia) e il banco l'ha preso al secondo contratto.
2. **polilivello regge su un bersaglio esterno** — e il suo bug è emerso AL PRIMO
   uso vero, non nella sandbox del hub: conferma che i tool vanno provati fuori casa.
3. **La regola «il loop lascia le lezioni scritte» funziona**: il loop di ieri
   CHIEDEVA esplicitamente due portate al hub — fatte entrambe oggi (pattern
   estrazione-llm-spezzata; lezione del segreto cloud nel metodo).

## Dove il processo merita ancora miglioramento (le proposte)

1. **PROJECT.md invecchia come gli header fossili**: dichiarava «nessun codice» con
   255 righe già scritte. Proposta: una sonda per i repo TARGET («il PROJECT dice
   X: il repo contiene Y: la distanza va dichiarata») — da portare in sync-repo.
2. **Il banco node-vm si riscrive da zero ogni repo**: lo stub GAS di
   test-pipeline.js (Properties/Sheets/Triggers/Lock) è RIUTILIZZABILE — proporre
   nel hub un docs/runner-gas-style con lo stub pronto (il runner generico esiste
   già da REPO-E: qui l'estensione è lo stub di Stato+Trigger per le pipeline).
3. **Il deploy resta il collo umano**: giusto per regola, ma la PR potrebbe portare
   la PROCEDURA di verifica post-deploy (checklist di cosa guardare nei primi chunk)
   già scritta — fatta a mano in #7, da templizzare.

## Proposta al canone

Il pattern estrazione-llm-spezzata (portato) e la lezione del segreto in sessione
cloud (portata). Il banco di prova conferma: il metodo tiene su un progetto nuovo,
dalla comprensione alla PR, con il banco che paga il biglietto prima del deploy.
