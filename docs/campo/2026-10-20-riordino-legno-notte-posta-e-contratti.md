# 2026-10-20 — riordino-legno, la notte della posta automatica e dei contratti (PR Riordino-legno#128, #129, #130, #131, #132)
**Autore**: sessione Claude Code (cloud) per Luca

## Cosa ho usato
Banco prima della correzione (rosso → verde) per la ricerca articoli (#128) e i rappresentanti con i gruppi (#129); per la posta automatica (#131) e i contratti (#132) il banco nuovo è venuto con il codice e la prova che morde è stata la voce di sabotaggio (XLF-/PAU-/SOL-, RGP-, CTR-: una per guardia, `MUT_SOLO` per prefisso, `MUT_GATE=browser` per le voci della pagina). Il controllo delle ancore (`ancore.js`) ha fermato sette voci vecchie rese cieche dall'Excel a una riga per articolo prima del giro lungo. Il patto 2 («le domande prima del codice») ha prodotto `DOMANDE-CONTRATTI.md`: undici domande fatte una alla volta, e la fase 1 dei contratti costruita sulle risposte.

## Cosa ho improvvisato
- Un piccolo script (fuori repo) che riallinea da solo le citazioni `file:riga` della guida e del banco di struttura dopo ogni modifica: l'ho riscritto tre volte nella notte, e due volte ha trovato citazioni che avrei sistemato a mano una per una.
- Le PR di oggi partono TUTTE da `main`, non impilate (dopo l'errore di #123-#126, che si erano fuse l'una nell'altra senza arrivare a `main`): i conflitti attesi su `Archivio.gs`, `Admin.gs`, `Config.gs` e sui test che contano le schede sono dichiarati nel testo delle PR.
- Il dato per la prova dei solleciti (giorni lavorativi, finestra 8-18) l'ho dovuto costruire sull'orologio finto: `orologio.ms` è uno SCARTO da `2026-10-03T10:00Z`, non un istante.

## Cosa ha retto / ostacolato
- Ha retto: il giudice dei sabotaggi con la copia non mutata come linea di base: ha segnalato un test del browser vecchio (le offerte con l'Excel a una riga per azienda) che io non avevo ancora toccato.
- Ha ostacolato: (1) un giro del giudice con una linea di base rossa va rifatto intero (mezz'ora persa); (2) i banchi che CONTANO cose (schede dell'archivio, voci del menu, attivatori installati) si rompono a ogni funzione nuova: sei banchi toccati per l'attivatore e la scheda dei contratti; (3) il test W7 sulle etichette delle azioni cerca la stringa `rich_evento_(utente, '…'`: una chiamata con `rich_evento_(paut_attore_(), '…'` non la vede e il banco ha accusato un refuso inesistente.
- Errori miei: ho scartato il nodo che `autocompleta()` ritorna (il campo di ricerca del fornitore non si vedeva: lo ha trovato il banco del browser, non io); e ho creduto assoluto un orologio che è uno scarto.

## Proposta al canone
Un controllo che derivi i conteggi (schede, voci di menu, attivatori) dal codice invece di scriverli nei test, o almeno un'unica tabella dei numeri attesi: oggi ogni funzione nuova costa sei modifiche meccaniche a banchi diversi.
