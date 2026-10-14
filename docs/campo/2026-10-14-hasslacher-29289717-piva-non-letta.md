# 2026-10-14 — hasslacher-29289717-piva-non-letta
**Autore**: sessione Claude (con Luca)

## Cosa ho usato
- Registrazione_Fatture_Acquisto: grep sul codice (`gas/AutomazioneSD.gs:734`, `gas/Claude.gs:64`, `gas/Regole.gs:146`), skill `gas-agent` e `gas-sviluppo` (`metodo.md`, `consegna.md`), un worktree per PR, il cancello `tools/gate.sh` e `tools/debiti-riapertura.sh`.
- Sei PR sul repo delle fatture, tutte con banco rosso prima del codice e sabotaggi: #384 prompt della P.IVA, #385 `sondaLetturaPiva`, #386/#387 rilettura Hasslacher (lista piena, poi vuota), #388 messaggio Chat a Maurizio, #389 `sondaPercheNonRegistrate`, #390 rilettura Noritec, #391 prima nota di credito (29289711).
- Il PDF della 29289717 è stato letto con PyMuPDF installato in un venv del sandbox: `pdftotext` non c'è.

## Cosa ho improvvisato
- La causa della P.IVA vuota l'ho trovata leggendo il PDF vero (la «P.IVA» in testata è la nostra, quella del fornitore sta solo a piè di pagina), ma la prova che il prompt corretto funziona l'ha data Luca dall'editor (`GIUSTA (ATU27313902)`): da una sessione cloud la chiave `ANTHROPIC_API_KEY` non si vede.
- Luca ha incollato in chat il link di un webhook Chat (con key e token): l'ho dichiarato una volta, non l'ho scritto in nessun file né usato, e il codice lo legge dalla proprietà `CHAT_WEBHOOK_URL`, con i segreti mascherati anche nei messaggi d'errore.
- Il `clasp pull` di Luca ha scaricato `.js` accanto ai nostri `.gs` (e lui era nella cartella del progetto sbagliato, `Riordino-legno`): il confronto fatto da `git diff` era vuoto per costruzione. Ho dato un confronto a mano per nome file (`DIVERSO` / `SOLO VIVO` / `SOLO REPO`).

## Cosa ha retto / ostacolato
- Ha retto: il controllo fail-closed sul fornitore ha fermato la fattura invece di registrarla sull'ordine sbagliato; i sabotaggi hanno trovato due miei errori (àncora non unica su tutti i `.gs`, sostituzione che perdeva la riga `var voci`); il cancello ha fermato tre volte un commit giusto per un motivo giusto (`test_fase2` non conosceva il file nuovo, `coerenza_gas` voleva `avvisaChat_` dichiarata fuori da BC, il censimento delle scritture idem).
- Ostacolato: ogni funzione nuova costa sei punti da registrare a mano (`.night-verify`, README, elenco file di `test_fase2`, eccezioni delle lenti): un solo punto di registrazione per le sonde in sola lettura risparmierebbe cicli. Il cancello dura ~10 minuti e a volte parte con un file di esito vecchio nel scratchpad (`gate7.out` era del 3/10).
- Mio errore di istruzione a Luca: ho dato `bash tools/gate.sh` e `clasp push` su righe separate, quindi il push partiva anche con il cancello rosso; corretto con `&&` (regola 4 del livello 0 di `metodo.md`, «verifica incatenata all'azione»).

## Proposta al canone
- Un solo elenco per le sonde di sola lettura (nome, banco, riga README) da cui derivare i punti da aggiornare, invece di sei posti scritti a mano.
- Nei comandi consegnati a una persona, `verifica && azione` sempre in una riga sola (già regola 4 del livello 0; da citare nel template del blocco comandi di `CLAUDE.md` §3).
- Candidata di dominio, in attesa di Luca: la logica di Treviso (registrazione diretta) per le fatture di pellet di magazzino come la 29289691, oggi passata a Maurizio; e l'accensione del trigger delle note di credito dopo la prima nota vera.
