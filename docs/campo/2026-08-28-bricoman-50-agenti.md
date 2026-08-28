Revisione approfondita — 50 sotto-agenti (2026-08-28)
Analisi del progetto Gestione-ordini-Bricoman eseguita con il metodo distillato in AI_Programmer (skill gas-sviluppo, agenti revisore-gas / revisore-calcoli-critici / dev-critic): censimento completo, lenti di difetto misurate su un parco reale di ~90 progetti GAS+Business Central, e dogfooding reale (esecuzione con node delle funzioni di calcolo estratte dal sorgente, non solo lettura).

Questo è un giro di sola analisi: nessun file del repo è stato modificato. I fix sono un passo separato ed esplicito, da decidere dopo aver letto questo report.

Metodo
50 sotto-agenti in due fasi:

35 agenti di scoperta — 13 letture complete per-file con le lenti di difetto (scope globale GAS, OData/Business Central, confine dei dati, concorrenza, sicurezza, igiene dei test), 12 agenti di dogfooding che hanno isolato ed eseguito realmente con node le funzioni critiche (classificazione BU, formula trasporto, prezzi, date, paginazione OData, injection), 4 di coerenza documentazione↔codice, 3 di sicurezza/igiene test trasversali, 3 di ricerca nuove idee/miglioramenti.
15 agenti di verifica avversariale — hanno riletto e, dove possibile, ri-eseguito da zero con dati sintetici indipendenti i rilievi a maggiore severità (bug/sicurezza), cercando di smentirli, non di confermarli per compiacenza.
Risultato: 153 rilievi grezzi, 59 di categoria bug/sicurezza. Il budget di 50 agenti ha permesso di verificare avversarialmente solo i primi 15 (per severità): 13 CONFERMATI, 2 SMENTITI (l'agente di verifica ha dimostrato che il rilievo originale era sbagliato o sovrastimato). I restanti 138 rilievi (compresi 44 bug/sicurezza ad alta severità) sono dichiarati NON VERIFICATI, non promossi tacitamente a confermati — seguendo la regola del metodo ("l'onore del non verificato").

Nessun segreto/credenziale reale è stato riportato per valore in nessun punto di questo documento.

1. Bug confermati con verifica avversariale (esecuzione indipendente)
1.1 — Nessun escaping negli apici dei filtri OData verso Business Central
src/BusinessCentralAPI.gs:197,307,354,425,463 · severità alta · CONFERMATO

Tutti i 5 punti che costruiscono un filtro OData ($filter=... eq '${valore}') interpolano il valore con template string, senza raddoppiare l'apice né applicare encodeURIComponent. I valori (EAN, codice articolo, codice fornitore) arrivano grezzi dal file EDI esterno (Parsers.gs:188,330), senza validazione di formato. Un apostrofo nel dato (refuso, dato corrotto, o costruito ad arte) rompe deterministicamente la query o produce un filtro tautologico (... or 1 eq 1 or ...) che restituisce un record diverso da quello cercato — assegnando silenziosamente codice/prezzo BC sbagliati alla riga d'ordine.

Verificato con node in due repliche indipendenti: 12345'678 → filtro sintatticamente rotto; X' or 1 eq 1 or identifierCode eq 'X → filtro sempre-vero. Nessuna funzione di escape esiste in nessun punto del repo.

Suggerimento: funzione di escape condivisa (value.replace(/'/g, "''")) applicata prima di ogni interpolazione in filtro OData, nei 5 punti.

1.2 — Paginazione OData (@odata.nextLink) mai gestita
src/BusinessCentralAPI.gs:112-173 (apiCall, usato da 198,308,355,426,464) · severità alta · CONFERMATO (confermato indipendentemente da 2 agenti diversi)

apiCall() fa un'unica UrlFetchApp.fetch e ritorna la prima pagina come se fosse l'intero result set. grep -rn nextLink src/ → zero occorrenze in tutto il repo. Riprodotto con node: con una pagina sintetica di 50 record (= $top) più @odata.nextLink verso una seconda pagina contenente l'unico prezzo generico corretto, _findGenericPrice ritorna null ("nessun prezzo trovato") mentre il prezzo esiste realmente in pagina 2, mai raggiunta. Impatta direttamente il pricing di ogni ordine con più di 50-100 righe prezzo storiche per articolo.

Suggerimento: in apiCall, ciclare finché data['@odata.nextLink'] è presente, accumulando value da tutte le pagine.

1.3 — CSV verso BC_Import senza alcun escaping/quoting
src/Converters.gs:156,184,234 · severità alta · CONFERMATO

_buildHeaderRecord/_buildLineRecord/_buildCommentRecord uniscono i campi con fields.join(';') senza quoting. _parseIMD (Parsers.gs:216-225) rimuove solo : dalla descrizione articolo, mai ; né \n. Riprodotto con node: descrizione "TAVOLA PINO; SEZ 20X100" produce un record con 18 campi invece di 17 — quantità e prezzo scambiati nel record risultante, senza errore né log. Una descrizione con un a-capo letterale spezza il record su due righe fisiche del file. Incoerenza interna: GateasyMessageGenerator.formatAsCSV (riga 324, stesso file) applica correttamente il quoting RFC4180 per l'altro export CSV.

Suggerimento: funzione di escaping centralizzata sui campi di testo libero (descrizione, nome/indirizzo/città cliente, testo commento) prima del join.

1.4 — testEmailCubbageReport() opera sulle cartelle Drive di PRODUZIONE
src/Main.gs:494-559 · severità alta · CONFERMATO

Funzione documentata in CLAUDE.md come comando utile standard. Usa lo stesso GDRIVE_FOLDER_ID di produzione (nessun ID sandbox esiste nel progetto), cestina incondizionatamente ogni .csv/.txt in Ordini_Ricevuti — se lanciata mentre gli ordini reali della giornata sono già arrivati (upload prima delle 7:30), li elimina dalla coda del trigger automatico. Poi rielabora 5 ordini storici già importati, rigenerando CSV in BC_Import (rischio doppia registrazione in BC) e un secondo messaggio Gateasy. Il finally ripristina solo REPORT_EMAILS, non i file cestinati né i CSV duplicati.

Suggerimento: cartella Drive dedicata al test (script property separata), mai riusare gdriveFolderId di produzione.

1.5 — Ripartizione trasporto: la quota "non attribuita" sparisce in euro
src/OrderProcessor.gs:227-239 · severità alta · CONFERMATO

Righe con volume valido ma senza fornitorePreferenziale vengono escluse da supplierVolumes (Validators.gs:446) ma restano dentro totalVolume. Il totale trasporto in testata (1060+0.19×MC) usa il volume completo; il ciclo che ripartisce per fornitore usa solo i fornitori noti. Riprodotto con node: totale mostrato €1.061,90, somma delle righe fornitore €743,33 — €318,57 di trasporto mai attribuiti né segnalati (solo un avviso testuale in MC, mai in euro). Il destinatario dell'email vede due numeri che non tornano, senza spiegazione.

1.6 — totalTransport resta undefined se nessun fornitore è attribuito
src/OrderProcessor.gs:227 · severità alta · CONFERMATO

Se tutte le righe con volume hanno fornitorePreferenziale vuoto, supplierVolumes è {}, la guardia Object.keys(...).length > 0 è falsa, e l'intero blocco di calcolo (incluso totalTransport) non viene mai eseguito — anche se l'ordine è EDIL con volume reale e il trasporto è comunque dovuto. Il report mostra — al posto di un importo dovuto (verificato: €1.061,90 scomparso dal report).

1.7 — Release character EDIFACT (?) mai onorato: apostrofi nei dati corrompono il parsing
src/Parsers.gs:77 · severità alta · CONFERMATO

content.split("'") non gestisce il carattere di rilascio ?' previsto dallo standard EDIFACT. Un apostrofo legittimo in un nome/indirizzo italiano (es. "L'Aquila", correttamente escaped come L?'AQUILA nel tracciato) spezza il segmento NAD a metà: riprodotto con node, il cliente arriva con nome=''; indirizzo=''; città='', nessuna eccezione, nessun log.

1.8 — CSVParser.parse(): nessun quoting, ; in un campo sposta le colonne successive
src/Parsers.gs:268 · severità alta · CONFERMATO

line.split(';') ingenuo. Riprodotto con node: descrizione "TAVOLA;ABETE 20X100" produce descrizione="TAVOLA", quantita=0 (era 10, scivolato), prezzo=10 (era 2.50, perso) — dati economici silenziosamente corrotti, riga comunque accettata ed esportata verso Business Central.

1.9 — moveFile() non atomico: copia-poi-elimina senza rollback, doppia copia su errore
src/Services.gs:102-118 · severità alta · CONFERMATO

createFile poi setTrashed(true): se il trash fallisce dopo la copia, il catch rilancia senza pulire la copia già creata. Il chiamante (_handleError, OrderProcessor.gs:313-324) richiama moveFile una seconda volta verso Errori sullo stesso file, creando una seconda copia lì. Risultato: l'ordine esiste sia in Elaborati sia in Errori, CSV e messaggio Gateasy già generati con successo, ma il report email lo segnala come "✗ Errore".

1.10 — QuantityRulesLoader: coercizione numerica silenziosa collassa celle malformate a zero
src/Validators.gs:665-670 · severità alta · CONFERMATO (impatto anche più ampio del dichiarato)

Number(row[x]) || 0: cella vuota, testo, virgola-decimale italiana ("10,5"), o la sentinella testuale "NON CONSIDERARE" collassano tutti a 0/1, indistinguibili l'uno dall'altro e da uno zero legittimo — nessun log. Impatto tracciato: volumeMC=0 per errore di digitazione fa scattare excludedFromCubbage=true, cambiando silenziosamente la classificazione BU (niente più EDIL) e il calcolo trasporto dell'intero ordine.

1.11 — Nessun controllo di plausibilità sul prezzo Business Central (zero o negativo)
src/BusinessCentralAPI.gs:393 · severità alta · CONFERMATO

unitPrice: record.Unit_Price || 0 — uno zero esplicito in BC è indistinguibile da un campo assente; un valore negativo passa inalterato. Riprodotto con node: Unit_Price=-3.00 viene applicato come "correzione prezzo" valida e scritto nel CSV BC_Import come -3.0000, senza alcun blocco o segnalazione di anomalia.

1.12 — DateUtils.parse() non rifiuta date di calendario impossibili
src/DateUtils.gs:83-101 · severità alta · CONFERMATO

new Date(year, month, day) esegue un rollover aritmetico per mese/giorno fuori range invece di produrre un Invalid Date; isNaN(date.getTime()) non lo intercetta mai. Riprodotto con node: '20251332' → 2026-02-01; '20250230' (30 febbraio) → 2025-03-02. Un campo data corrotto nell'ordine EDI viene accettato come valido e propagato a shouldValidatePrices()/isDateInRange().

2. Rilievi SMENTITI dalla verifica avversariale
Due rilievi iniziali sono stati corretti dal secondo giudizio — a dimostrazione che il processo di verifica non è cosmetico:

src/Validators.gs:592-596 (TotalConsolidator) — il rilievo affermava che escludere righe a quantità/prezzo zero "sottostima il totale trasmesso a BC". Falso: matematicamente sommare o non sommare uno zero produce lo stesso totale (verificato con node, due algoritmi a confronto: risultato identico). L'unico effetto reale è un conteggio righeValide leggermente impreciso ai fini del solo reporting — non un problema economico.
src/Validators.gs:343-350 (QuantityValidator) — il rilievo affermava che quantita || 0 confonde "quantità 0 voluta" con "dato mancante" nella pipeline reale. Smentito: ogni riga arriva da createOrderLine()/parseFloat(...)||0 a monte (Parsers.gs), quindi line.quantita è sempre già un numero definito quando raggiunge questo validatore — l'ambiguità, se esiste, andrebbe cercata (e riportata separatamente) in Parsers.gs, non qui.
3. Bug ad alta severità — NON VERIFICATI (fuori budget, dichiarati per onestà)
Questi rilievi sono supportati da lettura diretta e/o esecuzione node dell'agente di scoperta, ma non hanno ricevuto un secondo giudizio avversariale per limite di budget (50 agenti totali). Vanno letti come "probabili, da verificare prima di agire", non come confermati.

BusinessCentralAPI.gs:200,310,357,428,466 — nessun Array.isArray(data.value): un body 200 con errore OData mascherato (niente value) è indistinguibile da "0 risultati legittimi" in 5 punti.
BusinessCentralAPI.gs:393 → Validators.gs:230,265 → Converters.gs:179 — prezzo BC negativo propagato fino al CSV senza controllo di segno (variante del §1.11 con path di propagazione tracciato fino all'export).
BusinessCentralAPI.gs:307,354 — stesso escaping mancante di §1.1 per itemCode nei filtri prezzo (Item_No eq '...'), con rischio aggiuntivo di injection via & (parametri OData duplicati) oltre all'apice.
Converters.gs:109-235 — CSV/formula injection: nessun campo di testo libero viene prefissato/neutralizzato; una cella che inizia con =,+,-,@ (nome cliente, descrizione, commento) diventa una formula eseguibile se il CSV viene aperto in Excel/Sheets per controllo manuale.
OrderProcessor.gs:342 + Services.gs:271 — nessun LockService in tutto il progetto: due esecuzioni sovrapposte (trigger + run manuale nella stessa fascia atHour) processano gli stessi file, duplicano CSV in BC_Import e inviano due email di report. Simulato con node: 2 run concorrenti → stessi 2 file duplicati, 2 email.
Services.gs:102-118 — la finestra non-atomica di moveFile (STEP 9 CSV salvato PRIMA dello STEP 10 move) può lasciare l'originale in Ordini_Ricevuti se l'esecuzione si interrompe a metà: al rilancio il file viene riprocessato da zero, con un secondo CSV omonimo in BC_Import (Drive non impedisce nomi duplicati) e un secondo messaggio Gateasy.
TestBusinessCentralAPI.gs:77,127,176 — testGetPriceALTAVILLA/PERO/Generico dichiarano successo su qualunque prezzo non-null, senza mai verificare salesCode/gruppo prezzo atteso — non potrebbero mai rilevare il bug reale di "prezzo del gruppo sbagliato" che il resto del file esiste apposta per diagnosticare.
test/test_pricing_fixes.js:220-235 — il "Test 4" costruisce gli array attesi nel test stesso e li confronta con sé stessi: strutturalmente sempre vero, e descrive un comportamento ("filtro server-side") diverso da quello realmente implementato (filtro in memoria, BusinessCentralAPI.gs:307,318).
OrderProcessor.gs:396-399,528-542 — se un errore critico avviene prima di _finalize(), l'unica email di report non viene mai inviata: nessuno dei 3 destinatari viene avvisato, solo il log/notifica di default di Apps Script.
Config.gs:274-286 — il fallback "ultime 4 cifre EAN" di getStoreCodeFromEAN è strutturalmente incoerente con la codifica reale di tutti i 39 EAN già mappati (es. atteso '121', prodotto '1216'): per qualunque negozio non censito produce un prezzo silenziosamente sbagliato.
README.md:207-247 (×3 rilievi indipendenti, stesso fatto) — la tabella Negozio→Gruppo Prezzo del README diverge dal codice reale per 5 negozi su 40 (120,121,132,133,135), dopo due commit di fix (bf0e19c, f3fa2ee) mai riportati in doc. Il README stesso, in Troubleshooting, dice di confrontare con Config.gs — un operatore che segue il README rischia di reintrodurre i valori sbagliati già corretti una volta.
Config.gs:219-245 / CLAUDE.md — CLAUDE.md dichiara 3 email destinatarie hardcoded; nel codice reale sono lette da Script Property REPORT_EMAILS, e il fallback hardcoded ne contiene solo 2 (manca luca@..., rimosso deliberatamente dal commit 5697a61 ma mai tolto da CLAUDE.md/README).
TestPricingFixes.gs:496 + TestBusinessCentralAPI.gs:327-332,245 — il verdetto pass/fail è calcolato ma mai lanciato come eccezione: in Apps Script l'esecuzione risulta sempre "Completata", anche a 0 test passati.
BusinessCentralAPI.gs:50 — l'unica chiamata POST di tutto il codebase è il token OAuth2: non esiste alcuna scrittura reale verso Business Central in questo repo. L'"importazione" è la scrittura di un CSV su Drive; il passo finale (import vero in BC) è un processo esterno non documentato — se si ferma, i CSV si accumulano in BC_Import senza che nulla se ne accorga.
(Altri ~30 rilievi bug/sicurezza di severità media/bassa, dello stesso tipo, sono elencati con dettaglio completo — file:riga, scenario, esecuzione node dove applicabile — nel log grezzo del workflow; disponibili su richiesta.)

4. Debito tecnico e gap di processo (selezione — severità media/bassa)
Logger strutturato mai persistito: exportToFile/getEntries*/getStats/clear in Logger.gs non hanno nessun chiamante nel repo — i log persistiti su Drive sono un array di stringhe costruito a mano in parallelo (OrderProcessor.gs:520-526), non collegato alla classe Logger.
minLevel sempre INFO: ~35 chiamate .debug() già scritte nel codice sono no-op permanenti (nessun modo di attivarle senza modificare il sorgente).
sendBatchReport() non idempotente: un'unica GmailApp.sendEmail con tutti i destinatari; se fallisce, nessuno dei 3 riceve il report quel giorno, nessun retry, nessun canale di allerta alternativo.
_determineBU: EDIL ha sempre priorità assoluta su BIOC per un ordine con entrambe le condizioni vere — mai confermato esplicitamente col dominio (CLAUDE.md non lo dichiara come regola di precedenza).
Codice morto in violazione esplicita di CLAUDE.md §2 ("niente codice morto"): 5 metodi di DateUtils.gs (isPast/isToday/diffInDays/getFirstDayOfMonth/ getLastDayOfMonth, ~49 righe), 9 "alias di retrocompatibilità" in Main.gs (righe 563-602), _getCacheKey in BusinessCentralAPI.gs, logValidation in Logger.gs, un ramo ternario morto in OrderProcessor.gs:172.
Token OAuth e cache generica solo in memoria di istanza: non sopravvivono tra esecuzioni separate; ogni run (trigger, test manuale) rifà l'intero handshake anche se il token precedente è ancora valido per 50+ minuti.
Retry indifferenziato: apiCall() ritenta 3 volte anche errori deterministici (400/404), sprecando tempo su richieste che non cambieranno mai esito.
appsscript.json mai versionato (né nel working tree né in tutta la storia git): la correttezza di ogni data/ora del sistema dipende da un fuso orario di progetto non verificabile da questo repo.
Number(volumeMC) !== 'NON CONSIDERARE' (Validators.gs:475,503) è codice morto: volumeMC è sempre già numerico a quel punto, il confronto con la stringa sentinella non può mai essere vero.
Triplicazione quasi identica in TestBusinessCentralAPI.gs (3 funzioni di test prezzo, ~45 righe duplicate) e mappa colore BU_COLOR ripetuta 3 volte in Services.gs.
5. Sicurezza — riepilogo trasversale
Nessuna webapp esposta (confermato: nessun doGet/doPost/HtmlService/ google.script.run/ContentService in tutto il repo) — superficie di attacco limitata a chi ha accesso Editor Apps Script.
Nessun segreto hardcoded (confermato su codice E intera storia git): tutte le credenziali BC passano da PropertiesService; gli unici letterali trovati sono placeholder (YOUR_TENANT_ID ecc.).
checkConfiguration()/verifySecureConfiguration() (Main.gs:108-110,368) stampano nei log i primi 20/8 caratteri di Tenant ID/Client ID (solo il secret è escluso) — severità bassa ma da mascherare comunque.
Escaping HTML assente in tutto il repo: campi esterni (EAN, descrizione, codice articolo) finiscono senza escaping nell'HTML dell'email di report (Services.gs:731-739 e altri punti) — rischio di markup non voluto renderizzato da Gmail.
CSV/Formula injection verso BC_Import: nessuna neutralizzazione di celle che iniziano con =,+,-,@ in nessuno dei tre tipi di record.
6. Coerenza documentazione ↔ codice (evidenziati i più rilevanti)
Tabella Negozio→Gruppo Prezzo del README disallineata dal codice per 5 negozi (vedi §3) — rischio concreto di regressione se un operatore la segue.
CLAUDE.md dichiara 3 email destinatarie "hardcoded"; sono in realtà lette da Script Property, col fallback che ne contiene solo 2.
APP_CONSTANTS.VERSION è ancora '6.0' in Config.gs (stampato in ogni email di report) mentre README dichiara già v6.2, e il changelog non include gli ultimi due commit funzionali del branch.
debugPrezziArticolo('COD')/testEANLookup(...) documentati con parametro in CLAUDE.md/README, ma le funzioni reali non ne accettano alcuno (l'argomento viene ignorato in silenzio).
Il trigger è documentato come "ore 7:30" ma atHour/nearMinute è per specifica Apps Script una finestra approssimativa, non un orario esatto.
CORREZIONI_MAPPATURE.md dichiara "49 negozi mappati" ma le proprie tabelle (e il codice) ne contano 42 — incongruenza interna al documento stesso.
README elenca 11 moduli .gs, il repo ne contiene 12 (manca TestBusinessCentralAPI.gs dall'elenco).
7. Difetti cercati e NON trovati (assenze dichiarate, selezione)
Per onestà del metodo, si riportano anche i controlli che non hanno trovato nulla (comando/metodo usato indicato in ogni riga del log grezzo):

Nessun segreto/credenziale hardcoded in codice o storia git (tenant id, client secret, token, GUID, base64/hex sospetti).
Nessuna webapp/endpoint esposto (doGet/doPost/HtmlService/onEdit/onFormSubmit).
Nessun fuso orario fisso GMT+N hardcoded — sempre Session.getScriptTimeZone().
Nessun uso di toISOString().split('T') fuori da un unico punto diagnostico (OrderProcessor.gs:464, solo un timestamp di log, non logica di business).
Nessun duplicato di nome tra le 91 dichiarazioni top-level nei 12 file .gs (censite una per una, zero collisioni di scope globale).
Segno della formula trasporto (1060 + 0.19×MC) corretto, nessuna inversione.
Sentinella BC '0001-01-01' gestita correttamente come "validità infinita" nel confronto di business (isDateInRange), anche se la presentazione (_mapPriceRecord) usa un confronto di stringa esatto più fragile (riportato come rilievo separato di coerenza).
Nessun pattern "svuota-poi-scrivi" su Sheet o file Drive esistenti.
Nessuna divergenza reale nel calcolo monthDiff/cambio anno di shouldValidatePrices() (testato con node su più scenari dicembre→gennaio).
Il banco test/test_pricing_fixes.js non è "sempre verde": forzando un fallimento, l'exit code passa realmente a 1.
8. Proposte di sviluppo (dalla lente "sviluppo business")
Le tre analisi dedicate a nuove idee hanno convergentemente prodotto altri bug e debito tecnico piuttosto che funzionalità speculative — coerente con la regola del metodo ("un'idea architetturalmente speculativa senza un caso reale che la chieda oggi resta non ancora matura"). Le proposte concrete con dato a supporto già emerse sopra:

Persistere il token OAuth in CacheService (non solo proprietà di istanza) per evitare un handshake completo ad ogni run — costo basso, ma va deciso il comportamento di invalidazione su 401 per evitare loop.
Collegare _saveLog al Logger strutturato invece del solo array di stringhe manuale, per avere contesto/livello/timestamp persistiti — utile solo se combinato con l'abilitazione selettiva del DEBUG.
Un secondo canale di allerta indipendente dall'email di report, per il caso in cui l'unico invio fallisca e nessuno dei 3 destinatari venga avvisato.
Nessuna delle tre analisi ha trovato "dati raccolti e mai riletti" con un caso d'uso concreto sufficientemente maturo da proporre come feature nuova — solo strumentazione (cache stats, durata per-file) già scritta ma non collegata al report, elencata al §4.

Come leggere questo report
Sezione 1: agire con fiducia alta — riprodotto con dati sintetici indipendenti da un secondo giudizio avversariale.
Sezione 3: probabile ma da riverificare (leggere il file:riga citato) prima di programmare un fix — specialmente per severità alta.
Sezioni 4-7: debito tecnico/gap di processo/coerenza doc, utili per prioritizzare ma non urgenti quanto la sezione 1.
Prossimo passo naturale, se si vuole procedere: scegliere uno dei bug confermati in sezione 1 da correggere per primo (il metodo del framework raccomanda un fix alla volta, con banco di prova PARITÀ+CORREZIONE scritto PRIMA della correzione) — coerente con CLAUDE.md §"Un problema alla volta".