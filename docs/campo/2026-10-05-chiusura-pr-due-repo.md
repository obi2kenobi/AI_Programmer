# 2026-10-05 — chiusura delle PR su due repo (seguito del report del 4 ottobre)
**Autore**: sessione Claude (Sonnet 5.5) per Luca

## Cosa ho usato
Agenti `sviluppatore-gas` per le correzioni (G7–G12, T7–T12, K1–K4) e `revisore-gas` per il giro trasversale sul contratto. Il cancello di Treviso e il gate di Registrazione li ho rilanciati io a ogni consegna e a ogni merge, anche su una copia di lavoro separata per verificare lo stato combinato `main` + PR. Non c'era un modo meccanico per sapere se un merge «squash» avesse portato tutto il contenuto: ho usato il diff dei sorgenti fra `main` e l'ultimo commit del ramo.

## Cosa ho improvvisato
- Un merge di `main` nel ramo di lavoro, dopo che la #372 era entrata come squash, ha prodotto 25 conflitti identici nel contenuto: ho tenuto la versione del ramo e verificato che `main` e il ramo precedente coincidessero sui file in conflitto, prima di scegliere.
- Lo stesso merge ha duplicato in silenzio una funzione senza segnalare conflitto: l'ho trovata leggendo il diff di `gas/` e cercando funzioni duplicate. Nessuna guardia lo avrebbe visto.
- Per la lista delle PR di Treviso ho verificato lo stato combinato prima di unire. Lo standard in attesa (#197) metteva in rosso il cancello da solo: non unito.

## Cosa ha retto / ostacolato
- **Ha retto:** il cancello rilanciato su `main` + PR prima del merge (ha trovato la #197 rotta); i rapporti scritti prima di rispondere; il contratto con SHA identico e un banco in ciascun repo (ha fatto cadere il disallineamento delle derivate al terzo giro).
- **Ostacolato:** il clone di Treviso non ha i riferimenti `origin/*` (serve un fetch con refspec esplicito); l'API di GitHub risponde 403 sullo stato della CI e non l'ho potuto leggere; l'agente di correzione ha interrotto per sbaglio un suo giro con `pkill` e ha messo `git commit` e `cp` nello stesso comando.

## Proposta al canone
1. Dopo ogni merge di `main` in un ramo, ricerca obbligatoria di funzioni duplicate e diff dei sorgenti contro lo stato precedente (già nel report del 4 ottobre, proposta 5).
2. Una PR di adozione dello standard si verifica sullo stato combinato con il cancello prima del merge (già proposta 7): su Treviso ha messo in rosso un repo verde.
3. Nessun `pkill` per pattern negli agenti: uccide anche la shell che lo lancia.
