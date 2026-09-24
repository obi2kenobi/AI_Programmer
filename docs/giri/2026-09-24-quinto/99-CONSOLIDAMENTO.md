# Quinto ventaglio — consolidamento (2026-09-24)

Brief: `docs/giri/2026-09-24-quinto/00-BRIEF.md`. Cinque lenti, un giro ciascuna, ognuno in un clone:
- R1: la memoria del sistema;
- R2: il satellite end-to-end;
- R3: gli oracoli come strumenti;
- R4: i consumatori dei log;
- R5: giorno e notte sulla stessa repo.

I rapporti grezzi sono in `grezzi/`, ignorata da git (skill n-giri §2). Dettagli di ogni cura nel SAL,
voce 18°, righe «Quinto ventaglio».

## Esito

- **30 rilievi**, 6 per giro, tutti provati eseguendo. Tre punti sono dichiarati «non provato» dai giri
  stessi:
  - R2 R3: che Claude Code lanci il gancio nella cartella dopo un `cd`;
  - R4 R6: se «PR di» conti anche la PR di riallineo;
  - R5 R4: che il bottone di GitHub ignori i driver di merge.
- **Curati**: 29, di cui 4 solo in parte (R1 R2, R4 R6, R5 R4, R2 R5: il resto è dichiarato). Ognuno ha il
  suo banco rosso prima e il sabotaggio rosso dopo. Due eccezioni:
  - R1 R2 è curato nei documenti, senza guardia: nessun banco sa leggere il senso di una nota;
  - R5 R4 è curato nel testo della PR, con una guardia sul testo.
- **Esclusi** (domande di dominio, in DEBITI.md): R2 R4, cioè a chi appartengono le skill dello standard in
  un satellite. Altre domande nate curando stanno accanto al meccanico già fatto:
  - R2 R5: spostare o fermarsi sulle righe proprie del CLAUDE.md;
  - R2 R6: NON-VERIFICABILE contro il turno;
  - R3: D-R3-1 tutto-zero, D-R3-2 formato italiano, D-R3-3 leasing fuori periodo;
  - R5 R2: la scopa dei rami del giorno.
- **Smentite**: nessuna. Un conteggio del giro però era più piccolo del vero: R1 R3 contava sette righe
  SALDATO con residuo, ma solo quattro portano ⏳ (le altre tre sono prosa, dichiarata come limite).
- **Suite**: 183/183 a ogni consegna. Da 180 a 183 file: tre banchi nuovi, cioè
  `tests/test-giri-avversari-classifica.sh`, `tests/test-eval-review.sh` e il banco di main
  `tests/test-roadmap-repo.sh`.

## Temi trasversali

1. **La promessa che il codice non mantiene** (R1, R2, R3, R4, R5). Casi:
   - la docstring degli indici prometteva una nota che nessuno stampava;
   - la dashboard prometteva un KeepAlive che il plist non ha;
   - la PR del grafo prometteva un merge che vale solo dove la spina è passata;
   - l'onboard diceva «un CLAUDE.md proprio non si sovrascrive», e il sync lo sostituiva;
   - la nota del cervello diceva «ogni PR passa dal censore»;
   - il SAL diceva «nessun limite di tempo»;
   - il modello di `.night-verify` chiede una dichiarazione che il turno punisce.

   Cura: la promessa si allinea al codice, o il codice alla promessa, e dove la scelta è di Luca la domanda
   è in DEBITI.
2. **Il turno che tocca ciò che non è suo** (R5 R1, R2, R3, R5, R6; pattern cuore-unico-proprietario). Casi:
   - il self-pull con reset sul lavoro del giorno;
   - la scopa sui rami `claude/`;
   - il «lease» che era un force-push;
   - l'indice del SAL scritto nella copia viva;
   - il `pkill` dell'opencode del giorno.

   Ora ogni gesto distruttivo del turno si limita a ciò che il turno ha creato: il suo PID, i suoi rami, il
   suo ramo senza commit altrui. Mette da parte il resto e lo dice.
3. **Il contatore che conta la cosa sbagliata** (R1 R1, R1 R4, R4 R1, R2, R4, R6). Casi:
   - i debiti contati per sezione (14 domande uscivano come 1);
   - le ancore del SAL (146 link su 146 non combaciavano);
   - il censimento senza storia;
   - la lente muta letta come difetto delle forme;
   - cicli e fix dalle code sovrapposte;
   - un consumatore di eventi che bastava esistesse.

   Ogni contatore ora ha un caso che lo fa sbagliare di proposito.
4. **Il dato marcio che arriva a un verdetto** (R3, tutti e sei). NaN e inf, celle vuote o in formato
   italiano, JSON della forma sbagliata e argomenti ignorati davano un verdetto con rc 0, a volte VERDE, o un
   traceback. Il contratto D32 ora si prova anche su celle, tipi e argomenti: `tests/test-oracoli-uso.sh`,
   da 60 a 91 casi.

## Tassonomia

**Implementata**
- R1:
  - R1 (righe, non sezioni);
  - R2 (annotazioni nella memoria);
  - R3 (residui ⏳ dei saldati; la riga n-giri riverificata);
  - R4 (ancore alla GitHub);
  - R5 (indice dell'archivio, ed esenzione dell'archivio nel pre-commit);
  - R6 (`cita-verifica --deriva`: 9 citazioni scivolate su 10).
- R2:
  - R1-R2 (garante e sensore del turno);
  - R3 (cancello clasp dai `package.json` antenati);
  - R5 (righe proprie dette, nell'uscita e nel commit);
  - R6 (residui, PROJECT.md, gate GAS).
- R3: R1-R6 (sei oracoli su NaN, quattro sulle celle, cinque sui tipi, sei sull'argomento, la nota degli
  indici, D9 e `classifica`).
- R4:
  - R1-R3 (censimento, lente muta, wedge);
  - R4 (digest);
  - R5 (dashboard);
  - R6 (catalogo eventi, consumatori, sentinella).
- R5:
  - R1 (allinea_hub);
  - R2 (scopa provvisoria su `night/`);
  - R3 (commit altrui);
  - R4 (testo della PR del grafo);
  - R5 (indice del SAL sul ramo);
  - R6 (`ferma_opencode_del_turno`).

**Esclusa** (domanda di dominio)
- R2 R4: le skill dello standard nei satelliti, personalizzabili o dell'hub.

**Rinviata**
- R1 R2: il controllo automatico «una nota di decisione più vecchia di un SALDATO sullo stesso tema».
- R4 R6: la metrica `loop-rilettura` scritta su `/dev/null` (HUB_METRICS mai impostata). Il censimento inverso
  delle 27 righe ⚠/⛔, rinviato qui, è stato fatto dopo il consolidamento (SAL, voce 18°).
- R5 R4: la notte che fonde da sola `origin/main` col driver prima di aprire la PR del grafo.
- R2 R3 e R5 R4: le prove dal vivo (un gancio lanciato da Claude Code in una sottocartella, un merge dal
  bottone di GitHub).

**Già coperta**
- R3 R4, indici con `"pn": null` o stringa: coperto dalla guardia di R3 R2. C'è un caso che lo prova.

## Da fare a mano (non potevo)

- `rm -f /CLAUDE.md /claude-satellite.md` nel container di questa sessione. È un residuo del quarto
  ventaglio, e il controllo di sicurezza non lascia a me la rimozione.
- Questa PR tocca `graphify-out/graph.json` a ogni commit (R5 R4): va fusa con `git merge` in una copia dove
  `tools/graphify-spina.sh` è passata, oppure il conflitto su `graph.json` si risolve rigenerando il grafo.

## Errori miei in questo ventaglio

- **E-048** (nel REGISTRO, con guardia): ho sovrascritto `.githooks/pre-commit` con un `cp` senza guardarlo.
  Era un rimando di quattro righe e l'ho fatto diventare una copia del gancio. L'ho ripristinato prima di ogni
  commit.
- Il mio aiuto di consegna faceva `git reset` su un rosso, anche durante un merge, e ha perso lo stato del
  merge di main. Ho rifatto il merge e corretto l'aiuto: niente reset con `MERGE_HEAD`. L'aiuto non è nel
  repo, quindi non c'è una guardia.
- Prime stesure prese dai banchi prima della consegna:
  - quattro note attese al posto di cinque (gli indici su attivo sono due);
  - un caso di dashboard che passava per caso (`find /` a profondità 3 vedeva la fixture);
  - un conteggio dei cicli che tornava 3 per coincidenza;
  - `git mv -q`, che non esiste;
  - un `celle` che faceva ombra a una variabile locale;
  - un grep «NON-VERIFICABILE» che prendeva l'esempio del modello.
- Un heredoc chiuso dall'`EOF` interno: le righe dopo sono girate in bash con percorsi vuoti. Ho verificato
  che non avessero scritto niente.
- Dal merge di main, curati nel merge: nel prompt della caccia virgolette doppie dentro una stringa (PROMPT
  vuoto, SC1078), `tools/eval-review.sh` senza banco e con l'uso che usciva 1, e un banco con la forma
  E-002.
