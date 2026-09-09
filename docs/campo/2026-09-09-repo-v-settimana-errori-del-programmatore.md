# 2026-09-09 — REPO-V: una settimana di errori del programmatore, contati
**Autore**: sessione AI_Programmer (Claude Code), su richiesta di Luca dopo una giornata
in cui gli ho fatto perdere tempo tre volte di seguito.
**Periodo**: 2026-09-03 → 2026-09-09 (sette giorni, REPO-V (magazzino di sede)).
**Fonte**: `docs/errori/REGISTRO.md` (22 voci), `DEBITI.md`, `SAL.md`, e la giornata del 9
settembre che al momento della scrittura è solo in parte registrata.
> Questo non è un elenco di scuse. È il materiale che serve a chi decide cosa cambiare nel
> metodo: i numeri veri, le famiglie, e — la parte che conta — **chi ha trovato cosa**.
---
## 1. I numeri, contati e non stimati
```
22 voci in 7 giorni (E-001 … E-022)
per giorno:     03/09: 3 · 04/09: 6 · 05/09: 3 · 07/09: 4 · 08/09: 4 · 09/09: 2
per famiglia:   R1: 7 · R2: 7 · R6: 3 · R4: 2 · R5: 2 · R3: 1
emerse in:      banco o lente 15 · vivo/produzione 7
```
**Tre lettura da questi numeri, e la terza è quella scomoda.**
**(a) Il ritmo non è calato.** Tre al giorno il primo giorno, due l'ultimo: non c'è una curva
di apprendimento visibile nel registro. Le voci cambiano *tipo*, non frequenza.
**(b) Due famiglie fanno il 64%.** `R1` (assunzione non verificata) e `R2` (ho agito sulla mia
lettura invece che sulla richiesta) sono 14 su 22. Le altre quattro famiglie insieme sono 8.
⭐ Non è varietà: è **lo stesso errore in due forme** — non eseguire, e non chiedere.
**(c) La distribuzione di CHI trova cosa è il dato più importante del registro, e il registro
non lo traccia.** L'ho dovuto ricostruire leggendo le voci:
- le lenti e i banchi trovano gli errori **meccanici** (una regex, un codice d'uscita, un
  banco che non compila) — 15 voci;
- **il vivo e Luca** trovano gli errori di **giudizio**: la cosa dichiarata chiusa che non lo
  era, il numero affermato senza misura, la funzione mai lanciata — 7 voci, e sono le più
  costose perché arrivano dopo un deploy o dopo una richiesta ripetuta a lui.
- Le ultime due voci (E-021, E-022) le ha **nominate Luca**, non una lente.
⚠️ **Conseguenza per il canone**: il sistema di verifica che abbiamo costruito è tarato sul
codice, e gli errori che pesano non sono nel codice — sono nelle **affermazioni** su di esso.
---
## 2. Le cazzate di questa settimana, per tipo
### 2.1 Ho dichiarato chiuso ciò che era chiuso a metà (il tipo più costoso)
| Quando | Cosa ho dichiarato | Cosa era vero |
|---|---|---|
| 09/09 mattina | «#228 chiuso: i nomi dei clienti non arrivano più al piazzale» | Un cammino su due. Il cammino del **ricordo** (`daSaltareSenzaAprire_`) tornava senza `causa`, e i tre nomi erano **ancora a schermo**. Trovato da una fotografia di Luca, dopo il deploy. |
| 09/09 mattina | «#228 chiuso» (di nuovo) | `scarti_altrui` era **prodotto e reso, mai spedito** nel payload: la sezione d'ufficio era sempre vuota, e le attese erano verdi perché lo stub la inietta (#233). |
| 09/09 pomeriggio | «il calendario mostra cosa arriverà» | Mandava due secchi su quattro: sui dati veri di Luca **il futuro non c'era** (#238). |
| 08/09 | «il cancello è verde» | Era verde **ieri** (E-017). |
| 08/09 | «la pagina non la posso provare io» | Non l'avevo **mai lanciata**. Il primo lancio ha trovato due difetti veri in dieci minuti (E-020). |
⭐ **La regola che manca**: un difetto si chiude sui **CAMMINI**, non sul sintomo. #228 aveva
due strade verso lo stesso schermo e io ne ho provata una. La domanda che avrebbe evitato tre
giri: *«per quali strade questo dato arriva a quello schermo?»* — e la risposta va **contata**,
non intuita.
### 2.2 Le mie lenti mentivano (e una volta era la stessa lente di sei giorni prima)
- **E-003, 03/09**: «una guardia che era verde e non presidiava niente».
- **09/09, la stessa cosa**: `corpoDi(nome)` su un'ancora assente tornava **stringa vuota**,
  quindi ogni attesa che asserisce qualcosa di *negativo* era vera a vuoto. **MG8 era verde su
  una funzione che non esisteva ancora.** ⚠️ E la regola per evitarlo l'avevo scritta io **la
  mattina dello stesso giorno**, nel report dal campo, come proposta al canone. Violata il
  pomeriggio, nello stesso file.
- **MG7** misurava la *menzione* di una stringa, non il rifiuto: il sabotaggio che smontava il
  presidio passava **verde**.
- **PZ9** non distingueva «il clic ha funzionato» da «c'era già»: il valore atteso era a
  schermo *prima* del gesto.
- **L'ordine dei giorni del calendario**: nessuna attesa lo guardava, e per data pura la
  stringa vuota viene *prima* — l'ODA senza data finiva in cima al calendario.
- Su ~21 sabotaggi della giornata, **tre sono passati verdi** al primo giro.
⭐ **La lezione che il canone non ha**: una proposta scritta in prosa **non si presidia da
sola**. Le ho violate entrambe (gli accenti gravi nel template literal: avviso scritto da me,
violato due volte lo stesso giorno; l'ancora della lente: proposta scritta al mattino, violata
al pomeriggio). Una regola vale solo se **una lente la fa rossa**.
### 2.3 Ho affermato ipotesi con la tipografia dei fatti
**Oggi, il caso peggiore.** Le due viste rispondevano «il server non ha risposto». Ho misurato
che sono le sole due che chiamano Business Central, gli ho presentato **una tabella** con cinque
righe e ho concluso che era un'attesa infinita verso BC, non catturabile da un try/catch. Ho
anche scritto un debito (#239) su quella base.
Poi il log delle Esecuzioni ha detto: **«Completata», 4,978 s.** Non era un timeout, non era BC,
la funzione girava e restituiva.
⚠️ Il difetto non è avere fatto un'ipotesi: è averla **vestita da misura**. La tabella era vera
(quelle due chiamano BC), la conclusione no — e una tabella si legge come un fatto. ⭐ La regola:
*una tabella, un numero, un elenco puntato sono la tipografia della MISURA. Un'ipotesi si scrive
in prosa, con la parola «ipotesi» dentro, e con scritto accanto cosa la confermerebbe.*
### 2.4 Ho mandato Luca a misurare al mio posto, tre volte in un'ora
`clasp logs` → «non fa log». Poi il pannello Esecuzioni. Poi la console del browser col frame
`userCodeAppPanel`. Tre richieste, tre attese, e l'ultima è arrivata quando aveva già smesso di
avere pazienza — giustamente.
⚠️ È la stessa famiglia di **E-020**: là avevo detto «non posso provarlo» senza provarlo; qui ho
detto «serve una misura tua» tre volte di seguito **senza cercare la strada che non passava da
lui**. E ce n'era una: rendere il payload banalmente trasferibile toglie l'intera classe di
cause senza sapere quale sia. L'ho detto solo dopo che mi ha fermato.
⭐ **La regola**: *prima di chiedere una misura al padrone del dominio, si scrive cosa se ne
farà — e se la risposta è «una correzione che potrei fare comunque», si fa la correzione.*
Il tempo di Luca è il collo di bottiglia dichiarato di questo progetto: è **la risorsa più
scarsa del sistema**, e l'ho spesa tre volte per informazione che non cambiava la mossa.
### 2.5 Penelope: costruito e disfatto nello stesso giorno
- **Allargamento di ruolo** (E-021): ho aperto `attribuisciOrdine` a qualunque ruolo con
  magazzino — endpoint, ponte, stub, attese — e mezz'ora dopo l'ho riportato indietro, perché
  un chiarimento di Luca ha reso quel pezzo inutile. Un'ora costruita e disfatta, e nel mezzo un
  confine di sicurezza aperto. ⚠️ **Avevo scritto io, nel messaggio, «è tua da decidere e me
  l'hai chiesta»** — e sono andato avanti. *Dichiarare che una cosa è da decidere non è
  deciderla.*
- **Il corpo della PR riscritto tre volte in tre ore**, ogni volta con conteggi che il commit
  successivo invalidava. Alla terza ho tolto i numeri, che è la cura: *un numero che marcisce in
  una descrizione è un numero che qualcuno crederà.*
- **Il popup di attribuzione in piazzale**, costruito e poi buttato per il calendario. ⚠️ Questo
  **non** è Penelope mia: l'ha corretto Luca cambiando la richiesta, e rifare dopo una
  correzione del dominio è il lavoro. Lo separo di proposito, perché mescolarlo con i due sopra
  diluirebbe il difetto vero.
### 2.6 Ho distrutto materiale mio con lo strumento sbagliato
- Una sostituzione «da qui alla fine» ha **cancellato 67 attese** di un banco (E-022).
- Due volte un **accento grave** nei miei commenti dentro un template literal ha chiuso la
  stringa — con l'avviso già scritto accanto, da me, dalla prima volta.
- ⭐ Qui **la guardia c'era e ha sparato**: il verdetto dei banchi confronta
  `eseguite === ATTESE_DICHIARATE`, quindi ha rifiutato di essere verde con 31 attese su 100 e
  **zero fallite**. Il costo è stato tempo, non un difetto consegnato. È la differenza fra
  questo e §2.1, dove nessuna lente guardava.
### 2.7 Un dato falso a schermo, nato da un mio commento
Avevo scritto in un commento «l'elenco è i viaggi di QUESTO MAGAZZINO». Poi l'ho copiato
nell'interfaccia come «sono i viaggi di [SEDE]». È **falso**: il foglio annunci non ha nessuna
colonna magazzino (misurato). ⭐ Un'imprecisione in un commento diventa una bugia a schermo
appena qualcuno la copia — e chi la copia è quasi sempre chi l'ha scritta.
---
## 3. Cosa ha retto (perché non tutto va rifatto)
Va detto, o il report non serve a decidere:
- **`patterns/sabotaggio-plausibile.md` è la cosa che ha reso di più.** Ha trovato tre lenti
  debolissime che a rileggerle non avrei visto, e ha trovato il buco di ramo di AZ3.
- **Il verdetto `eseguite === ATTESE_DICHIARATE`** ha impedito che una cancellazione passasse
  per verde (§2.6). Un banco che contasse solo le rosse avrebbe detto «tutto bene».
- **`esegui-non-dedurre` funziona quando lo applico**: mi ha corretto tre volte oggi (gli
  endpoint `admin` sono nove e non otto; `letto_il` non è la lettura del documento; il foglio
  annunci non ha la colonna magazzino). Quando NON lo applico nascono le voci di §2.3.
- **La consulenza allo specialista GAS**: due chiamate, due difetti veri trovati che avevo
  davanti e non vedevo (`scarti_altrui` mai spedito; le lenti vacue).
- **Il registro degli errori**: senza, questo report non esisterebbe. È l'unica ragione per cui
  posso dire «22 in 7 giorni» invece di «alcuni».
---
## 4. Proposta al canone — cinque, in ordine di quanto costerebbero a NON farle
**1. «Chiuso» richiede l'elenco dei CAMMINI, non il sintomo che sparisce.**
Prima di dichiarare chiuso un difetto: *per quali strade questo dato arriva a quello schermo?*
La risposta si conta (grep sulle chiamate), si scrive nella voce, e ogni cammino vuole la sua
attesa. #228 è costato tre giri per questo, ed era il difetto che Luca aveva chiamato **grave**.
**2. Una lente le cui asserzioni sono tutte NEGATIVE deve prima asserire che il soggetto
esiste — e chi ritaglia un'ancora deve LANCIARE se l'ancora non c'è.**
Fatto per `corpoDi` in `banco-numeri-ponte.js` (attesa LL1). ⚠️ **Non** controllato in
`banco-riferimenti.js`, `banco-cruscotto.js`, `test-citazioni-vere.sh`, che usano la stessa
forma. È la proposta che ho scritto e violato lo stesso giorno: **finché non è una lente, non
esiste**.
**3. La tipografia della misura è riservata alle misure.**
Tabelle, conteggi, elenchi puntati = qualcosa è stato eseguito, col comando citabile. Un'ipotesi
si scrive in prosa, contiene la parola «ipotesi», e ha accanto **cosa la confermerebbe**. Oggi
ho dato a Luca una tabella per un'ipotesi, e il log l'ha smentita in una riga.
**4. Prima di chiedere una misura al padrone del dominio, scrivere cosa se ne farà.**
Se la risposta è «una correzione che potrei fare comunque», si fa la correzione. Il tempo di
Luca è la risorsa più scarsa del sistema e va speso solo per ciò che **cambia la mossa**.
Corollario: mai due richieste di misura di fila sullo stesso problema senza aver provato, nel
mezzo, una strada che non passa da lui.
**5. Un allargamento di permessi non si costruisce sull'assunzione.**
Si chiede prima, anche a costo di fermare il lavoro. Il segno da riconoscere è preciso: *se sto
scrivendo «è tua da decidere», non ho la risposta.* (E-021; la guardia è MG9, il complemento
chiuso degli endpoint `admin`.)
**E una proposta sul registro stesso**: aggiungere un campo **«chi l'ha trovato»** (lente /
vivo / Luca). L'ho dovuto ricostruire a mano per scrivere §1, ed è il dato da cui si vede la
cosa che conta: *le lenti prendono gli errori meccanici, il dominio prende quelli di giudizio.*
Finché quel campo non c'è, il registro racconta 22 errori e nasconde la loro asimmetria.
---
## 5. La cosa da dire in fondo
Il metodo di questo progetto è costruito per impedire a un programmatore di **consegnare codice
sbagliato**, e in quello funziona: dei 22 errori, i difetti arrivati fino a una persona sono
pochi e ognuno ha una guardia che lo prende oggi.
Non è costruito per impedirgli di **affermare cose sbagliate**, e lì non c'è nessuna guardia:
non su «è chiuso», non su «non si può provare», non su «la causa è questa», non su «serve una
tua misura». Sono le quattro frasi che questa settimana hanno fatto perdere più tempo a Luca di
qualunque difetto nel codice.
Le proposte 1, 3 e 4 sono l'inizio di quella metà mancante. La 2 dice come renderle vere:
scritte in prosa non tengono — l'ho dimostrato violandone una nel giro di sei ore.
