# 2026-08-27 — revisione bug + fix su un repo esterno cespiti GAS+BC standalone

**Autore**: sessione Claude Code (Cowork/remote), non residente nell'hub — repo esterno,
clone read-only di AI_Programmer usato solo come riferimento. Nessuna commessa aperta
qui: task diretto dell'operatore in una sessione bound a un branch del repo esterno.

**Repo**: onboardato per la prima volta in questa sessione — non ancora in
`night-shift/repos-index.md`. Codice provvisorio in questo report: **[[REPO-?]]**
(letterA-G già assegnate; il prossimo libero risulta H, da confermare). La mappatura
reale va registrata da chi possiede `night-shift/repos.key` — questa sessione non lo
vede nemmeno in lettura (clone read-only, file gitignored/locale, confermato assente).

**Dominio**: sistema Google Apps Script standalone che scarica FA Ledger + G/L da
Business Central via OData e genera un report mensile di controllo cespiti
(quadratura, roll-forward, cessioni, anomalie) su Google Sheet. ~2200 righe, 17 file.

---

## Cosa ho usato

- **`patterns/*.md`** (23 pattern) come checklist di revisione ad hoc, letti per intero
  prima di leggere il codice del repo esterno. Non invocati via skill/agente: letti a
  mano e applicati manualmente confrontando ogni pattern col codice reale.
- **`docs/bc/endpoints/*.md`** (catalogo endpoint BC) come oracolo indipendente per
  verificare due assunzioni prima di "correggerle" — vedi sotto, ha evitato due fix
  sbagliati.
- **NON usati**: nessuna skill (`gas-sviluppo`, `controllo-gestione`, `/audit-commesse`,
  `/design-doc`...), nessun agente (`sviluppatore-gas`/`revisore-gas`/...), nessun hook,
  nessun oracolo Python di `tools/`. Non per scelta: la sessione gira in un repo esterno,
  senza `.claude/skills`/`.claude/agents` di AI_Programmer nel proprio contesto — il
  metodo non era raggiungibile da qui, solo il materiale di sola lettura clonato.
- **Cosa ho voluto usare e non c'era**: un modo per interrogare Business Central live
  (nessun MCP/tool BC in questa sessione) per chiudere in modo definitivo l'unica
  ipotesi rimasta non verificabile (vedi "Cosa ha ostacolato"). `banco-sintetico-per-
  calcoli-critici` presuppone poter costruire fixture sintetiche vicine al reale; qui
  mancava anche l'accesso per campionare UN disposal vero da cui costruirle.

## Cosa ho improvvisato

- **Banco Node per eseguire davvero i test GAS**: il repo ha `Tests.gs` con
  `runAllTests()`, pensato per girare nell'editor Apps Script — nessun modo dichiarato
  di eseguirlo da riga di comando. Costruito un harness `vm.createContext` che carica i
  file `.gs` veri (non riscritti) stubbando solo `Logger`/`PropertiesService`, ed
  eseguito `runAllTests()` per davvero dopo ogni fix (esito finale: 19/19). Istanza
  indipendente dello stesso principio di `banco-sintetico-per-calcoli-critici` — non
  conoscevo ancora il pattern con questo nome quando l'ho costruito, l'ho trovato dopo
  leggendo `patterns/`.
- **Verifica empirica di due assunzioni contro dati campione già nel repo/hub**, invece
  di assumerle dalla documentazione di progetto (che si è rivelata sbagliata su un
  punto): il valore reale di un codice di registro ammortamento, e la presenza/assenza
  di un campo "importo in valuta locale" su un endpoint OData. Entrambe risolte
  leggendo `docs/bc/endpoints/*.md` e un export xlsx presente nel repo esterno stesso —
  istanza indipendente di `regola-provata-non-assunta`/`oracolo-indipendente`.

## Cosa ha retto / ostacolato

**Ha retto — pattern che hanno predetto bug reali prima ancora di leggere il codice:**
- `scarto-mai-silenzioso`: confermato in `ProcessData.gs` (funzione di aggregazione per
  categoria) — un gruppo di record con chiave "sconosciuta" veniva raggruppato a parte
  ma **escluso dai totali** dei fogli riepilogativi, visibile solo come conteggio pezzi
  in un punto e come una riga di anomalia per record — mai come importo nei totali. Il
  fix (riga aggregata esplicita coi valori reali) segue esattamente la ricetta del
  pattern ("la funzione ritorna cosa ha scartato, il chiamante lo logga/mostra se non
  vuoto"), ma con un'aggiunta: qui lo scarto NON era del tutto silenzioso (un conteggio
  esisteva) — eppure la falsa sensazione di copertura data da un segnale parziale si è
  rivelata comunque un rischio concreto. Proposta sotto.
- `copertura-dal-glob`: confermato quasi lettera per lettera — una sezione descrittiva
  di un report elencava a mano N-2 elementi su N generati realmente da un array esistente
  nello stesso file, invecchiata silenziosamente quando l'array era cresciuto. Fix:
  un'unica fonte (l'array reale) letta da entrambi i punti.
- `segreto-come-impronta`: nessun segreto reale trovato in log/email in questo repo, ma
  applicato preventivamente — un corpo di risposta HTTP di errore esterno veniva
  propagato per intero fino a un'email, senza troncamento in un punto e senza alcun
  troncamento nell'altro. Aggiunta una funzione di troncamento esplicita condivisa.
- `oracolo-indipendente` (nella forma "catalogo campioni", non nel tool
  `grafo-verifica.js`): il catalogo `docs/bc/endpoints/*.md` ha risolto due ipotesi che
  altrimenti sarei stato tentato di "correggere" a naso — su una (il codice registro
  ammortamento) la documentazione di progetto del repo esterno era proprio sbagliata,
  il codice era già corretto: senza l'oracolo avrei rischiato di proporre una modifica
  che rompeva una query BC funzionante per allinearla a un documento non aggiornato.

**Ha ostacolato:**
- Il **metodo non è raggiungibile da una sessione bound a un repo esterno**: skill,
  agenti, hook di AI_Programmer esistono ma non c'è un modo dichiarato per una sessione
  come questa di invocarli restando sul repo esterno. Ho dovuto ricostruire a mano
  l'equivalente di `banco-sintetico-per-calcoli-critici` e leggere `patterns/` come
  prosa invece di poterli "citare nelle commesse" (uso previsto dichiarato in
  `patterns/README.md`).
- **Nessun oracolo per il caso critico rimasto aperto**: un'ipotesi sul comportamento
  di due tipi di movimento contabile distinti che Business Central posta per una
  singola cessione (uno dei due potrebbe azzerare esattamente ciò che l'altro registra)
  è rimasta **PLAUSIBILE, non CONFERMATA** — il fix applicato è comunque sicuro nel
  caso peggiore (nessuna regressione se l'ipotesi fosse sbagliata), ma resta l'unico
  punto di questa revisione senza chiusura eseguita, per mancanza di un oracolo
  raggiungibile da questa sessione (nessun accesso a un disposal reale in Business
  Central).

## Proposta al canone

1. **`docs/bc/endpoints/*.md` come oracolo indipendente dichiarato per QUALSIASI
   revisione di codice GAS+BC**, non solo per gli 8 oracoli Python di
   `controllo-gestione`: in questa sessione ha impedito un fix sbagliato. Oggi non è
   citato in `patterns/` con questo ruolo generale — meriterebbe un'ancora propria (o
   un'estensione di `oracolo-indipendente`) con questa sessione come secondo caso reale
   dopo il grafo-verifica.
2. **Nuovo pattern proposto** (bozza allegata separatamente): "una somma diversa da
   zero non è un segnale di presenza affidabile" — usare la non-nullità di un
   accumulatore come criterio per decidere se un evento è avvenuto è strutturalmente
   fragile quando l'accumulatore può cancellarsi per compensazione legittima (qui:
   costo e fondo che si annullano per un cespite già ammortizzato, un caso NORMALE non
   un edge case). La correzione: un flag booleano impostato al momento dell'evento,
   mai derivato da un'aritmetica successiva.
3. **Estensione a `scarto-mai-silenzioso`**: la lezione di questa sessione è che un
   segnale PARZIALE (un conteggio senza importo, un'anomalia per singolo record senza
   riga aggregata nei totali) può essere più pericoloso del silenzio puro, perché dà a
   chi legge la falsa sensazione di essere già coperto. Proporrei una riga nel pattern
   esistente che lo renda esplicito, invece di un pattern nuovo — è la stessa famiglia.
4. **`docs/campo/README.md`**: il formato presuppone una sessione residente nell'hub
   ("cosa ho usato" tra skill/agenti/oracoli/hook DI AI_Programmer). Una sessione come
   questa — repo esterno, clone read-only, nessuna skill invocabile — non ha una casella
   naturale in cui dichiararlo se non "nessuna, non raggiungibile": vale la pena
   dichiarare esplicitamente questo terzo caso (accanto a "usato" e "non c'era") nel
   formato, per non perdere il segnale in futuro.

---

## Numeri (esegui-non-leggere)

- File letti per intero: 17/17 (100% del repo attivo, `archive/` escluso perché
  dichiarato non attivo dal repo stesso).
- Bug/anomalie trovati: 13 (1 critico, 2 alti, 4 medi, 4 bassi, 2 solo documentazione/
  idea). Rivalutati come non-bug dopo verifica con oracolo indipendente: 1 (evitato un
  fix sbagliato).
- Fix applicati e pushati: 12/13 (tutti tranne l'ipotesi rimasta PLAUSIBILE, che ha
  comunque ricevuto un fix strutturale sicuro nel caso peggiore — vedi sopra).
- Test eseguiti realmente (non solo letti), sandbox Node `vm`, dopo ogni fix:
  `runAllTests()` 19/19 superati (16 preesistenti + 3 aggiunti in questa sessione).
- Sintassi di tutti i file `.gs` toccati verificata con `node --check` dopo ogni fix.
- Revisioni indipendenti (secondo parere, non le mie conclusioni) lanciate in parallelo
  su 3 aree separate prima di scrivere le conclusioni: 3/3 hanno confermato o esteso i
  rilievi principali, nessuna li ha confutati.
