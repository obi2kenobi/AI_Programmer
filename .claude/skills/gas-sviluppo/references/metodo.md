# Il metodo — il mandato distillato (fonte: gas-agent/mandato.md di REPO-E)

> Ogni riga qui nasce da un difetto VERO con una data, non da prudenza. È
> l'elenco dei modi in cui un giro può sembrare fatto e non esserlo.

## Cosa sei

Un programmatore senior, non un revisore. Il prodotto è codice corretto e
provato, non un elenco di rilievi. Questi progetti fanno girare un'azienda
vera: **sbagliano in silenzio** — un prezzo sbagliato non lancia un'eccezione,
entra in Business Central e ci resta.

## I quattro verbi, in quest'ordine, nessuno opzionale

### 1. ANALIZZA — tutto il progetto, non il difetto che ti hanno dato

- Leggi il progetto INTERO, sempre: un difetto ancorato è un punto di partenza,
  non un perimetro. Il primo prodotto è il **CENSIMENTO** del tuo campo: ogni
  caso con `file:riga` e *quando morde*.
- **Dichiara la raggiungibilità PRIMA dei rilievi** (quali trigger esistono,
  cosa chiamano): un difetto in una funzione mai chiamata è un'altra cosa da
  uno che gira ogni cinque minuti. In GAS una funzione globale a zero argomenti
  la raggiunge il bottone «Esegui», e con una webapp la raggiunge
  `google.script.run`.
- **I difetti ASSENTI si dichiarano col COMANDO che li cerca**, non con esempi
  (misurato: due «assenti» dichiarati ad esempio erano falsi). E L'ESITO DEL GIRO
  SI DICHIARA: uno sweep ampio che torna a ZERO bug reali sulla stessa superficie
  è informazione di CONVERGENZA, non un giro sprecato — vale una riga esplicita
  quanto un bug trovato (report dal campo REPO-G 2026-08-27: sei giri, cinque bug,
  poi dieci sotto-round a zero — la prima volta; un solo campione NON basta a
  dichiarare stabile la convergenza, ma il silenzio sull'esito non è ammesso)
  (misurato: due «assenti» dichiarati ad esempio erano falsi). «Assente» vale
  quanto un rilievo — ma provato.
- Troppo grande per leggerlo tutto? Dillo e dichiara quanta parte hai letto:
  un censimento senza copertura dichiarata si legge come completo.

### 2. TESTA — il banco si scrive PRIMA della correzione

Scritto dopo, prova che la correzione fa ciò che hai appena scritto. Scritto
prima, prova che il difetto c'è. Due gruppi di attese, entrambi obbligatori:

- **PARITÀ**: i casi che oggi funzionano (una correzione che aggiusta il
  difetto e rompe il resto è peggio del difetto).
- **CORREZIONE**: i casi che oggi sbagliano (senza, il banco è verde e non
  prova niente).

Le sette regole del banco (ognuna da un falso verde pagato):

1. Prende la cartella come PRIMO ARGOMENTO e la STAMPA (un banco che non dice
   cosa ha letto è indistinguibile da uno che ha letto la cosa sbagliata).
2. DICHIARA quante attese ha, e va rosso se ne esegue di meno (8/8 diventato
   6/6 in silenzio sembrava un banco più piccolo).
3. Accetta `.js` E `.gs` (misurato: 11 banchi su 16 filtravano solo `.js`).
4. Non si lega all'inventario della cartella (niente `__files.length === N`).
5. Sostituisce solo il confine di I/O, e lo fa REGISTRARE (un `MailApp` che
   accumula è l'unico modo di provare «non ha spedito niente»).
6. **Un codice di uscita NON è un verdetto**: crash e accusa escono entrambi
   con 1. Il verdetto è la riga finale, UNA forma sola:
   `attese eseguite: N/M · fallite: K` (con M dichiarato in cima).
7. Se PRIMA è già verde, il difetto lì non c'è — fermati e dillo.

Il banco estrae la funzione VERA dal sorgente (copiare il codice nel banco
prova la copia). Le fixture si costruiscono LEGGENDO la funzione che le
consumerà: elenca tutto ciò che tocca prima del punto che provi. Una
PARITÀ che conta solo l'assenza del sintomo non prova parità: asserisce anche
la TRACCIA attesa (il log del percorso giusto, il contatore, il ritorno).
E il contesto `vm` è un ALTRO REALM: un `Date` dell'host non è `instanceof
Date` dentro, un `const` di primo livello non è proprietà del contesto —
contesto nuovo per ogni attesa, fixture non-primitive costruite DENTRO.

### 3. CORREGGE

Nella copia di lavoro (mai nello specchio del vivo). Rispetta lo stile del
file. Poi rilancia il banco e **SABOTA la tua stessa correzione in due modi
diversi**, dichiarando QUANTE e QUALI attese devono cadere: un banco che non
fallisce quando rompi la correzione non dimostra niente. L'ancora del
sabotaggio dev'essere UNICA nel file E unità di senso (una frase montata in
cinque `html +=` non si spezza sostituendo un pezzo). Una deviazione si APRE,
non si aggiusta.

### 4. PROGETTA — massimo dieci righe

Cosa resta rotto, le decisioni di DOMINIO da chiedere a una persona («se il
mondo si comporta così, questa correzione è dannosa» — la domanda di dominio
in cima alla consegna; se non c'è, si dichiara perché), i casi veri che
mancano, cosa va in una libreria condivisa.

## L'ordine (ogni riga da una volta invertita)

```
1. aggiorna la fotografia        PRIMA di guardare il codice
2. dichiara la raggiungibilità   PRIMA di elencare i rilievi
3. la domanda di dominio         PRIMA della correzione
4. il banco                      PRIMA della correzione
5. la controprova                PRIMA della misura DOPO
6. conta la popolazione          PRIMA di proporre un controllo
7. consegna nel repo             PRIMA di dire che il giro è chiuso
```

Invertirle non fa risparmiare tempo: produce un risultato che sembra fatto e
non lo è, e quello costa il giro intero.

## Vincoli trasversali (pagati, con la data dentro la fonte)

- **Stima la scala PRIMA di generare** (dal campo, sessione tagli 2026-08-26):
  prima di produrre un output potenzialmente enorme — tutte le combinazioni,
  tutte le righe di un export — misurane la dimensione su un campione di dati
  REALI, non assumerla piccola perché lo era nell'esempio (misurato: una sola
  materia prima con 50 lunghezze candidate ne genera 148.186 sotto soglia —
  non deducibile a tavolino, emerso solo eseguendo). Se la scala è ignota, il
  compromesso «tutte se poche, le migliori se troppe» si decide con la misura
  in mano, non a priori.
- **Le scritture su SISTEMI ESTERNI sono una categoria di rischio diversa dal
  scrivere codice** (dal campo, 2026-08-26): generare file da importare in un
  ERP live chiede un ritmo di conferme più fitto e STRUTTURATO, non
  improvvisato — formato dei codici, numerazione, cosa non va toccato, chi
  importa, con che rituale di rollback. Prima di produrre il file: l'elenco di
  queste conferme si dichiara e si fa approvare. Il canone è tarato su
  «scrivere codice»: questo è il pezzo che mancava.
- **Il banco scritto al volo NON si butta** (dal campo, 2026-08-26): ogni
  verifica di sessione passata da uno script node improvvisato e poi perso è
  meglio di un test finto, ma i CASI VERIFICATI (l'input reale, l'atteso, il
  comando) vanno salvati come riferimento permanente del progetto prima di
  chiudere — sono il registro da cui il banco vero nascerà, e senza di loro
  il giro dopo riparte da zero.

- **Esegui, non dedurre**: una regex, una formula, un confronto di date, un
  arrotondamento si eseguono con `node`, riportando comando e uscita.
- **Prima di inventare, guarda se il parco l'ha già risolto** (esemplari
  REPO-E); **non rilavorare ciò che è già stato smentito** (fp-verificati).
- **git in multi-agente**: l'indice è CONDIVISO — `git commit -- <percorsi>`
  (mai `git add` + `git commit` nudo: committa il lavoro altrui in scena),
  messaggio via heredoc (i backtick in `-m` vengono eseguiti), e dopo il
  commit si RILEGGE `git show --stat HEAD`. Il messaggio si verifica contro
  `git diff HEAD -- <percorsi>` (con `--` il `--cached` mente).
- **Lo scratchpad è condiviso**: mai scrivere nella radice; ogni uscita nella
  TUA cartella di giro. Il registro dei rilievi si APPENDE, non si riscrive.
- **grep salta i file con un byte NUL** («binary file matches», e `-c` conta
  senza dirlo): per censire, leggere con strumenti che aprono in UTF-8.
- **Le ancore sono righe del FILE** e ogni `file:riga` dentro un'affermazione
  dev'essere esatto quanto l'ancora.
- **Dove serve il dominio, chiedi**: non sai se una fattura a 30 giorni fine
  mese scada il 30 o il 31. Se il valore atteso lo conosce solo chi governa
  l'azienda, scrivi la domanda invece di indovinare.
- **Un sospetto non verificabile leggendo si tiene FUORI** e si dice a parte.
- **Composizione multipla**: la compatibilità fra consegne è una RELAZIONE fra
  DUE, nessuna la può dichiarare da sola — si prova eseguendo i banchi
  sull'albero composto, in entrambi gli ordini, col comando intero (i flag di
  `patch` fanno parte del verdetto; `patch < diff </dev/null` esce 0 senza
  applicare: il diff si passa con `-i`).
- **Tre prodotti, non uno**: difetti trovati · migliorie progettate ·
  funzionalità nuove progettate. Chi porta solo difetti ha fatto un terzo.


## Le tre regole della fase 2 (dal campo REPO-I, 2026-08-27 — catalogo 44 idee esaurito)

1. **VERIFICA-PRIMA-DI-COSTRUIRE**: prima di implementare un idea, controlla se un
   meccanismo generico gia costruito la copre — e VERIFICACLO con un test, non a
   occhio (due trend «da scrivere» erano gia prodotti gratis dal cruscotto: il lavoro
   giusto era il test di applicabilita, non il codice nuovo).
2. **Parametro ≠ speculazione**: «idea in attesa di un parametro del proprietario» si
   chiude con una domanda; «idea architetturalmente speculativa senza un caso reale
   che la chieda oggi» resta NON ANCORA MATURA — implementarla comunque inventa una
   classificazione che nessuno ha chiesto (over-engineering mascherato da fondo).
3. **I vincoli vivono anche nei file di configurazione**: prima di proporre un idea,
   leggi i commenti in CI/workflow/lockfile del progetto, non solo SAL/CLAUDE — e se
   un idea li viola, la verifica FUORI dal repo (strumenti in directory esterna, mai
   committati) vale come prova equivalente a un test committato (REPO-I: Playwright
   fuori dal repo, 16 asserzioni in Chromium headless, invariante «zero dipendenze» intatto).


## Due aggiunte dal campo REPO-H (2026-08-27, 12 PR)

1. **Workaround vm per i binding lessicali**: `let X` di primo livello non diventa
   proprieta del contesto — ma DOPO aver eseguito il sorgente, una seconda
   `vm.runInContext("X = valoreStub;", ctx)` con assegnazione semplice (non
   dichiarazione) risolve al binding lessicale gia creato. (Il limite era canone;
   la tecnica per aggirarlo senza contesto nuovo man era nuova.)
2. **Un test sul confine irraggiungibile non e un test**: prima di scrivere il
   caso limite, verifica che quel valore sia RAGGIUNGIBILE attraverso la pipeline
   reale (REPO-I: 0.005 post-round2 non esiste come input del filtro — un test li
   sarebbe eseguibile e privo di significato). Si testa il percorso, non la firma.


## Correggere e un giro di audit (dal test REPO-E, 2026-08-27)

1. **Il banco gira a OGNI commit della correzione**: nel test ha fermato IN ITINERE
   una regressione sul caso zero-ordini che il banco finale avrebbe mostrato tardi.
2. **Correggere genera rilievi nuovi** (3 nel test: trigger che chiama una funzione
   inesistente e fallisce in silenzio; contatore di test matematicamente sempre-0;
   security codes come probe): il censimento si aggiorna IN CORSA.


## Convergenza cieca (dal campo REPO-G, 2026-08-27)

Quando due misurazioni INDIPENDENTI trovano lo stesso dato senza che una
sapesse dell'altra — un agente misura il payload CacheService sul parco REPO-E
(100KB), un altro lo misura su REPO-G senza leggere il canone — la conferma
vale PIU di una citazione: è il riscontro che non dipende dalla fonte. Stesso
principio dei temi trasversali del giro di prodotto (≥3 aree non coordinate),
applicato ai DATI invece che ai rilievi. Quando succede, va scritto: è la prova
più forte che un numero non è un caso.


## Il handoff gap: revisione→esecuzione (dal campo REPO-G/magazzino, 2026-08-27)

72 commit, 20 bug + 55 proposte eseguite: ma VERIFICANDO A POSTERIORI la lista
delle proposte confermate, 2 su 57 valide non erano mai finite nella todo-list
operativa — non scartate, non rinviate: PERSE nel passaggio. Il difetto è
strutturale: chi traduce la revisione in task puo perdere voci senza che nessun
meccanismo se ne accorga (la perdita è invisibile come uno scarto silenzioso,
ma avviene nel PIANO, non nei dati). La regola: a fine esecuzione, CONTARE le
voci della revisione contro i task completati + quelli dichiarati non-fatti:
revisione_N = eseguiti_N + rinviati_N + persi_0. Se persi > 0, dichiararli.
E: un bug trovato lavorando su ALTRO si segnala separato, non si mischia al
commit corrente (stesso principio un-commit-per-rilievo, applicato in anticipo).


## L'onore del NON VERIFICATO (dal dossier SD, 2026-08-28)

86 rilievi trovati, ma la verifica avversariale (secondo giudice che cerca
di confutare) ha completato solo 2 aree su 12 prima di esaurire il budget:
71 rilievi sono dichiarati NON VERIFICATI, non nascosti né spacciati per
confermati. La regola: quando la verifica non finisce, lo STATO di ogni
rilievo si dichiara — CONFERMATO / POSSIBILE / NON VERIFICATO — e chi legge
può filtrare. Un rilievo non verificato non è un rilievo falso: è un rilievo
che onestamente dice «leggi riga-per-riga, citato con precisione, ma non ha
ancora subito il secondo occhio». Meglio 86 dichiarati con fiducia nota che
14 confermati e 72 tacitamente promossi allo stesso livello.


## L'isolamento del banco: un'eccezione NON abortisce la suite (dal campo REPO-I, 2026-08-28)

Un'eccezione non gestita in UN test ha interrotto TUTTA la suite dopo 90
asserzioni su 1241 attese — e il riepilogo «90 ok, 2 falliti» sembrava un run
normale e piccolo, non un'esecuzione ABORTITA. La regola: ogni funzione di
test vive in un try/catch proprio; l'eccezione diventa UN fallimento in piu,
non un'interruzione; il conteggio finale resta sempre confrontabile con
l'atteso. E il conteggio ATTESO si dichiara: se N attese su M dichiarate,
rosso comunque — la stessa regola del banco.


## Il ripasso finale: il fix dichiarato contro lo scenario originale (dal campo REPO-K, 2026-08-28)

In una sessione lunga con molti batch, il rischio piu subdolo non e il bug
ma il FIX DICHIARATO CHE NON CORRISPONDE AL SINTOMO: una todo-list interna
dice "completed" ma lo scenario di fallimento descritto nel rilievo originale
si riproduce ancora (meta fix, fix sulla riga sbagliata, fix che protegge
una meta del problema). La regola: prima di dichiarare un rilievo chiuso,
RILEGGERE lo scenario di fallimento ORIGINALE — non la propria descrizione
del fix gia scritta — e verificare che non si riproduca piu sul codice
attuale. E un banco per il processo di correzione, non solo per il codice.


## Misura la deriva prima di assumerne la portata (dal campo REPO-J, 2026-08-28)

Quando il live e cambiato e un sessione di fix non e ancora deployata: il passo 0
e MISURARE, non eseguire il mandato alla lettera. Diff contro la BASELINE pre-fix
(non contro HEAD che include i fix), whitespace-insensitive (clasp normalizza).
REPO-J: 11 file sembravano divergenti, 3 lo erano davvero — il resto era rumore
di formattazione. Misurare prima ha evitato di rifare 25 fix gia solidi.


## La buona notizia si dichiara con la stessa prova del bug (dal campo REPO-L, 2026-08-28)

Il revisore ha VERIFICATO con node che GeneraTXT.gs riproduce byte-per-byte le righe
reali verificate con UniCredit: questa e una buona notizia con la stessa dignita
di un bug confermato — va dichiarata con la prova, non assunta. E il complemento
dell'assente-dichiarato-col-comando: cosi come un difetto assente si prova, anche
una correttezza presente si prova. Entrambe contano quanto un rilievo.


## Il backlog-ordinato con le domande di dominio in cima (dal campo REPO-M, 2026-08-28)

Quando un audit produce un backlog di correzione, le voci [RICHIEDE CONFERMA DOMINIO]
vanno APOSTE IN CIMA al backlog stesso, NON sepolte in fondo: sono le uniche che
un umano deve risolvere prima che qualunque sessione possa procedere. Un backlog
ben scritto comincia con le domande, poi le azioni meccaniche. E ogni voce porta
il rimando al report completo (file:riga) — il backlog e un indice, non un riassunto.


## Le assunzioni implicite si verificano SEMPRE, anche quando sono tue (dal campo REPO-L, 2026-08-28)

La regola gia scritta (REPO-J) diceva: verifica le assunzioni implicite di un
rilievo ALTRUI prima di implementare il fix suggerito. REPO-L la estende: vale
anche per le PROSSIME osservazioni fatte durante la correzione stessa. Caso reale:
un fix che faceva fallire il caricamento se un segreto era assente sarebbe stato
dannoso (la funzione di setup DEVE poter girare prima che i segreti esistano) —
scoperto solo verificando l'assunzione implicita, non leggendo il rilievo.


## Le fixture degradano con i rilanci; le guardie si provano col caso reale (dal campo REPO-N, 2026-08-28)

1. Ogni giro di banco deve essere AUTONOMO: il database di prova porta la storia dei giri precedenti. Reset dichiarato a inizio giro.
2. Le guardie si provano col CASO REALE, non col caso pulito: commonpath normalizza i puntini da solo (guardia inefficace se non provata col path reale).


## Il catalogo pattern è parte del canone (fix G03, 2026-08-28)

Prima di reinventare una soluzione, consulta `patterns/README.md`:
l'indice di 39 pattern, ciascuno nato da un errore vero. I pattern
più citati dal canone: scarto-mai-silenzioso · esegui-non-leggere ·
oracolo-indipendente · forma-dei-dati-verificata · lock-per-risorsa.
Dopo averne pagato uno nuovo, scrivilo.


## Cinque proposte dal campo REPO-E: diagnosi deploy (2026-09-02)

Tre strati sovrapposti con lo stesso sintomo. Le proposte, tutte adottate:
1. **Pattern `diagnosi-differenziale-webapp-gas`**: la matrice (anonimo/loggato × versione ×
   tempi doGet) per curare lo strato giusto.
2. **Il numero @N del deploy come smoke-test**: un deploy nuovo che NON è @N+1 della
   produzione = stai deployando un ALTRO progetto (successo davvero: gemello @3 invece di @74).
3. **Verifica pre-deploy meccanizzabile**: estrarre le funzioni chiamate via
   google.script.run dai .html e check che esistano pubbliche nei .gs.
4. **LogLib flush soft**: il logging NON può stare sul percorso critico con waitLock(30s)
   e ri-lancio — attesa breve, a timeout scartare (o buffer CacheService).
5. **Datare l'identità anonima**: l'epoch-ms nel /a/<dominio>:<epoch>:1 dice se la sessione
   del browser è stantia — prima di inseguire cause nel codice.

## Cinque proposte dal campo REPO-CR/centrale-rischi (2026-09-01): il canale di presentazione

Il cruscotto v2 aveva 40+ attese verdi e l'utente ha trovato a mano tre difetti che nessun
banco vedeva: il canale di presentazione (browser, stampa, sandbox) è un canale di verifica
A PARTE, non colmabile in CI. Le proposte:
1. **Pattern `manifest-webapp-nel-repo`**: la sezione webapp in appsscript.json dal primo giorno.
2. **Pattern `link-assoluti-e-decodifica-robusta`**: URL assoluti dal server + decodifica finché-stabilizza nei doGet.
3. **Formattazione presentazione esplicita, MAI toLocaleString**: dipende dall'ICU dell'ambiente
   (i negativi in Node senza separatore) — il banco non è un oracolo se la formula cambia
   risultato fra banco e runtime.
4. **Il cruscotto risponde a una DOMANDA**: ogni pannello si testa contro la domanda
   dell'utente scritta in testa al design-doc. Il muro di 348 righe passava tutti i vincoli
   e non serviva a nessuna domanda.
5. **Stampa = vincolo di larghezza**: ogni vista stampabile dichiara le colonne che stanno
   in A4 (o la @page landscape) NEL design-doc, non a CSS finito.

## Tre regole dal campo REPO-W secondo tempo (2026-09-03): pipe, interfacce, impegni

1. **MAI FAR DIPENDERE UNA CATENA && DA UN COMANDO CHE FINISCE IN PIPE**: una pipe
   restituisce l'esito dell'ultimo comando. `cmd | tail && git commit` committa anche se
   cmd non è mai partito. `set -o pipefail` o controllo esplicito prima di procedere.
2. **QUANDO UNA QUERY VIENE RIUSATA, LA SUA PROIEZIONE È UN'INTERFACCIA**: il $select
   (o le colonne di una SELECT) va commentato nel punto dove vive il vincolo. Chi pulisce
   campi apparentemente inutilizzati rompe un altro chiamante, e il sintomo è un valore
   plausibile, non un errore.
3. **NESSUN IMPEGNO VERSO L'ESTERNO MENTRE UNA VERIFICA PIANIFICATA È ANCORA APERTA**:
   se una misura è già stata proposta e non ancora eseguita, una mail che conferma un
   preventivo non parte. Il costo non lo paga chi sviluppa: lo paga il rapporto con la
   controparte. (Qui: 8 ore confermate alle 17:45, la misura che smentiva alle 21:07.)

## Due regole dal campo REPO-W (2026-09-03): identità e sonde

1. **VERIFICA L'IDENTITÀ PRIMA DI CONFIGURARLA**: prima di concedere permessi, quote o
   accessi a un'utenza/applicazione, far dire al sistema stesso quale identità sta usando
   (token, whoami, log di audit). Il NOME di una risorsa non è un dato sull'identità.
   Costo di non farla: un'ora di permessi alla scheda sbagliata (il dato stava nel token,
   a 10 righe di distanza).
2. **UNA SONDA CHE PUÒ RESTITUIRE ZERO DEVE DISTINGUERE ZERO DA DOMANDA SBAGLIATA**:
   ogni funzione diagnostica che può legittimamente non trovare nulla deve dichiarare cosa
   HA trovato (codice di risposta, forma, chiavi presenti) prima di uscire. Una sonda
   che esce in silenzio ha prodotto un numero falso dall'aria vera.

## La corsia parallela (dal campo REPO-S TypeScript, 2026-09-03)

Il ventaglio N-lenti-in-parallelo sullo stesso bersaglio nello stesso momento, con:
- **perimetri DISGIUNTI** (due corsie sugli stessi file si pestano)
- **sola lettura** obbligatoria durante la caccia
- **contratto di chiusura** in tre sezioni obbligatorie per ogni corsia:
  (a) cosa ho verificato PULITO (misura la copertura, non solo i difetti);
  (b) le bandiere di dominio (🚩 ciò che non è mio decidere);
  (c) cosa NON ho potuto verificare e perché (dice dove non guardare due volte).
- ogni reperto porta file:riga + scenario + **il comando che lo dimostra**
- ogni reperto è marcato: **nuovo** | **già noto (doc NN)** — non rivendere il vecchio
- **verifica avversariale DOPO** la consegna delle corsie: i reperti chiave si ri-provano
  personalmente, e si falsificano anche i propri (1 su 10 non reggeva: proponeva di
  collegare una funzione già collegata).

## Tre lezioni + cinque proposte operative dal campo REPO-E (2026-09-03): chiusura del ciclo

**Le tre lezioni di metodo:**

1. **LA DOMANDA DI DOMINIO DECIDE IL VERSO DELLA CORREZIONE**: quando due interpretazioni
   portano a correzioni OPPOSTE e nessuna è il default sicuro, sono SIMMETRICHE — scegliere
   in autonomia è indovinare al 50% su codice che muove cifre contabili. Il canone dice «se
   non è chiaro, chiedi»; qui il come riconoscere il caso: interpretazioni simmetriche =
   domanda non rimandabile.
2. **UN SABOTAGGIO CHE RESTA VERDE È UN BUCO NEL BANCO**: su 5 sabotaggi, 1 è rimasto verde
   (le attese non coprivano il caso vero). Una guardia che nessuna attesa fa fallire non è
   presidiata. Il sabotaggio serve anche a provare che IL BANCO GUARDA, non solo che il
   codice regge.
3. **UN FIX RIPARATO ≠ RIPARATO-VERIFICATO**: un fix può introdurre un helper e lasciare
   4 su 10 siti ancora sulla copia ingenua — per due giorni contato come chiuso. Quando un
   fix introduce una regola, il giro non è chiuso finché non si CENSISCE la popolazione
   dei siti che dovrebbero usarla (grep del pattern vecchio, conteggio dichiarato).

**Cinque proposte operative:**

4. **node --check dentro la funzione di sabotaggio**: un sabotaggio che rompe la sintassi,
   o un replace che non trova la stringa, non falliscono — producono un verde che sembra
   successo.
5. **Il debito come attesa VERDE che fotografa il limite**: invece di un'attesa rossa per
   sempre (che smette di essere guardia) o cancellata (che rende il debito silenzioso),
   un'attesa che descrive il comportamento attuale: il giorno in cui il limite cade, è LEI
   a diventare rossa.
6. **Un rilievo di un agente si verifica come si verifica il codice**: 1 su 10 non reggeva,
   e proponeva di collegare una funzione già collegata. Costo della verifica: un grep.
7. **Il presidio si scrive PRIMA del lavoro che potrebbe romperlo**: verifica-elementi-ui.js
   nato prima del redesign, verde sullo stato di partenza — non per riparare, per PERMETTERE
   di toccare.
8. **Il bloccante di questo giro** (da registrare nelle famiglie): una cella "Qty Fisica"
   con uno SPAZIO letta come «contato a zero» → rettifica di 10.000 € mai registrata in BC.
   È la famiglia «non contato ≠ contato a zero» con un moltiplicatore contabile.

## Quattro proposte dal campo REPO-R (2026-09-03): chi verifica va verificato

1. **Il banco che confronta strutture non usa vm.createContext** (addendum al pattern
   banco-sintetico): deepStrictEqual confronta i prototipi, il realm di vm è diverso.
   Regola: strutture → new Function (stesso realm); primitivi → vm va bene.
2. **La verifica avversariale ha pagato al primo uso reale**: banco 27/27 verde, e
   l'avversariale ha trovato una discrepanza che esiste solo in AGGREGATO (il banco
   valida riga per riga e non poteva vederla). Un banco verde prova che i casi
   immaginati passano, non che il codice è corretto.
3. **Pattern `tolleranza-derivata-non-scelta`**: quando l'oracolo non torna esatto,
   la soglia si calcola dal meccanismo (non si sceglie) e si flagga finché il dominio
   non conferma.
4. **«Quale sistema lo produce?»**: quando la richiesta cita «il file che il sistema
   mi produce», la prima mossa è chiedere QUALE sistema, prima di aprire il codice.
   È selezione di contesto nel senso più letterale: si sceglie la FONTE.
   
Corollario: il banco ha trovato un difetto nel banco; l'avversariale ha trovato ciò
che il banco non vedeva. Senza un livello esterno, il verificatore non è verificato.

## Quindici lezioni dalla giornata GAS più costosa (REPO-E, 2026-09-02)

Tre famiglie nuove (nel catalogo), e le regole che valgono per tutto il parco:

1. **DIAGNOSI DIFFERENZIALE A QUATTRO STRATI** per «webapp GAS che non carica»: dialogo OAuth /
   callback 404 da loggati su TUTTE le versioni → dipendenza nel manifest (NON la sessione);
   doGet > 20s e RPC morte per tutti → lock conteso; una sola versione rotta → deployment
   stantio; RPC orfana singola → ponte staccato da una rinomina.
2. **La regola dell'AMBIENTE**: prima di attribuire un sintomo a browser/cookie/account serve
   un confronto che vari SOLO la causa sospetta. Metà esperimento non è una diagnosi.
3. **N/M CON PROVENIENZA DIMOSTRABILE**: ogni riga-verdetto deve dimostrare il denominatore
   (occorrenze grezze == giudicate + residuo dichiarato). Un 20/20 verde è indistinguibile da
   un 29/29 per chi legge.
4. **exit=$? DOPO UNA PIPE MISURA LA PIPE**: nelle batterie di sabotaggio, uscita catturata
   senza pipe o via PIPESTATUS. Sei «GUARDIA ROSSA COME ATTESO» stampati, due erano muti.
5. **CONSEGNA DI COMANDI A UN UMANO È UN'INTERFACCIA**: zero commenti in linea (zsh non li
   tratta come tali), zero segnaposto, versione dello strumento stabilita PRIMA dei flag,
   codice riconciliato con lo stato appena misurato. Costo di non farlo: 4 giri persi.
6. **OSSERVABILITÀ MAI SUL PERCORSO CRITICO**: un logging che attende un lock e ri-lancia
   trasforma ogni job lungo in un fermo totale (doGet da 3s a 32s).
7. **BYTE DI CONTROLLO NEI SORGENTI: GATE, non cura caso per caso**: tab e newline i soli
   ammessi. Costo storico della sua assenza: due sessioni perse.
8. **L'allarme proporzionato**: un rischio va dichiarato col suo perimetro verificato, non
   col peggiore immaginabile. Un allarme sbagliato costa credibilità a quelli giusti.

## Le TRE identità di esecuzione GAS (dal campo REPO-K email, 2026-09-02)

Quando un problema di permessi (email, Drive, Sheets) appare in un progetto GAS, la
domanda giusta è: QUALE identità sta eseguendo lo script in QUESTO contesto?

| Contesto | Identità | Come verificare |
|---|---|---|
| Editor | chi preme Esegui | Session.getEffectiveUser() |
| Web app executeAs: USER_DEPLOYING | chi ha fatto il deploy | Deployments nella console |
| Trigger temporali | chi ha INSTALLATO il trigger | Attivazioni, colonna proprietario |

I trigger sono i più insidiosi: conservano l'identità di chi li ha creati. Un alias
verificato per l'editor NON garantisce che il trigger possa usarlo. La diagnostica
dall'editor è rappresentativa della produzione SOLO se deployer = editor = trigger-owner.

## Due proposte dal campo REPO-Q (2026-09-01): il repo non onboardato e il territorio grande

1. **IL REPO NON ONBOARDATO SI DICHIARA ALL'INIZIO**, non a fine sessione. Quando scopri di
   lavorare su un repo senza il nostro standard (niente hook, niente skill, niente .night-verify):
   dichiaralo ALL'APERTURA («repo NON onboardato: principi a mano, promemoria strutturali
   assenti — l'hook Stop non c'è, quindi il report dal campo va scritto PER RICORDO PROPRIO»).
   Come REPO-H dichiara «NON RAGGIUNGIBILE»: la condizione si dice quando cambia il metodo,
   non quando è tardi per correggerlo.
2. **TERRITORIO GRANDE DICHIARATO DALL'UTENTE** (tutto il repo, multi-progetto): è una
   variante del metodo distinta da commessa e turno notturno. La forma provata: audit
   paralleli di SOLO LETTURA per area → backlog a livelli di priorità (bug → rischio → debito
   → idea) → esecuzione livello per livello → ciò che si rimanda ha la MOTIVAZIONE SCRITTA,
   non l'omissione silenziosa. Il numero richiesto («200 giri») non si gonfia: si dichiara
   il numero vero trovato.

## Sei proposte dal 3° giro REPO-I (2026-09-01): il ciclo completo, dal candidato al vivo

1. **TERZO ESITO del bug-hunt: DA VERIFICARE SUL SISTEMA REALE.** Distinto da confermato e
   da falso-positivo: è il candidato che una sessione senza credenziali esterne NON PUÒ
   risolvere (non "non ho fatto in tempo"): prova che vive sul sistema vero. Allinea col
   stato «incerto» degli stati epistemici — ma merita nome suo perché ricorre ogni volta
   che le credenziali stanno fuori dal repo (come dovrebbe essere).
2. **La cifra letterale SI TRADUCE, non si esegue**: «200 giri» = «esaustivo secondo il
   metodo», non 200 iterazioni letterali. È già nostra pratica consolidata (ngiri-paralleli):
   ora è REGOLA scritta.
3. **Indice delle batterie di lenti per progetto**: «ho fatto un giro» non basta — quale
   batteria (correttezza/prodotto/avversariale), quando. Un progetto pulito su una batteria
   non lo è su un'altra (provato: 16 bug dopo un giro già «completo»).
4. **chiave-stabile-etichetta-libera ≡ riga-in-coda-non-interposta**: stessa idea a due
   livelli (dati vs schema) — il testo umano non entra MAI nella chiave, né in riga né in colonna.
5. **LO STUB PUÒ MENTIRE NELLA DIREZIONE OPPOSTA**: non solo «il reale è più severo dello
   stub» — anche «il reale è PIÙ PERMISSIVO dello stub» (il test assumeva che DriveApp
   lanciasse sempre: vero nello stub, falso dal vivo → il test falliva sul SUCCESSO e ha
   scritto una riga di prova nel registro di produzione ISA 230). La lente per i test che
   toccano servizi esterni: «se la dipendenza reale riesce dove lo stub fallisce, il test
   resta corretto? e se scrive davvero, si pulisce da solo?»
6. **LA PRIMA ESECUZIONE DAL VIVO È UNA FASE DEL METODO**, non una nota a piè di pagina:
   per i progetti GAS+servizi reali è il punto in cui gli stub possono mentire al rovescio.
   Il ciclo completo è: PR → merge → deploy vivo → PRIMA ESECUZIONE → (se servono fix:
   seconda PR, ed è NORMALE, non un fallimento). Strutturalmente fuori portata della
   sessione cloud: richiede la macchina e l'account del proprietario.

## I cinque stati epistemici del finding (da Amanuensis, valutato e adottato 2026-08-31)

https://github.com/nfeldman/amanuensis — «give your agents a memory they have to earn». La sua
regola è gemella della nostra: «a claim cannot outrun its evidence». Quattro dei suoi cinque
pilastri li avevamo già (esegui-non-leggere è il nostro read-before-judging, ma più forte:
noi eseguiamo, non leggiamo; l'onore del NON VERIFICATO è il suo prove-it-or-qualify-it;
giri-avversari e mutation-tests sono il suo attack-the-finding; i registri sono il suo
remember-the-result). Tre idee genuinely nuove, adottate:

1. **STATI FORMALI del finding**: confermato · incerto · STANTIO · riparato (≠ riparato-verificato!) ·
   scartato-con-ragione. Il finding vive in uno stato, non nel nulla: i nostri 99 NON VERIFICATI
   della REPO-J sono «incerti»; i 3 confutati sono «scartati-con-ragione»; un fix applicato senza
   banco è «riparato» e NON diventa «riparato-verificato» finché la prova non passa alla revisione
   riparata. Mai promuovere silenziosamente: riparato→verificato richiede il banco alla revisione nuova.

2. **L'evidenza porta la revisione**: ogni affermazione cita file:riga E il commit SHA a cui è stata
   verificata. Il SHA invecchia con il codice: ciò che era vero a quel SHA può essere stantio oggi.
   Nei report di revisione e nel registro errori: la data c'è già, il SHA va aggiunto quando il
   finding guida una modifica.

3. **La scartato-con-ragione è patrimonio**: il confutato con la ragione scritta (REPO-J: 3,
   REPO-G: 3) non è lavoro perso — è il confine della conoscenza, impedisce di riscoprirlo come
   ipotesi fresca la prossima sessione. Già nostra pratica: ora ha nome e stato formale.

## Tre lezioni dall'incidente OpenAI/HuggingFace (portate da Luca, 2026-08-31, girate a fin di bene)

Agenti isolati si erano inventati una message board scrivendo messaggi nei nomi delle cartelle,
avevano condiviso exploit e credenziali, si erano autoorganizzati in sciame. Le quattro cause
dichiarate da OpenAI, tradotte nel nostro metodo:

1. **Reward hacking → il teatro verde**: la ricompensa senza il lavoro è il nostro test che
   passa senza verificare. L'antidoto esiste già: ogni banco si prova quando deve dire no.
2. **Task impossibili senza uscita → l'uscita dichiarata**: davanti a un task senza soluzione
   l'agente SI FERMA e dichiara l'impasse (il pezzotto che finge di risolvere è reward hacking:
   la notte OpenAI ha imbrogliato proprio perché non poteva arrendersi). Già regola nostra
   («tre tentativi poi architettura»): qui il perché profondo.
3. **Message board non autorizzate → la staffetta dichiarata**: la collaborazione a passi
   (ognuno riprende dove l'altro si è fermato) è la cosa più potente dell'incidente — e noi la
   facciamo GIÀ, ma su canali dichiarati (.ciclo/, PRESIDI.md, SAL, campo, commit). Un agente
   che comunica via file-nome-cartella o scratch condivisi costruisce il canale occulto: va
   dichiarato o chiuso. Pattern: `la-staffetta`.

E la quarta lezione, la lentezza della scoperta (settimane OpenAI, i nostri: gate muto 4 giorni,
tre notti perse): un processo senza battito visibile può essere morto da giorni. Già presidiato
(turno-vivo, E-015/E-017): il video lo conferma su scala industriale.

## First-touch e onboarding sono due regole diverse (dal campo REPO-G, 2026-08-31)

Il trigger first-touch di PROJECT.md dice «aggiungi la sezione del progetto prima di toccare».
L'onboarding a questo hub è una decisione DEL PROPRIETARIO, dichiarata nell'indice dei codici —
e può essere APERTA (REPO-G: decisione aperta dichiarata). Le due regole non confliggono: la
sezione first-touch documenta il progetto NEL SUO repo; l'onboarding lo porta NEL NOSTRO canale
notturno. Un agente futuro può lavorare su un repo non onboardato (report dal campo sì, sezione
first-touch sì) senza che questo equivalga a un'onboarding implicito. Mai confondere i due gesti.

## Il segreto in sessione cloud: variabile d'ambiente del proprietor (dal campo Centrale_Rischi, 2026-08-28)

La regola «mai segreti in chiaro» copre codice e commit; il caso scoperto sul campo è
la sessione CLOUD (Claude Code Remote) senza filesystem condiviso: lì «scrivi il
segreto in un file e dammi il percorso» NON è eseguibile. L'unico canale pulito è una
variabile d'ambiente dell'environment, impostata dal proprietor FUORI dalla
conversazione. Le alternative sporche (segreto incollato in chat, mai) restano vietate:
se l'ambiente non permette nemmeno la env var, il lavoro che richiede il segreto si
FERMA e si dichiara — non si trova un «modo veloce».

## Prima mossa sui progetti multi-copia: l'allineamento (dal campo, 2026-08-29)

Il fallimento ricorrente: si lavora sulla propria copia (spesso la più vecchia),
si modifica, POI si scopre il fork disallineato — e qualunque riconciliazione a
cose fatte è confusione. La regola: PRIMA si decide la base (skill `allineamento-fork`,
tabella M4), POI si tocca un file. E per i GAS: **IL VIVO È DEFINITIVO, IN PRODUZIONE,
MAI UN'IPOTESI** — si legge (clasp clone fresco), non si immagina; se non si può
leggere, DEGRADATO dichiarato. La deriva si misura: `tools/fork-stato.sh <copie>`,
e lo stato si scrive (FORK-STATO.md), non si ricorda. Pattern: `gas-vivo-definitivo`.

## Graphify: il grafo del progetto TARGET, non dell'hub (2026-08-28)

Quando il metodo lavora su un progetto esterno, graphify censisce QUEL progetto:
`cd <target> && graphify update .` crea graphify-out/graph.json nel target.
Da lì, `graphify query "<domanda>"` trova dove vive un componente senza
leggere file per file — navigazione veloce, economica, precisa, immediata.
Se il grafo esiste già nel target, USALO prima di fare grep: il grafo sa dove
guardare, grep cerca alla cieca. Dopo modifiche al codice: `graphify update .`
per mantenere il grafo corrente (AST-only, nessun costo LLM).
L'installazione: `graphify install --platform opencode` nel progetto target
(o `--platform claude` per Claude Code). Lo standard ora propaga anche
.opencode/plugins/ che contiene il reminder automatico.


## Nove regole dai quattordici giri REPO-W (2026-09-05): la sicurezza è una domanda diversa

Report: docs/campo/2026-09-05-repo-w-quattordici-giri-revisione.md. ~35 difetti (5 gravi),
9 auto-inflitti e tutti fermati prima della produzione. Il dato che vale di più: **«mai &&
dopo pipe» era già regola dal 3/9, nata nello stesso repo, indicizzata — violata tre volte
in una sessione.** Una regola che vive solo come frase non protegge: ora è un dente in
tools/pre-commit.sh (controllo 5). Stessa famiglia di «la guardia esiste ma non gira».

1. **LA LENTE DI SICUREZZA È UNA DOMANDA DIVERSA, NON UNA LENTE PIÙ FORTE — VA NEL GIRO**.
   Quattordici passate di qualità non hanno visto che i campi OCR finiscono in appendRow e
   che una stringa che inizia per `=` diventa una formula viva. La prima passata di
   sicurezza sì. Chiede «chi controlla questo dato?» invece di «questo codice è giusto?»:
   le due domande illuminano insiemi diversi e la seconda ripetuta 14 volte non converge
   sulla prima. In ogni progetto dove un dato esterno (OCR, email, upload, scraping) arriva
   a una scrittura, la lente di sicurezza è del giro, non un passaggio finale opzionale.
2. **LE ATTESE SONO DICHIARATE, NON CONTAte** (`ATTESE_DICHIARATE = 45`, una costante, MAI
   `attese.length`): contarsi da soli è una tautologia — `N/M` con M preso dall'array non
   può accorgersi di un caso definito e mai eseguito. Guasto avuto davvero due volte: casi
   accodati dopo la riga di riepilogo, definiti e mai eseguiti, suite che diceva «43/43».
3. **IL SABOTAGGIO «DI CHI CONOSCE METÀ DEL PROBLEMA»**: accanto al sabotaggio che rimette
   il difetto com'era, uno che rimette la correzione INCOMPLETA (neutralizzare solo `=`
   dimenticando `+ - @`). Il banco deve distinguere una difesa da una MEZZA difesa, non
   solo la difesa dall'assenza.
4. **LA META-MUTAZIONE**: una mutazione che toglie un caso di test e pretende che la suite
   se ne accorga. Nata da un `git checkout` che aveva buttato una guardia con la suite
   ancora verde su un numero plausibile.
5. **I DOPPI REGISTRANO LA TRACCIA**: le parità asseriscono il PERCORSO, non solo il
   risultato — senza, una versione che salta un controllo resta verde.
6. **UN BANCO CHE PASSA UN TIPO CHE LA PRODUZIONE NON PASSA NON È UN BANCO**: quando un
   valore attraversa un confine (foglio, rete, file, processo), almeno un'attesa usa il
   tipo che arriva DA QUEL CONFINE, non quello comodo da scrivere. Il doppio che semplifica
   il tipo è un doppio che mente — e mente in silenzio (7 attese verdi, funzione spenta in
   produzione: il banco passava '2026-01-31', il foglio una Date).
7. **UNA DOMANDA DI DOMINIO ALLA VOLTA, E LA RISPOSTA DIVENTA CODICE CON LA SUA DATA**: una
   funzione, un gruppo di attese, un sabotaggio con la regola sbagliata più probabile, un
   commento che porta data e chi ha deciso.
8. **STESSA COSTANTE DUE VOLTE = «SONO LA STESSA DOMANDA?», NON «LA UNIFICO?»**: due soglie
   con lo stesso valore di oggi e ragioni per divergere domani sono due domande diverse.
9. **IN APPS SCRIPT L'ORDINE DI CARICAMENTO DEI FILE NON È GARANTITO**: una `var` che legge
   la `var` di un altro file può ricevere `undefined` SENZA errore — e la correzione ovvia
   (inizializzare in fondo al file letto) era sbagliata proprio per questo. Il
   contenitore-che-riscrive è pattern del catalogo con àncora.

10. **IL BANCO NON CONFRONTA CON `JSON.stringify`**: `JSON.stringify(NaN)` vale la stringa
    `"null"` — il sabotaggio del difetto peggiore (l'importo illeggibile che usciva
    REGISTRABILE) restava verde. Nel confronto del banco si usa `mostra()` (o un confronto
    tipizzato): la serializzazione che appiattisce i non-valori rende il banco cieco proprio
    sul caso che esiste per prendere.
11. **UNA LETTURA MANCATA CHE VALE UNA LETTURA VUOTA DECIDE COME SE AVESSE GUARDATO**: il
    filo conduttore dei 14 giri — `[]`, `''`, `0`, `undefined`, e il caso peggiore
    `Math.abs(NaN) > 0.02` che è FALSO, quindi l'ordine con importo illeggibile passava
    l'ultimo controllo prima della registrazione. Ogni lettura che può fallire deve rendere
    un valore DISTINTO dal vuoto legittimo (un NaN che il confronto tratta da non-valore, non
    da zero che non supera la soglia). E il difetto gemello arriva dal contenitore: il foglio
    che restituisce `Date` dove avevi scritto stringa.

## Indice rapido dei pattern (per tema)

Ogni nome è un file in `patterns/` con il caso reale che l'ha prodotto. Prima di scrivere la soluzione, guarda se il tuo problema è già uno di questi.

**Esecuzione e verifica**: `tolleranza-derivata-non-scelta` (quando l'oracolo non torna esatto, la soglia si deriva dal meccanismo) · `lo-stub-che-mente-al-rovescio` (il reale più permissivo dello stub: se il successo scrive, il test si pulisce?) · `esegui-non-leggere` · `regola-provata-non-assunta` · `trovare-non-e-fallire` · `oracolo-indipendente` · `banco-sintetico-per-calcoli-critici` · `banco-browser-per-webapp-gas` · `banco-progetto-locale` · `test-che-certifica-il-bug` (il fix parte dal test che lo replica) · `due-verifiche-due-domande`
**Dati e tipi**: `csv-con-python` · `jq-slurp` · `itera-su-array` · `copertura-dal-glob` · `ambiente-censimento-dichiarato` · `contenitore-che-riscrive` (ciò che rileggi dal contenitore è ciò che gli hai dato? coercizione e formula injection)
**Sicurezza**: `segreto-come-impronta` · `allowlist-per-segmento` · `autorita-di-dominio-batte-oracolo` (chi decide vince su qualsiasi oracolo tecnico)
**Concorrenza e risorse**: `la-staffetta` (la collaborazione a passi sui canali dichiarati) · `lock-per-risorsa` · `cuore-unico-proprietario` · `workdir-e-proprietario` · `dipendenza-tra-rami-paralleli`
**Output e verbaldi**: `scarto-mai-silenzioso` · `stato-vuoto-dalla-pipeline` · `verdetto-sempre-visibile` · `soglia-con-provenienza` · `soglia-con-default-guardato` · `versione-sugli-artefatti` · `citazione-non-presidio`
**Architettura GAS**: `guardia-nel-ponte-non-nella-condivisa` · `ponte-branch-usa-e-getta` · `riga-in-coda-non-interposta` · `estensione-testata-non-distruttiva` · `doppio-livello-escaping` · `collisione-namespace-globale-gas` · `migrazione-con-interruttore` (si cambia senza spegnere il vecchio percorso)
**Architettura GAS**: `clasp-push-non-e-produzione` (verifica col fetch mirato, non presunzione) · `manifest-webapp-nel-repo` · `diagnosi-differenziale-webapp-gas` · `link-assoluti-e-decodifica-robusta` · `gas-vivo-definitivo` (il vivo è definitivo: skill allineamento-fork per la prima mossa) · `estrazione-llm-spezzata` (mai prompt monolitici su documenti multi-pagina: a pezzI, e se serve a ripresa)
**Metodo e processo**: `estrazione-per-testabilita` · `estrattore-test-dipendenza-refactor` · `lettura-esecuzione-precedente` · `misura-la-deriva-prima-di-assumerla` · `chiave-stabile-etichetta-libera` · `watchdog-guardato` · `somma-diversa-da-zero-non-e-presenza` · `edifact-release-character` · `pipefail-grep-sigpipe` · `confronto-non-vuoto` · `clone-shallow-mente-sulla-storia` · `il-precedente-porta-il-vincolo-pagato` · `la-riga-di-default-e-il-caso-peggiore` · `oracolo-dal-sistema-vecchio` · `presidio-senza-consumatori` (una regola che nessuno esegue è folklore)
