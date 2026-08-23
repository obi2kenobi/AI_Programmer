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
3. **Cerca il criterio di successo, non la feature.** "Cosa deve essere vero dopo" è la
   domanda che chiude il brainstorming — quando l'utente la sa rispondere in una frase
   verificabile, il passo è finito (regola "Goal-driven execution" di CLAUDE.md).
4. **Se emergono 2+ strade plausibili**, non scegliere: è il momento di passare a
   `/design-doc`, che le struttura confrontandole su criteri espliciti. Il brainstorming produce IL problema
   chiaro, non la scelta fra soluzioni — quella è lo step successivo, esplicito.
5. **Ferma il brainstorming quando smette di produrre informazione nuova**, non dopo un
   numero fisso di domande: se la seconda domanda rivela già che la richiesta era chiara
   fin dall'inizio, fermati lì — un brainstorming che continua per abitudine è lo stesso
   spreco di un brainstorming saltato (regola "Zero waste").

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
