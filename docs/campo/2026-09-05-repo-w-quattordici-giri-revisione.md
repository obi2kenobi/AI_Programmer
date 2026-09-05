# 2026-09-05 — REPO-W: quattordici giri di revisione sullo stesso codice

Autore: Luca + sessione Claude Code (remota). Repo: REPO-W (GAS+BC, fatture fornitore estere,
Fase 2). Seguito di `2026-09-03-repo-w-fatture-estere-fase2.md`.

Esito misurato: **~35 difetti** trovati e corretti (5 gravi, ~30 minori), di cui **9 introdotti
dalla sessione stessa** e tutti fermati prima della produzione; **quattro** strumenti di verifica
dove ce n'era uno; **quattro** domande di dominio poste una alla volta e trasformate in codice.
Verdetto finale: `45/45 banco Fase 2 · 9/9 sabotaggi · 64/64 test · 18/18 mutazioni · coerenza ok`.

Il mandato era: *«un ciclo di controllo qualità su tutto il codice alla ricerca di errori,
inesattezze e problemi SILENZIOSI»*, poi ripetuto sei volte su richiesta.

## Cosa ho usato

- **Lenti del canone**: `dev-critic`, `revisore-gas`, `famiglie-difetti.md`, `metodo.md`,
  `patterns/` (39 pattern ancorati), `tools/gas_qualita.py`, i sub-file dello specialista BC di
  `gas-agent`. Questi ultimi non hanno trovato niente ed è **dichiarato** nel commit: sono buone
  pratiche generiche, e tacere un'assenza è peggio che riportarla.
- **`/security-review`** (skill builtin), al 14° giro: **mai eseguita prima su questo codice**.
- **Strumenti costruiti qui**, tutti entrati in `.night-verify`: un controllo di coerenza statica
  (nomi in ombra, globali duplicate, chiamate a funzioni inesistenti, chiavi di configurazione
  fantasma, valori prodotti e mai letti, campi letti e non chiesti nel `$select`, censimento di
  raggiungibilità); un banco sintetico di 45 attese con 9 sabotaggi; 18 mutazioni sul codice vero
  più una meta-mutazione che verifica che la guardia esista ancora.
- **Voluto e NON c'era**: un modo di leggere il **codice vivo in produzione** da una sessione
  remota. Lo strumento di deploy sta sulla macchina dell'operatore; in quattordici giri il codice
  in produzione non è stato letto **nemmeno una volta**. Il canone dice *«il vivo è definitivo, mai
  un'ipotesi»* — qui è rimasto un'ipotesi per quattordici giri, e nessuna lente lo segnala.

## NON RAGGIUNGIBILE: l'installazione è ancora parziale (era già nel report del 03/09)

`.claude/skills/` (fra cui `post-mortem`) e `DEBITI.md` continuano a non esistere in REPO-W.
`docs/errori/REGISTRO.md` invece **ora esiste**: l'ho aperto in questa sessione, con due voci e la
loro guardia. Nota per chi tria: la parte che è stata chiusa è quella che una sessione può creare
da sola con `cat`; quella che è rimasta aperta è quella che richiede l'installazione dello
standard. La segnalazione da sola non ha chiuso niente in due giorni.

## Cosa ho improvvisato

- **Le attese DICHIARATE** (`ATTESE_DICHIARATE = 45`, una costante, non `attese.length`). Il
  canone chiede che un banco dica quante attese ha; **contarle dall'array è una tautologia** —
  `N/M` con M preso da `attese.length` non può accorgersi di un caso definito e mai eseguito. Che
  è il guasto avuto davvero, due volte: casi accodati **dopo** la riga di riepilogo, definiti e mai
  eseguiti, con la suite che diceva tranquillamente «43/43».
- **Il sabotaggio «di chi conosce metà del problema»**: accanto al sabotaggio che rimette il
  difetto com'era, uno che rimette la correzione **incompleta** — neutralizzare solo l'`=`
  dimenticando `+ - @`. Prova che il banco distingue una difesa da **mezza** difesa, non solo la
  difesa dall'assenza. Ne fa cadere tre.
- **La meta-mutazione**: una mutazione che toglie un caso di test e pretende che la suite se ne
  accorga. Nata perché un mio `git checkout` aveva buttato via la guardia scritta due ore prima, e
  la suite continuava a stampare un numero plausibile.
- **I doppi che REGISTRANO la traccia**: le parità asseriscono il **percorso**, non solo il
  risultato. Senza, una versione che salta un controllo restava verde.

## Cosa ha retto / ostacolato

**Ha retto — «una lente diversa, non una rilettura».** Nove difetti introdotti da me in questa
sessione. **Nessuno** è stato trovato rileggendo il mio codice: li ha presi un controllo
meccanico, un sabotaggio che doveva fallire, o una lente con una domanda diversa. La rilettura di
sé non trova niente, e quattordici giri di rilettura non trovano niente quattordici volte.

**Ha retto — il registro degli errori con la guardia vista rossa.** Due voci, e in entrambe la
guardia *esisteva già come idea* e **non era stata lanciata**: una era stata scritta al 2° giro,
eseguita una volta, e per tre giri mai più. La regola vera non è «scrivi la guardia», è **«mettila
nel gate»** — `.night-verify`, o non esiste.

**Ha retto — la riconciliazione (revisione = eseguiti + rinviati + persi).** Ha recuperato due
rilievi che stavo perdendo, e ha costretto a scrivere la RAGIONE di ogni rinvio. Uno dei rinvii
(«un solo posto per il nome della società») ha rivelato una trappola vera: in Apps Script
**l'ordine di caricamento dei file non è garantito**, quindi una `var` che legge la `var` di un
altro file può ricevere `undefined` **senza errore**. La correzione ovvia era sbagliata.

**Ha ostacolato — la catena di comandi che nasconde l'esito, e la regola che c'era già.** Tre
volte in una sessione ho committato o dichiarato verde qualcosa mentre un banco era **rosso**,
perché la catena di verifica si era interrotta su un comando prima di arrivare ai banchi.

E qui c'è il dato che vale più dell'errore: **«mai `&&` dopo una pipe» è già una regola del
canone, ed è nata in questo stesso repo il 3 settembre**, due giorni prima. Era scritta, era
indicizzata, ed è stata violata tre volte in una sessione. Una regola che vive solo come frase
non protegge nessuno: quella famiglia di errori si ferma con un controllo che gira, non con un
paragrafo che qualcuno dovrebbe ricordare al momento giusto. È lo stesso identico esito del
registro degli errori qui sopra — guardia scritta, guardia non lanciata, difetto passato.

**Ha ostacolato — cancellare per indice.** Due volte ho troncato un file a un indice di stringa
portandomi via il codice che stava dopo. La prima volta erano **due funzioni di produzione**
(l'idempotenza e la scrittura di ogni riga): rotte per tre commit, con `node --check` verde perché
la sintassi era perfetta e mancavano solo due dichiarazioni. `git diff` letto **prima** del commit
lo prende sempre; non l'avevo letto.

## Proposta al canone

### 1. La lente di sicurezza è una domanda diversa, non una lente più forte — va nel giro

Quattordici passate con le lenti della qualità non hanno visto che i campi estratti dall'OCR
finiscono in `appendRow` e che una stringa che inizia per `=` diventa una **formula viva**. La
prima passata di sicurezza sì, in una volta.

Non è che sia una lente migliore: chiede *«chi controlla questo dato?»* invece di *«questo codice
è giusto?»*. Le due domande illuminano insiemi diversi, e la seconda ripetuta quattordici volte non
converge sulla prima. Proposta: `/security-review` (o una lente equivalente) **fra le lenti del
giro**, non come passaggio finale opzionale — e in particolare in ogni progetto dove un dato
esterno (OCR, email, upload, scraping) arriva fino a una scrittura.

### 2. Pattern nuovo: `contenitore-che-riscrive`

Due difetti diversi di questa sessione hanno la stessa forma, ed è una forma che nessuno dei 39
pattern copre.

Il contenitore in cui scrivi **non restituisce quello che gli hai dato**:
- la stringa `'2026-01-31'` scritta in un foglio torna indietro come **`Date`** — il controllo che
  la rileggeva rispondeva «data non leggibile» su **ogni** riga, cioè un controllo di dominio
  spento in silenzio, senza un errore da nessuna parte;
- una stringa che inizia per `=`, `+`, `-`, `@` torna indietro come **il risultato di una
  formula** — e poiché quei campi vengono tutti dall'OCR, cioè dal documento, cioè da chi lo
  manda, un documento poteva cambiare i valori con cui il sistema decide. Non esfiltrazione:
  **controllo sulla decisione**.

La domanda generale, che vale per un foglio come per un CSV, un DB con coercizione di tipo, una
cache che serializza: **ciò che rileggi dal contenitore è ciò che gli hai dato?** Anchor
disponibile in REPO-W (`Foglio.gs`, funzioni `isoDaCella_` e `valoreDiCella_`, con 6 attese e 3
sabotaggi).

### 3. Un banco che passa un tipo che la produzione non passa non è un banco

Il controllo sul periodo IVA aveva **sette attese verdi** e in produzione non avrebbe deciso
niente: il banco gli passava `'2026-01-31'` (stringa) e il foglio gli avrebbe passato una `Date`.
Il banco era verde e la funzione era spenta.

Corollario operativo, verificabile: **quando un valore attraversa un confine** (un foglio, la rete,
un file, un processo), **almeno un'attesa deve usare il tipo che arriva DA QUEL CONFINE**, non
quello che è comodo scrivere nel banco. Il doppio che semplifica il tipo è un doppio che mente, e
mente in silenzio: la costruzione «doppio scriptabile» del canone non basta da sola a prenderlo.

### 4. Una domanda di dominio alla volta, e la risposta diventa una riga di codice con la sua data

Su richiesta dell'operatore ho posto **quattro** domande di dominio una alla volta invece che tutte
insieme. Ogni risposta è diventata: una funzione, un gruppo di attese, un sabotaggio con **la
regola sbagliata più probabile** (per la liquidazione IVA: «il mese si chiude a fine mese» — ne fa
cadere due, perché rompe anche il salto d'anno), e un commento nel codice che porta la data e chi
ha deciso.

Il guadagno misurato non è la correttezza: è che la **soglia** più delicata del sistema ha smesso
di essere una copia di un'altra soglia con un commento che diceva «la stessa di». Erano due domande
diverse — arrotondamenti in un caso, prezzi nell'altro — con la stessa risposta di oggi e ragioni
per divergere domani. Proposta: quando una costante compare due volte con lo stesso valore, la
domanda da fare non è «la unifico?» ma **«sono la stessa domanda?»**.


## Nota di metodo su questo report

`tools/privacy-check.sh` in questa sessione è **DEGRADATO e lo dichiara**: `night-shift/repos.key`
è locale alla macchina dell'operatore e qui non c'è, quindi il gate non ha controllato né i file né
la storia git. Il testo è stato scritto applicando a mano la regola «repo pubblico, lavoro privato»
(codice REPO-W, nessun nome di fornitore, di persona esterna o di società), ma **questo non è un
verdetto di pulizia**: va ripassato dal gate vero prima del push, sulla macchina dove `repos.key`
esiste. Che lo strumento dica «non ho controllato niente» invece di uscire con 0 è, di per sé, la
cosa giusta ed è la stessa regola della sonda che distingue lo zero dalla domanda sbagliata —
proposta nata in questo repo il 3 settembre.

---

## Seconda parte della stessa sessione: la fase di test

Dopo i quattordici giri, sei decisioni di dominio e cinque passi, fino a una registrazione **mai
eseguita**: la catena di controlli è arrivata in fondo su un caso vero e si è fermata su un blocco
esterno noto (un'assegnazione che l'API del gestionale non espone). Fermarsi lì è stata una
decisione dell'operatore, non una resa.

### Cosa ha retto

**«Non posso decidere» invece di un motivo plausibile.** Il campo su cui il controllo interrogava
l'anagrafica si è rivelato **non filtrabile** — errore HTTP, non un risultato vuoto. Il sistema non
ha detto «nessun record con quel valore», che sarebbe stato falso e perfettamente credibile: ha
detto che non poteva decidere e si è fermato. È la regola «una lettura mancata non è un dato»
messa alla prova da un caso che nessuno aveva previsto.

**La correzione che produce la misura.** Su un disallineamento di fuso orario fra i due sistemi non
ho dedotto: ho tolto il dato imposto *e* fatto stampare al sistema quello che decide lui. Il giro
dopo, la misura c'era, e l'ipotesi si è chiusa con un dato invece che con un ragionamento.

### Cosa ha ostacolato — tre errori, una sola famiglia

1. una sonda ha guardato in **un solo perimetro** mentre il percorso che indagava li scorre tutti;
2. una sequenza di comandi conteneva il nome di funzione preso da **un messaggio di log** scritto
   per un altro percorso, invece che dalla descrizione della funzione;
3. da «il campo esiste ed è valorizzato» ho dedotto **«è filtrabile»**.

Tre volte ho verificato **la cosa accanto** a quella che mi serviva, e ho trattato la vicinanza
come una prova. Ogni volta il costo è ricaduto sull'operatore umano: un artefatto consumato, una
schermata aperta per scoprire che era quella sbagliata, un giro di lancia-e-incolla.

### Proposta al canone (5-7, oltre alle quattro della prima parte)

**5. Una sonda verifica UNA proprietà, e le proprietà di un campo sono almeno tre.** Esistere,
essere valorizzato, essere interrogabile (filtrabile, ordinabile, scrivibile) sono domande
separate e si provano separatamente. «Il campo c'è ed è pieno» non autorizza a filtrarci sopra:
quella risposta si ottiene solo provando a filtrare. Anchor in REPO-W (§25.83, errore vero con la
sua guardia).

**6. Un doppio che non sa RIFIUTARE non protegge da una richiesta sbagliata.** Il sabotaggio che
rimetteva la query non supportata non poteva cadere finché lo stub rispondeva 200 a qualunque
domanda. Un doppio deve dire *no* dove il sistema vero dice no, altrimenti prova solo che il codice
sa gestire il caso felice. Corollario già visto due volte nella stessa sessione: uno stub che
risponde uguale a ogni domanda non può provare che la domanda fosse quella giusta.

**7. Una sequenza di comandi è una previsione, non documentazione da copiare.** Il nome di una
funzione da mettere in una sequenza si prende dalla sua **descrizione**, non da un messaggio di log
scritto per un altro percorso. E una funzione che produce un artefatto incompleto lo deve
**dichiarare rileggendolo**, invece di lasciare che se ne accorga chi lo aprirà.
