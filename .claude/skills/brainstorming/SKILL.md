---
name: brainstorming
description: Raffina una richiesta vaga in requisiti concreti PRIMA che qualcuno scriva codice o un design-doc — domande socratiche, una alla volta, senza proporre soluzioni finché il problema non è chiaro. Nato da un incidente reale documentato in docs/test-processo-2026-08-21.md: il primo tentativo di sviluppare una feature nuova è stato "pattern-matching, non progettazione" (un bottone gemello copiato invece di una domanda di dominio) perché l'operatore aveva saltato questo passo — citato ovunque in METHOD.md/docs/system.md come prima fase della pipeline ("/brainstorming → /design-doc → commessa") ma mai implementato come file (stesso debito già chiuso per /design-doc). Usa quando l'utente porta un'idea vaga ("servirebbe qualcosa per X", "vorrei migliorare Y") prima di passare a /design-doc o scrivere codice, o invoca /brainstorming esplicitamente. Non sostituisce /design-doc (quello struttura opzioni già chiare, confrontandole su criteri espliciti); questo arriva prima, quando non è ancora chiaro COSA si vuole davvero.
---

# brainstorming — le domande prima delle risposte

Il fallimento che questo comando chiude non è ipotetico: è nella cronaca di
`docs/test-processo-2026-08-21.md` — saltare questo passo ha prodotto una soluzione
copiata da un pattern visto altrove invece che una risposta al problema di dominio
reale. Il sintomo di un brainstorming saltato è sempre lo stesso: la prima frase della
risposta è già una soluzione ("aggiungiamo un bottone che fa X"), non una domanda.

## 0. Quando si usa (e quando NO)

Usalo quando la richiesta è vaga, aperta, o "sembra semplice ma non lo è ancora
abbastanza per essere una commessa". NON usarlo quando la richiesta è già una decisione
ferma e concreta ("aggiungi un campo `note` a questa tabella") — lì si passa dritti al
territorio/commessa, il brainstorming su una richiesta già chiara è solo attrito.

## 1. Metodo — socratico, una domanda alla volta

1. **Non proporre soluzioni nella prima risposta.** Rifletti la richiesta con la domanda
   che manca: chi la usa, quale problema reale risolve (non quale funzionalità aggiunge),
   cosa succede oggi senza — se non sai rispondere a queste da solo, falle all'utente.
2. **Una domanda per turno**, non una lista di dieci. Chi risponde a una domanda alla
   volta resta nel problema; una lista intera invita a rispondere in fretta e superficie.
3. **Divergere PRIMA di convergere (6° ciclo, set 2, 2026-08-24).** Dopo le prime 2-3
   risposte, se il problema ammette letture diverse, proponi 2-3 RIFORMULAZIONI del
   problema — non soluzioni: "il problema è (a) il flusso che non esiste, (b) la
   visibilità di quello che esiste, o (c) i dati che non quadrano?". Una riformulazione
   scelta dall'utente vale più di dieci domande in più: chiude la divergenza con una
   decisione, non con la stanchezza. Se il problema ha UNA sola lettura plausibile,
   salta questo passo — divergere su un problema univoco è attrito, non profondità
   (stesso criterio del punto 5).
3bis. **Cerca la DOMANDA DI DOMINIO, non solo il criterio di successo** (7°
   ciclo, set 2 — dal corpus gas-agent di REPO-E): la riga che dice «se il
   mondo si comporta così, questa soluzione è dannosa». Prima di convergere su
   COSA deve essere vero dopo, chiediti COSA DIPENDE DAL MONDO REALE e non dal
   codice: scadenze contrattuali, regole fiscali, convenzioni aziendali non
   scritte. Se esiste, è la prima cosa da scrivere — e se chi governa non sa
   rispondere, la soluzione va progettata per dichiararlo, non per indovinarlo.
   Se non esiste, dichiara «nessuna domanda di dominio: perché» — il silenzio
   si legge «non serviva» e vuol dire «non ci ho pensato».
4. **Cerca il criterio di successo, non la feature.** "Cosa deve essere vero dopo" è la
   domanda che chiude il brainstorming — quando l'utente la sa rispondere in una frase
   verificabile, il passo è finito (regola "Goal-driven execution" di CLAUDE.md).
5. **Se emergono 2+ strade plausibili**, non scegliere: è il momento di passare a
   `/design-doc`, che le struttura confrontandole su criteri espliciti. Il brainstorming produce IL problema
   chiaro, non la scelta fra soluzioni — quella è lo step successivo, esplicito.
6. **Ferma il brainstorming quando smette di produrre informazione nuova**, non dopo un
   numero fisso di domande: se la seconda domanda rivela già che la richiesta era chiara
   fin dall'inizio, fermati lì — un brainstorming che continua per abitudine è lo stesso
   spreco di un brainstorming saltato (regola "Zero waste").

## 1bis. Il contesto si seleziona prima di chiedere (6° ciclo, set 2, 2026-08-24)

Prima della prima domanda, un giro rapido di contesto con budget (il metodo completo
è la skill `selezione-contesto`): le voci SAL della stesso dominio, i pattern già
pagati, la mappa dei domini (`docs/mappa-dominio-gas-src.md`) se la richiesta tocca
calcoli gestionali. Non per riempire la conversazione di riferimenti — per non
chiedere all'utente ciò che il sistema SA già, e per riconoscere una lezione già
scritta quando la rivede. Se il giro di contesto trova il problema già risolto o
già discusso, dillo alla prima risposta: il brainstorming più breve è quello che
un altro documento ha già fatto.

## 2. Cosa NON fare

- Non uscire da questo passo con del codice scritto — è un chiarimento di requisiti, non
  un'implementazione (stessa regola di `/design-doc`: passi separati, espliciti).
- Non inventare il criterio di successo per l'utente ("immagino che tu voglia Z") — se
  manca, è proprio quello che questo comando deve far emergere, chiedendolo.
- Non trasformare una domanda socratica in un modulo a caselle: è una conversazione, non
  un questionario — la domanda successiva dipende dalla risposta precedente, non da una
  lista precompilata.

## 3. Dopo il brainstorming

Il problema chiaro (criterio di successo + vincoli reali) passa a `/design-doc` se
esistono più strade plausibili, o direttamente a `/nuova-commessa` se la strada è unica e
il territorio è piccolo e noto. Il brainstorming stesso non produce un documento
permanente — è `/design-doc` (o la sezione `## Design` della commessa) a farlo, citando
cosa è emerso qui in una frase, non riportando la conversazione intera.


## Vedi anche

skill `design-doc` (il passo dopo)
