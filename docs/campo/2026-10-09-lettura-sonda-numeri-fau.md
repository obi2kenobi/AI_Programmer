# 2026-10-09 — cosa erano i PDF «26FAU-000861…865 NC INTERNA» (lettura di sondaNumeriFau)
**Autore**: sessione Claude (Sonnet 5.5) per Luca — Registrazione_Fatture_Acquisto

## Cosa ho usato
Il codice (`gas/ArchiviaPdf.gs:44`: il flusso rinomina solo col numero registrato), i metadati Drive in sola lettura (nessuna descrizione «nome originale» sui cinque file) e la nuova `sondaNumeriFau` lanciata da Luca sul vivo (PR #382). Non c'era: una sonda che prendesse un numero di documento a scelta (l'ho scritta, per `sondaRegistrazioniDiOggi` vede solo i documenti del flusso).

## Cosa ho improvvisato
Due ipotesi dichiarate come ipotesi prima del log: «NC INTERNA è un'etichetta dell'ufficio» e «861–865 non sono del flusso». Il log le ha confermate (cinque note di credito Noritec di Francesca Russo, ciascuna identica alla registrazione sbagliata che storna), e ha mostrato un buco che non avevo visto: la nota della 834 non è fra queste cinque.

## Cosa ha retto / ostacolato
Ha retto: dichiarare cosa NON potevo vedere da qui (BC) e farlo leggere a chi ha il vivo; la regola «un errore di lettura non è mai non trovato». Ha ostacolato: la lista dei numeri è una costante nel codice, quindi guardare 866+ costa un `clasp push` (`gas/SondaNumeriFau.gs:21`).

## Proposta al canone
Una sonda di lettura per numero di documento prende l'intervallo da una Script Property (con default), così allargare l'esame non richiede un deploy.
