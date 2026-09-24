# 2026-09-24 — la notte dei giri (hub AI_Programmer, due ventagli di lenti)
**Autore**: sessione cloud di Claude Code, su mandato di Luca («analisi lenta, trova e aggiusta, non fermarti»)

## Cosa ho usato
- La skill `n-giri`: primo ventaglio 10 aree × 3 lenti, secondo ventaglio con 6 lenti trasversali
  (T1-T6: satellite appena nato, concorrenza, Mac contro Linux, documenti contro codice, segreti,
  coda piccola), ogni giro in un clone.
- Per ogni cura: banco rosso prima, sabotaggio rosso dopo, voce nel SAL (18°), suite verde.
- Il settimo patto all'apertura; il REGISTRO per i miei errori (E-043, E-044).
- Non c'era: un modo di provare dal vivo il Mac (sandbox-exec, bash 3.2, launchd). Tutto ciò che lo
  richiede è dichiarato ⏳ nel SAL.

## Cosa ho improvvisato
- Un helper di consegna (indice SAL → pre-commit → suite → commit → push) che toglie lo stage se
  qualcosa è rosso. Senza questo, una consegna fallita lasciava tutto in stage e il commit dopo era
  misto.
- La regola «il verdetto del sabotaggio si scrive in un comando successivo» (E-043).
- Dopo E-044, la consegna via API GitHub di una patch (`docs/giri/2026-09-23-notte/in-attesa-di-firma-01.patch`),
  perché i commit locali non si potevano più firmare.

## Cosa ha retto / ostacolato
- Ha retto il banco rosso prima della cura. Ha fatto vedere che due mie prime cure erano incomplete:
  la maschera di privacy-check per un solo termine, e il confine dell'allowlist, che rompeva un caso
  legittimo.
- Ha retto il controllo dei percorsi citati nel pre-commit: ha fermato cinque SAL con nomi di file
  nudi.
- Ha ostacolato, per colpa mia: un sabotaggio su una variabile che finiva in `rm -rf` ha svuotato `/tmp`
  (E-044). Ho perso lo scratchpad, i rapporti grezzi dei giri T1-T6 e il programma di firma dei
  commit dell'ambiente. Il ripristino è stato negato dal classificatore dei permessi, e serve Luca.
- Ha ostacolato: i rapporti grezzi dei giri non versionati (per disegno, portavano citazioni
  sbagliate) sono morti con lo scratchpad. Ne restano i riassunti e le cure nel SAL.

## Proposta al canone
- CLAUDE.md §5, voce nuova (proposta, non applicata): «un sabotaggio non tocca mai una variabile che
  finisce in `rm`, e il backup di un sabotaggio non sta dove il sabotaggio può cancellare» (E-044).
- CLAUDE.md §5 (proposta): «il verdetto di un sabotaggio si scrive dopo averne letto l'uscita, in
  un comando separato» (E-043).
- skill `n-giri` §2 (proposta): il giro scrive il suo file DENTRO il repo, in una cartella ignorata
  da git, non nello scratchpad. Sopravvive a una pulizia di `/tmp` e resta non versionato.
