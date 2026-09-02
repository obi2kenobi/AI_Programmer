# 2026-09-02 — Una webapp GAS morta da loggati: il manifest, i verdetti che mentono, la consegna dei comandi

**Autore**: sessione Claude Code (remota, senza clasp) + Luca ai comandi `clasp` sul suo Mac.
**Bersaglio**: `REPO-<CODICE>` — progetto GAS gestionale (webapp `ANYONE_ANONYMOUS` + trigger schedulati).
> Codice anonimo da sostituire da `night-shift/repos.key` dopo aver controllato
> `night-shift/repos-index.md` per evitare collisioni (regola "public repo, private work").
> **Questo report sostituisce la versione parziale scritta a metà giornata.**

Partiti da «da qualche giorno non riusciamo a fare deploy dall'interfaccia di Apps Script».
Finiti con: una **famiglia di difetti nuova** per il canone GAS, una **diagnosi del giorno prima
rovesciata**, il gate del progetto da 2 a 5 passi e da 68 a 93 attese, tre deploy in produzione
nella stessa giornata, **sei difetti trovati nei miei strumenti prima del commit** e **dieci
errori miei**, di cui quattro pagati in giri persi.

---

## 1. La famiglia di difetti nuova (il pezzo che vale per tutto il parco)

**Una dipendenza da LIBRERIA dichiarata nel manifest di un progetto Apps Script può rompere
`google.script.run` per le sessioni AUTENTICATE.** Firma misurata:

- `doGet` viene servito regolarmente (HTTP 200, la pagina arriva);
- il POST verso `/callback` risponde **404**;
- nel log delle esecuzioni **non compare nulla** (le RPC non raggiungono mai il server);
- **da anonimo tutto funziona**, da loggato no, su **tutte** le versioni deployate.

Sintomo per l'utente: dashboard bloccata su "Caricamento in corso…" per sempre, failure handler
con `error.message` `undefined`.

**Domanda discriminante** da mettere accanto alle altre famiglie: *il manifest dichiara una
libreria? Prima di incolpare il browser, prova il progetto senza quella dipendenza.*

Isolato per confronto diretto su **due** progetti dello stesso parco (uno in una sessione
parallela). Rimossa la dipendenza: da sessione autenticata di dominio la dashboard carica tutto,
**senza toccare cookie, logout o account di sistema**. Popolazione: 2 su 2 controllati.

Secondo difetto della stessa libreria, indipendente: il suo `flush()` attendeva il lock di script
**30 secondi sul percorso critico di ogni chiamata interattiva** e ri-lanciava. Qualunque job
lungo sotto lock metteva ko l'intera webapp invece di degradarla (`doGet` cronometrato da 2-3s a
**32s**). Regola: **l'osservabilità non sta sul percorso critico** — se il sink non risponde si
scartano gli eventi, non si uccide l'entrypoint.

### Il corollario atomico

Manifest e punti di chiamata sono **un solo cambiamento**:

- rimuovere la dipendenza e lasciare le chiamate ⇒ **tutti i trigger muoiono** con
  `<Simbolo> is not defined` al primo firing (accaduto sul progetto gemello: manifest ripulito,
  7 file ancora da ripulire, trigger a poche ore);
- rimuovere le chiamate e lasciare la dipendenza ⇒ la webapp resta rotta da loggati.

**Presidio**: un banco che esegue i wrapper VERI dei trigger **senza alcuno stub della libreria**.
Una chiamata superstite non passa (provato: `ReferenceError`).

---

## 2. La seconda famiglia: il nome del trigger non segue la rinomina

Un trigger schedulato conserva **il nome della funzione con cui è stato creato**. Se la funzione
viene rinominata — e un audit di sicurezza che aggiunge l'underscore finale è esattamente questo —
il trigger punta a un nome che non esiste più e **fallisce a ogni attivazione**, senza che nulla
lo dica.

Misurato sul vivo: **4 handler su 4** puntavano ai nomi pre-rinomina; i due che sono scattati dopo
la rinomina risultano al **100% di errori** nel pannello Attivatori, ed è la ragione per cui il
foglio di inventario del giorno non è stato creato. Gli altri, scattati prima, a 0%: **è la data
della rinomina che taglia in due la tabella**, non una correlazione.

Due difetti a valle, entrambi peggiori del primo:

- **Le funzioni di rimozione confrontavano solo il nome nuovo**: `rimossi: 0` stampato mentre
  cinque trigger omonimi-senza-underscore erano installati. E poiché le tre funzioni erano **copie
  identiche a meno del nome**, la pulizia legacy aggiunta a una quarta (il trigger mensile) non
  correggeva le altre tre — nessuno strumento lo diceva.
- **La diagnostica era cieca**: cercava sei nomi la cui intersezione con quelli davvero installati
  era **vuota**. Riportava `0` per tutti mentre dodici trigger esistevano e due fallivano ogni
  mattina. Lo strumento che serve a distinguere "zero" da "assente" li confondeva.

**Fatto**: i nomi vivono ora in un **elenco unico** (handler + alias pre-rinomina) usato **sia dalle
rimozioni sia dalla diagnostica** — la prossima rinomina si aggiorna in un punto invece di quattro.
Le rimozioni delegano a un helper che cancella i nomi passati **e nessun altro**. La diagnostica
cerca i legacy e li **dichiara con un WARNING**, invece di contarli in silenzio.

Sabotaggio a quattro casi, tutti rossi. Quello che conta di più: il **rimedio-ruspa** (cancellare
qualunque trigger invece dei propri, 7 attese rosse) — perché la cura sbagliata di questo difetto
è cancellare troppo.

---

## 3. La terza: l'underscore finale nasconde anche all'editor

In Apps Script l'underscore FINALE non rende una funzione invisibile solo a `google.script.run`:
**la nasconde anche al menu a tendina dell'editor**, che non la elenca e non la lascia eseguire.
Una proprietà, due effetti — e la seconda metà non era scritta da nessuna parte.

Conseguenza misurata: l'audit del giorno prima aveva reso private **34 funzioni** di setup,
rimozione e migrazione, cioè **tutto il toolkit che un umano deve poter lanciare a mano**, senza
prevedere un'uscita. Aveva messo l'underscore persino a un wrapper nato mesi prima proprio per
essere eseguibile dall'editor: porta chiusa, chiave buttata. La via d'uscita presa dal proprietario
è stata togliere l'underscore a due installatori — riaprendoli a chiunque avesse la URL della
webapp anonima, uno dei due con parametri che riprogrammano un job di fine mese.

**Il rimedio, ancorato al codice che già c'era**: implementazione privata + wrapper pubblico
**guardato**. La guardia di sessione del progetto passa quando l'identità c'è davvero (esecuzione
dall'editor: utente del dominio) e rifiuta il chiamante anonimo senza identità né token. I wrapper
non espongono parametri: nemmeno superando la guardia si potrebbe alterare la pianificazione.

**Nota per il canone**: *"underscore finale = privato"* va scritto con la sua seconda metà — **e non
eseguibile dall'editor**. Un audit che rende privato un toolkit operativo senza lasciare wrapper
guardati non mette in sicurezza: **costringe chi opera a smontare la sicurezza per lavorare**, che è
un esito peggiore di entrambe le alternative.

---

## 4. La lezione di ragionamento più costosa: correlazione al posto della causa

Il giorno prima la conclusione era: *«sessione Google loggata su quel Mac in stato incoerente,
cura = cookie / logout / account di sistema»*. Le prove raccolte erano tutte **vere**: da anonimo
funzionava, da loggato no, su ogni versione; l'iframe RPC mostrava il dialogo OAuth solo da
loggati; l'identità anonima nel 404 portava un timestamp vecchio di ore.

Mancava **la mossa che isola la variabile**: confrontare lo stesso progetto **con e senza** la
dipendenza sospetta. Senza quel confronto un'asimmetria ambientale (anonimo/loggato) ha preso il
posto di una causa, e la cura proposta era il browser invece del manifest.

**Proposta al canone**: prima di attribuire un sintomo all'AMBIENTE (browser, cookie, account,
profilo, rete) serve un confronto che faccia variare **solo** la causa sospetta. "Da anonimo
funziona" non è una diagnosi: è una delle due metà di un esperimento che nessuno ha finito.

---

## 5. I verdetti che mentono — quattro istanze in un giorno

Il tema che tiene insieme quasi tutti i miei errori: **uno strumento risponde, e la risposta viene
creduta senza rieseguirla.**

### 5.1 Il denominatore va provato, non stampato
Uno strumento nuovo doveva verificare che ogni funzione invocata dal frontend esistesse pubblica
lato server. Tre implementazioni, tre risultati sullo stesso file:

| Approccio | Ponti trovati |
|---|---|
| `grep` per righe | **0** (le catene sono spezzate su più righe) |
| regex con un livello di annidamento | **20 su 29** |
| cammino della catena a parentesi bilanciate (stringhe e commenti compresi) | **29 su 29** |

La seconda stampava `attese eseguite: 20/20 · fallite: 0` — indistinguibile da un 29/29 per chi
legge. Ho consegnato quel verdetto al proprietario prima di accorgermene. Nessuno dei 29 ponti era
rotto: **la conclusione era giusta per caso, il metodo sbagliato.**

`patterns/copertura-dal-glob.md` copre "l'elenco fisso invecchia". Questo buco è diverso: il
perimetro veniva da un glob giusto, ma l'**estrattore** perdeva un terzo degli elementi in silenzio.
**Guardia**: ogni banco che dichiara `N/M` deve dimostrare da dove viene `M` — qui
`occorrenze grezze == catene parsate + residuo dichiarato` (36 = 34 + 2), col residuo sempre
dichiarato anche quando benigno.

### 5.2 Un verde per assenza non è un verde
Nel presidio dei byte di controllo il perimetro era `(*.gs *.html appsscript.json)` con `nullglob`.
**`appsscript.json` non è una glob**: resta nell'array anche quando non esiste, il lettore non
riesce ad aprirlo, e su perimetro vuoto la guardia **usciva verde**. Trovato dal sabotaggio, non
dalla rilettura. Ogni voce di un perimetro va filtrata per **esistenza e leggibilità reali**.

### 5.3 Rilevare non basta: il verdetto deve dire il vero
Nello stesso strumento il byte trovato veniva stampato con `ord($1)` **dopo** un match usato per
contare le righe — che **azzera `$1`**. Rilevava sempre correttamente e riportava **`0x00` qualunque
byte fosse**. Un difetto così non fallisce nessun test verde: manda la sessione dopo a inseguire il
byte sbagliato.

### 5.4 `exit=$?` dopo una pipe misura la pipe
La prima batteria di sabotaggio stampava "GUARDIA ROSSA COME ATTESO" su sei casi su sei — ed era
**falso**: leggevo `exit=$?` dopo `| tail -3`, cioè l'uscita di `tail`, sempre 0. Due dei sei
presidi erano in realtà **muti**. Un banco che mente è più pericoloso di una guardia che manca.

### 5.5 Un ref remote-tracking è un sensore stantio
Ho aperto una PR dichiarando **nel titolo** che il branch principale era "111 commit indietro
rispetto alla produzione". Falso: il riferimento remoto della sessione era fermo a una fotografia
vecchia e non l'ho riverificato con un `fetch`. Me l'ha rivelato la risposta del server alla
creazione della PR, non una rilettura. **Guardia**: nessuna affermazione su avanti/indietro senza
`fetch` esplicito prima.

---

## 6. Il byte invisibile (famiglia chiusa, non due casi curati)

Due sorgenti contenevano un **byte NUL letterale** dentro una stringa, usato come separatore di
chiave, invece dell'escape. JavaScript valido — passa il controllo di sintassi, passa il deploy —
ma fa dichiarare a `grep` il file **binario**, e `grep` allora **lo salta in silenzio**: nessun
errore, nessun avviso, solo risultati vuoti o incompleti su cui poi si ragiona.

Costo misurato: **due sessioni**. La prima chiusa con un "il grep torna vuoto su una stringa che
c'è" mai spiegato; la seconda con dieci falsi "ponte rotto" mentre nasceva il presidio del §5.1.

Corretti entrambi con banco di parità (chiave estratta dalla **riga vera**, confronto carattere per
carattere su 8 input, rosso su tre sostituzioni sbagliate). Ma la lezione è che la famiglia va
**chiusa nel gate**, non curata due volte: ora un controllo rifiuta ogni byte di controllo nei
sorgenti tranne tab e newline, dicendo file, riga, offset e byte.

Nota: un byte non-testo nel codice è un difetto di **leggibilità del progetto** anche quando il
linguaggio lo accetta. E la forma corretta era già la convenzione del repo in altri due file — il
cui commento citava proprio la funzione difettosa come riferimento della convenzione, mentre il
riferimento era l'unico a non rispettarla.

---

## 7. Consegnare comandi a un umano è un'interfaccia, e l'ho rotta quattro volte

Tutti pagati in giri persi, tutti evitabili. È la categoria che mi è costata più tempo in assoluto
nella giornata — **più della logica di dominio**.

1. **Commenti in linea in comandi per zsh.** Consegnato `cd /percorso     # NON la cartella
   archiviata`. **zsh interattivo non tratta `#` come commento**: il `cd` è fallito con
   `too many arguments` e i comandi successivi hanno ricevuto le parole del commento come nomi di
   file. Regola: **zero commenti in linea**; le spiegazioni stanno fuori dal blocco.
2. **Segnaposto lasciati nei comandi.** `update-deployment … INCOLLA_QUI_ID` e un `curl` sulla URL
   col segnaposto dentro: due comandi a vuoto, e **la strada che preserva la URL non è stata provata
   al primo tentativo** (con la conseguenza di un deployment in più, poi da eliminare). Chi riceve
   comandi li **incolla**: i valori li sostituisce chi li scrive.
3. **Versione dello strumento non stabilita.** Ho dato flag della major precedente a chi aveva la
   successiva, dove i comandi sono rinominati; e ho dichiarato un comando "rimosso nella v3"
   basandomi su una issue relativa a una alpha — **esiste, e ha funzionato**. Regola: la versione si
   **stabilisce** (`--version`, `--help`) prima di dettarne i flag; per un comando che scrive in
   produzione, il suo `--help` vale più di qualunque memoria.
4. **Codice consegnato senza riconciliarlo con lo stato appena misurato.** Ho dato uno snippet che
   chiamava una funzione col nome vecchio **dopo** aver letto il diff che mi diceva che nel vivo
   quel nome era stato rinominato. Risultato: `ReferenceError` alla prima esecuzione. Stessa famiglia
   dei segnaposto.

E due errori di **prosa tecnica**, dello stesso ceppo:

5. **`*/` dentro un commento JSDoc** (avevo scritto `setup*/remove*`): chiude il commento e rompe la
   sintassi del file. Preso dal gate al primo giro, con un errore che non nomina il commento ma il
   sintomo a valle.
6. **Allarme sproporzionato.** Ho messo come prima cosa urgente il rischio che una funzione che
   scrive una credenziale fosse stata resa pubblica. Il diff, che avevo chiesto io, ha mostrato che
   **non era stata toccata**: due funzioni in tutto, e l'esposizione era limitata al deployment di
   test, non alla produzione (una webapp deployata esegue il codice della **propria** versione).
   Un allarme sbagliato costa credibilità agli allarmi giusti.
7. **Affermazione inventata su dati veri.** Ho definito "duplicati accumulati silenziosamente" dodici
   trigger che erano invece **l'insieme di progetto** (cinque giornalieri = uno per giorno feriale,
   scritto nell'installatore). Il codice lo diceva; l'ho letto solo dopo. Le date di ultima esecuzione
   diverse, che avevo dichiarato inspiegabili, erano cinque giorni feriali consecutivi.

---

## 8. Cosa ha retto

- **"Esegui, non dedurre"** ogni volta che l'ho applicato. La produzione l'ho misurata: HTTP,
  cronometro, e la lettura di un'**iniezione dinamica** nella risposta come prova che l'entrypoint
  ha *eseguito* — distinguendo esecuzione da cache senza simulare il protocollo RPC.
- **"Il vivo è definitivo, si legge"**: il fatto decisivo è arrivato da un clone del vivo in una dir
  temporanea — il manifest in produzione **aveva ancora** la dipendenza, mentre tutto il lavoro sul
  repo la dava per rimossa. Nessuna quantità di verde locale lo avrebbe detto.
- **Il sabotaggio prima di dichiarare viva una guardia.** Ha trovato **sei difetti nei miei strumenti
  nuovi prima del commit** (§5.1 ×2, §5.2, §5.3, un caso cieco nel residuo, e il grep senza `-a`),
  quattro dei quali invisibili a un giro verde. È la pratica che ha pagato più di ogni altra.
- **Il gate come cancello vero.** Da 2 a 5 passi, da 68 a **93 attese**. Ha preso il mio `*/` in
  due secondi, e ogni presidio nuovo è entrato solo dopo essere stato visto rosso sul difetto che
  deve prendere.
- **Il check pre-deploy da due secondi** (nessuna modifica locale al file di puntamento + versione
  restituita = `N+1` della produzione): tre deploy, tre volte confermato il progetto giusto in un
  contesto dove esiste davvero un progetto gemello col codice identico.
- **Il cancello tecnico sul deploy**: l'hook che nega `clasp` in scrittura ha sparato quattro volte.
  Una era il caso vero, tre erano falsi positivi su **prosa che citava i comandi negati** — un hook
  che guarda la stringa e non la struttura tassa chi documenta il deploy: ho dovuto comporre le
  stringhe a runtime per non farmi negare la scrittura di un report.

## 9. Cosa ha ostacolato

- **La libreria era illeggibile da questa sessione** (progetto separato, nessuna credenziale): la
  semantica di `run`/`flush` è stata dedotta dai punti di chiamata e da un report precedente, non
  letta. Dichiarato DEGRADATO invece di presentato come verificato.
- **Nessuna CI**: il progetto non ha workflow. L'unico cancello è lo script di verifica locale, che
  qualcuno deve eseguire — un presidio che nessun automatismo invoca dipende dalla memoria di chi
  committa. È `citazione-non-presidio` un livello più su.
- **Nessuna esecuzione server-side diretta** (`run-function` inutilizzabile su questo progetto):
  alcuni gesti finali restano manuali nell'editor e **non verificabili** da fuori.

---

## Proposta al canone

1. **Famiglia GAS nuova**: "dipendenza da libreria nel manifest rompe `google.script.run` per le
   sessioni autenticate" — firma completa, domanda discriminante, corollario atomico (manifest +
   chiamate insieme, mai uno solo). Popolazione: 2/2 progetti controllati.
2. **Famiglia GAS nuova**: "il trigger conserva il nome con cui è stato creato" — una rinomina lo
   orfana e lo fa fallire a ogni firing; le rimozioni e la diagnostica vanno alimentate da un
   **elenco unico** di nomi con alias, o la correzione entra in una copia e non nelle altre.
3. **Completare la regola dell'underscore**: privato a `google.script.run` **e** non eseguibile
   dall'editor. Corollario: un audit che rende privato un toolkit operativo deve lasciare **wrapper
   guardati**, altrimenti chi opera smonta la sicurezza per lavorare.
4. **Diagnosi differenziale a quattro strati** per "webapp GAS che non carica": dialogo OAuth /
   callback 404 **da loggati su tutte le versioni** → dipendenza nel manifest (**non** la sessione
   del browser); `doGet` > 20s e RPC morte per tutti → lock conteso da un job; una sola versione
   rotta → deployment stantio; RPC orfana singola → ponte staccato da una rinomina.
5. **La regola dell'ambiente**: prima di attribuire un sintomo a browser/cookie/account serve un
   confronto che faccia variare **solo** la causa sospetta. Metà esperimento non è una diagnosi.
6. **`N/M` con provenienza dimostrabile** (candidato a pattern: `denominatore-provato`): ogni
   riga-verdetto deve poter dimostrare il denominatore, con quadratura fra elementi grezzi, giudicati
   e residuo dichiarato.
7. **Perimetri**: mai una voce non-glob assunta esistente; mai un verde su perimetro vuoto (uscita
   "non giudicabile" distinta da "pulito"). Estende `copertura-dal-glob`.
8. **Il verdetto deve dire il vero, non solo sparare**: il valore che un banco riporta va catturato
   prima di qualunque operazione che possa sovrascriverlo.
9. **`exit=$?` dopo una pipe è un falso**: nelle batterie di sabotaggio, uscita catturata senza pipe
   o via `PIPESTATUS`.
10. **Un ref remote-tracking è un sensore**: nessuna affermazione su avanti/indietro senza `fetch`.
11. **Byte di controllo nei sorgenti: gate, non cura caso per caso.** Tab e newline i soli ammessi.
    Costo storico della sua assenza: due sessioni.
12. **Consegna di comandi a un umano** (candidato a pattern: `comando-consegnato-e-eseguibile`):
    zero commenti in linea, zero segnaposto, versione dello strumento stabilita prima dei suoi flag,
    e codice consegnato **riconciliato con lo stato appena misurato**.
13. **Proporzione dell'allarme**: un rischio va dichiarato con il suo perimetro verificato, non col
    peggiore immaginabile. Un allarme sbagliato costa credibilità a quelli giusti.
14. **Osservabilità mai sul percorso critico**: un logging che attende un lock e ri-lancia trasforma
    ogni job lungo in un fermo totale.
15. **L'hook che nega per stringa tassa la documentazione**: valutare un riconoscimento più
    strutturale del comando, o una via dichiarata per scrivere prosa che *cita* i comandi negati.

---

## Numeri della giornata

| | |
|---|---|
| Passi del gate | 2 → **5** |
| Attese del banco | 68 → **93** |
| Difetti trovati nei miei strumenti dal sabotaggio, prima del commit | **6** (4 invisibili a un giro verde) |
| Miei errori registrati | **10** (4 pagati in giri persi) |
| Famiglie di difetti nuove per il canone GAS | **3** |
| Deploy in produzione, ciascuno col gate verde e la versione verificata `N+1` | **3** |
| URL degli operatori cambiate | **0** |
