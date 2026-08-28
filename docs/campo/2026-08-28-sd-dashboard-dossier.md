DOSSIER TECNICO · REVISIONE MULTI-AGENTE
SD Web Dashboard — Revisione del codice
Bug, errori silenziosi e problemi di sicurezza trovati nell'app Google Apps Script di
Gruppo Camarlinghi per la gestione ordini Pellet, Edilizia e Legna, sincronizzata con
Business Central.
28 agosto 2026
12 aree di codice coperte
86 problemi trovati
25 idee di miglioramento
Nota sul metodo. 12 agenti indipendenti hanno analizzato ogni area del codice (87 problemi grezzi
trovati). La verifica avversariale a doppio giudice — un secondo lettore che cerca di confutare ogni
segnalazione — ha completato solo 2 aree su 12 (Config/Bootstrap e Database/Cache: 13
confermate su 14) prima di esaurire il budget della sessione automatica. Le restanti 71
segnalazioni sono etichettate 
NON VERIFICATO : sono comunque il prodotto di una lettura riga-per-
riga con citazioni precise, ma non hanno ancora superato un secondo controllo scettico
indipendente. Usa i filtri sotto per isolare solo ciò che è già confermato, se preferisci partire da lì.
I 5 problemi critici, in breve
1. Config.gs:447 I tre codici sicurezza reali sono scritti in chiaro nel repository — anche in
Tests.gs, ApiEndpoints.gs, Indice.js e nei README.
2. WebApp.gs:175 Le funzioni di amministrazione (crea/rimuovi codici, sovrascrivi credenziali BC)
sono chiamabili da chiunque dalla console del browser, senza alcun controllo lato server.
3. OrderService.gs:1153 La Conferma in blocco riscrive intere righe da una cache di 3 minuti
prima: cancella silenziosamente modifiche fatte nel frattempo, annullamenti inclusi.
4. BCSync.gs:979 Il sync ordini aperti svuota il foglio prima di sapere se ci sono righe nuove da
scrivere: se il fetch fallisce, il foglio resta vuoto senza alcun errore visibile.
5. ApiEndpoints.gs:505 Un ordine può essere annullato di fatto bypassando il flusso protetto di
annullamento: nessun codice sicurezza, nessuna mail, nessun audit.
5
CRITICI
27
ALTI
41
MEDI
13
BASSI
Confidenza
confermato (14)
possibile (1)
non verificato (71)
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
1/18
86 di 86 problemi mostrati
Configurazione & Bootstrap
6
CRITICAL
CONFERMATO
Config.gs:447
secrets-exposure
I codici sicurezza reali (a 6 cifre) sono scritti in chiaro nel codice sorgente e ripetuti
come commento, non solo tenuti in Script Properties come dichiarato.
Scenario di fallimento ▸
CRITICAL
CONFERMATO
WebApp.gs:175
authorization
Le funzioni di amministrazione dei codici sicurezza e delle credenziali BC
(addSecurityCodes, removeSecurityCode, listSecurityCodes, setupBCCredentials,
setupSecurityCodes) non hanno alcun controllo di autorizzazione lato server, ma sono
funzioni globali dello script.
Scenario di fallimento ▸
MEDIUM
CONFERMATO
appsscript.json:9
dependency-risk
La libreria esterna HasslacherScript e' collegata con developmentMode: true in
produzione, quindi lo script esegue sempre la versione HEAD non pubblicata della
libreria invece di una versione fissata.
Scenario di fallimento ▸
MEDIUM
CONFERMATO
WebApp.gs:30
security
doGet() imposta XFrameOptionsMode.ALLOWALL, disabilitando la protezione anti-
clickjacking di default di Apps Script per una dashboard che espone azioni sensibili a
un click (annulla ordine, forza invio, conferma in blocco).
Scenario di fallimento ▸
MEDIUM
CONFERMATO
Config.gs:173
authorization
CONFIG.security.allowedDomains e requireAuth sono dichiarati ma non vengono mai
letti/applicati da nessuna parte del codice (nessun uso di
getConfig('security.allowedDomains') o requireAuth trovato nel repo, ne' controlli su
Session.getActiveUser()/getEffectiveUser()).
Scenario di fallimento ▸
LOW
CONFERMATO
Validators.gs:143
security
▸
Area
Tutte le aree
Cerca per file, parola chiave…
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
2/18
validateSecurityCode (usato anche da apiVerifySecurityCode) non ha alcun limite di
tentativi o lockout sul codice numerico a 6 cifre.
Scenario di fallimento ▸
Database & Cache
6
CRITICAL
CONFERMATO
OrderService.gs:1153
lost-update-stale-cache
bulkConfirmFromCSV riusa uno snapshot COMPLETO del foglio (tutte le colonne) preso
fino a 3 minuti prima da apiBulkPreview via
CacheManager.getLarge('bulk','main'/'temp'), e lo riscrive per intero con setValues() su
tutta la larghezza riga (ncols = headers.length), non solo sulle colonne che intende
modificare.
Scenario di fallimento ▸
HIGH
CONFERMATO
Database.gs:253
pagination-logic
readSheetPaginated ritorna offset invariato (eco del parametro in ingresso) invece
della posizione reale raggiunta nel foglio, mentre il filtro bcStatus è SEMPRE attivo
(OrderService passa sempre filters.bcStatus in getOpenOrders/getHistoryOrders): il
numero di righe fisiche lette per riempire 'limit' risultati è quasi sempre maggiore del
numero di oggetti restituiti (count).
Scenario di fallimento ▸
HIGH
POSSIBILE
OrderService.gs:1458
unverified-write-path
updateNote (usata da apiUpdateOrderNote, il cambio-stato/NOTE ordine,
probabilmente la scrittura più frequente dell'app) chiama Database.updateField
direttamente, non updateFieldsVerified: è un percorso di scrittura NON coperto dalla
mitigazione rilettura+retry già presente per
changeDate/changeAddress/cancelOrder/notifyDeliveryCSV.
Scenario di fallimento ▸
MEDIUM
CONFERMATO
Database.gs:325
date-timezone
_applyFilters costruisce i bordi data (filters.dateFrom/dateTo,
dateOrdineFrom/dateOrdineTo) con `new Date(filters.dateFrom)` invece di
Utils.parseDate, contraddicendo la convenzione del progetto (usare sempre
Utils.parseDate per evitare shift UTC); il confronto avviene poi contro orderDate
ottenuto con Utils.parseDate.
Scenario di fallimento ▸
MEDIUM
CONFERMATO
CacheManager.gs:34
cache-invalidation
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
3/18
g
g
_namespaceKeys['stats'] elenca chiavi statiche ('stats_temp','stats_main','pellet','edil')
che non corrispondono più al formato reale usato da Database.getStats
(`stats_${sheetKey}_${statusFilter || 'all'}` → es. 'stats_temp_all',
'stats_temp_EDIL_SD'), e il tracking dinamico (_dynamicKeys, oggetto in memoria) non
sopravvive tra esecuzioni separate dello script — quindi non compensa la discrepanza
quando invalidate('stats') viene chiamato da un'esecuzione diversa da quella che ha
popolato la cache.
Scenario di fallimento ▸
MEDIUM
CONFERMATO
Database.gs:567
row-lookup-consistency
_findAndReadRows (usata da updateField, updateFields, updateAllRows e
findOrderRows, cioè tutti i percorsi di SCRITTURA/lookup mirato) localizza le righe con
TextFinder sul testo visualizzato della colonna Nr_Ordine_Cliente, senza applicare la
normalizzazione che il resto del codice usa esplicitamente per la stessa colonna
quando torna un oggetto Date di Google Sheets (vedi Database.gs:58-60 in
_rowsToObjects, righe 181-183 e 222-223 in readSheetPaginated, riga 443-445 in
findOrderRows): la ricerca testuale non troverà mai una cella il cui Nr_Ordine_Cliente
sia stato auto-convertito in Date da Sheets.
Scenario di fallimento ▸
Sync Business Central
7
CRITICAL
CONFERMATO
BCSync.gs:979
data-loss
syncOpenPelletOrders svuota il foglio 'Ordini Arrivati da Gestire' (temp)
incondizionatamente PRIMA di sapere se ci saranno nuove righe da scrivere: se il ciclo
produce zero righe scrivibili il foglio resta vuoto, senza eccezione né alert.
Scenario di fallimento ▸
HIGH
CONFERMATO
BCSync.gs:1107
logic-bug
syncOpenPelletOrders forza sempre NOTE="DA PROGRAMMARE" e
Data_Precedente_Posticipo="" per ogni ordine SD aperto, ignorando lo stato reale
dell'ordine in BC e cancellando ogni stato impostato manualmente dagli operatori, a
ogni sync (ogni 4 ore).
Scenario di fallimento ▸
HIGH
CONFERMATO
BCSync.gs:958
main-temp-inconsistency
TEMP_HEADERS (colonne del foglio 'Ordini Arrivati da Gestire' create/ricreate da
syncOpenPelletOrders) non include le colonne 'RESP modifica Manuale' e
'Indirizzo_Modificato', che OrderService.gs scrive e verifica per gli ordini trovati aperti
( f
dI O
t
)
d f l i f lli
ti di h
g D t / h
g Add
h
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
4/18
(_foundInOpen=true) — causando falsi fallimenti di changeDate/changeAddress anche
quando la modifica è realmente persistita.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCSync.gs:583
logic-bug
L'indirizzo effettivo PRJ viene risolto una sola volta per Order_No usando la PRIMA
spedizione (DDT) restituita da BC, non ordinata per data, e viene applicato a TUTTE le
fatture collegate a quell'ordine.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCSync.gs:726
logic-bug
getBatchPurchaseInvoicesPreWrite interroga BC usando come filtro Your_Reference il
riferimento GIÀ normalizzato (uppercase, spazi rimossi da normalizeReference),
invece del valore originale: se il campo Your_Reference in BC contiene spazi o
minuscole, il filtro OData non trova mai la fattura, e Fattura_Fornitore resta
silenziosamente vuota.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCSync.gs:390
missing-validation
Le righe fattura con Quantity zero o negativa (rese/note di credito) non vengono mai
scartate: entrano nel flusso come ordini normali e finiscono scritte in
Pianificazione_Pellet, alterando quantità/aggregazioni a valle.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCSync.gs:518
injection
I filtri OData costruiti da yourReference/orderNo/fattura (usati in almeno 8 punti del
file) non escapano l'apice singolo, a differenza del filtro su shipToName (riga 1711) che
lo fa correttamente — un valore con un apostrofo rompe o altera la query batch e fa
fallire silenziosamente l'intero lotto di 10-50 riferimenti.
Scenario di fallimento ▸
Client BC & Setup
8
HIGH
NON VERIFICATO
BCLogger.gs:184
silent-failure-write-path
flush() scrive il log persistente Sync_Log con una setValues() nuda, senza
rilettura/verifica né retry — un nuovo percorso di scrittura NON coperto dalla
mitigazione updateFieldsVerified/updateAllRowsVerified già presente in Database.gs
per lo stesso fenomeno noto.
Scenario di fallimento ▸
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
5/18
HIGH
NON VERIFICATO
BCLogger.gs:185
race-condition
flush() calcola la riga di append con getLastRow()+1 senza alcun lock (nessun
LockService), quindi due esecuzioni sovrapposte possono scrivere sulla stessa riga.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
BCSetup.gs:1147
unsafe-diagnostic-function
forzaInvioHasslacherDaEditor() è una funzione a zero parametri che invia email REALI
a un fornitore esterno (Hasslacher), senza conferma, dry-run o controllo TEST_MODE,
ed è elencata nel menu Esegui dell'editor accanto a funzioni diagnostiche sicure (es.
verificaLibreriaHasslacher()).
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCSetup.gs:569
unsafe-diagnostic-function
resetSyncDateTo1Marzo2026() sovrascrive incondizionatamente
PELLET_LAST_SYNC_DATE con una data fissa hardcoded, senza guardia contro
esecuzioni ripetute, pur essendo documentata come 'usare UNA SOLA VOLTA'.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCApiClient.gs:256
retry-logic-error
Su HTTP 401 il token cache viene invalidato (riga 257) ma isRetryableError() classifica
'401' come NON recuperabile (riga 58-60), quindi l'errore risale immediatamente
senza che la chiamata corrente venga ritentata con il token appena invalidato.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCLogger.gs:133
alerting-no-throttling
critical() invia un'email di alert admin (sendAdminAlert) ad OGNI chiamata, senza
throttling, deduplicazione o batching.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
BCApiClient.gs:31
weak-classification
isRetryableError() classifica gli errori cercando sottostringhe numeriche
('400','401','404','429','500','502','503','504') nel messaggio d'errore stringificato, senza
legarle esplicitamente al codice HTTP reale.
Scenario di fallimento ▸
LOW
NON VERIFICATO
BCApiClient.gs:185
silent-failure-error-masking
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
6/18
Il catch generico in getBCAccessToken() avvolge QUALSIASI eccezione (incluso un
JSON.parse fallito su risposta non-JSON o un errore di rete/proxy) nello stesso
messaggio generico 'Impossibile autenticarsi... Verifica credenziali', scartando la
causa reale se non si va a leggere il log.
Scenario di fallimento ▸
Logica Ordini (OrderService)
7
HIGH
NON VERIFICATO
OrderService.gs:611
logic-error
changeDate (e come changeAddress) instrada la scrittura solo in base a isEdil,
ignorando isLegna: per gli ordini Legna con più righe (più articoli sotto lo stesso
Nr_Ordine_Cliente) usa updateFieldsVerified, che aggiorna una sola riga.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
OrderService.gs:739
logic-error
Stesso bug di changeDate anche in changeAddress: instradamento basato solo su
isEdil, isLegna non esiste nella funzione, quindi un ordine Legna multi-riga vede
aggiornato l'indirizzo solo sulla prima riga trovata.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
OrderService.gs:1152
race-condition
bulkConfirmFromCSV, quando riusa la cache di apiBulkPreview (TTL 180s), riscrive
INTERE righe del foglio prese dallo snapshot cache-ato, non solo i campi modificati:
qualunque modifica concorrente fatta su quelle righe tra preview e conferma viene
silenziosamente annullata.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
OrderService.gs:1627
logic-error
_fetchRivenditoriMap assegna il risultato BC a un nome cliente tramite match a
sottostringa (bcName.includes(origName) || origName.includes(bcName)) confrontato
contro TUTTI i nomi del batch, non solo quello che ha generato il filtro: nomi diversi ma
l'uno sottostringa dell'altro possono ricevere gli stessi dati BC (email/postingGroup)
sbagliati.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
OrderService.gs:930
silent-failure
In notifyDeliveryCSV i tre rami che marcano l'ordine 'ERRORE' dopo un fallimento
(salvataggio CSV su Drive righe 930-944, email Brico IO righe 1021-1024, email
rivenditore righe 1042 1044) usano Database updateAllRows/updateFields NON
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
7/18
rivenditore righe 1042-1044) usano Database.updateAllRows/updateFields NON
verificati, a differenza della scrittura principale della stessa funzione (riga 974-976)
che usa le varianti *Verified.
Scenario di fallimento ▸
LOW
NON VERIFICATO
OrderService.gs:1112
logic-error
In notifyDeliveryCSV la catena di fallback usata per il nome cliente nel messaggio
diagnostico ('Notifica non inviata: cliente X non trovato in BC', riga 1112-1116) è
diversa da quella usata per l'effettiva ricerca su BC (riga 1031): la diagnostica omette
Vendere_a.
Scenario di fallimento ▸
LOW
NON VERIFICATO
OrderService.gs:1235
dead-code
In bulkConfirmFromCSV il fallback 'order.Data_Consegna ||
order.Data_Richiesta_Consegna' (riga 1235) non può mai attivarsi:
'Data_Richiesta_Consegna' non è una colonna reale dei fogli main/temp (è solo il nome
di campo usato nell'output verso il frontend in _compressOrders/ApiEndpoints),
mentre mainObjMap/tempObjMap sono costruiti direttamente dagli header reali del
foglio (righe 1191/1200).
Scenario di fallimento ▸
Email
6
HIGH
NON VERIFICATO
EmailService.gs:650
silent-failure
sendAddressChangeEmail non ritorna alcun esito: usa GmailApp.sendEmail
direttamente in un try/catch che in caso di errore fa solo AppLogger.error, senza return
{sent,error} come tutte le altre send* del file.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
OrderService.gs:1076
silent-failure
L'esito di EmailService.sendEdilNotifyEmail (mail 'Documentazione Ordine' a
Hasslacher) non viene mai loggato in ORDER_ERROR_LOG e il fallimento è
indistinguibile dal caso 'nessun allegato' nel risultato mostrato all'operatore.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
EmailService.gs:1436
config-inconsistency
sendEdilNotifyEmail, sendErrorSummaryEmail e (parzialmente)
sendAddressChangeEmail usano indirizzi email hardcoded invece di leggerli da
CONFIG.email.*, vanificando la centralizzazione dichiarata in Config.gs ('Email -
i
h
d
d d i
iù
i')
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
8/18
CENTRALIZZATE, prima erano hardcoded in più punti').
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
EmailService.gs:1161
race-condition
addToErrorLog fa un read-modify-write su PropertiesService (ORDER_ERROR_LOG)
senza lock; sendErrorSummaryEmail legge il log e poi lo svuota con deleteProperty in
una finestra separata, anch'essa senza lock.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
EmailService.gs:1618
reliability
sendAddressChangeEmail, sendEdilNotifyEmail, sendLeroyMerlinNegozioEmail,
_sendDeliveryBookingEmail, sendRivenditoreDeliveryEmailBatch e
sendErrorSummaryEmail chiamano GmailApp.sendEmail direttamente in try/catch,
senza passare da sendWithRetry/sendNonBlocking: un solo tentativo, senza il retry
con backoff esponenziale che hanno invece sendCancellationEmail,
sendDateChangeEmail, sendSpecialArticleEmail e sendEdilMorningReport.
Scenario di fallimento ▸
LOW
NON VERIFICATO
EmailService.gs:770
type-safety
sendEdilMorningReport chiama .toFixed(3) senza controllo di tipo su totalMC (righe
770, 788) e su ogni valore di mcPerFornitore (riga 754), mentre lo stesso file controlla
difensivamente `typeof o.mc === 'number'` per gli ordini (riga 737); l'intera
costruzione del corpo HTML non è in un try/catch.
Scenario di fallimento ▸
API Endpoints
8
CRITICAL
NON VERIFICATO
ApiEndpoints.gs:505
authorization-bypass
apiUpdateOrderNote permette di impostare NOTE='ANNULLATO' (o qualsiasi altro
stato dell'elenco consentito) senza codice di sicurezza, bypassando completamente il
flusso protetto apiCancelOrder.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
ApiEndpoints.gs:1094
silent-bug
La funzione globale apiHealthCheck è definita due volte nel progetto
(ApiEndpoints.gs:1094 e WebApp.gs:66): essendo Apps Script un unico scope globale,
una delle due definizioni sovrascrive silenziosamente l'altra senza errore.
Scenario di fallimento ▸
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
9/18
HIGH
NON VERIFICATO
ApiEndpoints.gs:670
race-condition
apiBulkPreview mette in cache uno snapshot grezzo (righe intere) dei fogli main/temp
per 3 minuti sotto una chiave GLOBALE condivisa ('bulk'/'main', 'bulk'/'temp');
apiBulkConfirm→bulkConfirmFromCSV riscrive poi l'INTERA riga sul foglio live
partendo da quello snapshot, non solo i campi modificati.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
ApiEndpoints.gs:1141
secret-exposure
apiTestConfiguration ha hardcoded nel codice sorgente uno dei tre codici di sicurezza
reali di produzione ('300489', usato in isValidSecurityCode('300489')), che corrisponde
esattamente a uno dei codici configurati in Config.gs (setupSecurityCodes: '300489' →
'Lavinia').
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
ApiEndpoints.gs:704
missing-rate-limit
apiVerifySecurityCode (e di riflesso ogni endpoint che chiama
Validators.validateSecurityCode) non ha alcun rate-limiting, lockout o alert su tentativi
ripetuti falliti; è un entry point globale invocabile direttamente da console browser con
google.script.run, bypassando qualunque throttling lato UI.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
ApiEndpoints.gs:242
cache-inconsistency
La cache di apiGlobalSearch (chiave 'gsearch2:...', TTL 600s) è scritta direttamente su
CacheService.getScriptCache() bypassando CacheManager, e la cache di
apiSearchOrder (namespace 'search', TTL 60s) pur passando da CacheManager non
viene mai invalidata da CacheManager.invalidateOrder() (che pulisce solo
'openOrders', 'stats' e 'calendar'): un annullamento, cambio data o cambio indirizzo su
un ordine non invalida nessuna delle due cache di ricerca.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
ApiEndpoints.gs:843
injection
apiExportCSV e apiExportFilteredCSV costruiscono il CSV racchiudendo i valori tra
virgolette senza neutralizzare caratteri che Excel/Google Sheets interpretano come
inizio formula (=, +, -, @), esponendo a CSV/Formula Injection quando il file esportato
viene aperto da un operatore.
Scenario di fallimento ▸
LOW
NON VERIFICATO
ApiEndpoints.gs:884
logic-error
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
10/18
In apiExportFilteredCSV, `let value = order[h] || '';` converte in stringa vuota
qualunque valore falsy, incluso il numero 0: una Quantita legittima di 0 sparisce
silenziosamente dal CSV esportato.
Scenario di fallimento ▸
Utility & Validatori
9
HIGH
NON VERIFICATO
Utils.gs:176
date-parsing
Utils.parseDate interpreta un anno a 2 cifre nel ramo DD/MM/YYYY come 19xx invece
di 20xx, producendo una data sbagliata di 100 anni senza sollevare eccezione.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
Validators.gs:208
input-validation
validateAddress chiama .trim()/.toUpperCase() direttamente sui campi indirizzo
assumendo che siano stringhe, ma hasRequiredFields (usato subito prima) non verifica
il tipo, solo che non siano undefined/null/''.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
Validators.gs:125
security-xss
Validators.sanitize() (anti-XSS) esiste ed è testata in Tests.gs ma non viene mai
invocata da nessuna funzione di validazione reale (validateAddress, validateOrderRef,
validateNote) né altrove nel codice di produzione: è codice morto che non fornisce
alcuna protezione effettiva.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Utils.gs:177
date-parsing
Il parsing DD/MM/YYYY in Utils.parseDate non valida i range di giorno/mese: valori
fuori range vengono silenziosamente 'normalizzati' da Date invece di essere rifiutati.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Validators.gs:166
date-parsing
Validators.validateDate implementa un parsing data indipendente e incoerente
rispetto a Utils.parseDate: gestisce solo lo YYYY-MM-DD con fix mezzogiorno, ma non
il formato italiano DD/MM/YYYY che Utils.parseDate supporta esplicitamente altrove
nell'app.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Utils.gs:74
logic-bug
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
11/18
U
s.gs:
og c bug
Utils.deepClone usa JSON.parse(JSON.stringify(obj)), che converte silenziosamente
ogni campo Date in una stringa ISO e rimuove le chiavi con valore undefined, invece di
produrre una copia fedele dell'oggetto.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
ErrorHandler.gs:152
error-handling
safeExecute intercetta indistintamente qualunque eccezione (errori di validazione
attesi ED errori di programmazione reali come TypeError/ReferenceError) e le fa
passare tutte per la stessa classificazione a pattern-matching su stringa in handle(),
restituendo al chiamante una risposta 'gestita' indistinguibile da un normale errore di
validazione.
Scenario di fallimento ▸
LOW
NON VERIFICATO
Utils.gs:108
type-coercion
Utils.sortBy confronta i valori con < / > senza normalizzare i tipi: se lo stesso campo è
number in un foglio (es. main) e stringa numerica nell'altro (es. temp, tipico delle
incoerenze note tra i due fogli), l'ordinamento diventa lessicografico invece che
numerico.
Scenario di fallimento ▸
LOW
NON VERIFICATO
Utils.gs:130
type-coercion
filterByText scarta un campo dal confronto di ricerca se il suo valore è falsy (0, false,
''), anche quando .toString() funzionerebbe correttamente, per via del controllo `value
&& value.toString()...`.
Scenario di fallimento ▸
Parser & Storico
9
HIGH
NON VERIFICATO
HST_Parser.js:134
correctness
parseImportoHST inghiotte qualunque errore di parsing dell'importo e ritorna
silenziosamente 0, senza mai segnalare un dato non valido.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
HST_Parser.js:129
silent-failure
scriviSaldiBanca sovrascrive integralmente il foglio SALDI_BANCA (clearAndWrite) ad
ogni import, senza alcuna validazione contro i dati precedenti o contro anomalie
evidenti (es. banca sparita, saldo azzerato).
Scenario di fallimento ▸
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
12/18
MEDIUM
NON VERIFICATO
HST_Parser.js:89
correctness
parseFileHST assume che il record 61 di un conto preceda sempre il relativo record 64
nello stesso file; se l'ordine fosse invertito il saldo viene perso silenziosamente.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
HST_Parser.js:55
edge-case
Il controllo `line.length >= 97` per il record 61 è più restrittivo dei campi realmente
letti (che si fermano a offset 75), quindi record validi ma più corti vengono scartati
integralmente.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
HST_Parser.js:65
correctness
I campi `abi` e `cab` estratti dal record 61 non vengono trim-ati (a differenza di
`conto` e `valuta` nella stessa riga), a rischio di mancato match nella mappa
ABI_BANCA_MAP.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
StoricoModifiche.gs:41
silent-failure
StoricoModifiche.log() cattura qualsiasi eccezione e la registra solo con
AppLogger.warn, senza propagarla né restituire un esito: i chiamanti in
OrderService.gs (changeDate, cancelOrder, changeAddress, bulkConfirmFromCSV)
non hanno modo di sapere che la voce di audit non è stata scritta.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
StoricoModifiche.gs:17
race-condition
_getSheet() non è protetto da lock: due esecuzioni concorrenti che trovano entrambe il
foglio 'Storico Modifiche' inesistente possono entrambe chiamare insertSheet con lo
stesso nome, e la seconda chiamata lancia un'eccezione che il chiamante log()
inghiotte silenziosamente (vedi finding precedente).
Scenario di fallimento ▸
LOW
NON VERIFICATO
diagnosticAddress.gs:125
edge-case
diagnosticCheckSpecificOrder non verifica che nrOrdineIdx sia diverso da -1 prima di
usarlo per confrontare row[nrOrdineIdx]; se la colonna 'Nr_Ordine_Cliente' non esiste/
è rinominata, la funzione riporta sempre 'Ordine non trovato' anche quando l'ordine
esiste, mascherando il vero problema (colonna mancante).
Scenario di fallimento ▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
13/18
Scenario di fallimento ▸
LOW
NON VERIFICATO
diagnosticAddress.gs:53
edge-case
diagnosticCheckPRJAddresses usa confronti stretti (=== 'PRJ' / === 'STANDARD') e
una condizione di 'vuoto' altrettanto stretta (!fonteIndirizzo || === ''), per cui un valore
con spazi o maiuscole/minuscole diverse (es. 'PRJ ', 'prj') non rientra in nessuna delle
tre categorie contate.
Scenario di fallimento ▸
Test
4
HIGH
NON VERIFICATO
TEST_INTEGRATION_SAFE.gs:605
test-false-safety
testFase4_BricoIoEmail() (Test 3), nel file che si dichiara 'SAFE', invia una email VERA
alla casella di produzione ordini.biocombustibili@gruppocamarlinghi.it quando
eseguito, contraddicendo il proprio commento.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
TEST_INTEGRATION_SAFE.gs:815
correctness
migrazioneEmailBricoIo() è una funzione di scrittura reale su 'main' in un file che si
presenta come 'test sicuro': riscrive intere righe da uno snapshot ottenuto a inizio
funzione, senza retry/verifica, con rischio di sovrascrivere modifiche concorrenti — un
nuovo percorso di scrittura non coperto da
updateFieldsVerified/updateAllRowsVerified.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Tests.gs:476
test-coverage
Diverse funzioni incluse in runAllTests (testUtils, testErrorHandler, testHealthCheck,
testApiStats, testSecurityCodes) non usano mai assert_: si limitano a fare console.log
dei risultati, quindi una regressione logica in quelle aree non fa fallire la suite.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Tests.gs:636
secret-exposure
testCSVNotification() usa come 'codice sicurezza valido' il valore letterale '300489',
che corrisponde esattamente al codice sicurezza reale di produzione (Lavinia) definito
in Config.gs:448 e documentato in chiaro anche in
README.md/README.it.md/Indice.js.
Scenario di fallimento ▸
Frontend (shell/UI)
6
▸
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
14/18
HIGH
NON VERIFICATO
Scripts.html:2669
config-duplication
Il vocabolario degli stati ordine è duplicato e disallineato tra backend (NOTE reali
scritte da OrderService.gs) e frontend (mappe hardcoded in
Scripts.html/dashboard.html), e il canale di config condiviso pensato per questo
(CONFIG.noteColors da WebApp.gs) è di fatto morto.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
Scripts.html:991
xss
escapeHtml() esegue solo entity-escaping HTML (&,<,>,") e non escapa l'apice singolo,
ma il suo output viene riusato per costruire stringhe JS single-quoted dentro attributi
onclick="..." — con un nome cliente contenente un apostrofo il gestore onclick si rompe
e può essere dirottato.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Scripts.html:2879
xss
calEsc() usato per costruire l'onclick degli eventi calendario escapa solo backslash e
apice singolo, non le virgolette doppie, mentre viene inserito dentro un attributo
onclick="..." delimitato da doppi apici.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Styles.html:886
css-responsive
Le regole responsive per `.filters` impostano `grid-template-columns` ma `.filters` è
definito con `display: flex` (riga 203-209) e nessuna media query lo cambia in grid: la
regola è morta e il layout a 2/1 colonne su mobile non si applica mai.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
dashboard.html:155
accessibility
Le intestazioni di colonna ordinabili sono `` con solo `onclick` (nessun `tabindex`,
`role="button"` o gestore da tastiera) e tutte le modali (`modal-overlay`) non hanno
`role="dialog"`/`aria-modal`, non si chiudono con Esc e non gestiscono il focus:
funzionalità chiave della dashboard non sono operabili da tastiera o screen reader.
Scenario di fallimento ▸
LOW
NON VERIFICATO
dashboard.html:504
config-duplication
L'indirizzo email di destinazione per l'invio forzato a Hasslacher è scritto come testo
statico nel modale di conferma invece di essere letto dalla configurazione condivisa,
per cui un cambio di destinatario in Config.gs non si riflette nel testo di avviso
t
t
ll'
t
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
15/18
mostrato all'operatore.
Scenario di fallimento ▸
Frontend (logica JS)
10
HIGH
NON VERIFICATO
Scripts.html:2183
xss
escapeHtml() non esclude l'apice singolo, ma è usato ovunque per interpolare dati
ordine dentro attributi onclick delimitati da apici singoli: un valore con un ' rompe la
stringa JS e inietta HTML/JS arbitrario.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
Scripts.html:2679
stale-state
La cache della vista Calendario (CalState.cache) non viene mai invalidata dopo una
modifica ordine (data/indirizzo/annulla/notifica CSV) fatta dal dettaglio aperto dal
calendario stesso: la griglia resta con dati vecchi finché non si esce e rientra dal tab
Calendario.
Scenario di fallimento ▸
HIGH
NON VERIFICATO
Scripts.html:144
date-parsing
Il filtro "data a" (dateTo) confronta con new Date(stringa) a mezzanotte locale, ma le
date ordine sono ancorate a mezzogiorno (convenzione server nota): un ordine
consegnato proprio nel giorno selezionato come limite superiore viene
silenziosamente escluso dai risultati filtrati.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Scripts.html:1588
state-corruption
_patchOrderInState() aggiorna lo stato client cercando l'ordine per solo
Nr_Ordine_Cliente in TUTTE le sezioni (pellet/edil/legna, aperti/storico/archivio),
senza filtrare per tipo ordine: se due ordini di tipo diverso condividono lo stesso
riferimento cliente, la modifica dell'uno sporca silenziosamente la vista dell'altro.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Scripts.html:2046
logic-error
In globalSearch()/openFromGlobalSearch() il tipo ordine viene dedotto solo
controllando 'EDIL' in BC_Status, senza il controllo sul codice articolo LEG/TRON usato
invece in orderToSection(): gli ordini Legna trovati con la ricerca globale vengono
sempre trattati come 'pellet'.
Scenario di fallimento ▸
▸
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
16/18
MEDIUM
NON VERIFICATO
Scripts.html:117
main-temp-inconsistency
Il filtro e il menu a tendina "Settimana" confrontano/raccolgono order.Settimana
grezzo, mentre la tabella lo mostra sempre passato da normalizeWeek(); se main e
temp scrivono la settimana in formati diversi (es. "14/26" vs "14/2026" — da cui
l'esistenza stessa di normalizeWeek), il filtro produce doppioni nel menu e non
seleziona tutti gli ordini della stessa settimana.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Scripts.html:1015
race-condition
confirmCancel() è l'unica delle quattro azioni di modifica a non avere il guard anti-
doppio-submit (window._xxxSubmitting) presente invece in confirmDateChange,
confirmAddressChange e confirmCSVNotify: un doppio click sul bottone "Conferma"
del modal di annullamento invia due apiCancelOrder() concorrenti.
Scenario di fallimento ▸
MEDIUM
NON VERIFICATO
Scripts.html:2685
xss
calEsc() (usato solo negli eventi della vista Calendario) esegue l'escape inverso
rispetto a escapeHtml: protegge la stringa JS tra apici singoli ma non il doppio apice
dell'attributo onclick che la contiene, quindi un valore con " rompe l'attributo HTML.
Scenario di fallimento ▸
LOW
NON VERIFICATO
Scripts.html:846
dead-code-logic-mismatch
renderOrderDetail() accetta e documenta il parametro isStorico come ciò che decide
se mostrare i pulsanti di modifica ("mostra pulsanti modifica solo per ordini gestiti"),
ma il corpo della funzione non lo referenzia mai: canModify dipende solo da NOTE e
data, non dalla sezione/foglio di provenienza.
Scenario di fallimento ▸
LOW
NON VERIFICATO
Scripts.html:940
memory-leak
Ogni apertura del dettaglio di un ordine EDIL/Legna crea un nuovo oggetto globale
window['articles_' + Date.now()] che non viene mai eliminato, accumulandosi
indefinitamente in memoria per tutta la durata della sessione del browser.
Scenario di fallimento ▸
Idee di miglioramento
Cinque assi di intervento ricavati incrociando i problemi trovati con la storia del
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
17/18
Cinque assi di intervento, ricavati incrociando i problemi trovati con la storia del
progetto in SAL.md. Non sono passate per una verifica avversariale dedicata: sono
una sintesi diretta, con impatto stimato.
AFFIDABILITÀ & COERENZA DATI
Scrittura verificata come default, non
eccezione
Rendere
updateFieldsVerified/updateAllRowsVerified il
percorso standard di Database.gs invece di
varianti opt-in: updateNote, BCLogger.flush, i
tre rami ERRORE di notifyDeliveryCSV e le
scritture dei test erediterebbero
automaticamente la protezione rilettura+retry
che oggi copre solo 4 flussi.
IMPEGNO: MEDIO
bulkConfirmFromCSV: scrivere solo i
campi cambiati
Rileggere i valori freschi al momento della
conferma e scrivere solo le colonne
effettivamente modificate
(NOTE/Data_Consegna/settimana/RESP),
invece di riscrivere l'intera riga presa da uno
snapshot cache di 3 minuti prima. Elimina la
sovrascrittura silenziosa di modifiche
concorrenti trovata indipendentemente da 3
angolazioni diverse (database-cache, order-
service, api-endpoints).
IMPEGNO: MEDIO-ALTO
Lock espliciti sulle sequenze read-
modify-write
LockService.getScriptLock() attorno a
BCLogger.flush (append log),
StoricoModifiche._getSheet (creazione foglio al
primo uso) e
addToErrorLog/sendErrorSummaryEmail
(Script Properties), le tre race condition trovate
in questa revisione.
IMPEGNO: BASSO
Instradare la scrittura su isEdil ||
isLegna, non solo isEdil
Allineare changeDate/changeAddress alla
logica già corretta di cancelOrder, così un
ordine Legna con più righe/articoli viene
aggiornato su tutte le righe e non solo sulla
prima trovata da Database.gs.
IMPEGNO: BASSO
TEMP_HEADERS allineato ai campi
che OrderService scrive davvero
Aggiungere 'RESP modifica Manuale' e
'Indirizzo_Modificato' (e verificare altri campi)
alle 27 colonne che syncOpenPelletOrders
ricrea, per chiudere i falsi fallimenti di
changeDate/changeAddress sugli ordini ancora
aperti.
IMPEGNO: BASSO
28/08/26, 06:14
Dossier SD Web Dashboard
https://claude.ai/code/artifact/fd427fe6-dad3-4d1f-b0de-cf1a306f38fc
18/18
