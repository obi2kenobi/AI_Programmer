# 2026-09-14 — Magazzino_Treviso: la settimana dello specchio — dalla regola della merce alla sonda ODA→DDT

**Autore**: sessione `glm/treviso-*` (ZCode/GLM) su Magazzino_Treviso, con un lungo
passaggio nel gemello Registrazione_Fatture_Acquisto. Mandato di Luca, cresciuto giro dopo
giro: capire come si registrano i carichi in BC («per delineare strategie»), fare la prova
generale della comunicazione all'ufficio, predisporre la registrazione, poi — dopo la call
col partner (Olsi/DATO-RIMOSSO) — i documenti dell'integrazione per entrambi i repo, una
giornata di collaudo dal vivo, e il censimento specchio. Il report copre l'11–14 settembre:
debiti **#248 → #371b**, di cui **undici giri in un solo giorno** (il 14), **6 PR** (#71–#76),
il cancello cresciuto da 1093 a **1454 attese**.

## Cosa ho usato

- **Il cancello a ogni giro**, e le sue lenti hanno morso più spesso mentre sbagliavo io
  che sul codice: la lente delle proprietà ha preteso la documentazione della proprietà
  nuova (`CARTELLA_FOTO_NC_ID`) nel libretto prima di lasciar passare; T3 ha preso
  `BcAttese.riduciTestata` inesistente mentre lo scrivevo; la lente degli endpoint ha
  preteso l'ordine **alfabetico** (Ocr prima di Oda — un ordine che non avevo scelto io);
  la lente del cancello-dichiarato ha preso il mio sed cieco che aggiornava due marcatori
  uguali (`# attese: 79` apparteneva a due banchi diversi).
- **Banco-prima + sabotaggio col verdetto**, su ogni giro: W49–W51 (il gesto che non si
  capiva), MA1–MA6 (le tre aree NC), W52–W53 (la casella e i grappoli), AK7–AK9 (le foto
  NC col nome `NC_<ODA>__<viaggio>_<voce>_<n>.jpg`), AN10 (il dubbio trilingue all'ufficio),
  OC1–OC6 (la sonda specchio). I sabotaggi sono stati presi tutti, con il valore atteso.
- **Il banco browser fuori dal cancello ma non fuori dal metodo**: il wrapper dei
  banchi browser (nel repo di progetto) dichiara il salto sul Mac di Luca (Chromium assente); io ho installato playwright-core in
  /tmp e puntato `CHROMIUM_BIN` al Chrome di sistema. **Il cancello resta verde su
  qualunque macchina, il banco gira a mano dove l'ambiente c'è** — il compromesso ha
  retto tutto il giorno senza mai lasciare le 82+ attese della schermata al buio.
- **Il vivo come ultima lente**, due volte decisivo: (1) il log del database letto per
  intero ha mostrato il falso negativo del destinatario — che era già **#293, chiuso da
  due giorni** (v. sotto); (2) il primo giro vero della sonda specchio ha stampato ogni
  ODA **tre volte** (merce+trasporto+assicurazione: tre righe, un ordine) con il banco
  verde, perché le mie fixture avevano una riga per ordine. OC6 l'ha chiusa al vivo.
- **Il ciclo sonda→log→analisi** come canale col vivo: le sonde non tornano niente al
  chiamante (#181), Luca le lancia dall'editor e incolla il log. Ha funzionato per la
  prova generale, per i giri di scarico e per la specchio — un canale a mano che vale più
  di un'API rotta (v. ostacolato).

## Cosa ho improvvisato

- **La riveduta dei documenti per un esterno, fatta sul codice**: Luca ha chiesto «tutti i
  dati corretti?» nei documenti per il partner. Riletti contro il sorgente, due errori
  veri: l'elenco dichiarava **due** entità BC su **tre** ( mancava `purchaseDocumentLines`,
  le righe d'ordine — la prima cosa che il partner aveva chiesto) e citava un filtro
  `Order_No eq` che non esiste (il confronto è a lettura). La lezione: chi scrive per un
  esterno ri-verifica ogni fatto citabile contro il codice, non contro la memoria — la
  «citazione-non-presidio» applicata ai documenti di confine.
- **Il «vai» che diventa verifica** (#368→#368b): la cura del falso negativo trovato nei
  log era già stata costruita (#293, stessi tre viaggi, trovata dal vivo due giorni prima);
  e la mia proposta era **più debole** di quella esistente (l'azienda ha più sedi: il nome
  solo non dice quale — il gesto umano di #293 è la forma giusta). Precisato e chiuso
  senza scrivere codice.
- **Il deliverable leggibile e scaricabile**: la mail al partner come testo + **un PDF
  unico** dei quattro documenti, generato con marked + Chrome headless print-to-PDF, con
  controllo a vista a campione sulle pagine. Il metodo non vietava il PDF: vietava di
  spacciarlo per guardato.
- **La risoluzione dei conflitti in sola-aggiunta**: tre PR aperte che appendono tutte in
  coda a DEBITI/SAL. Risolte fondendo il default dentro ogni ramo e **ordinando le righe
  per numero** — nessuna riga persa, l'ordine di merge dichiarato (#74→#72→#76).

## Cosa ha retto / ostacolato

**Ha retto:**

- **Le decisioni di dominio prese per misura pagano alla chiamata col partner**: la chiave
  `Vendor_Shipment_No` (misurata viva il 13/09) è stata confermata dal partner come chiave
  del prendi-righe — *lui* ha citato il campo che noi avevamo già in produzione. E il
  censimento specchio dà **29/30** carichi con la chiave piena: la catena regge.
- **Il registro che si legge con uno strumento**: `voce_etichetta` scritta al momento del
  record ha reso il redesign del catalogo NC (#367: tre macro aree, codici fusi)
  retrocompatibile gratis — le righe vecchie restano leggibili perché la loro etichetta fu
  scritta allora.
- **Il trigger a identità**: il primo giorno operativo, il log delle esecuzioni ha
  mostrato DATO-RIMOSSO autorizzata e idempotente (60/60 già presenti, zero doppioni) e il
  secondo trigger (DATO-RIMOSSO) sì in lettura ma senza permesso sul registro — preso leggendo
  il log, curato condividendo il foglio.
- **L'idempotenza per chiave** alla prima conferma vera: una conferma, due marche in
  ordine, sei secondi dal tap alla mail.

**Ha ostacolato:**

- **Miei, tutti al banco o al vivo**: `setAttribute('hidden','false')` nasconde comunque
  (l'attributo presente vale, il valore no); il primo verso della condizione dei grappoli
  mostrava tutto a riposo; la deduplica per ordine mancava (v. sopra); ho dichiarato 69
  attese su 68 reali contando una **riscrittura** come aggiunta; il sed sui marcatori ha
  colpito due banchi uguali. E la ricorrente degli ancori python non univoci.
- **`clasp run` è rotto su questo progetto** (NOT_FOUND dallo storage, in ogni modalità e
  su funzioni minime): l'esecuzione remota delle sonde resta il canale a mano
  editor→log→incolla. Dichiara il limite invece di fingere l'API.
- **La UI nuova di Gmail oppone resistenza ai clic guidati** (a11y con virtual DOM): il
  censimento della casella è passato per la casella di ricerca (set_value) e dai risultati
  letti dall'albero, senza aprire i thread. E il gate visivo degradato: il Read sui PNG
  torna solo URL CDN al sottoagente — controllo a vista fatto col modello di visione
  direttamente, dichiarato.
- **Il collo della catena è configurazione, non codice**: la consegna confermata ieri non
  è in BC perché `DESTINAZIONI_TREVISO` punta ancora all'indirizzo di test. Nessun giro
  di codice può chiudere quel cerchio: è un gesto di un minuto che aspetta l'umano.

## Proposta al canone

1. **«Il vivo è l'ultima lente, e conta il primo giro vero»**: una sonda nuova non si dice
   finita al banco verde — le fixture minime nascondono esattamente ciò che il vivo
   moltiplica (righe per documento, pagine, ripetizioni). Proposta: nel SAL di ogni sonda,
   una riga di «primo giro vero» col dato che il banco non aveva (qui: «tre righe per
   ODA»), prima di dichiarare il giro chiuso.
2. **«Il "vai" comincia con la verifica»**: prima di costruire la cura chiesta, si cerca
   se il difetto è già stato trovato e curato (grep sui DEBITI + git log). Qui il giro si
   è sciolto in una precisazione: il difetto era #293, chiuso da due giorni, con una cura
   più forte della proposta. Un «vai» che parte dalla ricerca risparmia giri e, peggio,
   cure deboli che sovrascrivono cure forti.
3. **«I documenti per un esterno si rileggono sul codice»**: ogni fatto citabile in un
   documento di confine (nomi di entità, filtri, numeri) si ri-verifica contro il
   sorgente prima dell'invio. È la famiglia della citazione-non-presidio, applicata dove
   l'errore non rompe un test ma una relazione.
4. **«Il dichiarato segue il conto reale, anche al ribasso»**: riscrivere un'attesa non è
   aggiungerla — il numero dichiarato va riletto dall'esecuzione dopo ogni giro (il mio
   69/68 l'ha preso la lente; che lo prenda sempre l'abitudine).

**E una non-proposta, dichiarata**: `clasp run` rotto, la UI di Gmail ostile ai clic
guidati, il CDN-only sulle immagini al sottoagente — specifiche di piattaforma di questa
sessione: stanno nei libretti dei progetti e qui solo come fatto, non come regola.
