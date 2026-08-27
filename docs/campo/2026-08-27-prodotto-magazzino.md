# Secondo giro di revisione — completezza di prodotto, UX, efficacia — 27/08/2026

Non un giro sui bug (già fatto nel primo audit): questo cerca cosa manca, cosa aggiungere, come rendere il sistema più efficace, più facile, più "parlante". 13 lenti nuove — mappa dei percorsi utente reali → 10 lenti di ricerca (giro 1) → verifica di fondatezza per ogni proposta (un secondo agente apre il codice e verifica che il dato/meccanismo citato esista davvero, o scarta) → 3 lenti mirate (giro 2) → critica finale di completezza.

**Numeri**: 72 agenti, 497+814 letture/comandi, ~7,6M token. **57 proposte confermate** su 57 valutate (0 scartate: le proposte generiche/scollegate dal codice sono già state filtrate dai finder stessi, seguendo l'istruzione di non proporre "feature da manuale SaaS" senza un riscontro concreto). Nessuna modifica al codice: solo censimento, come da mandato.

---

## Come leggere questo documento

Ogni proposta cita **dove** nel codice si aggancia (file:riga) e **per chi** è pensata. Il costo è una stima grossolana (piccolo = poche righe/un giorno, medio = una funzionalità piccola ma completa, grande = richiede una scelta di design). Non è un backlog ordinato per priorità assoluta — le 3 proposte con il miglior rapporto valore/costo *per l'uso di oggi*, secondo la critica finale, sono in fondo.

---

## 1. Copertura del ciclo di vita del magazzino

- **Copertura reale della Mappa Magazzino** (piccolo) — la mappa mostra solo gli articoli con Area/Zona già nota in `Articoli_Ubicazioni` (popolata a 5 articoli/giorno dalla conta): non dice mai quanto valore resta fuori mappa. Il dato per calcolarlo è già in memoria nello stesso punto (`WebAppDashboard.gs:1821-1873`).
- **Riepilogo Carichi/Scarichi nel drill-down Movimenti Articolo** (piccolo) — `getItemLoadUnloadSummary` (`InventoryDataService.gs:269-292`) esiste, calcola già carichi/scarichi separati, e non ha **zero chiamanti** in tutto il repo: è orfana, mai collegata al modale Movimenti.
- **Verifica mirata post-ricezione** (medio) — oggi un articolo appena arrivato da fornitore viene escluso dalla conta fisica per `ESCLUSIONE_MOVIMENTI_GIORNI` giorni (stesso trattamento di un articolo "in lavorazione"), perché `fetchCurrentInventoryByLocationForCodes` non legge `Entry_Type` (letto altrove nello stesso endpoint BC). Il momento più economico per intercettare un errore di put-away è esattamente quello oggi mai controllato.
- **Da "Scorta Minima" a "giorni di copertura residua"** (piccolo) — `minStock` è già calcolato come consumo su una finestra nota (`SnapshotExporter.gs:944-999`): basta dividere per ottenere un'urgenza in giorni invece di una soglia piatta.

## 2. Leggibilità della Dashboard ("si spiega da solo"?)

- **Soglie anomalia mostrate come testo fisso** (piccolo) — `"Fermo 6+ mesi"` è hardcoded in UI, ma la soglia reale (`ARTICOLO_FERMO_GIORNI`) è già self-service dal foglio `Config_Anomalie`: se qualcuno la cambia, l'etichetta mente.
- **Override per singolo articolo invisibili nel tab dedicato** (piccolo) — il tab "Override Config" mostra solo Gruppi e Categorie; gli override per Articolo esistono (`Override_Articoli`) ma non hanno una vista aggregata, solo un filtro nascosto in Inventario.
- **"Invia via email" dell'analisi AI non dice a chi** (piccolo) — va sempre e solo a `NOTIFICATION_EMAIL` (indirizzo fisso), mai al mittente: chi clicca crede di essersi mandato una copia personale.
- **Ripartizione anomalie per tipo, mai mostrata nel tempo** (medio) — calcolata ad ogni export, buttata via nel log: la Direzione vede "12 anomalie critiche" senza sapere se migliora o peggiora.
- **Le 5 KPI card principali senza sottotitolo** (piccolo) — il componente CSS `.kpi-card .sub` esiste ed è usato 5 righe sopra (blocco Inventario Fisico) ma non nelle 5 card principali: un numero senza contesto.
- **Icona "Fuori giacenza" senza spiegazione** (piccolo) — nella Mappa Magazzino, un tooltip generico invece di dire "ubicazione da aggiornare, non articolo introvabile".

## 3. Automazione del lavoro manuale residuo

- **Un'indagine su BC richiede una nuova funzione + `clasp push`** (piccolo) — `BCRevaluationAnalysis.gs` ha funzioni motore già parametriche (`analizzaRivalutazioniBC(from,to)`), ma per eseguirle dall'editor servono wrapper con la data bruciata nel nome (`analizzaAcquistiMarzo2026()`...). Zero menu/sidebar sul foglio per passare i parametri.
- **`Storico_Conte` congela lo Stato a T+1** (medio) — l'archivio è append-only e idempotente sul cicloKey: se qualcuno segna "Corretto" giorni dopo sul foglio, l'archivio (e il drill-down "Storia articolo" già in dashboard) non lo sanno mai.
- **La conta straordinaria per emergenze esiste già ma solo Luca può lanciarla** (piccolo) — `generateAndEmailInventoryToday()` è completa, testata, con lock — ma zero bottone in dashboard, zero trigger.
- **`TRIGGER_ORA` è "self-service" solo in apparenza** (piccolo) — il foglio lo legge ad ogni esecuzione, ma il trigger installato resta fissato all'ora del setup: serve rilanciare 2 funzioni dall'editor perché il valore abbia effetto, e nulla lo segnala.

## 4. Fiducia e osservabilità dei dati

- **Badge di freschezza snapshot in dashboard** (piccolo) — `checkMonthlySnapshotFreshness` esiste e alimenta già l'alert nel report email del venerdì; sul web `#lastUpdate` mostra solo il nome dello snapshot, mai se è vecchio.
- **Data del foglio Inventario Fisico selezionato** (piccolo) — il campo è già trasmesso al browser e mai mostrato.
- **Cache di Trend/Bridge non invalidata dopo un export on-demand** (piccolo) — `forceRefresh` esiste già (commentato "per i casi urgenti") ma è chiamato sempre con `false`.
- **Pannello minimo "salute sistema"** (medio) — `LogLib.run` già avvolge ogni entry point; oggi l'unico segnale di un trigger che non parte è il silenzio assoluto.

## 5. Ricerca, navigazione e produttività quotidiana

- **I filtri si azzerano in silenzio dopo un Override** (piccolo) — `populateFilters` ricostruisce le opzioni senza preservare la selezione: si torna a vedere tutte le BU senza accorgersene.
- **Nessun modo di sapere se un articolo ha una rettifica aperta ora** (medio) — il dato (`code` per riga) è già letto da `getPhysicalInventoryStatus` e scartato.
- **Nessuna vista aggregata delle conte recenti** (medio) — solo un articolo alla volta; `Storico_Conte` viene già letto per intero altrove, serve solo cambiare il filtro da codice a data.
- **Tabella, Anomalie e Mappa Magazzino sono tre stati di ricerca indipendenti** (medio) — filtrare in una vista non si riflette nelle altre due nella stessa sessione.
- **Nessun modo di condividere una vista filtrata via link** (medio) — zero uso di query string/history per lo stato dei filtri, mentre il meccanismo di parametro in URL esiste già per la chiave di sessione.

## 6. Resilienza operativa sul campo

- **Nessun avviso prima di lasciare la pagina a metà scrittura** (piccolo) — solo il modale snapshot ha un testo "in corso"; gli altri 7 ponti di scrittura no, zero `beforeunload`.
- **Nessun avviso proattivo prima che la sessione scada** (piccolo) — TTL fisso a 6 ore (`AccessoWeb.gs:55`), l'utente scopre la scadenza solo con un errore a metà azione.
- **Nessuna indicazione per la conta offline** (piccolo) — il foglio nasce nuovo ogni mattina (nuovo ID via `makeCopy`); nulla nell'email suggerisce di attivare "Disponibile offline" prima di entrare in una zona senza rete.
- **Nessun segnale a logistica se il trigger del mattino fallisce** (piccolo) — oggi il silenzio totale è l'unico segnale che "non c'è lavoro oggi", indistinguibile da "il sistema è rotto".
- **Invio rettifiche a Operations senza guardia anti-doppio-invio** (medio) — nessun lock, nessun marcatore: un retry di rete può produrre due email con due TSV, rischio di doppia rettifica reale in BC.

## 7. KPI di settore magazzino calcolabili ma non mostrati

- **Aging dello stock come colonna, non solo flag** (piccolo) — già calcolato in `SnapshotExporter.gs:1001-1009` e scartato dall'oggetto restituito.
- **Giorni di copertura scorta** (piccolo) — due colonne già affiancate nella stessa tabella, mai divise.
- **Tasso di conferma per motivo di selezione** (medio) — prima misura oggettiva di quanto l'algoritmo di selezione "azzecchi" davvero le anomalie, dati già presenti in `Storico_Conte`.
- **Accuratezza inventariale e tasso di rettifica per Area/Zona/Gruppo, cumulativo** (medio) — oggi `Storico_Conte` serve solo il drill-down di un singolo articolo.

## 8. Configurabilità self-service vs editor Apps Script

- **Cap interno 50 hardcoded** (piccolo) — mai esposto in `Config_Inventario`, a differenza di `CAP_GIORNALIERO`/`TOP_VALORE_N` nello stesso file.
- **Location BC escluse/secondarie su due array in codice** (piccolo) — `LocationPolicy.gs`, mai un tab foglio.
- **`NOTIFICATION_EMAIL` in Script Properties, non in `Config_Inventario`** (piccolo) — mentre `EMAIL_LOGISTICA`/`EMAIL_OPERATIONS` sono già self-service da foglio.
- **`TRIGGER_ORA` nel foglio non dice che non basta modificarlo** (piccolo) — stesso problema del punto 3, versione "documentazione".

## 9. Messaggi d'errore parlanti e onboarding

- **Errore "chiave AI mancante" rimanda a Impostazioni Script**, a cui la Direzione non ha accesso (piccolo).
- **"Nessuno snapshot" non menziona il bottone "Genera Nuovo" a due centimetri** (piccolo).
- **Un errore JS non gestito è invisibile**: click che non fa nulla, zero `window.onerror` in tutto il file (piccolo).
- **Zero pagina di aiuto, 3 tooltip in 4000 righe** (medio) — nessuna guida per un nuovo utente/assunto.

## 10. Integrazione con altri processi aziendali

- **Riepilogo mensile rettifiche a valore per la chiusura contabile** (piccolo) — nessuno oggi sa "quanto abbiamo aggiustato a valore questo mese" senza sommare a mano `Storico_Conte`.
- **Lista sotto-scorta azionabile per acquisti** (medio) — `Vendor_No`/`Vendor_Item_No` sono già letti da BC e mai più riusati: il dato per passare da "anomalia rilevata" a "ordine di riacquisto" c'è già, sparso.
- **Valore di magazzino per Business Unit nell'email mensile** (piccolo) — il dato è già per riga, mai aggregato per BU.

## 11. Usabilità su mobile/touch (il contesto reale del magazzino)

- Griglie di card fisse a 5 colonne, mai responsive, mentre il pattern responsivo esiste già altrove nello stesso file (piccolo).
- Bottoni azione riga (Movimenti/Override/**Rimuovi**) sotto la soglia minima di tocco — rischio concreto di premere l'azione distruttiva per errore (piccolo).
- Filtri multi-select nativi, pattern touch fragile per selezioni combinate (medio).
- Modali senza X e senza footer sticky: il tasto Chiudi scorre via col contenuto (piccolo).
- Tabella Inventario a 15 colonne, solo scroll orizzontale su mobile, nessuna vista a schede (grande).

## 12. Cosa togliere o semplificare

- **Due strade per notificare rettifiche a Operations**, senza guardia anti-doppio-invio (medio) — stesso problema del punto 6, guardato dal lato "troppe strade" invece che "manca una guardia".
- **~120 righe di migrazione one-shot** ancora eseguite per trigger/funzioni che non esistono più nel codice (piccolo).
- **5 funzioni di export CSV** che ripetono lo stesso blocco Blob/link/download (piccolo).
- **3 funzioni di override gruppo/categoria scritte ma mai richiamate da nessuna UI** (piccolo) — un dubbio che il progetto si porta dietro da tempo (già annotato in SAL.md) senza mai risolverlo in un verso o nell'altro.
- **`TRIGGER_ORA`**: la proposta di rimuoverlo dal tab self-service (invece di ripararlo) come opzione più economica.

## 13. Coerenza terminologica fra le viste

- **Il digest email e la Dashboard contano "le rettifiche aperte" con due insiemi diversi** (medio) — `_categorizeInventoryRows` include lo stato "Corretto", `STATI_DISCREPANZA_APERTA` lo esclude: stesso ciclo, due numeri.
- **"Eff. Prezzo €" vs "Impatto €"**: stessa formula, due nomi diversi in due viste della stessa modale Bridge (piccolo).
- **"Stato" significa due cose opposte** in due modali diverse della stessa Dashboard (workflow di conta vs classificazione di variazione) (piccolo).
- **Il modale aperto per un singolo articolo si intitola "Movimenti Magazzino"**, non "Movimenti Articolo" — refuso di naming, il codice sorgente stesso lo chiama correttamente nel commento (piccolo).

---

## Cosa non è stato toccato da nessuna lente (dalla critica finale)

**Sicurezza/governo dell'accesso nel tempo**: la distinzione "interno vs estraneo" è una singola chiave condivisa (`CHIAVE_VISTA_INTERNA`), uguale per tutti, senza scadenza, senza revoca per persona, senza log di chi l'ha usata. Nessuna lente ha toccato cosa succede quando qualcuno lascia l'azienda o inoltra il link per errore (l'unico rimedio oggi è ruotare la chiave per tutti). Collegato: `LocationPolicy.gs` assume una singola azienda (array fissi `['SD']`/`['NC','Sospesi']`) — scalabilità multi-BU/multi-azienda mai discussa.

**Un prerequisito nascosto**: "`Storico_Conte` congela lo Stato a T+1" (sezione 3) è il prerequisito reale sia di "nessun modo di sapere se una rettifica è aperta ora" (sezione 5) sia di "digest e Dashboard contano le aperte diversamente" (sezione 13) — sistemarlo per primo risolve le altre due per costruzione invece di tre patch separate sullo stesso sintomo.

## Le 3 con il miglior rapporto valore/costo per l'uso di oggi

1. **Nessun segnale a logistica quando il trigger del mattino fallisce** (sezione 6, costo piccolo) — il percorso utente #1 (magazziniere) dipende al 100% dall'arrivo di un'email per sapere se c'è lavoro; un fallimento silenzioso azzera la giornata di conta.
2. **Data del foglio Inventario Fisico selezionato + segnalazione se manca quello di oggi** (sezione 4, costo piccolo) — controllo quotidiano di Operations, oggi zero segnale in dashboard.
3. **Invio rettifiche a Operations non protetto da doppia richiesta** (sezione 6, costo medio) — l'unico di questi tre il cui fallimento produce un danno reale e irreversibile (doppia rettifica in BC), non solo un fastidio.

---

Nessuna modifica al codice: questo è un censimento di prodotto, come il primo era un censimento di difetti. Fammi sapere quali vuoi che implementi.
