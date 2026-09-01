# Report di chiusura sessione — Associazione-Energikal, agosto/settembre 2026

Report di handoff per una futura sessione AI (metodologia AI_Programmer). Riassume cosa è stato fatto in questa sessione (estesa su più turni), le decisioni prese, e cosa resta aperto. Sostituisce integralmente la versione precedente di questo file (che si fermava a PR #57 ancora aperta).

**Stato PR** — tutte mergiate in `main`:
- PR #55 "Revisione multi-agente e piano di lavoro completato".
- PR #56 "Claude/project analysis review cbenv6" (100 giri di robustezza + coerenza grafica + 14 nuove funzionalità).
- PR #57 "Aggiungere configurazione clasp per il deploy verso Apps Script".
- PR #58 "Nuovo giro di revisione: fix di correttezza e robustezza" (V1-V26, dettaglio in Fase 6 sotto).
- PR #59 "Aggiornare il report di handoff per ai_programmer" (questo file).
- `main` è quindi allineato a **tutto** il lavoro descritto in questo file.
- **Il progetto Apps Script live** (Script ID `1TdBkczkJgZLzyZeGmWP5Zw8SLMrJmU2OeD5BNim7GO-p2ruFgEYvIVNm`) ha ricevuto un `clasp push` con **tutto** il codice fino a Fase 6 inclusa (40 file, V1-V26 compresi). Verificato nessuna credenziale reale inclusa (config.gs (del progetto) ha solo placeholder `INSERIRE_QUI`). La prossima generazione di un rendiconto (`generaReportBilancino("Qx", anno)`) sul progetto live userà quindi automaticamente tutti i fix V1-V26.

## Cosa è successo in questa sessione (in ordine cronologico)

### Fase 1 — Revisione iniziale e piano di lavoro (PR #55, dettaglio in ANALISI-REVISIONE (file del progetto) e PIANO-DI-LAVORO (file del progetto))
12 agenti paralleli hanno analizzato tutto il repo; il piano derivato (Fasi 1-4, 39 voci) è stato eseguito una voce alla volta con fix mirato + verifica + commit dedicato. Vedi la sezione "Decisioni di dominio" più sotto per le 5 domande risolte in questa fase.

### Fase 2 — "100 giri" di robustezza (R1-R7)
Una fresh review (12 agenti paralleli indipendenti, poi la verifica dei loro finding) ha trovato e corretto:
- **R1**: Guadagno Lordo nel RIEPILOGO del Bilancino usava ancora la base sbagliata (un mio oversight della Fase 1, corretto solo in un punto e non nell'altro).
- **R2**: i match "RICONCILIATO CON ANOMALIA" (introdotti in Fase 1) non erano inclusi nel fatturato Brico, nel foglio Dettaglio Vendite-Acquisti né nel denominatore del match rate — sparivano silenziosamente da tre calcoli a valle.
- **R3**: regressione auto-introdotta in Fase 1 — query rimanenze duplicata.
- **R4**: valutato un apparente problema di segno in `pct_()` sulle righe TOTALE, **confermato che il comportamento originale era corretto** (documentato con commento, nessun fix).
- **R5**: analisi_anomalie.py (del progetto) — ZeroDivisionError quando vendita e acquisto hanno entrambi importo 0; slice silenzioso (`cells[:None]`) se il marcatore di sezione non viene trovato, sostituito con un errore esplicito.
- **R6**: esposte le colonne `Entry_Type`/`Location_Code` nel foglio Dettaglio Manodopera (Capacità), per poter verificare a occhio il filtro applicato in estrazione.
- **R7**: `.trim()` mancante in `isBrico_()` (un nome cliente con spazio iniziale falliva il match); `validaHeaderFoglio_()` mancante in 3 punti che scrivono su un foglio per indice di colonna.

### Fase 3 — Coerenza grafica dei fogli del rendiconto
Nuovo sheet-style.gs (del progetto): palette verde aziendale (RAL 6018) condivisa, prima duplicata/incoerente tra i vari fogli (7 su 9 usavano un blu generico). Aggiunte note (`setNote`, l'unico vero meccanismo "hover" nativo di Google Sheets) sulle voci chiave di tutti i 9 fogli del rendiconto più il foglio Dettaglio Vendite-Acquisti.

### Fase 4 — 14 nuove funzionalità (F1-F14)
Proposte su richiesta esplicita dell'utente ("proponimi tu delle idee"), poi sviluppate tutte, una alla volta, con test e commit dedicato:

**Fondamenta**
- **F11**: suite di test offline (node tests/run.js (del progetto)) — carica i file `.gs` in una sandbox Node (stub generico delle API GAS via Proxy) e rilancia i test già esistenti nel codice, senza bisogno dell'editor Apps Script.
- **F12**: foglio "Guida" nel rendiconto — spiega a cosa serve ciascun foglio.
- **F13**: segnala conti CONTI_CG configurati ma senza movimenti nel trimestre (probabile errore di config).
- **F14**: backup automatico su Drive dei fogli DB (uno al giorno) prima di ogni scrittura.

**Storico**
- **F1**: foglio "Storico" con il trend dei trimestri già elaborati (da DB Report Log).
- **F4**: colonna Δ% vs trimestre precedente nel Bilancino (Fatturato Netto, Utile).
- **F8**: storico riporti (saldo negativo tra trimestri, da DB Riporto) reso leggibile nello Storico.
- **F9**: grafico andamento Fatturato Netto/Utile (da 2 trimestri in su).
- **F10**: tracciamento del coefficiente Formula K nel tempo — **richiede un'azione manuale una tantum**, vedi sotto.

**Automazioni**
- **F2**: export PDF automatico dell'intero rendiconto (endpoint nativo Sheets, non serve abilitare l'Advanced Sheets API).
- **F3**: email di riepilogo a fine generazione riuscita.
- **F7**: email di alert se Quadratura in ALLARME o Euribor fuori range.
- **F6**: menu "Riconciliazione" per marcare a mano un'anomalia come verificata — **solo tracciabilità** (decisione esplicita utente: non altera fatturato/match rate/quadratura).
- **F5**: promemoria email settimanale se un trimestre non è ancora elaborato — **decisione esplicita utente: mai esecuzione automatica**, solo un promemoria; l'attivazione richiede un'azione manuale una tantum, vedi sotto.

### Fase 5 — Primo deploy
Collegato il repo al progetto Apps Script live con `clasp` (login via OAuth, .clasp.json (del progetto)/`.claspignore` creati) e pushato tutto il codice fino a Fase 4. Nessuna credenziale reale nel push (config.gs (del progetto) ha solo placeholder).

### Fase 6 — Nuovo giro di revisione: 26 fix di correttezza e robustezza (V1-V26, PR #58)
Su richiesta esplicita dell'utente ("altri 100 giri di correzione errori bug, logica, metodologia, correttezza formule"): 10 agenti paralleli indipendenti hanno analizzato l'intero repo (tutti i `.gs`, lo script Python, la documentazione business), con istruzioni esplicite di non ri-segnalare problemi già risolti/intenzionali (citando commit/commenti esistenti come disambiguatore). I ~30 finding grezzi sono stati deduplicati in 26 fix concreti, implementati uno alla volta con test dedicato e commit separato:

**Formula K** (costi-engine.gs (del progetto))
- **V1**: `calcolaFormulaK()` logga un warning ATTENZIONE quando `fatturatoTotaleGC` non è positivo, invece di restituire silenziosamente 0.
- **V2**: guardia sul denominatore allineata tra `calcolaFormulaK` e il calcolo di `rapportoK` in `calcolaFormulaKBilancino_` (prima potevano divergere su un fatturato negativo).

**Manodopera capacità** (manodopera.gs (del progetto))
- **V3-V4**: `estraiCostiManodopera()` ora usa `Math.abs()` + `numeroSicuro_()` su Quantity, stessa convenzione già in uso per i materiali.

**Rimanenze** (report.gs (del progetto), rimanenze-sheet.gs (del progetto))
- **V5**: bug reale — un override manuale parziale (solo rimanenze finali O solo esistenze iniziali) azzerava con `|| 0` il campo NON fornito invece di estrarlo da BC come nel percorso normale. Nuova `risolviRimanenze_()` valuta i due campi in modo indipendente.
- **V6**: quando l'override è attivo, il foglio "Dettaglio Rimanenze" (che mostra sempre il dettaglio da BC) riporta un avviso esplicito: il suo totale può non coincidere con la voce "Rimanenze Finali" del Bilancino in quel caso.

**Riconciliazione/vendite** (vendite.gs (del progetto), note-credito.gs (del progetto), riconciliazione.gs (del progetto))
- **V7**: nuovo `segnalaOrfaniConImportoSignificativo_()` — segnala quando righe vendita/NC senza header (cliente sconosciuto) hanno importo complessivo diverso da zero: senza il cliente non si può valutare `isBrico_()`, quindi il fatturato Brico potrebbe essere sottostimato senza alcun avviso.
- **V8**: `contaRigheVenditaConMatch_()` conta le righe vendita individuali nei gruppi riconciliati (non i gruppi per Your_Reference), allineando il log alla sua stessa etichetta.
- **V9**: documentato un limite noto di `cercaMatchAcquisti()` (solo test/diagnostica, non in produzione): perde i duplicati quando più acquisti condividono lo stesso Your_Reference.

**Pipeline report.gs**
- **V10**: fogli Storico e Guida ora best-effort (try/catch) come menu Riconciliazione ed export PDF.
- **V11**: bug reale — `salvaProtocolliUtilizzati()` spostata per ultima nello STEP 16, dopo che `salvaReportLog` ha scritto Stato=OK. Prima, se un passo successivo falliva, gli acquisti risultavano già "consumati" per un report mai completato.
- **V12**: `notificaErrore_()` ora riceve (quando disponibile) lo spreadsheet parziale già creato al momento dell'errore, e ne include il link nell'email.

**Persistenza DB** (db-report-log.gs (del progetto), db-verifiche-anomalie.gs (del progetto), db-utilizzate.gs (del progetto), db-riporto.gs (del progetto), storico-sheet.gs (del progetto))
- **V13**: `leggiRigaReportLog_()` ora chiama `validaHeaderFoglio_()` come il percorso di scrittura.
- **V14**: `registraVerificaAnomalia_()` ora chiama `backupFoglioDB_()` come le altre funzioni salva*.
- **V15**: race condition reale — le funzioni di sola lettura che aprono/creano un foglio DB (`leggiRigaReportLog_`, `leggiProtocolliUtilizzati`, `leggiRiportoPrecedente`, `leggiStoricoReportLog_`, `leggiStoricoRiporti_`) ora girano sotto lo stesso `eseguiConLock_` dei percorsi di scrittura: alla primissima esecuzione (foglio non ancora esistente) due chiamate concorrenti potevano creare due fogli duplicati per lo stesso DB.

**Riconciliazione assistita e Storico** (riconciliazione-assistita.gs (del progetto), storico-sheet.gs (del progetto))
- **V16**: bug reale — `isRigaAnomaliaVerificabile_()` ora risale (`trovaSezioneNonRiconciliate_()`) alla sezione di appartenenza della riga selezionata nel foglio "Non Riconciliate", invece di controllare solo che le colonne A e D fossero valorizzate. Le tabelle VENDITE SENZA ACQUISTO e ACQUISTI SENZA VENDITA hanno "Your Reference" in colonna D, spesso valorizzata quanto la colonna A: una riga di quelle tabelle passava per errore lo stesso controllo pensato solo per RICONCILIATI CON ANOMALIA.
- **V17**: `leggiStoricoReportLog_()` deduplica per Trimestre+Anno tenendo l'ultima riga OK (`salvaReportLog` accoda sempre, senza upsert: rielaborare lo stesso trimestre produceva righe duplicate nello Storico).
- **V18**: `estraiTrimestreAnnoDaNomeFile_()` usa ora una regex ancorata (`^...$`) sul formato esatto scritto da report.gs (del progetto), invece di matchare ovunque nel nome file.

**Client Business Central** (api.gs (del progetto))
- **V19**: `buildEndpointUrl_()` fa `encodeURI()` del nome endpoint (alcuni contengono caratteri accentati).
- **V20**: `bcFetchUrl_()` tratta il 401 come transitorio: invalida la cache del token e ritenta con uno fresco, invece di fallire subito o ripetere la stessa richiesta con lo stesso token già rifiutato.
- **V21**: il singolo `UrlFetchApp.fetch()` nel retry loop è ora protetto da try/catch — un errore di trasporto (timeout, DNS) prima faceva perdere tutti i record già accumulati in una paginazione lunga.
- **V22**: `getBcToken_()` ritenta con backoff sugli errori transitori nella chiamata al token endpoint, simmetrico al retry già presente per le chiamate dati.

**Python** (analisi_anomalie.py (del progetto))
- **V23**: guardia zero-division della Sezione 9 (prossimità date/importi) ora usa `max(abs(v_amount), abs(a_amount))` — con importi negativi il vecchio `max(v_amount, a_amount)` poteva dare un numero negativo diverso da zero, facendo saltare la guardia.
- **V24**: data/importo di ogni acquisto vengono parsati una sola volta prima del loop nidificato, non per ogni vendita — un acquisto con data non parsabile stampava lo stesso avviso N volte.
- **V25**: `parse_vendite`/`parse_acquisti` controllano ora i limiti dell'array prima di indicizzare in avanti — un file troncato/malformato sollevava un `IndexError` non gestito invece di scartare il record incompleto con un avviso.
- Verificato che l'output su `anomalie.rtf` (dati reali) è **identico** prima/dopo i 3 fix — nessuna regressione, i casi corretti (importi negativi, file troncato) non si presentano nei dati attuali.

**Documentazione**
- **V26**: corretto un refuso nella tabella mesi Q4 di BILANCINO-GUIDA-BUSINESS (del progetto) ("Ottobre, Dicembre, Dicembre" → "Ottobre, Novembre, Dicembre").

I bug **reali** (comportamento scorretto già in produzione, non solo robustezza/logging) di questo giro sono **V5, V11, V15, V16** — meritano attenzione prioritaria se si osservano numeri anomali su rimanenze, riconciliazione assistita o rielaborazioni di trimestri già chiusi.

## Decisioni di dominio prese in questa sessione

Dalla Fase 1 (dettaglio completo in PIANO-DI-LAVORO (file del progetto)):
1. Piano dei conti C/G rinumerato dopo il 2024 → codici attuali in contabilita.gs (del progetto) corretti.
2. Filtro `Entry_Type=Output`/`Location_Code=PRINCIPALE` esteso anche ai movimenti di capacità (manodopera).
3. Pubblicità GDO resta trimestrale; il vero gap era la mancata sottrazione delle NC vendita Brico, corretta.
4. Filtro "tutte le location" sulle NC vendite BIOC confermato intenzionale.
5. Limiti Euribor 1,95%/2,95% confermati esclusivi.

Dalla Fase 4 (F5, F6):
6. Trigger schedulato: **solo promemoria email**, mai esecuzione automatica del rendiconto (rischio di generare su un trimestre non ancora chiuso in BC).
7. Riconciliazione assistita: la marcatura "verificato" registra **solo tracciabilità** (log chi/quando/riferimento), non promuove/declassa il match — i calcoli restano quelli di R2.

## Azioni manuali richieste (una tantum, dall'editor Apps Script)

Da eseguire a mano, una sola volta (se non già fatto in una sessione precedente — verificare prima di rieseguire, anche se entrambe sono idempotenti):

1. **migraHeaderReportLogFormulaK_ (del progetto)** (in db-report-log.gs (del progetto)) — aggiunge l'etichetta "Formula K %" all'header del foglio "DB Report Log" già esistente in produzione (che potrebbe avere ancora l'header a 13 colonne). Idempotente, sicura da rieseguire.
2. **installaTriggerPromemoriaRendiconto_ (del progetto)** (in promemoria-trimestrale.gs (del progetto)) — attiva il promemoria email settimanale (F5), **solo se lo si vuole attivo**. Idempotente.
3. Al primo utilizzo di una funzionalità che richiede nuovi permessi (Drive, Mail, trigger installabili), Google mostrerà una schermata di autorizzazione da accettare nell'editor — normale, una tantum.

## Azione fuori scope ancora aperta

**Rotazione del secret Azure AD/Business Central**: config.gs (del progetto) conteneva credenziali reali committate in git dal 16 febbraio 2026. I placeholder sono ripristinati nel codice (verificato di nuovo prima di ogni push clasp), ma **la rotazione del secret in Azure AD resta da fare da chi ha accesso ad Azure AD** — verificare se è già stata fatta.

## Stato attuale del codice

- Tutti i file `.gs` e lo script Python passano il controllo di sintassi.
- node tests/run.js (del progetto) passa interamente — 19 gruppi di test (era 12 a fine Fase 4), tra cui il golden test CSV 2024 (`testBilancinoQ1_2024_CSV`), i test di logica F1-F14, e i nuovi test dedicati per ciascun gruppo di fix V1-V26 (incluse `tests/risolvi-rimanenze.test.js`, `tests/riconciliazione-warnings.test.js`, `tests/api.test.js`, aggiornamenti a `tests/riconciliazione-assistita.test.js` e `tests/storico-sheet.test.js`).
- **Non verificato in questa sessione** (nessun accesso a Business Central live): `testSaldiBilancinoQ1_2025()` e simili vanno rieseguiti dall'editor Apps Script per la conferma end-to-end sui dati reali correnti.
- Il codice pushato con clasp è già live, **inclusi i fix V1-V26** (Fase 6): la prossima generazione di un rendiconto (`generaReportBilancino("Qx", anno)`) userà automaticamente tutte le funzionalità F1-F14 e tutti i fix V1-V26.

## Cosa resta da fare (in ordine di priorità)

1. **Eseguire le 2 azioni manuali una tantum** (vedi sopra) se non già fatto.
2. **Confermare la rotazione del secret Azure AD** (vedi sopra).
3. **Verificare end-to-end su dati reali**: generare un rendiconto di prova (`generaReportBilancino`) dall'editor Apps Script per controllare a occhio, in particolare, i 4 bug reali di Fase 6 (V5, V11, V15, V16) e le funzionalità F1-F14 sul progetto live.
4. **Fase 5/6 residue dalla prima sessione** (pulizia strutturale, idee di miglioramento non implementate): vedi PIANO-DI-LAVORO (file del progetto) §5-6 — da fare solo su richiesta esplicita, non di iniziativa (regola CLAUDE.md #5).
5. **Trovare feedback reale**: dopo un paio di trimestri d'uso, chiedere all'utente cosa delle 14 nuove funzionalità è risultato utile e cosa no, prima di aggiungerne altre.
6. Il catalogo di funzioni che superano il limite di 30-40 righe (CLAUDE.md regola #12), individuato nella revisione Fase 1: resta deliberatamente non affrontato come refactoring a sé — va sistemato solo quando un futuro fix tocca di nuovo quella funzione specifica.

## Come proseguire in una nuova sessione

1. Leggere questo file, poi PIANO-DI-LAVORO (file del progetto) e ANALISI-REVISIONE (file del progetto) solo per il dettaglio storico della Fase 1 (non riflettono il lavoro successivo, ora descritto qui).
2. Verificare se le 2 azioni manuali una tantum sono state eseguite.
3. Prima di ogni modifica: leggere `CLAUDE.md` (regole di lavoro vincolanti) e lanciare node tests/run.js (del progetto) per verificare lo stato di partenza.
4. Per il deploy: .clasp.json (del progetto) è già configurato; `npx @google/clasp login` (una volta per sessione/ambiente) poi `npx @google/clasp push` allineano il codice al progetto live.
