# 2026-09-01 — REPO-K, terza sessione: 3 giri extra su richiesta esplicita, la scoperta che `clasp push` non basta per andare in produzione

**Autore**: sessione Claude Code (continuazione diretta delle due sessioni REPO-K
precedenti — 2026-08-28 dossier, 2026-08-31 seconda sessione — stesso repo, stesso
utente, git history continua)

## Cosa ho usato

- **Lo stesso metodo a lenti concordato con l'utente nelle sessioni precedenti**,
  non una skill di questo hub (REPO-K non è onboardata a questo hub — dichiarato
  anche nel report della sessione precedente). Richiesta esplicita dell'utente:
  "rieseguire tutto il controllo su tutto il codice con tutte le lenti possibili,
  una volta eseguito riesegui le correzioni e riesegui il loop altre due volte" —
  tre cicli completi, ciascuno chiuso con una PR propria (branch, commit, push,
  PR, `subscribe_pr_activity`), non un'unica PR gigante.
- `/tmp/gascheck/check.sh`/`checkjs_html.sh` e `check-duplicate-functions.js`
  (già esistenti dalle sessioni precedenti) su ogni file toccato, prima di ogni
  commit — invariato dalle sessioni precedenti, ha continuato a reggere.
- GitHub via MCP (`create_pull_request`, `merge_pull_request`,
  `update_pull_request`, `subscribe_pr_activity`) per aprire, tenere sotto
  osservazione e infine mergiare le tre PR di questa sessione più una PR
  residua della sessione precedente rimasta aperta.
- Il trucco FIFO + `run_in_background` nativo per `clasp login --no-localhost`
  (proposto nel report della sessione precedente dopo un fallimento):
  **usato due volte in questa sessione, andato liscio entrambe le volte** — nessuna
  race, nessun `state` sbagliato. Prima conferma concreta che il fix regge oltre
  il caso singolo che lo ha originato.

## Cosa ho improvvisato

- **La disciplina "cerca lenti nuove, non rigirare le stesse"**: alla terza
  richiesta consecutiva dello stesso "rieseguire tutto con tutte le lenti", il
  rischio reale era manifatturare rilievi per sembrare produttivo. Per ogni
  ciclo ho tenuto un elenco esplicito di lenti/file già coperti nei cicli
  precedenti della stessa sessione e ho cercato deliberatamente angoli non
  ancora battuti (rilettura integrale riga-per-riga di file mai riletti con
  quella profondità, coerenza fra config esposta al frontend e config
  effettivamente usata, tracciamento manuale di ogni funzione sospetta con
  grep esaustivo prima di dichiararla morta). Risultato onesto: i rilievi si
  sono ridotti in numero e gravità ciclo dopo ciclo (dal bug funzionale reale
  al primo ciclo, alla pulizia di codice morto e piccoli gap di robustezza
  all'ultimo) — dichiarato così nei riepiloghi delle PR, non gonfiato.
- **La scoperta che ha richiesto più investigazione di tutta la sessione**:
  l'utente ha chiesto di verificare che la dashboard "live" funzionasse dopo
  `clasp push`. `clasp push` aggiorna SOLO i sorgenti del progetto Apps
  Script — non l'URL usato in produzione, se quello punta a un deployment
  VERSIONATO (non a `@HEAD`). `clasp deployments` ha mostrato 3 deployment:
  uno `@HEAD` (sempre sincronizzato) e due versionati, di cui uno con un nome
  descrittivo che segue una numerazione progressiva riconoscibile come
  "quello vero" (l'unico con un nome non generico). Ho dovuto: (1) dedurre
  quale fosse il deployment di produzione dal pattern di naming, non da
  documentazione esplicita; (2) creare una nuova versione con
  `clasp deploy -i <deploymentId> -d "<nome-nella-stessa-serie>"`; (3)
  verificare con `curl` sull'URL `/exec` che l'HTML servito contenesse
  marcatori specifici del codice appena pushato (un id introdotto in questa
  sessione, l'assenza di una variabile rimossa in questa sessione) — non
  bastava un fetch generico, serviva la prova che la versione live fosse
  quella nuova e non quella precedente silenziosamente ancora servita.
- **Gestione di una catena di PR stacked quando una PR intermedia viene
  mergiata prima delle altre**: questa sessione ha aperto 3 PR in sequenza,
  ciascuna con base la HEAD della precedente (pattern già in uso dalla
  sessione precedente per una PR di un collaboratore). Quando l'utente ha
  chiesto di procedere al deploy, la prima PR della catena era già stata
  mergiata da GitHub ma le altre due puntavano ancora al branch head (ora
  storicamente superato) invece che al branch bersaglio reale. Ho dovuto
  ririgirare la base di ciascuna PR ancora aperta verso il branch bersaglio
  effettivo (verificando con `git merge-base --is-ancestor` che il contenuto
  fosse comunque già incluso, quindi nessun rischio di perdita), poi
  mergiarle in ordine. Una PR indipendente di un ciclo precedente della
  stessa sessione, rimasta aperta con base un branch intermedio ormai
  irrilevante, ha richiesto lo stesso trattamento.

## Cosa ha retto / ostacolato

**Ha retto**: la sequenza "un ciclo, una PR, un riepilogo onesto dei rilievi"
ha reso visibile il calo di rendimento invece di nasconderlo — l'utente ha
potuto vedere che il primo ciclo extra trovava ancora un bug funzionale vero
(cache non invalidata dopo il pulsante "aggiorna" manuale, con tanto di
sorella-funzione che invece lo faceva già — stesso pattern "due percorsi che
dovrebbero fare la stessa cosa e non la fanno" già visto nella sessione
precedente con `allowedNoteValues`), mentre l'ultimo ciclo trovava soprattutto
codice morto e piccole incoerenze di robustezza. Nessun rilievo manifatturato,
nessun rollback di un fix sbagliato.

**Ha ostacolato — nuovo, non nel catalogo di questo hub**: il presupposto
implicito "il codice è in produzione dopo `clasp push`" è falso per qualunque
progetto Apps Script con un deployment versionato pubblicato separatamente
dal codice sorgente — e non c'è alcun segnale nell'output di `clasp push`
(che riporta successo) che lo segnali. Un push "riuscito" e un utente che
chiede "controlla che sia live" sono l'occasione naturale in cui questo
gap silenzioso emerge, ma solo se qualcuno lo controlla DAVVERO (fetch reale
dell'URL, non fidarsi dell'esito di `push`). Nella sessione precedente lo
stesso comando (`clasp push --force`) era bastato perché — non verificato,
ma plausibile — nessuno aveva mai chiesto di controllare l'URL live dopo,
solo di pushare.

## Proposta al canone

**Adottata** — con l'àncora in questa sessione, un'altra sessione/il turno
notturno l'ha già trasformata in un pattern vero mentre questo report era in
revisione: `patterns/clasp-push-non-e-produzione.md`. Non ripropongo qui lo
stesso testo; noto solo che il pattern ha già ricevuto un addendum reale da
un incidente indipendente (REPO-Q, 2026-09-02): un `clasp push` lanciato da
un clone dichiarato di sola lettura ha sovrascritto il live di due progetti
sviluppati altrove — la stessa disattenzione ("presumere invece di
verificare quale progetto/deployment riceve il comando"), manifestata al
contrario. Il pattern ora copre entrambe le direzioni.
