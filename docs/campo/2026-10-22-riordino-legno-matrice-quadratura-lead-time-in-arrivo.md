# 2026-10-22 — riordino-legno: matrice offerte, Quadratura dal vecchio script, lead time, importo archivio, «In arrivo»
**Autore**: sessione Claude Code (utente: Luca) — un coordinatore e agenti `sviluppatore-gas` (uno per area, ciascuno nel proprio worktree e ramo), PR #139–#146 del repo del progetto.

## Cosa ho usato
- Agenti `sviluppatore-gas` in parallelo (matrice, Quadratura, lead time, caricamento in BC, avvisi sulle date, importo archivio, importo di testata, «In arrivo»), brief con le decisioni di Luca già prese e le regole di `CORREZIONI.md`/`RISPOSTE.md`: banco rosso prima, sabotaggio rosso, un commit per passo.
- Le **sonde di sola lettura sul vivo lanciate da Luca** come strumento di decisione: `acqSondaWhitelist`, `acqSondaScriviFornitoreArticolo` (scrive una riga e la ripristina), `acqSondaFornitoreArticolo`, `acqSondaImportoArchivio`. Il log vero ha cambiato due decisioni (formula dell'importo archiviato: quantità × costo 95,2% → testata/importo di riga 99,6%; `nG`/`nS` non sono unità di BC).
- Domande di dominio a Luca una alla volta (AskUserQuestion) e «prima memoria, poi lavoro»: le risposte in `docs/progetto-acquisti/LEADTIME-DOMANDE.md` prima del codice (PR #143).
- Microsoft Learn per cercare il servizio web giusto invece di indovinarlo (pagina 114 «Catalogo art. fornitori», non 99).

## Cosa ho improvvisato
- **Catena di PR sugli stessi file** (`Config.gs` versione, `tests/lib/mutazioni-acq.js`, `banco-acq-struttura.js`, `GUIDA-STAGING.md`, `PROJECT.md`, `SAL.md`): a ogni fusione ho dovuto riallineare a mano gli altri rami con script Python (unione di liste, versione, citazioni `file:riga` con `fixcit`). Funziona ma costa un giro per PR.
- Gli ordini di consegna: lead time prima (sblocca la sonda), poi matrice, poi Quadratura, dicendo agli altri agenti di non lanciare la suite completa finché il primo non chiudeva.
- Per i comandi `clasp` di Luca: la procedura è nel progetto (`GUIDA-STAGING.md:36-51`) ma ho dovuto aggiungere il controllo dello `scriptId` contro `README.md:106` e il fatto che il terminale parte dalla home.

## Cosa ha retto / ostacolato
- **Ha retto**: le sonde sul vivo con maschera dei codici nel log (nessun codice vero è entrato nel repo); il piano PROVA → APPLICA con idempotenza (il caricamento di 246 righe in tre lanci sotto il limite dei 6 minuti non ha richiesto stato salvato: BC è il checkpoint); il banco di parità col vecchio script (8614 → 12604 casi identici, deviazioni volute contate a parte).
- **Ha ostacolato**: un agente ha usato `pkill -f` con un pattern largo e può aver ucciso suite altrui (dichiarato da lui; gli altri hanno ricontrollato le uscite «attese eseguite: N/M»); `fixcit2.py` ha il percorso di un worktree scritto dentro (due agenti l'hanno scoperto eseguendolo); il giudice dei sabotaggi sull'intero insieme va in timeout (solo per fette `MUT_SOLO`, il cancello intero non è mai stato eseguito); una descrizione di PR con la versione sbagliata dopo l'allineamento a `main` (corretta); il controllo `tools/privacy-check.sh` dà esito 1 anche su `main` pulito per quattro file di test esistenti.
- Un mio errore da annotare come tale: avevo detto «pagina 99» per il catalogo fornitore-articolo (è la tabella; la pagina è la 114) e un nome di servizio inventato (`PS_PowerBI_99_Item_Vendor`) prima di cercarlo.

## Proposta al canone
1. Per le catene di PR su registri condivisi (`mutazioni-acq.js`, struttura, versione, guida) un'unica persona/agente che fonde in ordine, oppure id e righe di struttura con prefisso per agente per costruzione (già proposta nel report dei giri).
2. Vietare ai brief degli agenti `pkill -f` con pattern non limitati al proprio worktree (fermare per PID o per cwd).
3. `fixcit2.py` deve prendere il worktree come argomento (oggi ha un percorso scritto dentro).
