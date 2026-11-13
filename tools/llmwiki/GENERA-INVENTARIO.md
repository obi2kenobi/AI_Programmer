# llmwiki — GENERA-INVENTARIO (v0, battesimo su Golilla 13/11/2026)

Tool dell'harness: genera l'inventario di UNA REPO QUALUNQUE (non è legato a Golilla).

## MANDATO STANDARD (adattare solo il percorso e il nome repo)

Genera INVENTARIO-<REPO>.md nella ROOT della workspace (mai dentro la repo).
Per ogni file sorgente: nome, cosa fa in una riga (dalla lettura delle
funzioni PRINCIPALI, mai dal solo header), hot-path sì/no con chi lo serve,
voce-diario collegata se esiste. Fonte firmata in testa: "Generato il
<data> da <modello> — verificare". Verifica incrociata finale: 5 file a
campione con grep della prova — la funzione citata DEVE esistere nel
codice; se il campione smentisce, correggi l'inventario e dichiaralo.
Copertura dichiarata (x/y); se il turno non basta: consegnare per impatto
(hot-path prima) e dichiarare la parte mancante. Tassonomia dei giorni
scorsi: ottimizzato / scagionato / da fare.

## REGOLE FONDAMENTALI (dalla prima esecuzione)

- La verifica CORREGGE: nella prima corsa 5 nomi di funzione furono
  aggiustati in fase di campionamento — correggere è parte del tool
- Dichiarare il criterio di conteggio funzioni: grep -c "function "
  conta anche le callback anonime (Main.gs: 56 occorrenze, 31 top-level)
- Assunzioni verificate "dall'header" NON bastano: leggere le funzioni
  o dichiarare l'assunzione (revisione 16, regola 6)

## PROSSIMA SCALA (v1)

- Rigenerazione nel pass notturno accanto al grafo (stessa PR night/grafo-*)
- Diff d'inventario dentro il cancelletto verifica-doc.sh (R2)
- Su mini: costo zero, rigenerabile a ogni giro
