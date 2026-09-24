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

## Aggiornamento (2026-09-24, ripresa della sessione alle 05:29Z)
- La firma dei commit è tornata da sola: l'ambiente ha ricreato `/tmp/code-sign` alla ripresa. La
  patch in attesa è diventata il commit `cc26f7a`; il file della patch è stato tolto.
- Il lavoro è ripreso dalla coda: T2#2-5, T4, T5#2b (il debito risolvibile, prima del resto per il
  settimo patto), T6 e T1 per intero. Poi il consolidamento del secondo ventaglio e il brief del terzo.
- Ha retto, ancora: il banco prima della cura ha preso quattro mie prime stesure bucate prima della
  consegna. Ha ostacolato: E-043 si è ripetuto una volta (T6#6), corretto nel SAL.
- Proposta in più per la skill `n-giri` §2, già applicata al terzo ventaglio: il rapporto del giro va
  in una cartella del repo ignorata da git (`docs/giri/*/V*.md`), non nello scratchpad.

## Aggiornamento (2026-09-24, terzo ventaglio, fino alle 12Z)
- Usato: cinque lenti (turno eseguito, banchi come giudici, skill come istruzioni, tempo, pattern), un
  clone ciascuna. Consolidamento in `docs/giri/2026-09-24-terzo/99-CONSOLIDAMENTO.md`: 30 rilievi più
  12 fuori tetto, tutti curati o dichiarati, e una smentita.
- Ha retto: leggere l'uscita del sabotaggio in un comando separato (E-043). Tre sabotaggi diversi
  davano lo stesso FAIL, e così è venuto fuori il bytecode stantio (E-047). Senza quella regola avrei
  scritto tre rossi veri.
- Ha ostacolato: un banco che, dentro la suite, eredita la cache fresca della suite stessa. La prima
  guardia di E-047 era rossa dentro e verde fuori. Il pre-commit e la suite della consegna l'hanno
  fermata prima del push.
- Proposte al canone (non applicate):
  - CLAUDE.md §7 promette «a 240-min per-issue watchdog», ma il watchdog vive nel ramo opencode, che non
    gira mai (V1#6d). La frase va corretta, dopo la risposta di Luca in DEBITI.
  - CLAUDE.md §5: un sabotaggio di un modulo Python si esegue con una cache di bytecode fresca (E-047).
    Già scritto nella skill `n-giri` §5, che non è canone vincolante.

## Aggiornamento (2026-09-24, quarto ventaglio, fino alle 14Z)
- Usato: cinque lenti nuove (il primo giorno, il guasto, i contratti d'uscita, il grafo, i ganci visti
  da un avversario). I grezzi sono in `docs/giri/2026-09-24-quarto/grezzi/`: la regola nuova della skill
  n-giri §2 ha retto al primo uso. Consolidamento in `docs/giri/2026-09-24-quarto/99-CONSOLIDAMENTO.md`:
  30 rilievi, 28 curati (3 in parte), 2 domande di dominio.
- Ha retto: il banco prima della cura ha preso sei mie prime stesure, compreso un gancio di sicurezza
  che moriva e, morendo, lasciava passare tutto. Il rilevatore E-002 ha fermato una mia pipe.
- Ha ostacolato: un giro (Q2), provando il difetto che poi ha trovato, ha lasciato due file alla radice
  del container, e il controllo di sicurezza non mi lascia toglierli. Vanno tolti a mano.
- Proposte al canone (non applicate):
  - CLAUDE.md §7: accanto a «trust the graph for orientation», la frase sui chiamanti invisibili al grafo
    (`"$(…)"`, `<(…)`, `trap`) e sulla conferma con `grep -rn` prima di dire morta una funzione (Q4 R1).
  - CLAUDE.md §2 «Deploy is the human's»: il gancio nega anche quando muore (modo prudente). È una
    proprietà da pretendere da ogni guardiano, non solo da questo.

## Aggiornamento (2026-09-24, quinto ventaglio, fino alle 19Z)
- Usato: cinque lenti nuove (la memoria, il satellite end-to-end, gli oracoli come strumenti, i
  consumatori dei log, giorno e notte sulla stessa repo). Consolidamento in
  `docs/giri/2026-09-24-quinto/99-CONSOLIDAMENTO.md`: 30 rilievi, 29 curati (4 in parte), 1 escluso, otto
  domande di dominio nuove in DEBITI. In mezzo, un merge di main che ha portato tre difetti, curati nel merge.
- Ha retto: il settimo patto, ora che conta le righe. Chi riapre vede 14 domande di dominio invece di una,
  più tre saldati con un residuo ⏳ e il conto delle citazioni scivolate (9 su 10).
- Ha ostacolato, per colpa mia: un `cp` sopra un file che non avevo letto (E-048, con la guardia). Poi il mio
  aiuto di consegna, che su un rosso faceva `git reset` anche durante un merge.
- Proposte al canone (non applicate):
  - CLAUDE.md §7, la frase sul grafo («versioned, merge driver `merge=graphify`»): aggiungere «il driver
    vive in `.git/config` e lo registra la spina; un clone nuovo o il bottone di GitHub non lo conoscono»
    (R5 R4).
  - CLAUDE.md §1 «Before deleting or overwriting, look at the target» ha retto come regola, ma non come
    abitudine: è E-048. Proposta per la skill `post-mortem` o per §2: «un `cp` sopra un file tracciato si fa
    solo dopo averne letto la testa».
