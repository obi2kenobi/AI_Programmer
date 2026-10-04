---
name: pipeline-idempotenti
description: La procedura per costruire e verificare una pipeline di dati IDEMPOTENTE a prova di rilancio — quando l'utente chiede raccolta dati da API/fogli, job schedulati, sincronizzazioni Business Central, importazioni ripetute, o «perché ogni notte ho righe doppione?». Nata dal parco (Price-Intelligence: 23 .gs + 14 .js di raccolta senza prova di rilancio; la famiglia nextLink-ignorato è tra le più pagate del parco GAS). Non è la skill del calcolo sui dati (controllo-gestione): è quella del TRASPORTO.
---

# pipeline-idempotenti — rilanciare non cambia il risultato

Ruolo di riferimento: `pipeline-dati`. Qui la PROCEDURA col banco; là il
canone (checkpoint, retry con tetto, errori forti, la pipeline dice come sta).

## 1. Il contratto della pipeline (si scrive PRIMA del codice)

Quattro righe, risposta obbligatoria prima di scrivere:

1. **Fonte**: endpoint/foglio, autenticazione col ciclo del token, limiti
   (rate, pagine, finestre temporali).
2. **Chiave naturale**: quale campo(i) identifica la riga DALLA FONTE.
3. **Deposito**: dove finisce, chi lo possiede (cuore unico: UNO scrive).
4. **Voce**: come dirà «sto bene» a fine corsa (conteggio atteso vs avuto).

Se la 2 non ha risposta: FERMATI. Una pipeline senza chiave naturale è una
collezione che cresce, non un sistema che si aggiorna.

## 2. Il codice (le forme che il parco ha pagato)

- Paginazione: il ciclo segue `nextLink` finché c'è. `$top` non è una difesa.
- Scrittura: **upsert sulla chiave naturale**, mai insert cieco:
  ```sql
  INSERT ... ON CONFLICT(chiave) DO UPDATE SET ...
  ```
  (o l'equivalente del deposito: setMap/put su chiave, UPDATE poi INSERT).
- Retry: 429/503 → attesa esponenziale con jitter, `Retry-After` rispettato,
  TETTO di tentativi dichiarato (5 è un tetto, «finché riesce» è un blocco).
- Errori: l'eccezione catturata si logga CON la chiave e l'endpoint, e si
  rialza o torna come stato d'errore della corsa. Mai `except: pass`.
- Checkpoint: l'ultima chiave processata si persiste PRIMA di processare la
  successiva. Il riavvio riparte da lì e lo DICHIARA nel log.
- Confini dati: riga vuota ≠ riga assente; `Number('')` è 0; sentinelle
  (`"0001-01-01"`) truthy: si filtrano con lista esplicita, non con `if x`.

## 3. Il banco (il cuore della skill: il DOPPIO LANCIO)

Il banco si scrive PRIMA della correzione e prova la proprietà che definisce
la categoria:

```
setup:    deposito di prova con 10 righe fonte (mock o fixture dichiarata)
lancio 1: la pipeline gira → deposito ha 10 righe, log dice attese=10 avute=10
lancio 2: la pipeline gira ANCORA sullo stesso input → deposito ha ANCORA 10
          righe (non 20), e il log dichiara il secondo giro per quello che è
fallimento: la fonte mock torna 500 → la pipeline esce con ERRORE dichiarato
          e il deposito resta COERENTE (o vuoto o completo, mai mezzo)
```

L'uscita è la riga unica: `attese eseguite: N/M · fallite: K` + le tre prove
(idempotenza, fallimento forte, conteggio). Un banco senza la prova del
SECONDO lancio non è un banco di pipeline.

## 4. Il sabotaggio (le mutazioni che il banco deve prendere)

1. Togliere l'upsert (torna insert cieco) → il doppio lancio DEVE diventare
   rosso (20 righe).
2. Togliere il tetto dei retry con una fonte che torna sempre 429 → il banco
   deve decretare il blocco (timeout dichiarato, non l'eternità).
3. Ammazzare una pagina a metà (pagina 3 di 5 vuota) → o si fallisce forte O
   si dichiara la pagina mancante: mai deposito in silenzio di 3/5.

## 5. La consegna

Nel PR: il contratto (le 4 righe), il risultato del doppio lancio, il
sabotaggio, e i COSTI (chiamate per corsa piena, attese totali sotto rate
limit). La PR senza il secondo lancio dichiarato si rifiuta da sola.
