---
name: design-doc
description: Trasforma un'idea o una richiesta vaga in 2-3 opzioni concrete con trade-off espliciti, SENZA implementare — la scelta resta sempre di chi possiede il progetto. Nato da un debito dichiarato in DEBITI.md (2026-08-21): il comando era citato in METHOD.md/docs/system.md come parte della pipeline "/brainstorming → /design-doc → commessa" ma non esisteva nessun file che lo implementasse (le fonti di verità dichiarate, .zcode/commands/ e .claude/commands/, non esistono nel repo). Usa quando l'utente chiede di progettare una feature nuova, valutare alternative architetturali, o invoca /design-doc esplicitamente — prima di scrivere codice, non dopo. Non sostituisce dev-critic (quello trova gap in codice ESISTENTE); questo struttura una decisione su codice che NON esiste ancora. Non sostituisce /nuova-commessa (quello compone l'issue finale); questo produce l'opzione scelta che /nuova-commessa cita come "da dove nasce" la commessa.
---

# design-doc — le opzioni prima del codice

Il difetto che questo comando chiude è documentato dal vivo in
`docs/test-processo-2026-08-21.md`: il primo tentativo di sviluppare una feature nuova è
stato "pattern-matching, non progettazione" (un bottone gemello copiato invece di una
domanda di dominio) — l'operatore aveva saltato la fase di design. Il sistema non
difendeva il proprio metodo perché il metodo non aveva un comando, solo prosa.

## 0. Input — cosa serve prima di iniziare

Una richiesta, anche vaga ("serve un modo per X", "vorrei che Y funzionasse meglio").
Se la richiesta è già una decisione presa ("fai X con la libreria Y"), chiedi PRIMA se è
una scelta ferma o se vale la pena esplorare alternative — non aprire un design-doc per
decisioni già chiuse (regola "Only what is asked").

## 1. Metodo

1. **Riformula il problema, non la soluzione.** Prima di generare opzioni, scrivi in una
   frase cosa deve essere vero DOPO (il criterio di successo), non come arrivarci — se non
   riesci a farlo, la richiesta è ancora troppo vaga: fai le domande che mancano (stesso
   spirito di `/brainstorming`, che può precedere questo comando quando i requisiti sono
   ancora aperti).
2. **Genera 2-3 opzioni reali**, non una opzione vera e due paglia. Ogni opzione ha:
   - cosa cambia concretamente (file/componenti coinvolti, a un livello alto — non il
     territorio riga-per-riga, quello è compito della commessa dopo);
   - il trade-off onesto (costo, rischio, cosa si perde scegliendola) — mai un'opzione
     senza controindicazioni dichiarate;
   - quando ha senso scegliERLA (non "è la migliore", ma "sceglila se ti importa di Z").
3. **Le opzioni scartate restano scritte**, col perché — non solo la vincente (regola
   "Surface interpretations and tradeoffs — don't pick silently"). Chi legge fra sei mesi
   deve vedere anche cosa NON si è fatto, non solo cosa sì.
4. **Non implementare.** Questo comando produce un documento, non una PR. Se l'utente
   chiede anche l'implementazione, trattala come uno step separato ed esplicito DOPO che
   la scelta è stata fatta — mai un'opzione già scritta come codice nella risposta.
5. **La scelta finale è dichiarata da chi possiede il progetto**, non presunta. Se
   l'utente non ha ancora scelto, il documento resta con le opzioni aperte — non
   inventare una raccomandazione spacciata per decisione.

## 2. Dove va a vivere il documento (mai solo in chat)

- **In questo hub**: una voce in `SAL.md` (sezione "### <data> — design: <titolo>"),
  stesso formato delle altre voci — è già la fonte di verità per decisioni qui.
- **In un progetto onboardato con un proprio diario vivo** (es. `docs/bc/SAL.md`,
  o un `SAL.md` di progetto): stessa convenzione, nello stesso file.
- **In un progetto senza diario vivo**: crea `docs/design/<slug-titolo>.md` — un file per
  decisione, con le opzioni e la scelta. Lo slug deve essere stabile: una commessa futura
  lo cita per percorso esatto (vedi §3).

In ogni caso: **il documento ha un percorso o un link stabile**, perché la sezione
`## Design` di una commessa night-shift lo deve poter citare per riferimento reale, non
per prosa (pattern `citazione-non-presidio`: un design-doc che vive solo nella
conversazione non è verificabile da chi legge la issue dopo).

## 3. Verso la commessa (dopo la scelta)

Quando l'opzione è scelta, il passo successivo è `/nuova-commessa`: la sezione
`## Design` della issue cita il PERCORSO del documento appena scritto (non lo riassume a
memoria) — "da dove nasce" diventa un riferimento verificabile, non un'affermazione.

## 4. Regole non negoziabili (eredità da CLAUDE.md)

- Niente implementazione in questo passo — è un documento di decisione, non una PR.
- Ogni opzione ha un trade-off dichiarato, comprese quelle scartate.
- Se la richiesta è ambigua su COSA deve essere vero dopo, fermati e chiedi — non
  indovinare il criterio di successo per poi progettare la risposta sbagliata.
