# 2026-08-27 — REPO-G: esecuzione delle 62 proposte "Quattordici Lenti" (batch 1-11, PR #36)

**Autore**: sessione Claude Code su REPO-G (Bilancio_periodico)

> Stesso metodo dei due report precedenti: dogfooding, non teoria. Prima di scrivere ho
> aggiornato il clone locale read-only dell'hub (`git fetch && git merge --ff-only
> origin/main`, 21 commit avanti) e riverificato dal vivo — comando o file:riga, mai il
> messaggio di commit da solo — sia lo stato della mia proposta del report precedente sia
> quello che l'hub ha fatto nel frattempo con il report "Quattordici Lenti" stesso.

---

## Parte 0 — la proposta del report precedente: adottata, testualmente

Il report del 2026-08-27 (prima di questo) proponeva un "segnale di convergenza": quando N
giri consecutivi di stress test ampio tornano a zero bug reali sulla stessa superficie, è
informazione quanto un bug trovato e va scritta, non lasciata silenziosa. Non l'avevo
lasciata come auspicio: verificato ora che è entrata nel canone testualmente, non
parafrasata —

`.claude/skills/gas-sviluppo/references/metodo.md:26-31`:
> «E L'ESITO DEL GIRO SI DICHIARA: uno sweep ampio che torna a ZERO bug reali sulla stessa
> superficie è informazione di CONVERGENZA, non un giro sprecato [...] (report dal campo
> REPO-G 2026-08-27: sei giri, cinque bug, poi dieci sotto-round a zero — la prima volta; un
> solo campione NON basta a dichiarare stabile la convergenza, ma il silenzio sull'esito non
> è ammesso)»

Cita il report per nome, tiene anche la cautela che avevo messo ("un solo campione non
basta") invece di trasformarla in una regola più forte di quella che avevo dati per
sostenere. Secondo loop di dogfooding chiuso punta a punta (il primo, F1-F6, era nel report
precedente): segnalazione dal campo → canone → verifica indipendente qui.

**Nota a margine, non richiesta da nessuno ma degna di trasparenza**: nel frattempo, senza
alcuna azione mia in questa sessione, il report "Quattordici Lenti" (62 proposte, l'artefatto
HTML che avevo prodotto per il cliente il 27/08 mattina) è stato depositato nell'hub da
un'altra sessione/mano (`git log`: commit `c8a1320`, autore Luca Camarlinghi) come
`docs/campo/2026-08-27-repo-g-quattordici-lenti.html`, e ha già prodotto una riga di canone:
`docs/ngiri-paralleli.md:28-35` ("La consolidazione delle lenti è zero-waste" — cinquanta giri
richiesti, consolidati in 14 realmente distinte, stessa disciplina zero-waste applicata al
processo di revisione). Non l'ho scritta io, la verifico e basta: **questo** report copre
invece cosa è successo DOPO quella revisione — l'esecuzione vera delle 62 proposte, non la
revisione stessa.

---

## Cosa ho usato

- **Banco sintetico / regola-provata-non-assunta**: `npm test` (4 banchi, `vm`-estrazione
  delle funzioni vere) rieseguito dopo OGNI commit dei 11 batch, sempre verde (35/35
  all'ultimo giro) — mai un "dovrebbe funzionare" senza esecuzione.
- **Playwright headless** per verificare HTML/JS realmente renderizzato dal browser (non
  solo dal motore Node `vm`) su due batch che toccano il DOM: il cruscotto KPI (batch 11) e
  lo smoke test dei pulsanti disabilitati (batch 4).
- **AskUserQuestion**, una sola volta sugli 11 batch: prima di spostare le credenziali BC
  fuori dal codice tracciato (batch 2), perché una decisione precedente del cliente (SAL.md
  D6) lo vietava esplicitamente — non un fix automatico, un'inversione di decisione.
- **Nessuno skill/agente dell'hub**: F1 resta aperto (nessun `.claude/skills/` in REPO-G,
  confermato di nuovo — vedi sotto quanto è costato stavolta, con numeri diversi dal report
  precedente).

## Cosa ho improvvisato

- **Una PR sola, aggiornata batch dopo batch** (`git push` sullo stesso branch +
  `update_pull_request` invece di aprirne una per proposta), per non far accumulare commit
  invisibili in attesa di review. L'ho deciso da solo, senza sapere che il giorno stesso
  l'hub aveva già canonizzato la stessa cosa da un altro campo: `consegna.md:116-121`, "I due
  regimi di conferma (dal campo REPO-I)" — un'autorizzazione unica del proprietario su un
  batch di fix GIÀ diagnosticati con precisione legittima la conferma compressa, non è
  indisciplina. Il cliente aveva dato esattamente questo ("procedi... una alla volta ma
  tutte") su un elenco di 62 proposte già scritte e ancorate a file:riga dal report
  precedente — coincidenza indipendente, buon segno per la regola.
- **`estendiHeaderSeManca_`** (`gas/Sheets.js`): per aggiungere colonne di audit
  (`modificato_da`/`modificato_il`) a fogli Google Sheets GIÀ in produzione, senza passo di
  migrazione manuale del cliente: legge l'intestazione esistente, calcola solo le colonne
  mancanti, le appende — non riscrive mai l'intestazione intera, non tocca le colonne/dati
  esistenti. Verificato con un caso dedicato in `tools/test-bookoverride.js` (foglio a 3
  colonne "vecchio stile" → migrazione automatica a 5, righe esistenti intatte).
- **Cruscotto KPI (batch 11) a costo zero**: legge SOLO dati già calcolati lato client dopo
  `loadData()` — nessuna chiamata server aggiuntiva, nessun nuovo endpoint.

## Cosa ha retto / ostacolato

- **Il limite CacheService (100KB/voce) confermato per convergenza indipendente, non per
  lettura del canone**: valutando il caching per il batch 9 (performance), ho misurato il
  payload reale (schema REDDITO-M da solo, ~560KB) e scartato l'idea perché supera il limite
  da solo. L'ho scoperto misurando, non leggendo — F1 è aperto, non ho `famiglie-difetti.md`
  caricato nella sessione. Solo scrivendo questo report ho letto
  `.claude/skills/gas-sviluppo/references/famiglie-difetti.md:24`: «**100 KB per voce di
  CacheService**» — stesso numero esatto, misurato indipendentemente sul parco REPO-E. Non è
  un fatto nuovo per l'hub, ma è una seconda conferma indipendente cieca — vale quanto un
  tema trasversale del giro REPO-I (convergenza fra letture che non si sono coordinate).
- **`estrazione-per-testabilita` ha retto di nuovo, ma ha mostrato un debito nuovo**: il
  banco `tools/test-computeperiod.js`/`test-ce-banca.js` estrae funzioni vere dal sorgente
  con una regex a riga singola (`estraiFunzioneRigaSingola`, `[^}]*` — nessuna graffa interna
  ammessa) per le funzioni ritenute "abbastanza semplici". Indagando il batch 10 (unificare
  `BU_LIST` con un loop al posto della somma scritta a mano) ho trovato che il loop avrebbe
  introdotto esattamente la graffa che la regex non ammette — l'estrattore, non il codice
  prodotto, si sarebbe rotto in silenzio. Ho deferito l'intero batch invece di aggiornare
  l'estrattore "di getto" nello stesso giro (rischio di regressione non proporzionato su un
  motore di calcolo di produzione), documentato in `SAL.md` D55 con entrambe le
  complicazioni reali (questa + l'inizializzazione a doppio percorso di `BU_LIST`/`COLS`).
- **`consegna.md` (letto solo ORA, scrivendo questo report — non durante il lavoro, F1)
  formalizza esattamente il protocollo che ho dovuto reinventare da solo**: il corpo PR
  canonico è `Ordine di lavoro / Diff sintetico / Prova di parità / Cosa resta all'umano`
  (`consegna.md:58-75`). Il corpo che ho scritto per PR #36 è organizzato batch-per-batch,
  non con questo template — più lungo, meno scansionabile. Sul worktree isolato
  (`consegna.md:6-23`, "un task · un worktree · un ramo · una PR") non l'ho seguito, ma senza
  danno: la regola nasce da un incidente fra CORRETTORI PARALLELI che si contendono lo stesso
  checkout — qui c'era una sola sessione sequenziale, il rischio che la regola previene non
  esisteva. Vale la pena dirlo esplicitamente invece di limitarsi a "non l'ho seguita": la
  regola è stata capita nel suo perché, non solo nel suo cosa.
- **Rinuncia dichiarata con la stessa disciplina di uno scarto**: il batch 10 non fatto non
  è un "non ho avuto tempo" silenzioso — due complicazioni REALI (trovate indagando, non
  ipotizzate) con file:riga in `SAL.md` D55, prima di decidere. Stessa logica di
  `scarto-mai-silenzioso.md`, applicata al proprio piano di lavoro invece che ai dati che
  elabora — non chiedo che diventi un pattern a sé, la segnalo solo come applicazione
  dell'esistente su un oggetto diverso da quello per cui è nato.

## Proposta al canone

1. **Nuovo pattern candidato — l'estrattore di test è una dipendenza nascosta sul
   refactor.** Quando il banco di regressione di un progetto GAS estrae funzioni vere dal
   sorgente con una regex (non un parser vero, perché GAS non ha un runner nativo), quella
   regex diventa essa stessa un vincolo sulla FORMA futura della funzione: un refactor
   innocuo nel codice prodotto (introdurre un loop o un blocco) può rompere silenziosamente
   l'estrazione, non la logica. Prima di un refactor che cambia la forma di una funzione già
   coperta da un estrattore fragile (a riga singola/regex stretta), aggiornare l'estrattore
   PRIMA, mai contestualmente — o, se il tempo non lo consente nello stesso giro, deferire
   esplicitamente citando l'estrattore come una delle cause (non solo il rischio sul codice
   prodotto). **Ancora**: REPO-G `tools/test-computeperiod.js:estraiFunzioneRigaSingola`,
   `gas/dashboard.html:recalcTot`, `SAL.md` D55 (2026-08-27).
2. **Nuovo pattern candidato — estensione di testata non distruttiva su Sheet già in
   produzione.** Per aggiungere colonne a un Google Sheet che un progetto GAS già legge/scrive
   in produzione (es. un campo di audit trail aggiunto dopo il fatto), la testata si LEGGE,
   si calcola il delta rispetto alle colonne attese, e si APPENDONO solo le mancanti — mai una
   riscrittura dell'intera intestazione. Evita sia un passo di migrazione manuale al cliente
   sia il rischio di disallineare silenziosamente le colonne esistenti rispetto ai dati sotto
   (imparentato con FORMATTAZIONE FANTASMA di `famiglie-difetti.md`, ma sul CONTENUTO della
   testata invece che sul formato della cella). **Ancora**: REPO-G
   `gas/Sheets.js:estendiHeaderSeManca_`, `tools/test-bookoverride.js` (caso "foglio già in
   uso a 3 colonne → migrazione automatica a 5").
3. **F1 (onboarding REPO-G): l'obiezione specifica scritta in `DEBITI.md:91-95` non trova
   più riscontro nel repo.** La voce motiva la sospensione con "la repo contiene credenziali
   BC nel repo stesso: onboardarla è una decisione di esposizione". Da questa sessione (batch
   2, SAL.md D53) non è più vero: `setupCredentials(clientId, clientSecret)` prende i valori
   come parametri passati a mano dalla console Apps Script, `credenziali BC.rtf` non è più
   tracciato da git (resta però in chiaro nella storia PRE-D53, spurgo non fatto, per lo
   stesso motivo per cui F3 non l'ha fatto sull'hub: force-push su repo condivisa, decisione
   del proprietario). Non è una richiesta di onboardare in automatico — restano le tre opzioni
   già scritte in F1, la decisione è di Luca — è solo il fatto che l'obiezione COM'ERA SCRITTA
   oggi non è più vera, e lasciarla scritta come se lo fosse ancora rischia di far sembrare
   bloccata una decisione che oggi è solo aperta.
4. **Conferma, non richiesta di cambiamento**: il limite CacheService 100KB/voce
   (`famiglie-difetti.md:24`) è stato ritrovato in modo indipendente su REPO-G con lo stesso
   numero esatto (vedi sopra) — nessuna modifica proposta, un secondo dato indipendente a
   favore della soglia già scritta.

---

## In sintesi

Il ciclo di feedback tiene anche al secondo giro: la proposta del report precedente è entrata
nel canone testualmente, citata per nome. Nel frattempo l'hub ha assorbito autonomamente il
report di revisione (Quattordici Lenti, 62 proposte) in un pattern di processo
("consolidazione delle lenti è zero-waste") — un ciclo che è successo FUORI da questa
sessione, verificato qui per trasparenza, non rivendicato. Questo report copre la fase
successiva, quella che il ciclo precedente non aveva ancora: l'ESECUZIONE delle 62 proposte
(11 batch, PR #36, 704 righe aggiunte, 20 file), con la stessa disciplina di verifica-prima-
di-dichiarare di sempre — e due debiti nuovi trovati indagando (non ipotizzati) mentre la si
applicava: un estrattore di test come dipendenza nascosta sul refactor, e un'obiezione
scritta in DEBITI.md che il codice di questa sessione ha silenziosamente superato senza che
nessuno l'abbia ancora detto all'hub. Lo dico ora.

---

*Sessione: PR #36 su REPO-G (aperta, CI verde, `mergeable_state: clean` — 11 batch della
revisione "Quattordici Lenti", SAL.md D53-D56). Nessuna modifica fatta ad AI_Programmer in
questa sessione, solo lettura (clone read-only, aggiornato a `origin/main` prima di scrivere
questo report) — le osservazioni sopra sono da valutare separatamente, come le volte
precedenti.*
