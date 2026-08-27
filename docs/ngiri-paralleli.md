# N giri paralleli — il workflow dichiarativo (dal campo REPO-I, 2026-08-27)

Struttura fissa, contenuto per progetto:

1. DIVIDI il progetto in AREE (REPO-I: 15) — nessuna esclusa, o dichiara l esclusione.
2. Per ogni area, LANCIA due letture indipendenti: una a caccia di difetti silenziosi
   (le lenti di patterns/), una a caccia di possibilita non sviluppate (dev-critic:
   chi porta solo difetti ha fatto un terzo). REPO-I: 30 agenti, batch da 10 per limiti
   di concorrenza.
3. SINTESI a posteriori, senza coordinamento in partenza: un tema che ricorre in >=3
   aree INDIPENDENTI e un TEMA TRASVERSALE (REPO-I: 8) — la convergenza indipendente
   e il segnale di qualita che un giro singolo non da.
4. L esito del giro si dichiara (zero bug su superficie ampia = convergenza, in metodo.md).

Ancora: docs/campo/2026-08-27-controlli-trimestrali.md (19/19 findings ALTA
riproducibili con test PRIMA/DOPO, zero regressioni, zero correzioni respinte).

## Il giro di PRODOTTO (dal campo, 2026-08-27: 72 agenti, 57 proposte confermate)

Distinto dal giro di bug: cerca cosa MANCA, non cosa è rotto. Struttura:
1. **Mappa dei percorsi utente reali** (chi usa cosa, in che ordine, con quali dipendenze) — prima delle lenti.
2. **Lenti di prodotto** (10+): ciclo di vita, leggibilità ("si spiega da solo?"), automazione del manuale residuo, osservabilità, produttività, resilienza sul campo, KPI calcolabili-ma-non-mostrati, configurabilità self-service, messaggi parlanti, usabilità nel contesto REALE (mobile/touch in magazzino).
3. **Verifica di fondatezza per ogni proposta**: un secondo agente apre il codice e verifica che il dato/meccanismo citato esista — la proposta generica si scarta. Ogni proposta cita file:riga, per chi, costo stimato.
4. **Critica di completezza**: cosa nessuna lente ha toccato (nel caso: governo dell'accesso nel tempo) + i PREREQUISITI NASCOSTI (una proposta che è prerequisito di altre due si fa per prima: risolve per costruzione, non con tre patch).
5. **Le 3 a miglior rapporto valore/costo per l'uso di oggi** — non un backlog: la scelta resta al proprietario.
Filtro d'ingresso che ha funzionato: vietare le "feature da manuale SaaS" senza riscontro concreto nel codice.

## La consolidazione delle lenti È zero-waste (dal campo REPO-G, 2026-08-27)

Cinquanta giri richiesti, consolidati in 14 lenti realmente distinte: evitare
passate quasi-duplicate è la stessa disciplina zero-waste del metodo applicata
al processo di revisione stesso. Il criterio: due lenti che rileggono gli
stessi file con la stessa domanda sono UNA lente; due che li leggono con
domande diverse (bug vs prodotto vs prevenzione) restano due. E ogni proposta
ancorata a file:riga letto davvero — mai principio da manuale.
