# 2026-08-28 — Bricoman, la deriva git↔live: misurarla prima di temerla

**Autore**: sessione Claude Code (Claude Sonnet 5) — stessa sessione dei due report precedenti
su REPO-J (`docs/campo/2026-08-28-bricoman-50-agenti.md`, analisi; `docs/campo/2026-08-28-bricoman-dal-audit-ai-fix.md`,
25 fix), continuata sullo stesso repo dopo che l'utente ha chiesto di verificare lo stato del
progetto Apps Script **live** prima di procedere con un eventuale deploy.

## Cosa ho usato

- Il metodo letto DAVVERO prima di partire, come nelle due fasi precedenti sullo stesso repo:
  nessun nuovo clone in questa fase, il canone era già in memoria di sessione dai report
  precedenti.
- **`clasp pull` per portare il codice live sul disco** — ma non dalla mia sessione: questa
  gira in un sandbox cloud isolato, senza browser e senza il login OAuth Google dell'utente.
  Verificato concretamente (non dedotto): `npx @google/clasp login` in questa sessione tenta
  di aprire un browser e si blocca — nessun modo di autenticarsi qui. Il `clasp pull` è stato
  eseguito dall'utente sul proprio Mac, dove clasp era già loggato (verificato con l'utente
  stesso, non assunto).
- **Un branch usa-e-getta come ponte tra il Mac dell'utente e questa sessione**: nessun
  filesystem condiviso tra la sessione e la macchina dell'utente, l'unico canale comune è il
  repo GitHub già esistente. Ricetta usata: l'utente lancia `git init` nella cartella clonata
  da clasp, `git remote add origin <stesso repo>`, `git checkout -b live-snapshot-<data>`,
  commit, push. Io faccio `git fetch origin <branch>` e lavoro sul contenuto da lì. Il branch
  resta nella history del repo come artefatto verificabile (non un file incollato in chat).

## Cosa ho improvvisato

- **Diff contro la baseline pre-fix, non contro il proprio HEAD**: prima di giudicare "quanto
  diverge il live", ho confrontato il clone live contro il commit `56e559d` — lo stato del
  repo ESATTAMENTE prima che questa stessa sessione iniziasse i 25 fix — non contro `main`
  attuale (che include già quei 25 fix, mai deployati). La differenza è enorme in pratica: un
  confronto contro `main` avrebbe mostrato ~11 file "divergenti" (ogni fix mai deployato conta
  come divergenza), inducendo a credere che l'intera base di lavoro dei 25 fix fosse da
  rimettere in discussione. Il confronto contro la baseline corretta ha isolato invece la
  domanda vera: cosa è cambiato in produzione che NON viene né dalla mia sessione né dalla
  storia git nota? Risposta: quasi niente (3 punti reali su 13 file).
- **Diff whitespace-insensitive per filtrare il rumore del round-trip clasp**: `clasp pull`
  normalizza whitespace/fine riga. Un diff letterale marcava 11 file su 11 come "diversi";
  `diff -b` (ignora whitespace) ne ha isolati solo 3 come realmente divergenti, gli altri 8
  erano byte-diversi ma semanticamente identici. Senza questo passaggio avrei dichiarato una
  deriva quasi tre volte più estesa di quella reale.
- **Nessuna assunzione sul contenuto della deriva prima di leggerla**: l'utente aveva chiesto
  esplicitamente di trattare il live come autoritativo e "rianalizzare tutto" — un mandato che,
  letto alla lettera, avrebbe giustificato ripetere l'intero ciclo di analisi e fix sui 25 punti
  già chiusi. Invece di eseguire quel mandato alla lettera, ho prima misurato la deriva reale
  (i due diff sopra) e poi sono tornato dall'utente con una proposta ridotta a 3 correzioni
  puntuali, spiegando perché il resto non serviva — l'utente ha approvato la versione ridotta.

## Cosa ha retto / ostacolato

- **Ha retto** — misurare prima di temere: la premessa implicita di questa fase (mia, prima di
  misurare — vedi la sintesi lasciata al turno precedente: "re-analizzare/re-verificare tutti i
  25 fix... alcuni fix potrebbero dover essere ri-derivati") era che la deriva fosse ampia e
  toccasse la logica dei fix già fatti. Era sbagliata: la deriva reale era 3 correzioni isolate,
  fatte a mano in produzione, in aree diverse da quelle toccate dai 25 fix, verificato con grep
  su tutto `src/` prima di assumerlo. Se avessi eseguito il mandato alla lettera senza prima
  misurare, avrei speso l'intera sessione a ri-verificare 25 fix già solidi invece di trovare e
  portare le 3 correzioni reali.
- **Ha retto** — le 3 divergenze trovate erano esse stesse correzioni valide fatte da qualcuno
  in produzione (sourcing di `fornitorePreferenziale` spostato a una chiamata dedicata invece
  di un campo inaffidabile; rimozione di un output mai consumato, `bySupplier`), non bug
  introdotti dal live. Il precedente audit a 50 agenti (report di fase 1, stesso repo) non le
  aveva mai potute vedere: guardava solo git, mai la produzione — un limite strutturale di
  qualunque audit "solo lettura del repository", non di quell'audit specifico.
- **Ha ostacolato** — nessun accesso diretto, né al filesystem dell'utente né a Google OAuth,
  da questa sessione: ogni lettura dello stato live ha richiesto un umano che eseguisse comandi
  e incollasse output o pushasse un branch. Due volte in questa sessione ho dato all'utente un
  comando con un placeholder non sostituito (`~/percorso/della/tua/cartella/...`,
  `clasp clone SCRIPT_ID_QUI`) che lui ha eseguito letteralmente ottenendo un errore — un costo
  diretto del canale indiretto (nessun modo di verificare io stesso prima che l'utente lo
  eseguisse).
- **Ha ostacolato** — due file del progetto Apps Script (`appsscript.json`, il manifest
  timezone/runtime, e `.clasp.json`, che contiene lo scriptId) non erano mai stati versionati
  in git, in nessuna delle fasi precedenti di questo stesso repo. Scoperto solo confrontando
  l'elenco completo dei 13 file live contro l'albero `src/` di git — un gap invisibile a
  qualunque audit che guardi solo dentro il repository. Portato `appsscript.json` in git su
  richiesta esplicita dell'utente; `.clasp.json` lasciato fuori di mia iniziativa (contiene lo
  scriptId, e nessuno degli altri repo di questo progetto lo versiona).

## Proposta al canone

- **"Misura la deriva prima di assumerne la portata"**: quando un mandato dell'utente implica
  "tratta il live come autoritativo e correggi tutto di nuovo" dopo una sessione di fix non
  ancora deployata, il passo 0 non è eseguire il mandato alla lettera né chiedere come gestire
  la deriva in astratto — è misurarla per prima cosa con un diff **contro la baseline esatta da
  cui la sessione di fix è partita** (non contro il proprio HEAD, che include i fix stessi), e
  con un diff whitespace-insensitive per non contare come "divergenza" il solo rumore di
  formattazione del tool di round-trip (qui `clasp pull`). Solo dopo aver misurato si torna
  dall'utente con una proposta scalata alla deriva reale, non al mandato preso alla lettera.
  Propongo una riga in `metodo.md`, verbo ANALIZZA, per questo scenario specifico
  (riconciliazione codice deployato vs repository).
- **Il ponte "branch usa-e-getta" per leggere uno stato live che la sessione non può raggiungere
  da sé** (nessun filesystem condiviso, nessuna credenziale OAuth propria) sembra un pattern
  generale, non specifico a questo repo: qualunque sessione onboardata su un progetto GAS reale
  incontrerà lo stesso muro (clasp richiede login umano). Propongo di documentare la ricetta
  (init/remote/checkout -b/commit/push sul repo GitHub esistente, poi fetch dalla sessione) come
  riferimento riusabile, forse in `gas-sviluppo/SKILL.md` accanto alle altre note GAS-specifiche,
  invece di reinventarla ogni volta.
- Conferma indiretta di una proposta già fatta nel report precedente su questo stesso repo
  (`docs/campo/2026-08-28-bricoman-dal-audit-ai-fix.md`, §Proposta al canone): un audit che
  guarda solo il repository, per quanto approfondito, non può vedere correzioni fatte
  direttamente in produzione. Le 3 divergenze qui trovate erano tutte migliorie reali del live
  sul git — un caso concreto a favore di considerare la lettura periodica dello stato deployato
  (dove tecnicamente possibile, cioè dove un umano può eseguire `clasp pull`) parte del ciclo di
  audit stesso, non solo un controllo eccezionale prima di un deploy.

## Esito

3 divergenze reali trovate e riportate su git, verificate con `node --check` + script di
riproduzione per ciascuna, commit separati: sourcing `fornitorePreferenziale` (logica di
business, PR #33), pulizia `TEST_FILES`/output morto `bySupplier` (PR #33), manifest
`appsscript.json` mai versionato (PR #34). Nessuno dei 25 fix della fase precedente è stato
rifatto: la misurazione ha confermato che restavano tutti validi.

PR: repo `Gestione-ordini-Bricoman`, branch `claude/project-analysis-review-ryly0b`
(`#33` e `#34` mergiate).

Dopo la riconciliazione, l'utente ha eseguito il deploy (`clasp push`, da lui, dal proprio
Mac — mai da questa sessione): 13/13 file caricati con successo. È il primo deploy reale
di tutti i 28 punti insieme (25 fix della fase 1 + 3 riconciliazioni + manifest
`appsscript.json`) — verificato con `clasp status` prima del push per confermare che i 13
file in coda corrispondessero esattamente all'atteso, nessuna sorpresa.

Report precedenti sullo stesso repo: `docs/campo/2026-08-28-bricoman-50-agenti.md`,
`docs/campo/2026-08-28-bricoman-dal-audit-ai-fix.md`.
