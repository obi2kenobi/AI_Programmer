# Revisione a 100 agenti — 2026-08-31

Metodo: AI_Programmer (le skill gas-sviluppo (metodo + famiglie-difetti) dell'hub,
gli agenti revisore-gas e revisore-calcoli-critici, la skill dev-critic). Seconda revisione dello stesso
repo dopo la revisione a 50 agenti del 2026-08-28 (REVISIONE_50_AGENTI (file del progetto)) e il riallineamento
git↔live (PR #33, #34, deployato). Analisi eseguita su main (branch del progetto) allo stato post-deploy (28 punti già
applicati: 25 fix + 3 riconciliazioni git/live).

## Metodo di esecuzione

Workflow a 3 fasi, 95 agenti totali:
- **Ricerca** (55 agenti): 12 aree di codice × 6 lenti (correttezza logica, calcoli critici, sicurezza/dati
  esterni, concorrenza/idempotenza, robustezza integrazione Business Central, manutenibilità/dev-critic),
  con una seconda lettura indipendente sulle 4 aree a rischio più alto (BusinessCentralAPI, OrderProcessor,
  Validators, Main/Cross-cutting).
- **Verifica avversariale** (35 agenti, capacità massima raggiunta — 99 rilievi unici restano oltre questo
  tetto, vedi sotto): un revisore indipendente per ciascuno dei primi 35 rilievi unici, con mandato esplicito
  di CONFUTARE, non confermare per abitudine. Ogni verifica ha letto il codice sorgente attuale in prima
  persona (non si è fidata della sintesi del rilievo) e, dove necessario, ha eseguito script node di
  riproduzione.
- **Idee di robustezza** (5 agenti): 5 angolazioni indipendenti (osservabilità, resilienza input EDI/CSV,
  resilienza Business Central, qualità ciclo di sviluppo, costo/performance), esplicitamente separate dalla
  ricerca bug.

Rilievi grezzi: 134. Dopo dedup (chiave file+prefisso sintesi): 134 unici — il dedup automatico non ha
trovato duplicati testuali esatti, ma 3 coppie di rilievi si sono rivelate **lo stesso difetto trovato da
lenti diverse** (vedi sotto, uniti manualmente nel riepilogo). Prima esecuzione: interrotta a metà (52/95)
per limite di utilizzo dell'account, ripresa da cache (i 55 agenti di ricerca già completati non sono stati
ripetuti) non appena il limite si è ripristinato.

## Bug confermati (29, dopo unione di 3 coppie duplicate)

### Severità ALTA (6)

**1. `_escapeODataValue` neutralizza solo l'apice, non i metacaratteri di query-string**
src/BusinessCentralAPI.gs (file del progetto). Il valore "protetto" (apice raddoppiato) viene concatenato crudo nell'URL
(righe 150, 270, 382, 440, 520, 561) senza `encodeURIComponent` per-valore. Un EAN/codice esterno con `&`
può iniettare parametri OData aggiuntivi ($filter, $top, $select). Riprodotto con node: un EAN contenente
`&$filter=1 eq 1&foo=` produce due parametri `$filter` distinti quando l'URL viene scomposto da un parser
standard (WHATWG URLSearchParams).

**2. `TRIGGER_HOUR`/`TRIGGER_MINUTE` a "0" vengono sovrascritti silenziosamente dal default**
src/Config.gs (del progetto). `parseInt(props.getProperty('TRIGGER_HOUR')) || 7` tratta "0" (mezzanotte, valore
legittimo) come assente. Verificato con node: `parseInt('0') || 7` → 7. Alimenta direttamente
`ScriptApp.newTrigger(...).atHour(...)` in `Main.gs`.

**3. CSV formula injection nel messaggio Gateasy**
src/Converters.gs (del progetto), `GateasyMessageGenerator.formatAsCSV()` (righe 348-353). A differenza di
`_escapeCsvField()` nello stesso file (usato per il CSV verso Business Central), il CSV verso Gateasy non
applica alcun prefisso anti-formula (`=,+,-,@`) né escaping del campo `orderNumber`. Riprodotto con node:
un `itemCode` malevolo (`=CMD|'/C calc'!A1`) finisce non neutralizzato nel campo Message.

**4. `numeroOrdine` mai passato da `_escapeCsvField` in nessuno dei 3 builder CSV verso Business Central**
src/Converters.gs (del progetto), righe 142/193/250. Un numero ordine EDI (proveniente dal segmento BGM, non delimitato
da alcun carattere di controllo) contenente `;` sposta tutte le colonne successive in ogni record
(testata/riga/commento), corrompendo l'import BC senza errore visibile. Riprodotto con node: 41 colonne
invece delle 40 attese.

**5. Campo "Quantità totale" del CSV BC scritto senza arrotondamento**
`src/Converters.gs:121`. `ordine.righe.reduce((sum, r) => sum + (r.quantita || 0), 0)` non passa mai da
`.toFixed()`, a differenza di ogni altro campo numerico omogeneo dello stesso convertitore. Riprodotto:
`[10.1, 0.2, 5.3].reduce(...)` → `15.599999999999998`, scritto letteralmente nel CSV a colonne fisse.
(Rilievo trovato indipendentemente da 2 lenti diverse — calcoli critici e correttezza logica.)

**6. shouldValidatePrices (del progetto) omette `deliveryDate`/`currentDate` nel ramo "data non valida", contraddicendo il proprio JSDoc**
src/DateUtils.gs (del progetto). Gli altri 4 return della funzione includono sempre quelle chiavi (via spread);
questo ramo no. Propagato fino alla mail di report giornaliero (`Services.gs`), dove compare letteralmente
il testo `undefined` in due celle HTML per un ordine con data di consegna EDI malformata — proprio il caso
in cui la diagnosi servirebbe di più.

### Severità MEDIA (15)

7. getItemPrice (del progetto) usa la data grezza non validata come fallback quando `DateUtils.parse()` fallisce,
   producendo un match di prezzo falso positivo via confronto lessicografico di stringhe in
   `isDateInRange`. Schermato oggi sul percorso automatico (che passa da `shouldValidatePrices` prima),
   ma raggiungibile dai tool manuali (`Main.gs`, `TestBusinessCentralAPI.gs`, `TestPricingFixes.gs`).
8. Ricerca prezzi (_findCustomerPrice/_findGenericPrice (del progetto)) filtra solo per `Item_No` e prende i primi
   `$top=100`/`$top=50` record senza filtro server-side sulla finestra di validità: un articolo con storico
   prezzi esteso può far restare fuori dalla pagina scaricata un prezzo valido. Non verificabile senza dati
   reali BC, ma la fragilità strutturale è dimostrabile dal codice (il progetto ha già rincorso il limite
   alzando `$top` da 5 a 50 invece di eliminare la causa).
9. Il 429 (throttling Business Central) non è distinto dagli errori transitori generici: backoff totale
   ~3s, nessuna lettura dell'header `Retry-After`, nonostante il throttling BC documentato (~60 req/min) e
   le chiamate sequenziali (non in batch) per riga ordine.
10. getItemPreferredVendorNo (del progetto) inghiotte qualsiasi errore Business Central (rete, HTTP, timeout) e lo
    converte in stringa vuota, indistinguibile dal caso legittimo "articolo senza fornitore in anagrafica" —
    un guasto di integrazione appare nel report come condizione di business normale.
11. 6 metodi di `BusinessCentralAPI.gs` superano il limite di 30-40 righe imposto da CLAUDE.md §2
    (_singlePageApiCall (del progetto) arriva a 77).
12. _findCustomerPrice/_findGenericPrice (del progetto) sono quasi duplicati strutturali (stesso scheletro, solo
    predicato di filtro e `$top` diversi, quest'ultimo un valore magico non commentato).
13. getBusinessCentralConfig (del progetto) valida solo 3 delle 5 credenziali BC richieste (manca `company`,
    `environment`); un valore assente produce un `baseUrl` strutturalmente sbagliato invece del
    `ConfigurationError` promesso, e non riconosce i placeholder `YOUR_*` lasciati da
    `setupSecureCredentials()` (a differenza di `checkConfiguration()`, più severa ma non riusata qui).
    (Rilievo trovato indipendentemente da 2 lenti.)
14. getStoreCodeFromEAN (del progetto) fa un lookup diretto (`EAN_TO_STORE_MAP[ean]`) su un oggetto letterale JS senza
    `hasOwnProperty`: un EAN esterno uguale a una proprietà ereditata da `Object.prototype`
    (`__proto__`, `constructor`, `toString`, ...) restituisce quella proprietà (truthy), bypassando sia il
    ramo "non mappato" sia il fallback a valle, e finisce come `[object Object]` nel CSV verso Business
    Central senza alcun errore.
15. Il messaggio Gateasy contiene sempre newline letterali nel blocco di chiusura; `formatAsCSV()` non li
    normalizza: il CSV a 1 record logico risulta fisicamente composto da 7 righe invece di 2 (RFC4180-valido,
    ma rischioso se il sistema che lo consuma usa un parser naive a righe).
16. `correctedQuantity`/`originalQuantity` interpolati senza formattazione numerica nel messaggio Gateasy al
    cliente (a differenza dei prezzi, formattati con `.toFixed(2)` poche righe sopra): un arrotondamento a
    multipli non intero a monte può produrre rumore floating-point visibile nella comunicazione esterna.
17. GateasyMessageGenerator.generate (del progetto) è lunga 63 righe, oltre il doppio del limite CLAUDE.md.
18. isDateInRange (del progetto) non valida lunghezza/formato della stringa data normalizzata (a differenza di
    `parse()`): un valore con suffisso orario romperebbe silenziosamente il confronto lessicografico. Non
    raggiungibile oggi con i chiamanti reali (che producono sempre 8 cifre), ma un'assunzione mai validata
    sul formato dei campi Business Central.
19. Il banco test/test_pricing_fixes.js (del progetto) reimplementa una propria classe `DateUtils` mock invece di
    richiedere il sorgente reale: il mock manca del controllo di overflow calendario introdotto nel
    sorgente vero (commit `1078dda`), quindi non testa più la funzione reale.
20. shouldValidatePrices (del progetto) è lunga 84 righe, oltre il doppio del limite CLAUDE.md, pur avendo già una
    struttura a 4 blocchi indipendenti facilmente estraibili.
21. getLogger (del progetto) istanzia il singleton globale con `minLevel` hardcoded a `INFO`: tutti i 38 call-site di
    `.debug()` nel progetto sono permanentemente no-op, senza modo di alzare la verbosità per diagnosi.

### Severità BASSA (8)

22. Asimmetria: `_findCustomerPrice` confronta `Sales_Code` con uguaglianza stretta, `_findGenericPrice`
    (stessa tabella) usa `.trim()`, assumendo che il campo possa avere spazi incidentali.
23. Il retry esaurito ricrea l'errore finale come nuovo `APIError` senza `statusCode`/`response` originali.
24. Classe `ValidationError` definita in `Config.gs` ma mai istanziata in tutto il progetto (dead code sin
    dal refactor iniziale).
25. Commento di intestazione di `Config.gs` dichiara ancora "Versione: 6.0" contro `APP_CONSTANTS.VERSION`
    = `'6.3'` nella stessa pagina.
26. Prefisso di 8 campi comune ai 3 tipi di record CSV ricopiato identico in 3 punti invece di costruito
    una sola volta.
27. Campo "Reparto" del CSV BC hardcoded a `'EDILIZIA (01)'` per ogni ordine, senza legame né esclusione
    esplicita dalla classificazione BU (EDIL/BIOC/ARRG) — il valore di BU calcolato da `_determineBU` non
    raggiunge mai il converter perché `_generateCSV` riceve `orderData`, non `result`.
28. Logger.clear (del progetto) riassegna `this.entries = []` invece di svuotare l'array condiviso, rompendo
    silenziosamente il collegamento padre/figlio stabilito da `withContext()`. Oggi dormiente (nessun
    chiamante usa `.clear()` su un logger con figli).
29. startOperation/endOperation (del progetto) non hanno difesa contro l'uso spaiato; l'unico call-site reale
    (`OrderProcessor.gs:85`) chiama `startOperation` scartandone il ritorno e non chiama mai `endOperation`
    — il log di durata non viene mai emesso.

## Rilievi confutati per esecuzione (3)

- **_singlePageApiCall (del progetto) segue qualunque URL assoluto** (incluso un `@odata.nextLink` malformo) senza
  validare l'host: comportamento confermato dal codice, ma scenario di sfruttamento non raggiungibile con
  i dati reali del sistema (nessun input esterno può iniettare un `@odata.nextLink` arbitrario nella
  risposta BC).
- **resetBusinessCentralAPI (del progetto) codice morto**: evidenza grezza corretta (zero chiamanti), ma la funzione è
  un tool diagnostico manuale dichiarato tale, non codice morto involontario.
- **_mapPriceRecord (del progetto) confronta `Ending_Date` con uguaglianza stringa esatta invece che tramite
  `isDateInRange`**: comportamento riprodotto, ma la differenza non produce un esito osservabile diverso sui
  formati data realmente restituiti da Business Central.

## Rilievi NON VERIFICATI (99)

Emersi dalla fase di ricerca ma non passati dalla verifica avversariale per esaurimento del tetto di 35
verifiche disponibili (capacità dichiarata nel workflow, non un limite nascosto). Severità **autodichiarata
dall'agente di ricerca, non confermata**: 38 ALTA, 36 MEDIA, 25 BASSA. Elenco completo con evidenza grezza
nel file `/tmp/.../scratchpad/workflow_result_full.json` di questa sessione (non incluso qui per
dimensione — disponibile su richiesta per un giro di verifica aggiuntivo).

## Idee di robustezza (20, solo analisi)

Raggruppate per angolazione:

**Osservabilità/diagnosi in produzione**: batch con 0 file non invia email (indistinguibile da "trigger non
partito"); skip per lock non ottenuto lascia solo un `console.log` perso; canale di allerta critica è un
singolo punto di guasto senza fallback; il logger strutturato produce dettagli mai esportati
(`exportToFile`/`getStats` senza chiamanti).

**Resilienza input EDI/CSV**: nessun controllo su record type sconosciuto (passa come successo silenzioso);
file che non rispettano l'euristica di naming restano invisibili; qualificatori EDIFACT hardcoded senza
fallback né log; encoding di lettura file fisso, mai verificato (nessuna gestione charset/BOM).

**Resilienza Business Central**: timeout/errore dopo i retry registrato come "articolo inesistente" invece
che guasto infrastrutturale; nessuna validazione dei campi OData essenziali (schema change silenzioso);
backoff retry ignora `Retry-After`; `JSON.parse` sulla risposta OAuth eseguito prima del controllo HTTP.

**Qualità ciclo di sviluppo**: nessuna verifica automatica dell'allineamento git↔Apps Script live (il
drift è già successo, non ipotetico — vedi `docs/campo/2026-08-28-bricoman-git-live-drift.md` su
AI_Programmer); nessuna esecuzione automatica dei test (assenza di CI); mock `DateUtils` nel banco di test
già disallineato (vedi bug MEDIA #19 sopra); triplicazione quasi identica dei 3 test prezzo in
`TestBusinessCentralAPI.gs`.

**Costo/performance**: chiamata OData duplicata in getItemPrice (del progetto); nessun batching HTTP (ogni riga ordine
fa round-trip sequenziali); token OAuth rifatto da zero ad ogni esecuzione (nessuna persistenza cross-run);
`getItemByEAN`/`getItemPreferredVendorNo` interrogano due collection OData diverse per lo stesso articolo.

## Nota metodologica

Prima esecuzione interrotta a metà per limite di utilizzo dell'account (52/95 agenti, tutti quelli di
ricerca completati, verifica e idee falliti); ripresa da cache non appena il limite si è ripristinato,
senza ripetere la ricerca già fatta. 3 coppie di rilievi risultate lo stesso difetto trovato da lenti
diverse sono state unite manualmente nel riepilogo sopra (il dedup automatico per prefisso di testo non le
aveva riconosciute come duplicate, essendo formulate con parole diverse).

Report di riferimento precedenti: REVISIONE_50_AGENTI (file del progetto) (analisi), `docs/campo/` su
AI_Programmer (fasi di fix e riallineamento git↔live).
