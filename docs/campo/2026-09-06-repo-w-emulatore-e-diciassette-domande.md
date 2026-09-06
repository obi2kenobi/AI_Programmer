# 2026-09-06 — REPO-W: un emulatore che chiude la catena, e diciassette domande di dominio

Autore: Luca + sessione Claude Code (remota). Repo: REPO-W (GAS+BC, fatture fornitore estere).
Seguito di `2026-09-05-repo-w-quattordici-giri-revisione.md`.

Due archi in una giornata, e vale la pena tenerli distinti perché insegnano cose diverse.

**Notte, non sorvegliata**: costruito uno strumento che percorre la catena completa (crea ordine →
scrive quantità → registra carico e fattura → rilegge) contro il sistema vero in sandbox. Tre
domande tecniche aperte da settimane chiuse in **dieci tentativi**, non cento. Una di esse
*falsificata*: la strada che il progetto sperava di poter prendere non esiste.

**Giorno, con Luca presente**: **diciassette domande di dominio, tutte risposte in un giro solo**.
Ma la cosa che conta non è il numero: è che **nove avevano una parte che il sistema sapeva già
dire**, e in due casi la misura ha **smentito** ciò che stavo per far confermare a voce.

Esito sulla richiesta a un fornitore esterno di sviluppo: **due voci eliminate** (un campo che non
esiste da nessuna parte, e una scrittura che era già possibile), **una voce aggiunta** che nessuno
aveva contato, **due voci declassate** da «con parametro» a «basta che scatti». Gate: da 6 a 8
verifiche dichiarate.

## Cosa ho usato

- **`gas-agent`**, specialista BC: 69 righe di buone pratiche generiche, **niente** sul problema.
  Seconda volta che lo dichiaro a vuoto. La sua regola CRITICAL sulle credenziali invece ha deciso
  due scelte di disegno vere.
- **La disciplina dei banchi del canone** portata su un **linguaggio nuovo**: attese dichiarate,
  doppi che registrano le chiamate, sabotaggi con la loro dichiarazione. Ha funzionato, e ha
  trovato due difetti **suoi** prima ancora che del codice.
- **La documentazione ufficiale del prodotto**, non la memoria: numeri di oggetti interni verificati
  sulla fonte prima di citarli. È una regola che questo repo si era già dato dopo un rimprovero.
- **Il gruppo di controllo**, due volte in un'ora.

## Cosa ho improvvisato

### 1. Rispondere a una domanda di dominio con una misura

Le diciassette domande erano nate per una persona. Su nove, il sistema sapeva già rispondere — e la
sua risposta è arrivata prima, e in due casi ha **contraddetto** l'ipotesi che stavo per far
confermare:

- avevo archiviato due volte un campo come «non è quello»; poi una frase dell'utente me lo ha fatto
  sospettare di nuovo; la misura ha detto che l'archiviazione **era giusta** (28 righe su 809
  valorizzate, e con valori che non potevano significare quello che speravo);
- avevo dedotto che una certa configurazione fosse attiva; il gruppo di controllo ha detto il
  contrario, su 146 righe e zero eccezioni.

**Il modello che ne esce**: prima di portare una domanda a una persona, guardare se il dato è già
scritto da qualche parte. Si chiede solo ciò che il sistema non sa — e ciò che resta è **davvero**
dominio, cioè decisione, non rilevazione.

### 2. Spaccare una domanda quando la risposta è ambigua

Due volte, la stessa forma. Una risposta netta dell'utente («arrivano separati», «replica il
modello A») copriva **due dimensioni indipendenti** che io stavo per trattare come una:

| Sembrano sinonimi | Non lo sono |
|---|---|
| *quando arrivano i documenti* | *quando si registra a sistema* |
| *quali regole segue un flusso* | *in quale momento avviene* |

In entrambi i casi prenderle per la stessa cosa avrebbe costruito la cosa sbagliata, e in un caso
avrebbe fatto chiedere a un fornitore uno sviluppo **non necessario**. Ho aperto due domande nuove
(`A1b`, `D2b`) invece di tirare a indovinare.

### 3. Un documento condiviso al posto della chat

Le domande sono finite in un file versionato: numerate, ognuna con scritto **perché conta** e
ancorata a un fatto misurato, ognuna con una riga `Risposta` vuota e una data. In testa, un
**conteggio dichiarato** (domande / bloccanti / risposte).

Effetti che non mi aspettavo così forti:
- l'utente ha risposto a tutte e diciassette **di fila**, chiedendo «una alla volta»;
- ogni risposta è diventata subito un commit, quindi il *perché* di una decisione è ancorato al
  giorno in cui è stata presa;
- il conteggio ha preso **due miei errori in un'ora**.

## Cosa ha retto / ostacolato

**Ha retto, e si vede:**

- *«Un numero senza gruppo di controllo non è una misura»*: mi ha fermato due volte. Una
  correlazione che stavo per scrivere (`tutte le righe divergenti hanno più versioni archiviate`)
  si è dissolta guardando il fondo: **anche quelle che non divergono, il 100%**.
- *«L'errore si mette a regime»*: un difetto della misura contava righe di commento e conti
  contabili fra gli «scostamenti». Il numero era gonfiato **oltre tre volte** — e su quel numero
  avevo già costruito una raccomandazione, detta a voce. Corretto in loco, registrato, guardia
  vista rossa sul difetto vero.
- *«Done means proven»*: al passo decisivo mi ha fermato il mio stesso metodo. Avevo scritto un
  campo con **lo stesso valore che c'era già** e preso il `200` per una prova. Non lo era.

**Ha ostacolato — o meglio, è mancato:**

- il canone **non dice cosa fare quando una misura corregge una raccomandazione già data**. L'ho
  fatto (correggo in loco, registro, ridico a voce) ma l'ordine l'ho deciso io;
- il canone **non dice cosa fare quando l'utente supera una regola dopo che gliel'hai spiegata**;
- il canone **non dice come comportarsi quando chi decide va a dormire** e lascia le chiavi.

## Proposta al canone

### 1. «Chiedi solo ciò che il sistema non sa» — prima di ogni domanda di dominio

Su diciassette domande, nove avevano una parte misurabile. Portarle a una persona *senza averla
misurata* significa chiedere di ricordare ciò che si può leggere — e la memoria di chiunque perde
contro un conteggio su duemila righe. In due casi la misura ha smentito l'ipotesi.

**La forma**: ogni domanda di dominio nasce con due parti dichiarate — *cosa può dire il sistema* e
*cosa può dire solo una persona*. Si misura la prima, si chiede la seconda. Ciò che resta da
chiedere è più corto, più preciso, e non fa perdere tempo a chi risponde.

### 2. Il conteggio dichiarato vale anche fuori dai banchi

Il canone ha `ATTESE_DICHIARATE`: un banco dichiara quante prove ha e va rosso se ne esegue meno.
Ho applicato la stessa forma a un **documento di testo** — un elenco che dichiara quanto è lungo — e
ha intercettato due miei errori in un'ora.

**Generalizzazione**: *ogni elenco che cresce dichiara la propria lunghezza, e un controllo la
verifica.* Vale per banchi, per registri, per liste di domande, per cataloghi. Costa tre righe.

### 3. Il controllo va INCATENATO all'azione, non messo accanto

Ho committato una volta con il conteggio **già rosso**: il comando di verifica stava nella stessa
riga del commit, ma separato da `;` invece che da `&&`. Il controllo ha parlato, e non ha fermato
niente.

**La regola**: `verifica && azione`. Un controllo che non può impedire l'azione che sorveglia non è
un presidio: è un commento. È parente stretto della regola «mai `&&` dopo una pipe» nata in questo
stesso repo — e come quella, era **scritta e non presidiata**.

### 4. Una regola sul lavoro non sorvegliato

Quando chi decide non c'è — «vado a letto, arrivaci tu» — il confine va **dichiarato prima di
iniziare**, e in termini di **irreversibilità**, non di rischio percepito:

- cosa posso **consumare** (documenti di prova in un ambiente di prova: sì);
- cosa posso **rompere** (niente che sia in produzione, per costruzione e non per disciplina);
- cosa resta **fermo fino al mattino** (le decisioni di dominio, sempre).

L'ho scritto **dopo** averlo applicato, che è il momento in cui si sa se regge. Ha retto.

### 5. Cosa fare quando una regola sul segreto è già stata superata

Il canone vieta di far passare un segreto dalla chat, e spiega le alternative. Ma **si ferma al
divieto**: non dice cosa fare quando l'utente, dopo aver ricevuto la spiegazione, lo fa lo stesso
perché vuole che il lavoro proceda.

La risposta che ho dato, e che propongo di scrivere:

1. **usarlo** — rifiutare dopo che il danno è fatto aggiunge un costo senza togliere l'esposizione;
2. **dirlo una volta sola**, senza moralismi: *è passato di qui, va ruotato*;
3. **dichiarare la conseguenza concreta** invece di quella generica: non «attenzione ai segreti» ma
   «quel valore va sostituito, e finché non lo fai resta valido»;
4. **non cancellare per far finta**: ho rimosso il file dal disco, ma quando l'utente ha chiesto di
   riprendere ho detto che era ancora fra gli allegati della sessione — che è un'altra ragione per
   ruotare, e tacerla sarebbe stato peggio.

### 6. Come accorgersi che il proprio doppio è compiacente

Il canone dice che i doppi devono poter **dire di no**. Non basta: due volte in una notte il banco
è rimasto verde su un difetto perché il doppio non sapeva **dove** dire di no — rispondeva «va
bene» a chiamate che il sistema vero rifiuta.

**La lente che ha funzionato, e che propongo come passo obbligato**: *ogni volta che il sistema vero
rifiuta qualcosa, il doppio impara a rifiutare la stessa cosa, con lo stesso messaggio.* Non come
principio generale — come azione dovuta dopo ogni errore trovato sul campo.

### 7. Un numero implausibile è un sintomo, non un dato

Il difetto più costoso della giornata non è saltato fuori da un controllo: è saltato fuori da
un'**altra domanda**. Misurando la grandezza degli scostamenti è uscita una mediana del **100%**,
che è assurda — vuol dire «non è arrivato niente» su metà dei casi.

Quella assurdità ha fatto guardare meglio, e sotto c'era un difetto che gonfiava un numero di tre
volte. **Se quella seconda domanda non fosse stata posta, il numero sbagliato sarebbe rimasto** — e
sarebbe rimasta anche la raccomandazione che ci poggiava sopra.

**La regola**: quando un risultato è troppo netto o troppo strano, si guarda la misura prima di
guardare il mondo. Un `100%`, uno `0`, un `sempre` sono affermazioni forti: vanno guadagnate.
