# 2026-09-06 — REPO-E: Audit a 20 lenti: report al metodo AI_Programmer

**Autore**: sessione Claude Code (remoto), branch `claude/ai-programmer-quality-checks-01r90t`.
**Richiesta di partenza**: «un set di controlli qualità sul sistema — accuratezza, migliorie,
revisioni — con ogni agente e lente possibile, poi le correzioni sicure senza fermarsi,
ripetendo il processo 20 volte sempre con lenti differenti, e alla fine il report per
AI_Programmer».

Venti giri, venti lenti, venti commit. Ogni giro: una lente, i rilievi **verificati** uno per
uno, il banco scritto **prima** della correzione e visto fallire, la correzione, i sabotaggi,
il gate verde. Nessun deploy: `clasp` resta un gesto umano, negato tecnicamente dalla sessione.

**Aggiornamento dello stesso giorno.** Il ciclo si era chiuso con sette domande di dominio. Il
proprietario ha risposto a tutte e sette, una per volta, e ogni risposta è diventata un commit
con lo stesso metodo: **sette giri in più**, che questo report incorpora invece di rimandarli.
Ciò che hanno insegnato è la sezione *«Le sette domande di dominio — e le sette risposte»*, ed è
la lezione più diversa dalle altre sei: riguarda il limite di ciò che un agente può decidere.

---

## Il consuntivo, misurato

| | Prima (`a7da1eb`) | Dopo |
|---|---|---|
| Controlli nel gate | 9 | **28** |
| Attese eseguite dal gate | 254 | **877** |
| Banchi e controlli in `tools/` | 8 | **19** |
| Guardie difensive presidiate (setaccio di mutazione) | 7 su 33 | **26 su 56** |
| Funzioni pubbliche invocabili anonimamente | 118 | 134 (ma **0 scritture nude**, erano 13) |
| Presidi di autorizzazione nel roster | — | **49** |
| Citazioni `file:riga` verificabili | 0 | **18 per simbolo, 19 dichiarate come debito** |
| Ancore di pattern locali morte | 12 su 12 | **0** |
| Gesti del README eseguibili dall'editor | 3 su 29 | **34 su 34** |

20 commit per i venti giri, più 7 per le sette risposte di dominio. Gate verde prima di
ogni push. I numeri di questa tabella si rimisurano con `bash .night-verify`, non si ricordano.

---

## Cosa è stato chiuso, in ordine di gravità

**Il distruttivo.** `recalculateCurrentSnapshotImpl_` verificava TRE colonne su nove e
calcolava il valore totale da `Giacenza`, che non verificava mai. Su uno snapshot con quella
colonna assente o rinominata — e gli snapshot sono file **mensili**, generati da versioni del
codice vecchie di mesi — `row[-1]` è `undefined`, `Number(undefined) || 0` è 0, e il valore di
ogni riga a zero **veniva scritto sul file**, con la funzione che rispondeva `success: true`.
La perdita permanente del valore di un mese di magazzino, senza eccezione e senza log. Ogni
salvataggio e ogni rimozione di override passa di lì.

**I nove-mila-ottocento euro.** `getMonthlyRectificationValueSummary` saltava in silenzio ogni
riga la cui `DataChiusura` non fosse un oggetto `Date`. Su quattro righe chiuse nel mese, una
sola data reincollata come testo faceva riportare −2.650,15 € invece dei −12.450,15 veri. È
l'unico numero che va in chiusura contabile.

**Le tredici scritture pubbliche nude.** Il confine pubblico di Apps Script è il trattino
**finale**: 118 funzioni pubbliche contro 25 ponti usati dalla dashboard, e tredici delle altre
scrivevano — fra cui `writeArticoliUbicazioni` (`clearContent()` sul foglio delle ubicazioni) e
`_notifyDailyInventoryTriggerFailure` (MailApp). Due col trattino **iniziale**: credute private
da chi le aveva scritte. Più due endpoint che aprivano per id un file qualunque del Drive del
proprietario, con errori distinguibili — cioè un oracolo per enumerarlo.

**La giacenza che smetteva di essere un numero.** In JavaScript `0 + "219"` non è 219: è
`"0219"`. L'unico dei cinque siti che leggevano `Quantity` senza coercizione era quello che
calcola la giacenza dello snapshot. Non serviva un dato sporco: bastava che BC serializzasse
un numero come stringa.

**Il calendario che si spegneva per una riga.** Bastava aggiungere a mano al tab delle festività
il patrono locale del 2028 — il gesto che il tab stesso invita a fare — perché le dodici
nazionali di quell'anno non venissero più calcolate. Natale lavorativo, e con lui Pasqua e
Ferragosto, su tutti e tre i trigger giornalieri.

**E poi**: l'XSS a due strati negli `onclick` (provata *eseguendo* il payload), la cache del
catalogo che non era mai stata scritta una volta, la leva anonima sulla quota del proprietario,
la doppia email a operations, il pannello salute che mentiva, le soglie all'italiana troncate
in silenzio, l'ultimo `toISOString` in un filtro BC, il mese contato due volte nelle serie.

---

## Le sette cose che il metodo ha prodotto e che valgono oltre questo progetto

### 1. Il tema che nessuna lente cercava, e che tutte hanno trovato

Quattro lenti indipendenti — confine dei dati, Business Central, concorrenza, meta-lente sul
banco — hanno consegnato lo stesso esito senza essersi parlate: **non è un progetto disattento,
è un progetto che corregge per SITO invece che per FAMIGLIA**.

Il conto, per il solo ciclo di oggi: `_numOrDefault_` esisteva e un lettore di config su nove
non lo usava; `_hasPhysicalCount` esisteva e un predicato su dodici era scritto a mano;
`_numeroOverride_` esisteva e due gemelli leggevano ancora con `parseFloat`;
`assertSheetIdInPhysicalInventory_` esisteva ed era usata in tre siti su cinque; il tie-break
sugli snapshot doppi proteggeva `[0]` e non i cinque consumatori di serie; il check-then-act era
stato messo sotto lock in due siti su tre; la guardia `indexOf < 0` era stata aggiunta alle
gemelle e non ai due siti che il commento del fix **cita per nome**.

Il report del 2026-09-03 aveva già proposto la cura al canone: *«quando un fix introduce un
helper o una regola, il giro non è chiuso finché non si è censita la POPOLAZIONE dei siti che
dovrebbero usarlo»*. Oggi quella proposta è **messa a regime**: metà delle attese dei banchi
nuovi non sono comportamentali, sono censimenti di popolazione che tornano rossi se una forma
ingenua ricompare.

### 2. Una guardia con N clausole ha bisogno di N attese

È il rilievo più generalizzabile del ciclo, e lo ha trovato il setaccio di mutazione applicato
al lavoro dell'audit stesso.

`_indexSnapshotRowsByGroup_` controlla **sei** colonne in un solo `if`. Il banco ne rinominava
**una** — il caso vero di uno snapshot vecchio — e la guardia risultava presidiata. Neutralizzando
le clausole una per una: cinque coperte per rimbalzo, la sesta da niente. Lo stesso per due
guardie scritte da questo stesso audit dodici ore prima: `_sumSnapshotTotals_` ne verifica tre e
il banco ne provava due.

**Un banco che prova una clausola presidia 1/N della guardia, e la frazione non si vede: il
verde è identico.** È la generalizzazione della lezione del 2026-09-03 («un'attesa che
passerebbe anche col difetto presente è peggio di un'attesa assente»): qui l'attesa non passava
col difetto presente — passava con cinque sesti del difetto presente.

**Proposta al canone**: quando un'attesa prova una guardia composta, il banco cicla sulle
clausole. Se ciclare è troppo, il numero di clausole coperte va scritto accanto all'attesa.

### 3. Il verso della correzione dipende da chi legge e da chi scrive

Tre volte in venti giri la stessa domanda — *cosa fare quando lo schema non si sa leggere* — ha
avuto tre risposte diverse, e la differenza non era di gusto:

- `_sumSnapshotTotals_` **legge** per disegnare una serie storica: un `throw` avrebbe fatto
  sparire ventiquattro mesi di storico buono per un file del 2025. → **saltare e dichiarare**.
- `readInventoryDataComplete` **legge** per dare i numeri di oggi: zeri finti sono peggio di un
  errore. → **fermarsi**.
- `recalculateCurrentSnapshotImpl_` **scrive**: rifiutarsi di scrivere su uno schema che non si
  sa leggere è sempre più sicuro che scrivere zeri. → **fermarsi, sempre**.

**Proposta al canone**: prima di scegliere fra «fermati» e «salta e dichiara», guarda se la
funzione LEGGE o SCRIVE, e se la sua uscita è una SERIE o un NUMERO DI OGGI. Le tre risposte
sono diverse e nessuna è la prudente per default.

### 4. Il gate non guardava sé stesso, in quattro modi diversi

Il ciclo ha trovato quattro buchi *nel gate*, tutti provati facendo passare in verde un difetto
vero:

1. **Nessun pavimento sulle attese.** Ogni banco stampava `N/N` col denominatore preso dal
   numeratore: commentando tre attese, `27/27` diventava `24/24` e il gate restava verde. Le
   «254 attese» dichiarate non erano presidiate da niente, e cancellare un'attesa scomoda era il
   modo più silenzioso di far passare un fix.
2. **Nessun perimetro sui controlli meccanici.** Con un solo file `.gs` il controllo di sintassi
   stampava `1/1` ed usciva 0.
3. **Il perimetro che il redesign aveva superato.** `verifica-elementi-ui.js` leggeva gli
   `onclick` solo dall'HTML statico; il redesign aveva spostato la tabella dentro il JS. Quindici
   azioni su settantuno fuori perimetro — e il controllo era nato tre giorni prima proprio per
   quel modo di guasto.
4. **Il gate non controllava la sintassi dei propri strumenti.** Scoperto committando uno script
   rotto: gli strumenti `.js` falliscono solo se il gate li esegue, e quelli `.sh` che non
   esegue non li guardava nessuno.

**Proposta al canone**: un gate dichiara sempre il proprio **perimetro** (quanti file, quante
attese, quali sorgenti) e ha un **pavimento**; e la sintassi degli strumenti del gate è parte
del gate.

### 5. Il costo dei falsi positivi è la fiducia, e si paga subito

Quattro volte in venti giri un controllo statico appena scritto ha misurato **la prosa invece
del codice**: la parola `return` dentro `early-return` in un commento; una JSDoc che *mostrava*
la forma di un handler; il commento del wrapper vicino letto come corpo; la prima parola di una
frase italiana letta come percorso. E due volte un'attesa ha presidiato **l'ortografia** invece
della regola: una rinomina innocua faceva rosso il gate.

Ogni volta la stretta è costata una riga. Ma un controllo che segnala il codice giusto insegna a
ignorarlo, e allora smette di proteggere anche quando ha ragione. **I commenti si tolgono prima
di contare, e un'attesa presidia una regola, mai una stringa.**

### 6. Una lezione scritta non è una guardia — e questo ciclo lo ha dimostrato su sé stesso

Il report del 2026-09-03 chiudeva con *«finché una lezione è solo scritta, è folklore»*. Questo
ciclo l'ha ripagata quattro volte, e ogni volta su **me**:

- **Il backtick** dentro un template literal: rotto **sei** volte (quattro in JS, una in shell, e
  la sesta committata). Il report precedente lo segnalava come già ripetuto due volte.
- **Il cross-realm nei banchi `vm`**: `deepStrictEqual` che fallisce sul prototipo invece che sul
  difetto, ripetuto quattro volte. E una **quinta variante nuova e peggiore**: `instanceof Date`
  su una `Date` creata in Node fallisce dentro il contesto `vm` — quello sbaglia il *confronto*
  e si vede dal messaggio, questo sbaglia il **verdetto** e sembra una scoperta.
- **Il trattino finale**: nel giro 1 ho reso privata `testGetItemHistory`, una prova manuale da
  editor, ripetendo alla lettera l'errore che un commento di questo repo descrive
  (*«stesso mestiere di doSetupPhysicalInventoryFolderId, a cui l'audit aveva messo l'underscore
  rompendo proprio la sua ragione di esistere»*). Il commento c'era. L'avevo letto. L'ho rifatto
  quindici giri prima di accorgermene.

Tutte e tre sono ora **guardie** — controllo 26 per il backtick, la ragione scritta dentro i
banchi per il cross-realm, controllo 23 per il trattino finale. Non perché scriverle non serva,
ma perché scriverle non basta.

### 7. La domanda al proprietario del dominio non sceglie fra i rimedi che hai preparato

Le sette domande hanno avuto risposta, e il gruppo delle risposte dice qualcosa che nessuna
singola risposta direbbe: **una sola** ha portato a togliere codice, **due** hanno cambiato una
cifra o la forma dei dati, **due** non hanno toccato il comportamento e hanno solo fatto *dire*
al sistema ciò che già faceva, **una** era una decisione presa che nessuno aveva scritto, **una**
era un errore nostro travestito da contraddizione del sistema. Un agente che avesse «corretto in
autonomia» avrebbe sbagliato verso in almeno quattro casi su sette, e in due avrebbe mosso cifre
contabili.

Ma il punto più forte è un altro, e vale come regola: **una risposta può invalidare entrambi i
rimedi che avevi preparato.** Sulla domanda 4 avevo proposto una colonna `Origine` sul tab come
alternativa all'euristica. La risposta — «sì, un anno in cui si lavora a tutte e dodici capita» —
non ha scelto fra i due: ha mostrato che **il tab è esattamente ciò che può essere svuotato**, e
quindi che il fatto («questo anno l'ho popolato io») doveva vivere fuori dal tab. La colonna è
rimasta, ma per un altro mestiere: non serve al codice per decidere, serve a chi apre il foglio
fra due anni. Il rimedio giusto è nato dalla risposta, non era fra le opzioni.

Corollario operativo: **due delle sette risposte sono state «misura prima di toccare»**, ed
entrambe si sono realizzate in codice che non cambia nulla e fa parlare il sistema (una riga di
log che dichiara quale ramo ha girato; una diagnostica di sola lettura che conta i casi che
cambierebbero cifra). È una forma di consegna che vale la pena avere in repertorio: quando la
correzione è una decisione e non un fix, **lo strumento che la renderà decidibile è consegnabile
subito**, e non richiede il permesso di nessuno.

---

## Il sabotaggio come strumento, e i sei che sono restati verdi

Su **cinquantasette sabotaggi** dichiarati nei venti commit, **sei sono restati verdi al primo
colpo**. Nessuno era un sollievo, e tre hanno cambiato il disegno della correzione:

| Sabotaggio | Cosa ha insegnato |
|---|---|
| Tolgo `assertSessioneWeb_` da `saveOverride` (giro 1) | Restava verde **tutto il gate**: nessun controllo presidiava la guardia dei ponti che scrivono. Ha generato il roster dei presidi attesi, oggi 45 voci. |
| Tolgo la guardia da un wrapper del toolkit (giro 16) | Stesso buco **riaperto dai 27 wrapper appena aggiunti**: pubblici, delegano tutto, il controllo sulle scritture dirette non li vede. Sono entrati nel roster. |
| Disattivo il controllo sul blocco di cache mancante (giro 14) | Il fail-safe reggeva grazie alla seconda difesa, ma l'attesa cercava un generico `/WARNING/` e non sapeva dire **quale** guardia avesse sparato: presidiava due difese in serie come se fossero una. |
| Rimetto pubblica una funzione (giro 16, ×2) | Il "corpo" letto conteneva la JSDoc del vicino. |
| Disattivo il ramo che usa la configurazione (giro 5) | **Non era un difetto**: il fallback mascherava comunque. Un sabotaggio che non produce il difetto non è un sabotaggio. |

E due sabotaggi **non si sono applicati**, salvati da un'assertion sul conteggio: la stringa
bersaglio compariva due volte, o zero. Senza quell'assertion sarebbero stati due verdi che
sembravano successi — è la proposta n.1 del report del 2026-09-03, ripagata due volte.

---

## Le sette domande di dominio — e le sette risposte, lo stesso giorno

Il ciclo si era chiuso con sette domande. **Tutte e sette hanno avuto risposta il 2026-09-06**,
una per volta, dal proprietario del dominio; ogni risposta è diventata un commit, con lo stesso
metodo dei venti giri (banco prima, rosso misurato, sabotaggio, gate verde). È la parte del
lavoro che nessuna lente poteva fare: **due letture simmetriche, correzioni opposte, e nessuna
è il default sicuro**.

1. **`generalCostsPercent` era letto, validato, messo in cache e non applicato a niente.**
   → *Via il foglio.* Zero aritmetica dietro sette occorrenze: era una configurazione che
   istruiva l'utente a scrivere un numero che nessun calcolo consumava. Ironia utile al metodo:
   il fix MS-2 di questo ciclo aveva **indurito la lettura di un valore che nessuno usa**.
2. **Il valore di magazzino ufficiale include o esclude i magazzini secondari?**
   → *Li include.* Vince l'email mensile, perde la dashboard. Conseguenza dichiarata e voluta:
   cambiano anche i punti **passati** del grafico, perché sono ricalcolati dagli snapshot a ogni
   lettura. Il KPI ora dichiara quanto viene dai secondari — un totale che sale senza dire perché
   sarebbe solo un altro numero non spiegato.
3. **Il perimetro di LETTURA della webapp è una decisione o un'eredità?**
   → *È una decisione.* Nessuna modifica al codice: l'asimmetria fra i due confini è ora scritta
   in `AccessoWeb.gs` accanto a quella sulla scrittura, insieme a **cosa la rimetterebbe in
   discussione** (un dato di natura diversa: prezzi di vendita, anagrafiche clienti, margini).
4. **Può esistere un anno in cui si lavora a TUTTE le dodici festività nazionali?**
   → *Sì.* E questo uccide non un'euristica ma **la categoria**: se tutte e dodici possono essere
   cancellate a mano, l'ultima cancellazione porta via anche l'ultima prova che l'anno fosse
   stato popolato. Il fatto che serve — «questo anno l'ho popolato io» — non è deducibile da
   righe che possono essere zero. Registro negli Script Properties (che nessuna cancellazione di
   righe tocca) + colonna `Origine` sul tab, che al codice non serve e a chi apre il tab fra due
   anni sì.
5. **Una funzione col trattino finale è eseguibile dall'editor?**
   → *No*: ha ragione la fonte che dichiarava una misura. Il report di campo del 2026-09-03
   elencava fra i gesti umani due diagnostiche «dall'editor» che **nessuno poteva compiere**.
   Corretto in calce a quel report, annotato come **errore nelle nostre note, non difetto del
   sistema** — la distinzione che il canone chiede di non confondere. Le due diagnostiche hanno
   ora il loro wrapper guardato.
6. **`Standard_Cost` e `Blocked`**, letti da `createInventoryItem` e in nessun `$select`.
   → *Prima si misura.* Il calcolo non si tocca: `diagnoseCampiCostoBC_` chiede a BC se quei
   campi sono serviti, se un `$select` che li nomina viene accettato o rifiutato, e — la domanda
   vera — quanti articoli hanno `Unit_Cost` **assente**, non zero. Solo quelli cambierebbero
   cifra: è l'ultima riga della famiglia «assente≠zero», e una diagnosi che li sommasse non
   risponderebbe alla domanda che le è stata fatta.
7. **`$skip` senza `$orderby`** nel ramo di riserva della paginazione BC.
   → *Prima si misura.* La riga di log dichiara con quale dei due rami la sequenza si è chiusa —
   e dichiara anche quando **nessuno dei due** è stato esercitato (una pagina sola), invece di
   inventare una risposta. Comportamento invariato.

**Cosa insegna il gruppo delle sette.** Nessuna era indovinabile leggendo il codice, e le
risposte non si distribuiscono come un audit si aspetterebbe: **una sola** ha portato a togliere
codice (1), **due** hanno cambiato una cifra o una forma dei dati (2, 4), **due** non hanno
toccato il comportamento affatto e hanno solo fatto *dire* al sistema ciò che già faceva (6, 7),
**una** era una decisione già presa che nessuno aveva scritto (3), e **una** era un errore nostro
travestito da contraddizione del sistema (5). Un agente che avesse "corretto in autonomia" avrebbe
sbagliato verso in almeno quattro casi su sette — e in due di questi avrebbe mosso cifre contabili.

Vale anche il contrario: **la domanda 4 ha cambiato la mia soluzione, non solo il suo verso.**
Avevo proposto una colonna `Origine` come rimedio; la risposta («tutte e dodici, sì, capita») ha
mostrato che una colonna sul tab non basta, perché il tab è esattamente ciò che può essere
svuotato. Il fatto doveva vivere altrove. Una domanda ben fatta non sceglie fra due rimedi
preparati: può invalidarli entrambi.

Restano inoltre **30 guardie difensive non presidiate** (setaccio di mutazione, `tools/setaccio-guardie.sh`),
con il limite dichiarato: il numero è un pavimento del debito, non un conteggio.

---

## I diciannove presidi lasciati nel gate

| Controllo | Attese | Cosa impedisce |
|---|---|---|
| `verifica-superficie-pubblica.js` | 134 | Una scrittura o una lettura per id invocabile anonimamente; e la perdita di uno dei 49 presidi |
| `banco-confine-bc.js` | 45 | La giacenza che diventa una stringa; il tenantId in chiaro nei log; la paginazione che non dice quale ramo ha usato; assente confuso con zero sui costi BC |
| `banco-mezza-strada.js` | 50 | Le forme ingenue che ricompaiono accanto all'helper indurito |
| `banco-escaping-onclick.js` | 30 | L'iniezione a due strati (provata eseguendo il payload) |
| `banco-guardie-non-presidiate.js` | 37 | Tre fix del 2026-09-01 che nessuna attesa faceva fallire |
| `banco-concorrenza-e-serie.js` | 11 | Il mese contato due volte; il check-then-act senza lock |
| `banco-guardia-cieca.js` | 14 | Il pannello salute che dice «mai eseguito» a un record illeggibile |
| `banco-contratto-fogli.js` | 24 | La scrittura di zeri sullo snapshot; il trim che manca a chi legge |
| `banco-date-e-calendario.js` | 14 | Il calendario spento da una riga; la finestra di sei giorni |
| `banco-aritmetica-contabile.js` | 25 | Le righe fuori dalla chiusura contabile; l'override confermato che non esiste |
| `banco-prestazioni-e-quote.js` | 17 | La cache a metà; la leva anonima sulla quota |
| `banco-idempotenza-invii.js` | 18 | La doppia email a operations, e la prenotazione che non scade |
| `verifica-citazioni.js` | 36 | Una citazione a un file, una riga o un simbolo che non esiste |
| `verifica-toolkit-operativo.js` | 34 | Un gesto documentato che non è eseguibile |
| `verifica-numeri-dichiarati.js` | 2 | Un numero nei documenti che non è più vero |
| `verifica-ancore-pattern.js` | 48 | Un pattern che si dichiara ancorato a codice che non c'è |
| sintassi di `tools/*` | 30 | Uno strumento del gate committato rotto |
| `banco-perimetro-magazzini.js` | 18 | Le tre risposte diverse sullo stesso snapshot; il KPI che non dichiara il proprio perimetro |
| `banco-festivita-origine.js` | 25 | Dodici festività cancellate apposta e rimesse dentro dal ricalcolo |

Più i preesistenti (`banco-override` 93, `banco-conta-fisica` 27, `banco-trigger-senza-loglib` 18,
`banco-soglie-e-date` 26, `banco-letture-difensive` 34, `verifica-ponti-rpc` 29,
`verifica-byte-controllo` 19, `verifica-elementi-ui` 2) e la sintassi dei 16 `.gs`.

**28 controlli, 877 attese, exit 0.** (`bash .night-verify` — il numero si rimisura, non si ricorda.)

---

## Il gesto umano che resta

- **Il deploy**, dal Mac di Luca. `clasp` è negato tecnicamente dalla sessione.
- **Le tre diagnostiche di sola lettura**, eseguite dall'editor: `diagnoseCampiCostoBC_()` (che
  chiude la domanda 6 con un numero), `diagnoseRettificheFantasma_()`, `diagnoseBCLocationVuota_()`.
  Più una lettura dei log dopo una notte di trigger, che chiude la domanda 7.
- **`migraFestivitaOrigine_()`**, una volta sola su questa installazione: finché non gira,
  `readFestivita` usa l'euristica di prima — e lo dichiara in log a ogni lettura.
- *(Le sette domande di dominio non sono più fra i gesti che restano: hanno avuto risposta lo
  stesso giorno, e le risposte sono nella sezione qui sopra.)*
- **Una review visiva** della dashboard sul vivo: il pannello salute ha uno stato nuovo
  (`ILLEGGIBILE`, ambra) che nessuno ha ancora visto a schermo.
- **`tools/setaccio-guardie.sh`**, quando si vorrà sapere se il debito di copertura scende.
