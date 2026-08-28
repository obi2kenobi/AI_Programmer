Analisi e Revisione del Progetto — Agosto 2026
Report prodotto tramite revisione automatizzata multi-agente (12 analisi parallele, una per area funzionale + 3 trasversali: sicurezza, coerenza business-logic vs dati reali, idee di sviluppo). Nessun file di codice è stato modificato durante l'analisi: questo documento è il solo output.

Ambito coperto: tutti i 27 file .gs, trimestri.js, analisi_anomalie.py, appsscript.json, la documentazione di business/architettura, e i due CSV 2024 usati come dato di verità (regola progetto #9).

Come leggere questo documento: i problemi sono divisi in Critici / Alti / Medi / Bassi in base all'impatto potenziale su dati contabili o sicurezza. Alcuni punti richiedono una conferma del dominio (rule #7/#11 di CLAUDE.md: "se non chiaro, chiedere") — sono segnalati esplicitamente con [DA VALIDARE COL DOMINIO].

0. Riepilogo per chi ha poco tempo
#	Problema	Gravità	Azione
1	Credenziali Azure AD/Business Central reali committate in config.gs (da febbraio 2026, già pushate su GitHub)	CRITICA	Ruotare il secret subito in Azure AD
2	I codici conto C/G hardcoded nel codice non corrispondono ai conti nel CSV 2024	CRITICA	Verificare col dominio: rinumerazione piano dei conti 2024→2025?
3	Riconciliazione vendite/acquisti fa matching solo per riferimento documento, mai per importo	CRITICA	Aggiungere verifica soglia importo
4	db-riporto.gs: regressione recente, apre il foglio per posizione invece che per nome	CRITICA	Ripristinare getSheetByName
5	Filtro manodopera (Entry_Type/Location) applicato solo ai materiali, non alla capacità	ALTA	Verificare col dominio e allineare
6	Math.abs() applicato ciecamente ai saldi C/G in tutto contabilita.gs	ALTA	Loggare/segnalare quando il segno è anomalo prima di forzarlo
7	Nessun LockService in tutto il repo — scritture concorrenti non protette	ALTA	Aggiungere lock sulle funzioni di scrittura DB
8	Nessun meccanismo di notifica errori (mail/alert) in tutta la pipeline	ALTA	Wrapper con MailApp sui trigger/step critici
9	Media Euribor calcolata silenziosamente su mesi parziali se la BCE non risponde	ALTA	Bloccare o segnalare esplicitamente il dato incompleto
10	pct_() in bilancino-sheet.gs nasconde il segno negativo nelle percentuali	ALTA	Rimuovere Math.abs dal numeratore
Il dettaglio completo segue, organizzato per area del codice.

1. Sicurezza
1.1 [CRITICA] Credenziali reali hardcoded e committate — config.gs:19-25
setupCredentials() contiene, in chiaro nel codice sorgente (non il placeholder INSERIRE_QUI previsto dal commento del file stesso), le credenziali OAuth2 client-credentials verso Business Central Production:

BC_TENANT_ID:       [valore reale presente in config.gs riga 20]
BC_CLIENT_ID:       [valore reale presente in config.gs riga 21]
BC_CLIENT_SECRET:   [REDATTO IN QUESTO REPORT — valore reale presente in config.gs riga 22]
Non riportiamo qui il valore reale del secret per evitare di aggravarne l'esposizione pubblicandolo in un ulteriore commit; è comunque già leggibile in config.gs e nella history git.

Confermato presente nella history git almeno dal commit 3039eea (16 febbraio 2026, PR #8) e pushato su origin (github.com/obi2kenobi/Associazione-Energikal). Chiunque abbia accesso in lettura al repository (o alla sua history) può autenticarsi come questa applicazione Azure AD e leggere/modificare i dati commerciali reali in Business Central.

Fix immediato:

Ruotare il client secret in Azure AD (Entra ID) — indipendente da qualsiasi intervento sul codice.
Ripristinare i segnaposto INSERIRE_QUI in config.gs.
Valutare la pulizia della history git (git filter-repo/BFG) per rimuovere il secret dai commit passati — operazione distruttiva, da fare solo su richiesta esplicita.
Aggiungere un hook pre-commit (gitleaks/git-secrets) per prevenire ricorrenze.
1.2 [ALTA] Nessun LockService in tutto il repository
Pattern identico ripetuto in 6 file (db-utilizzate.gs:52-94, db-riporto.gs:37-75, db-report-log.gs:63-68, db-euribor.gs:57-66, db-conti-cg.gs:48, db-consuntivi.gs:36): tutti leggono getLastRow() e scrivono su ultimaRiga+1 senza alcun lock. Due esecuzioni concorrenti (rilancio manuale mentre gira un trigger, o due utenti che chiudono lo stesso trimestre) possono scrivere sulla stessa riga o duplicare dati, senza errore visibile.

Fix: avvolgere le funzioni di scrittura con LockService.getScriptLock().waitLock(30000) in try/finally.

1.3 [MEDIA] Logging parziale del token OAuth — api.gs:142
Logger.log('Token ottenuto: ' + token.substring(0, 20) + '...') — i log Apps Script sono leggibili da chiunque abbia accesso al progetto script; anche un frammento di JWT riduce l'entropia da forzare. Fix: loggare solo token.length o un booleano di successo.

1.4 [BASSA] ID sensibili hardcoded come variabili globali
ID di spreadsheet/cartelle Drive in chiaro nel codice (db-conti-cg.gs:12, db-riporto.gs:11, db-utilizzate.gs:9). Non sono segreti in senso stretto (l'accesso resta governato dai permessi di condivisione), ma sono identificativi di sistema esposti anche nei messaggi di errore, utili a un attaccante per targeting mirato una volta ottenuto accesso.

Punti verificati e puliti: nessun doGet/doPost nel repo (nessun endpoint web esposto pubblicamente — api.gs/endpoints.gs sono client interni verso BC, non server); nessun eval()/new Function() da input esterno; nessun uso di SpreadsheetApp.getActiveSpreadsheet() (sempre openById esplicito); UrlFetchApp.fetch gestisce correttamente gli errori HTTP con muteHttpExceptions + controllo esplicito del codice.

2. Motore contabile (contabilita.gs, costi-engine.gs)
2.1 [CRITICA] Codici conto C/G non corrispondono ai dati reali 2024 [DA VALIDARE COL DOMINIO]
I conti hardcoded in contabilita.gs:12-21 (es. CONTO_VENDITA_PELLET='7008100001', CONTO_ACQUISTO_PELLET='7601000002') e nella guida di business non corrispondono ai conti effettivamente usati nel CSV reale 2024: lì la vendita pellet è sul conto 7000000000, l'acquisto su 7600000000, le provvigioni su 7647000002 (non 7610000010), la Penale su 7600000010 (non 7610000002). Se il piano dei conti non è stato rinumerato tra 2024 e 2025, un rilancio del report su un trimestre 2024 con i conti attuali produrrebbe saldo zero ovunque, senza errore.

Conseguenza aggravante: il test testBilancinoQ1_2024_CSV() (costi-engine.gs:382-483) non chiama affatto le funzioni reali di estrazione (estraiSaldiVendite_ ecc.), ma incolla a mano i numeri del CSV — quindi la regola progetto #9 ("ogni funzione testata con dati reali") di fatto non copre le funzioni di estrazione conti, proprio dove servirebbe di più.

Da chiedere all'utente: il piano dei conti è stato rinumerato dopo il 2024? Se sì, serve un test con dati reali 2025 (o un conto storico dei conti per anno); se no, è un bug attivo da correggere subito.

2.2 [ALTA] Math.abs() applicato ciecamente ai saldi — contabilita.gs:75-78,112-117,150-153,217,346-348
Ogni saldo C/G estratto viene forzato a valore assoluto assumendo che il segno sia sempre quello "atteso". Scenario: una nota di credito fornitore molto grande che rende il saldo netto di un conto acquisto negativo (un credito, non un costo) verrebbe trasformata in un costo positivo — l'opposto della realtà economica — senza alcun log di anomalia.

Fix: loggare un warning quando il segno del saldo grezzo non corrisponde a quello atteso per quel tipo di conto, prima di applicare Math.abs().

2.3 [ALTA] Somme non tipizzate — rischio concatenazione stringa
contabilita.gs:52,255,347-348,403,486: pattern saldo += m.Amount || 0 senza conversione esplicita a Number. Se BC restituisse anche un solo campo Amount come stringa, si otterrebbe concatenazione ("01234.56") invece di somma, corrompendo il totale silenziosamente. Fix: normalizzare sempre con Number(m.Amount) || 0 e loggare se isNaN.

2.4 [ALTA] estraiRimanenzeBIOC non applica il filtro "giacenza positiva" al totale
contabilita.gs:324-354 (usato per il totale "Rimanenze Finali" nel bilancino) somma tutti i movimenti ILE senza verificare la quantità netta per articolo, mentre estraiDettaglioRimanenzeBIOC (righe 410-412) applica il filtro quantità>0 solo per il foglio di dettaglio. Le due fonti possono non tornare: un articolo completamente venduto ma con residuo di costo per arrotondamenti contribuisce al totale bilancino senza comparire nel dettaglio.

2.5 [ALTA] estraiFatturatoTotaleGC non usa la C/G, in contraddizione con la guida
contabilita.gs:245-260 calcola il fatturato totale Gruppo Camarlinghi (denominatore Formula K) sommando solo le fatture di vendita testata (PS_PowerBI_112_Posted_Sales_Invoice), escludendo le note di credito — mentre il fatturato BIOC usato come base K deriva dalla C/G, che le NC le include già. Numeratore e denominatore della stessa Formula K sono quindi costruiti con criteri disomogenei.

2.6 [MEDIA-ALTA] Alert Euribor documentato ma non implementato
costi-engine.gs:59-66: la guida di business (§9.4) dichiara che se il tasso esce dal range contrattuale 1,95%-2,95% "il sistema genera un alert", ma nel codice non esiste alcuna logica di segnalazione — la funzione ritorna solo {tasso, importo}, applicando il tasso comunque fuori range senza avvisare nessuno.

2.7 [MEDIA] Default silenziosi su voci consuntivi/K
costi-engine.gs:108-113,138-141: una voce con importo mancante o non numerico contribuisce silenziosamente 0 al totale, senza log né eccezione — in contraddizione col principio di guida "nessun valore è frutto di stima".

2.8 Violazioni regola "funzioni corte" (#12 CLAUDE.md)
calcolaBilancino (costi-engine.gs:95-246, ~150 righe) cumula 7 blocchi di calcolo distinti. Da spezzare per blocco (valore produzione, costo venduto, Formula K, costi fissi, oneri finanziari, conguaglio).

3. Riconciliazione e quadratura
3.1 [CRITICA] Matching senza verifica importo → falsa quadratura — riconciliazione.gs:161-176
Un gruppo vendite viene marcato "riconciliato" solo perché esiste un acquisto con lo stesso Your_Reference — totaleVendita e totaleAcquisto vengono calcolati ma mai confrontati. Un abbinamento con importi completamente diversi (riferimento duplicato/errato) risulta comunque "riconciliato" e sparisce dal foglio Non Riconciliate: è l'esatto rischio "quadratura falsamente positiva". Conseguenza a cascata: l'acquisto abbinato in modo errato viene incluso in protocolliDaConsumare (riconciliazione.gs:183-184) ed escluso dai trimestri successivi, propagando l'errore.

Fix: dopo il match per riferimento, confrontare gli importi con una soglia assoluta+percentuale (stessa logica già usata in generaEsitoQuadratura_) e instradare gli scostamenti oltre soglia in una categoria "riconciliato con anomalia", escludendoli dal consumo protocolli fino a verifica.

3.2 [ALTA] Scelta acquisto arbitraria quando il riferimento non è univoco
riconciliazione.gs:131-159: quando più acquisti condividono lo stesso Your_Reference, viene scelto il primo non ancora usato nell'ordine restituito da OData, non per importo/data più vicini. Se il riferimento non è univoco, l'abbinamento può essere casuale.

3.3 [ALTA] Soglie testo/colore incoerenti in quadratura-sheet.gs
Il testo di allarme (righe 65-83) usa una soglia percentuale sul saldo C/G, il colore della riga (righe 209-222) usa una soglia a valore assoluto fisso (100€). Esempio: cg=100, delta=50 (50%) → testo "ALLARME: scostamento significativo" ma colore giallo (non rosso), perché 50<100. Chi legge solo il colore sottovaluta un vero allarme.

3.4 [BASSA] Nessuna validazione del contratto di segno su nc in calcolaQuadratura
Il commento dichiara che nc deve arrivare "già negativo" ma non c'è alcun controllo/assert.

4. Vendite, acquisti, note di credito
4.1 [ALTA] Filtro Location asimmetrico tra vendite e NC vendite — vendite.gs:48 vs note-credito.gs:23-27
Le vendite BIOC filtrano su Location_Code in (SD, PRINCIPALE); le NC vendite BIOC filtrano invece su tutte le location (dichiarato esplicitamente nel commento). Se esiste una NC BIOC da una location diversa, viene sottratta dal totale ricavi anche se la vendita originale non è mai stata inclusa — ricavi netti sottostimati senza traccia.

4.2 [ALTA] Enrichment header silenzioso senza log degli orfani
vendite.gs:89, note-credito.gs:92: var h = headers[r.Document_No] || {}. Righe che non trovano il proprio header restano con yourReference:'' senza alcun log — poiché Your_Reference è il perno della riconciliazione (§3.1), queste righe finiscono silenziosamente in "vendita senza acquisto", mascherando un problema di integrazione come mancanza dati.

4.3 [MEDIA] Campi numerici senza fallback, confermato dal CSV reale
vendite.gs:100-104: quantita, prezzoUnitario, importoRiga non hanno || 0. Il CSV reale conferma il rischio: due righe riconciliate hanno Prezzo Unitario vuoto in BC. Un consumatore che chiama .toFixed(2) su un valore null causa un'eccezione non gestita che interrompe l'estrazione a metà.

4.4 [MEDIA] Criterio di competenza incoerente tra vendite e NC vendite
vendite.gs:96 usa sempre Posting_Date di riga; note-credito.gs:99 preferisce quello di header. Se riga e header di una NC avessero date diverse, vendita e NC finirebbero in trimestri di competenza diversi.

4.5 [MEDIA] Filtro location incoerente tra domini simili (whitelist vs blacklist)
vendite.gs:48 usa whitelist esplicita (SD or PRINCIPALE); le rimanenze (contabilita.gs:337,382) usano blacklist (ne 'SD'). Una terza location futura verrebbe esclusa dalle vendite ma inclusa nelle rimanenze, producendo magazzino non riconciliabile.

5. Manodopera, rimanenze, Allegato C
5.1 [CRITICA] Filtro Entry_Type/Location applicato solo ai materiali, non alla capacità [DA VALIDARE COL DOMINIO]
I due fix recenti in git ("filtra manodopera materiali per Entry_Type = Output", "per Location_Code = PRINCIPALE") sono stati applicati solo a estraiCostiManodoperaMateriali() (manodopera.gs:30-35). estraiCostiManodopera() (movimenti capacità, righe 85-88) filtra solo BIOC+data, senza Entry_Type/Location_Code — confermato anche in ARCHITETTURA-TECNICA.md. L'endpoint ENDPOINT_MOV_CAPACITA (endpoints.gs:291-310) non seleziona nemmeno questi campi, quindi non è oggi possibile applicare lo stesso filtro senza prima estendere il $select.

Da chiedere all'utente: il criterio Entry_Type/Location_Code ha senso di business anche sui movimenti di capacità (in BC standard le Capacity Ledger Entries non hanno Location Code)? Se sì, va esteso; se no, va documentato esplicitamente per non sembrare una dimenticanza.

5.2 [ALTA] Mismatch di segno tra dettaglio e totale manodopera materiali
manodopera.gs:67 applica Math.abs() solo al totale, mentre il dettaglio (riga 58) conserva il segno originale. Se gli Output hanno costo negativo in BC, la colonna di dettaglio somma a un valore negativo mentre la riga TOTALE mostra il valore assoluto — chi verifica sommando manualmente la colonna trova una discrepanza di segno.

5.3 [BASSA] Match cliente Brico fragile (substring)
allegato-c-sheet.gs:82-85: isBrico_ usa indexOf('BRICO') !== -1 — un futuro cliente con "BRICO" come sottostringa (es. "FABRICO SRL") verrebbe erroneamente incluso nell'Allegato C e nel calcolo pubblicità GDO.

6. Euribor, acconti, trimestri
6.1 [ALTA] Media Euribor calcolata silenziosamente su mesi parziali — euribor.gs:100-127
Se getEuribor3M ritorna null per un mese (errore BCE/rete), il mese viene scartato dall'array e la media si calcola dividendo per tassi.length (1 o 2 invece di 3), senza mai lanciare errore né segnalarlo visibilmente nei fogli — solo un Logger.log invisibile a chi non apre l'editor. Questo valore alimenta direttamente gli oneri finanziari nel bilancino.

Fix: se tassi.length < mesi.length, bloccare con errore esplicito o propagare un flag mediaParziale: true che i fogli sono obbligati a mostrare visibilmente.

6.2 [ALTA] Valori duplicati hardcoded nel foglio Euribor
euribor-sheet.gs:59-69: il foglio scrive come testo statico '1,9500%', '2,9500%', '2,1500%' invece di derivarli dalle costanti EURIBOR_ALERT_MIN/MAX/TASSO_BASE_ASSOCIAZIONE. Se una rinegoziazione contrattuale cambia le costanti nel codice, il foglio continuerebbe a mostrare i vecchi valori — il report diventa internamente incoerente senza errore.

6.3 [MEDIA] Nessun try/catch attorno alla fetch Euribor
euribor.gs:52-56: gestito solo il caso HTTP≠200, non le eccezioni di rete (timeout, DNS). Un'eccezione risale non gestita fino a generaReportBilancino, interrompendo l'intera pipeline con uno stack trace generico.

6.4 [MEDIA] Duplicazione della definizione dei trimestri, senza test di coerenza
La vera definizione dei confini trimestre è duplicata in vendite.gs:15-20 (stringhe date per filtri OData) ed euribor.gs:21-26 (array mesi numerici), oggi coerenti ma senza alcun test che lo verifichi. trimestri.js non contiene affatto logica di trimestre: sono 12 wrapper annuali (fino al 2026) che richiedono manutenzione manuale ogni anno — mancano già i wrapper 2027.

6.5 [BASSA] Confini range Euribor inclusivi/esclusivi non verificati [DA VALIDARE COL DOMINIO]
euribor.gs:139-141 usa </> stretti: un valore esattamente 1,95% o 2,95% non genera alert. Il contratto è disponibile solo come immagini JPG (Contratto Energikal/), non verificabile testualmente in questa analisi.

7. Layer di persistenza (db-*.gs)
7.1 [CRITICA] Regressione in db-riporto.gs:21-23
Un commit recente (7d5388a) ha sostituito l'apertura per nome del foglio (getSheetByName, come fanno ancora gli altri 5 moduli db-*) con l'apertura del primo foglio per posizione (ss.getSheets()[0]). DB_RIPORTO_HEADER è rimasto nel codice ma non viene più scritto/validato da nessuna parte (dead code). Se in futuro viene aggiunta o riordinata una scheda nello spreadsheet condiviso "saldi conguaglio", il riporto del saldo negativo trimestrale verrebbe letto/scritto silenziosamente nel posto sbagliato.

Fix: ripristinare getSheetByName('Riporto') con creazione/validazione dell'header, come negli altri 5 moduli.

7.2 [ALTA] Scritture non idempotenti — righe duplicate su riesecuzione
db-riporto.gs:70-78, db-euribor.gs:54-68, db-report-log.gs:60-78: nessuna verifica che esista già una riga per trimestre/anno prima dell'append (solo db-utilizzate.gs deduplica). Se generaReportBilancino() viene rilanciata per correggere un errore, si accumulano righe duplicate, inquinando l'audit trail (la lettura prende sempre l'ultima occorrenza, quindi il calcolo "si autocorregge" ma la riga vecchia resta a sporcare lo storico).

7.3 [ALTA] Buco silenzioso se la pipeline fallisce prima dell'ultimo step
report.gs:238-246: il salvataggio del riporto avviene solo all'ultimo step (16) dopo aver estratto tutti i dati. Se uno step intermedio fallisce, salvaRiportoPrecedente non viene mai chiamata; il trimestre successivo legge "nessun riporto" — indistinguibile da un saldo effettivamente pari a zero.

7.4 [MEDIA] Nessuna validazione header nei 6 moduli db-*
Un rinominare/riordinare manuale delle colonne passa inosservato e disallinea i dati letti per indice.

7.5 [BASSA] Pattern "apri/crea foglio" incoerente tra i 6 moduli
db-conti-cg.gs lancia eccezione se il foglio manca, db-consuntivi.gs ritorna silenziosamente [], gli altri auto-creano con header, db-riporto.gs (dopo la regressione) non fa né l'uno né l'altro.

8. Fogli di output (Bilancino, Liquidazione, Report)
8.1 [ALTA] pct_() nasconde il segno negativo — bilancino-sheet.gs:308-311
return (Math.abs(valore) / Math.abs(base) * 100).toFixed(3) + '%';
Usato anche per UTILE ASSOCIAZIONE e GUADAGNO LORDO. Se in un trimestre debole l'utile diventasse negativo, la colonna Importo mostra correttamente il segno meno, ma la colonna % mostra comunque un valore positivo — il numero negativo appare positivo in percentuale.

Fix: non applicare Math.abs al numeratore.

8.2 [ALTA] "Guadagno Lordo" calcolato sulla base sbagliata
bilancino-sheet.gs:50,83,135 riusa baseFatturato per tutte le percentuali, ma BILANCINO-GUIDA-BUSINESS.md (§4.3, §16) definisce esplicitamente il Guadagno Lordo come percentuale del valore della produzione, non della base fatturato — sono due basi diverse che producono percentuali diverse (verificato: 15,2% atteso da guida vs 15,43% prodotto dal codice sugli stessi dati).

Fix: passare b.valoreProduzione come base a pct_() per la riga Guadagno Lordo.

8.3 [ALTA] Pubblicità GDO non usa la fonte C/G dichiarata come unica verità [DA VALIDARE COL DOMINIO]
La guida (§11.1) dichiara che il bilancino usa esclusivamente i saldi C/G perché "le fatture singole potrebbero non coprire il 100% del saldo". Ma la Pubblicità GDO (costi-engine.gs:161) si basa su fatturatoBrico, calcolato sommando le righe vendita riconciliate (allegato-c-sheet.gs:145-163) — proprio la fonte che la guida segnala come potenzialmente incompleta — e non sottrae mai le NC vendita verso clienti Brico.

Nota dati: nel CSV Q4 2024 la Pubblicità GDO implica un fatturatoBrico superiore al fatturato netto BIOC totale del trimestre — matematicamente impossibile con la regola "1,50% trimestrale" dichiarata, e coincide col trimestre con un "Premio clienti... solo Q4 annuale": suggerisce che nel 2024 questa voce fosse calcolata su base annuale/cumulativa, diversamente da guida e codice attuali.

8.4 [MEDIA] Calcolo duplicato tra costi-engine.gs e bilancino-sheet.gs
bilancino-sheet.gs:121 ricalcola totPropFissi autonomamente invece di leggerlo da calcolaBilancino() (che lo calcola già ma non lo espone). Se in futuro si aggiunge una quarta voce proporzionale fissa in un solo punto, i due fogli divergerebbero silenziosamente.

8.5 [MEDIA] Valori negativi/zero nascosti nel dettaglio Formula K
bilancino-sheet.gs:110: v.importoAzienda > 0 ? v.importoAzienda : '' — un costo negativo reale (storno) o zero resta indistinguibile da "dato mancante".

8.6 [MEDIA] "Formattazione per stampa" non imposta un'area di stampa reale
bilancino-sheet.gs:257-260, liquidazione-sheet.gs:167-170: Range.activate() seleziona solo temporaneamente le celle durante l'esecuzione, non configura l'area di stampa persistente in Google Sheets. Il commit "Migliora formattazione per stampa" lascia intendere un effetto che di fatto non esiste (solo setHiddenGridlines è reale).

8.7 [BASSA] Esistenze iniziali non ereditano un override manuale del trimestre precedente
contabilita.gs:434-456: estraiRimanenzeTrimestre() ricalcola sempre le esistenze iniziali da BC, ignorando un eventuale override manuale usato nel bilancino precedente (previsto da ARCHITETTURA-TECNICA.md §14.3 per quando l'inventario BC non è affidabile) — possibile discontinuità silenziosa tra trimestri.

9. Script Python (analisi_anomalie.py)
Nota preliminare: lo script non usa pandas né legge direttamente i CSV di riferimento — fa parsing euristico di un export RTF (anomalie.rtf) per trovare vendite/acquisti non riconciliati. Eseguito sui dati attuali: nessun errore runtime, conteggi coerenti col docstring.

9.1 [CRITICA] Allineamento campi basato su euristiche di stringa fragili
analisi_anomalie.py:44-127: il numero di campi per record è dedotto da pattern come field.startswith('PELL.') o "10 cifre o 25OV", non da un delimitatore strutturale. Un futuro codice articolo che non inizia per "PELL." sfaserebbe silenziosamente tutti i campi successivi (Qty dove ci si aspetta Description, ecc.), senza errore.

9.2 [MEDIA] parse_amount non gestisce formati alternativi
Riga 133-135: assume sempre formato USA, nessun try/except, nessuna gestione di importi negativi tra parentesi (tipici delle NC) — crash certo se un futuro export contiene una nota di credito.

9.3 [MEDIA] Encoding dichiarato vs usato
Il file dichiara \ansicpg1252 ma viene aperto con encoding='latin-1' — quasi identico ma non uguale nel range 0x80-0x9F (es. il simbolo €): corruzione silenziosa del testo su un futuro export con caratteri non-ASCII.

9.4 [MEDIA] Match parziali potenzialmente duplicati e senza soglia di confidenza
Righe 254-269: substring e reverse-substring sono controlli indipendenti sulla stessa coppia, che può essere contata due volte, gonfiando il conteggio "match parziali" mostrato.

9.5 [BASSA] Path hardcoded, nessun argparse; parse_date incassa eccezioni senza log
10. Config, API, Endpoints (oltre al punto 1.1)
10.1 [ALTA] Cache token OAuth non invalidata alla rotazione credenziali
api.gs:21-47: la cache usa una chiave fissa indipendente dalle credenziali correnti. Dopo una rotazione del secret (es. in risposta al punto 1.1), un token precedente resta valido in cache fino a 55 minuti, ritardando la verifica che la nuova configurazione funzioni.

10.2 [MEDIA] Validazione credenziali parziale
config.gs:38,71-74: solo BC_TENANT_ID viene verificato da isConfigured()/getConfig(); se solo il client secret venisse rimosso per errore, il sistema non lo segnalerebbe con un messaggio chiaro.

10.3 [MEDIA] Nessun retry/backoff su errori transitori BC
api.gs:94-106 (bcGetAll): un errore 429/503 a metà paginazione fa perdere tutti i record già accumulati, senza retry né log di avanzamento.

10.4 [BASSA] Codice morto disallineato dall'architettura reale
endpoints.gs:416-448: tre funzioni (buildFilterVenditeBIOC, buildFilterAcconti, buildFilterInventario) non richiamate da nessun altro file — buildFilterAcconti implementa persino un criterio diverso (filtro per fornitore) da quello realmente in uso per gli acconti (filtro per conto C/G).

11. Violazioni sistemiche della regola "funzioni corte" (#12 CLAUDE.md)
Riscontrate in quasi ogni file analizzato, tra le più significative: costruisciRigheBilancino_ (~110 righe), calcolaBilancino (~150 righe), riconciliaVenditeBIOC (~85 righe), estraiVenditeBIOC (~76 righe), formattaBilancino_ (~76 righe), leggiContiCG_ (~69 righe), scriviSezioneCapacita_ (~51 righe), testBilancinoQ1_2024_CSV (~113 righe). Pattern comune: mescolano più responsabilità (fetch + calcolo + formattazione) in un'unica funzione — la scomposizione già presente in note-credito.gs (header/mappatura/estrazione separati) è un buon modello di riferimento da replicare negli altri moduli.

12. Idee di miglioramento (consolidate)
Qualità del codice
Helper condivisi per i fogli di output (sheet-utils.gs): formattazione, stile sezione/totale/risultato oggi duplicati quasi identici in 9 file *-sheet.gs.
Sostituire lo string-matching su etichette italiane (isSezione_, isTotale_) con un flag esplicito {tipo: 'sezione'|'totale'|'risultato'} nell'oggetto riga — oggi rinominare una voce rompe silenziosamente la formattazione.
Estendere la copertura dei test con dati reali 2024 (regola #9) anche a riconciliazione, vendite, manodopera, db-riporto — oggi solo calcolaBilancino() è verificato end-to-end, e persino quello bypassando l'estrazione reale (§2.1).
Spezzare sistematicamente le funzioni sopra le 40 righe elencate al punto 11.
Centralizzare le costanti contrattuali (percentuali, soglie Euribor, tariffe manodopera) oggi sparse tra costi-engine.gs, euribor.gs e fogli esterni.
Architettura
Aggiungere LockService centralizzato in un helper comune per tutte le funzioni salva* sui 6 moduli db-*.
Funzione di upsert condivisa (cerca riga per trimestre+anno prima di accodare) per eliminare la non-idempotenza descritta al punto 7.2.
Separare estrazione dati grezzi (fetch BC) da aggregazione/calcolo, oggi mescolate in contabilita.gs/manodopera.gs.
Valutare un meccanismo di batching/streaming se il volume dati cresce oltre la finestra attuale (rischio quota/tempo esecuzione GAS).
Robustezza operativa
Wrapper eseguiConNotifica_(fn) con MailApp.sendEmail per segnalare fallimenti di pipeline — oggi MailApp/GmailApp non compaiono mai nel repo.
Scrivere in db-report-log anche i run falliti/interrotti (stato "ERRORE"), per rendere visibile il buco descritto al punto 7.3.
Validare esplicitamente trimestre/anno in ingresso a generaReportBilancino.
Hook pre-commit per secret scanning (gitleaks).
Funzionalità future
Dashboard multi-trimestre/anno basata sui dati già raccolti in db-report-log.gs.
Notifiche automatiche su anomalie già calcolate ma solo scritte nei fogli (match rate basso, quadratura fuori soglia, Euribor fuori range).
Export automatico PDF/Excel a fine pipeline per il commercialista.
Storicizzazione comparativa multi-anno oltre il 2024.
Processo di sviluppo
CI che misura la lunghezza delle funzioni (regola #12) e fallisce il check se superata.
Job CI che esegue il test CSV 2024 automaticamente (oggi manuale dall'editor GAS) — richiede estrarre la logica di calcolo in forma testabile fuori da GAS (es. con clasp).
Adozione esplicita di clasp per allineare l'editor GAS live con la history git.
13. Domande aperte da validare col dominio
Prima di intervenire sul codice, le seguenti domande vanno poste a chi conosce il dominio (regola CLAUDE.md #7/#11):

Il piano dei conti C/G è stato rinumerato tra il 2024 e oggi? (§2.1 — determina se è un bug attivo o solo un test non rappresentativo)
Il filtro Entry_Type=Output/Location_Code=PRINCIPALE ha senso di business anche sui movimenti di capacità (manodopera), o è specifico ai soli materiali? (§5.1)
I limiti contrattuali Euribor (1,95%/2,95%) sono inclusivi o esclusivi? (§6.5 — il contratto è solo in immagini JPG, non verificabile testualmente)
Le NC vendite BIOC devono davvero applicarsi a "tutte le location" come dichiarato, o è una svista rispetto al filtro delle vendite originarie? (§4.1)
La Pubblicità GDO nel 2024 era calcolata su base trimestrale o annuale/cumulativa? Il dato Q4 2024 sembra incoerente con la regola trimestrale attuale. (§8.3)
Report generato tramite revisione multi-agente automatizzata; ogni punto cita file:riga per verifica diretta. Nessun fix è stato applicato — in attesa di priorità e conferme dal dominio prima di procedere, come da regole di lavoro del progetto.