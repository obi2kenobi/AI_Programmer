# 2026-09-02 — diagnosi webapp bloccata, deploy v74 e i tre strati sovrapposti
**Autore**: sessione ZCode (GLM) + Luca (i comandi clasp e il run editor, a mano)

Report di chiusura della sessione notturna 2026-09-01/02 — completa il parziale
2026-09-01-diagnosi-webapp-reauth (file del progetto) (che resta come dettaglio della prima fase).

Partiti da "non mi fa fare il deploy", finiti dentro tre problemi diversi che si
mascheravano a vicenda con lo stesso sintomo ("Caricamento in corso…").

## I tre strati (con la prova ciascuno)

1. **Deployment/produzione** — risolto: v74 ("audit sicurezza 2026-09-01") in produzione sul
   progetto principale, URL nuova, dati verificati due volte da anonimo (Snapshot_2026-08,
   2.581 articoli, 2.489.060,61 €). Aggirato il "Gestisci deployment" rotto e il
   deployments.update (API Google) che risponde "Requested entity was not found": **deploy nuovo**
   (clasp deploy senza `-i`), vecchia @73 lasciata come rollback.
2. **Sessione Google loggata di Luca** — diagnosticato, cura a carico del proprietario:
   userCodeAppPanel (di Google)?createOAuthDialog=true` + callback 404 su TUTTE le versioni (v73
   compresa, che funziona da mesi) = login di sistema in stato incoerente; da usciti/anonimi
   tutto funziona. Stessa radice della finestra "Gestisci deployment". Cure: cookie Google →
   logout/login → al massimo account rimosso e ri-aggiunto in Account Internet.
3. **Lock di LogLib durante i job lunghi** — scoperta più importante, risolta da sé ma
   strutturale: il trigger del giorno 2 teneva il lock di script e ogni chiamata interattiva
   moriva nel flush (di LogLib) di LogLib (waitLock(30000) (di LogLib) + ri-lancio). Misurato: doGet da 2-3s a
   **32s**; finito il job, tutto è tornato (riverificato). Fix proposto per la libreria: flush
   "soft" (attesa breve, eventi scartati invece di eccezione).

In mezzo, un quarto ritrovamento: il **trigger mensile puntato al nome pre-rinomina**
(monthlyScheduledExport (del progetto) senza underscore) che sarebbe morto il 1° ottobre — corretto in
setupMonthlyTrigger_ (del progetto) (commit `7981fce`), da rieseguire una volta dall'editor.

## Cosa ho usato
- CLAUDE.md/SAL.md letti prima di agire: il contesto "clasp push di stasera" stava nel report
  di chiusura giornata e ha orientato tutta la diagnosi.
- clasp pull in **tre** dir temporanee (progetto principale, gemello `15ypIYt…`, LogLib):
  "il vivo è definitivo, si legge con clasp" applicato alla lettera — ogni conclusione è nata
  dal vivo, non dalle ipotesi.
- curl con cache-buster + lettura dell'iniezione window.SESSIONE_WEB (del progetto) nella risposta come
  **prova di esecuzione** (distinuzione cache/esecuzione senza simulare il protocollo RPC).
- Browser integrato (sessione separata dal Chrome di Luca): test da loggato, **logout** per
  costruire il "vero anonimo", screenshot come evidenza dei dati caricati.
- Gate .night-verify (del progetto) a ogni commit (sempre 68/68).
- La regola "il deploy è dell'umano" rispettata per tutta la sessione: nessun push/deploy
  dall'agente; Luca ha eseguito i tre comandi clasp con le sue mani.

## Cosa ho improvvisato
- **Il numero `@N` del deploy come smoke-test**: un deploy nuovo che NON è @N+1 della
  produzione significa che stai deployando un altro progetto. Ha smascherato in un minuto il
  .clasp.json (del progetto) modificato localmente in `~/dev` e puntato al gemello (deploy finito @3).
- **La matrice a tre assi** per non confondere i sintomi: (anonimo vs loggato) × (v73 vs v74
  vs /dev) × (doGet ~3s vs 32s). Ogni combinazione indicava uno strato diverso — senza la
  matrice si curava lo strato sbagliato (come è successo all'inizio con la sola ri-autorizzazione).
- **Il timestamp dentro l'identità anonima** (`gruppocamarlinghi.it:1788301739898:1` è un
  epoch-ms): datare la sessione stantia senza accesso ai cookie.
- **Il cronometro via curl** sui tempi doGet come termometro del lock conteso (32s ≈
  waitLock(30000) + lavoro: il numero stesso era la firma della causa).

## Cosa ha retto / ostacolato
- Ha retto: commit per scoperta con SAL aggiornato in tempo reale (d286ea6 → 9560266 →
  7981fce → f699ca3): ogni strato è documentato mentre emergeva, ricostruibilenel tempo.
- Ha retto: "Read the error completely / fix the cause": inseguire un laconico "failed:
  undefined" fino in fondo ha scoperchiato tre strati invece del primo trovato.
- Ha retto: la pausa metodica "uno strato alla volta" — la tentazione di curare la sessione
  (strato 2) come se fosse l'unico problema sarebbe costata la scoperta del lock (strato 3).
- Ostacolato: il grep Homebrew nel PATH che su `Dashboard.html` restituisce vuoto anche per
  stringhe esistenti (`/usr/bin/grep`: 39 match) — le prime conclusioni "funzione assente dal
  client" erano artefatti dello strumento, corrette rieseguendo tutto con `/usr/bin/grep`.
- Ostacolato: `clasp run` inutilizzabile su tutti i progetti ("NOT_FOUND reading from
  storage" / "permission to run") — nessuna esecuzione server-side diretta; tutto è dovuto
  passare da curl e browser.
- Ostacolato: Accessibility negata all'helper di ZCode → nessun controllo del Chrome di
  Luca; l'intero testing è passato dal browser integrato (che condivide il login di sistema:
  si è rivelato un vantaggio diagnostico, vedi strato 2).

## Proposta al canone
1. **Check pre-deploy da 2 secondi** (già scritta, ribadita): git status (per .clasp.json)
   + il deploy deve rispondere `@N+1` della produzione, altrimenti stai pubblicando un altro
   progetto. Stanotte è successsuccesso davvero (gemello @3 invece di @74).
2. **Verifica pre-deploy meccanizzabile**: estrazione delle funzioni chiamate via
   google.script.run (API GAS) dai `.html` + check che esistano pubbliche (senza `_` finale) nei
   `.gs` — l'audit delle rinomine rischia di romperla e oggi si fa a mano.
3. **LogLib flush soft** (strato 3, il fix che vale di più): il logging non può stare sul
   percorso critico delle chiamate interattive con `waitLock(30s)` e ri-lancio dell'errore.
   Proposta: attesa breve (1-2s), a timeout **scartare** gli eventi (o buffer in
   CacheService), opzione Log.init({ sink (di LogLib): 'soft' })` per i percorsi utente.
4. **Diagnosi differenziale a tre strati** da mettere nel canone GAS — stesso sintomo
   ("Caricamento in corso…", RPC morte), tre cause, tre cure:
   - `createOAuthDialog` / callback 404 solo da loggati → **sessione** (cookie/logout/account)
   - doGet > 20s e RPC morte per tutti → **lock conteso da un job** (aspettare il job; poi
     fix LogLib)
   - sola una versione rotta, le altre sane → **deployment stantio** (creane uno nuovo)
5. **Datare l'identità anonima** prima di inseguire cause nel codice: se il numero nel
   /a/<dominio>:<epoch>:1 (formato Google) 404 è vecchio di ore rispetto al momento del test, il colpevole
   è la sessione del browser, non il progetto.
