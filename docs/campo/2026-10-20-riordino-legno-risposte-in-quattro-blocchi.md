# 2026-10-20 — riordino-legno, le 28 risposte di Luca costruite in quattro blocchi (PR Riordino-legno#123, #124, #125, #126)
**Autore**: sessione Claude Code (cloud) per Luca

## Cosa ho usato
Banco prima della correzione (rosso → verde, provato rosso anche sul codice precedente con `ACQ_DIR` su una copia), poi una voce di sabotaggio per ogni guardia (`B1-`…`B4-` nel giudice dei sabotaggi del progetto, `MUT_SOLO` e `MUT_GATE=browser`), giro completo dei banchi prima di ogni PR. Una PR per blocco, impilate.

## Cosa ho improvvisato
- Le PR sono impilate (ognuna sulla precedente) perché i blocchi toccano gli stessi file di versione e guida: un conflitto banale ma certo se fossero tutte su `main`.
- Quando una risposta di Luca supera un test vecchio (Q-10, Q-20, Q-13, Q-12, Q-05, Q-06) ho riscritto il test dichiarandolo nel nome del gruppo, non l'ho lasciato rosso né l'ho tolto.

## Cosa ha retto / ostacolato
- Ha retto: il controllo delle ancore dei sabotaggi (`ancore.js`) ha trovato ogni voce che una mia modifica aveva reso cieca, prima del giro lungo.
- Ha ostacolato: i numeri di riga citati nella guida e nel banco di struttura scivolano a ogni modifica (ancora una volta: Chat, Oda, ReportBu, VisteElenco); e un controllo di struttura vieta le chiamate al livello del file, quindi un'espressione regolare scritta come letterale è stata presa per una chiamata (ho usato stringhe).
- Due errori miei: ho scritto una correzione (Q-17/Q-23) prima del banco, e ho lanciato per sbaglio il giudice dei sabotaggi senza filtro (2000+ voci). Il primo l'ho rimediato provando i nuovi test rossi sul codice precedente; il secondo l'ho fermato.

## Proposta al canone
Un esempio di «banco rosso sul codice precedente» (`ACQ_DIR=<copia del ramo base>`) nel metodo: è il modo di provare un test scritto dopo la correzione.
