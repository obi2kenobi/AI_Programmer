# 2026-10-01 — note di credito BIOC: dalle sonde al flusso spento
**Autore**: sessione Claude (con Luca) — repo Registrazione_Fatture_Acquisto, PR #274–#286

## Cosa ho usato
Banco `tools/test_fase2.mjs` (test rosso prima, sabotaggi con elenco esatto, 523 attese e 292 sabotaggi a fine giro), lente `coerenza_gas.mjs` (ha preso una decisione copiata, tre letterali OData non protetti, un valore mai consumato), gate, `test_regole`. Sonde di sola lettura sulla produzione (S18–S20), prova in sandbox (S21), documentazione Microsoft Learn (Service Declaration) e Drive (PDF dei fornitori). Non c'era: graphify (navigazione a grep).

## Cosa ho improvvisato
Il flusso «una nota per volta per numero» sul modello di `registraInProduzione()` e una funzione di chiusura sul cruscotto senza scritture in BC (`smaltisciNoteCredito`), perché il metodo non dice come si chiude il lavoro di un flusso spento. Sei errori miei messi a registro o annotati: filtro OData con `OR` fra campi diversi (HTTP 501, due volte la stessa famiglia), nome di campo scritto a memoria (`documentNo` invece di `documentNumber`, già nel censimento e in un commento), etag vecchio nella cancellazione, assunzione sbagliata su 6024100002 (era un conto, non un articolo), ma soprattutto **una decisione già scritta (BIOC sempre DIVPREBIOC, §42.18) dimenticata** nel costruire la nota.

## Cosa ha retto / ostacolato
Ha retto: sonda prima della regola (la regola «DIVPREBIOC» si è allargata e poi corretta dai dati: 5 note storiche su 8 passano, 3 sono storni parziali); i dati dell'ufficio come misura della pratica, mai come regola; il confronto con gli attesi (`confrontaConAttesi_`) che trasforma la prova in sandbox in un controllo per ogni nota vera. Ha ostacolato: la sandbox che non può provare la riga `Item DIVPREBIOC` (controllo della Dichiarazione dei servizi) e non lascia cancellare le bozze; le PR mergiate a ogni passo con README in coda (conflitto di sezioni, rifatto a mano); l'elenco dei sabotaggi da estendere a ogni nuova attesa (ora lo script che legge «caduta non prevista» lo fa, ma attribuisce male quando il sabotaggio ha un nome senza «Gnn»).

## Proposta al canone
(1) Prima di costruire un flusso da dati storici: rileggere le decisioni di dominio già scritte e dichiarare quali parti dei dati sono pratica e quali regola (errore DIVPREBIOC). (2) Chi propone un test alla sandbox dichiara PRIMA cosa la sandbox non può provare (controlli di configurazione diversi dalla produzione) e come si prova in produzione (qui: attesi + mail). (3) Lo script che estende `devonoCadere` dalle «cadute non previste» va tenuto in `tools/` e deve gestire i sabotaggi con nomi non `Gnn`.
