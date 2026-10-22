# 2026-10-22 — riordino-legno, secondo giro: PR concorrenti, sonde sul vivo, contratti F1, listini
**Autore**: sessione Claude Code (utente: Luca) — un coordinatore e agenti `sviluppatore-gas` (uno per area, ciascuno nel proprio worktree e ramo), PR #147–#164 del repo del progetto.

## Cosa ho usato
- Agenti `sviluppatore-gas` in parallelo (pulsante «Prenota lo scarico», sonda prezzi, correzione dell'evento eliminato, filtro BU, import whitelist dei contratti, sonde dei listini), con brief che riportano le decisioni di Luca già prese e le regole di `CORREZIONI.md`/`RISPOSTE.md`: banco rosso prima, sabotaggio rosso, un commit per passo.
- **Le sonde sul vivo lanciate da Luca come strumento di decisione**: `acqSondaCalendario` (ha trovato un difetto vero: `getEventById` restituisce ancora un evento eliminato, il controllo giornaliero non l'avrebbe mai riconosciuto), `acqSondaStatistiche`, `acqSondaPrezziAcquisto` (ha detto che i listini di BC sono spenti), `acqSondaCatalogoCampi`, `acqSondaFornitoreNuovo` (creato ed eliminato un fornitore di prova nel Sandbox).
- Domande di dominio a Luca una alla volta (AskUserQuestion) con la risposta salvata in un `.md` PRIMA del codice (`LISTINI-FORNITORI-DOMANDE.md`, `DOMANDE-CONTRATTI.md` §8, `DISEGNO-IN-ARRIVO.md` §10).
- Lettura del repo `obi2kenobi/Golilla` per capire come sono fatti i controllori delle fatture dei corrieri (quattro motori «gemelli»); il repo `saracamarlinghi/Analisi_vendite` **non è raggiungibile** da questa sessione (due tentativi, stesso errore).

## Cosa ho improvvisato
- **Realineare a mano, a ogni fusione, i rami ancora aperti** (versioni, voci di guida, liste e citazioni `file:riga` di `tests/banco-acq-struttura.js`, `PROJECT.md`, `SAL.md`): 11 riallineamenti in una sessione, ciascuno con script Python di unione. Funziona ma costa un giro per PR e produce rosso falso quando le citazioni slittano di una riga.
- Per i numeri di versione e le etichette della guida («10 sexagies», «bis», «ter») ho dovuto assegnare io una sequenza per evitare collisioni tra agenti paralleli.
- Un agente non aveva il tool delle PR (`mcp__github__create_pull_request`): ha usato `gh api`.

## Cosa ha retto / ostacolato
- **Ha retto**: il banco ha trovato un difetto che nessun conflitto di testo segnalava. #148 ha cambiato `arr_proprietari_()` da email a oggetto e `scarico.stato` (#151) passava l'oggetto dove serviva l'email: lo stato degli scarichi non vedeva più nessun ordine. Era in due banchi rossi, non in un conflitto.
- **Ha retto**: la regola «assente ≠ vuoto ≠ zero» nelle sonde: il log ha distinto «servizio non pubblicato» (404), «vuoto» (200 e zero righe) e «funzione non abilitata» (400), e questo ha deciso la domanda sui listini.
- **Ha ostacolato**: un testo di stato cambiato da un agente (#158) ha rotto banchi scritti da un altro (#155): le attese contenevano la frase esatta. Ho allineato i banchi alla frase nuova.
- **Ha ostacolato**: lo scratchpad condiviso fra agenti (file con nome generico sovrascritti da altri; dichiarato da tre agenti); `pgrep`/`pkill` con pattern larghi (ho ucciso per errore anche la mia shell).
- **Errori miei annotati**: (a) ho scritto il file e fatto il commit nello stesso comando (patto 5) per il primo salvataggio dei listini; (b) ho detto «i cinque esiti li ha già Acquisti» senza averlo verificato (erano del vecchio script, assenti in Acquisti: corretto in `PIANO-CONTRATTI-CONTROLLI.md`); (c) ho lasciato che l'agente del pulsante lavorasse su una base che poi la #150 ha fatto scivolare, e il riallineamento è arrivato tardi.

## Proposta al canone
1. Ai brief degli agenti paralleli: **lo scratchpad è condiviso**, nomi di file sempre con un prefisso proprio (già ripetuto da tre agenti).
2. Le citazioni `file:riga` nelle tabelle di struttura costano un riallineamento a ogni PR sugli stessi file: citare per **ancora di testo** (la stringa già presente) e calcolare la riga, come fanno le voci di sabotaggio.
3. Per le catene di PR sugli stessi registri condivisi (versione, guida, liste di struttura): un solo riallineatore per volta e l'ordine di fusione dichiarato in anticipo (già proposto nel report del giro precedente, qui confermato dal costo reale).
