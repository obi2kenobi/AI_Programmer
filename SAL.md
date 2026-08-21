# SAL — il diario vivo del sistema

> Diario del sistema di sviluppo (hub + cervelli + turno notturno + giudizio).
> Ogni decisione porta la data e i fatti che l'hanno imposta. Aggiornato dal morning-gate
> e a ogni decisione strutturale.

## Stato

`PRIMA INSTALLAZIONE` (2026-08-21) — sistema completo assemblato: base (regole + conoscenza),
cervelli richiamabili (`llm/`), turno notturno multi-repo, giudizio mattutino col banco
avversariale, memoria (questo file + `metrics/gate.csv`).

## Decisioni

- **2026-08-21 · Il repo chiama i vari LLM** (deciso da Luca). Wrapper uniformi `llm/ask-*`
  con contratto unico: chiunque può delegare a qualsiasi cervello. WayfinderRouter come tessuto
  per OpenCode; Opus resta diretto perché il router non implementa l'outbound Anthropic
  (verificato sui sorgenti, non presunto).
- **2026-08-21 · Nessun limite di tempo per issue notturna** (deciso da Luca, mutuata da AI_Develop):
  fino a che non ha finito, il tempo non esiste. Guardie: prompt anti-loop + review del mattino.
- **2026-08-21 · Config reale fuori dal repo pubblico**: `night-shift/repos.conf` è gitignored —
  i nomi delle repo private non entrano in un repo pubblico. Nel repo solo `repos.conf.example`.
- **2026-08-21 · Il giudizio è avversariale**: il morning-gate non colleziona report, prova a
  smentire le PR (metodo del Supervisore in AI_Develop, applicato al sistema). I fallimenti
  diventano proposte di commesse correttive — nulla si rifà senza il sì di Luca.
- **2026-08-21 · La scoperta di gap/nuove idee diventa una skill, non un'abitudine** (deciso da
  Luca): il ruolo "cervello di giorno per giudizio/architettura" della matrice `llm/README.md`
  esisteva solo come istruzione implicita ("fallo tu quando serve"). Diventa la skill
  `dev-critic` (`.claude/skills/dev-critic/`), richiamabile on-demand da qualunque sessione
  (questo hub o un progetto onboardato), non legata al turno notturno.

## Log cronologico

### 2026-08-21 — assemblaggio del sistema

Costruito su tutto ciò che le tre notti su AI_Develop hanno insegnato (cinque difetti
d'infrastruttura trovati e corretti; il modello locale capisce ma non converge sulle indagini;
le issue devono essere commesse). Primo carico notturno per il hub: compilazione della colonna
_Significato_ BC — lavoro documentale, zero credenziali, il riscontro resta umano.

### 2026-08-21, ore 12 — prima lezione operativa del gate (e chi la firma)

Assemblando il sistema, chi scrive ha spinto `.night-verify` su AI_Develop dal branch della PR
invece che da main: il commit è evaporato in un merge shallow senza inquinare la PR (verificato),
ma la dichiarazione è arrivata a destinazione solo al secondo tentativo, dal checkout pulito.
Regola che ne esce, già implicita nel turno notturno e ora estesa a tutto il sistema:
**ogni operazione git parte da main pulito o dichiara esplicitamente il branch** — e il gate
legge le dichiarazioni da `origin/main`, mai dal branch della PR (il branch può essere nato
prima della dichiarazione). Primo giro completo del giudice: PR #369 → verifiche dichiarate
✅ (test-motore 2005/0) → banco avversariale con proposta di smentita → metrica registrata.

### 2026-08-21, pomeriggio — graphify entra nel sistema come strato di navigazione

Il fatto che lo impone: l'agente notturno consuma la notte leggendo file (il collo di bottiglia
misurato sull'issue #363). `graphify query` restituisce un sottografo deterministico con file e
riga esatti — verificato dal vivo sul hub: «avvio del server ollama» → `ensure_server()` a
`night-shift.sh:L45` con l'intorno di chiamate, in una interrogazione.

**Versione pinata: 0.9.48** (trovata installata la 0.8.50 — vecchia). Lezione di AI_Develop
importata: lo schema cambia fra minor (0.8→0.9.36 ha rotto tre tool contemporaneamente) —
aggiornare solo a versioni verificate e stampare la versione sugli artefatti.

**Le tre regole del grafo** (tutte pagate da AI_Develop, le adottiamo):
1. il grafo serve per ORIENTARSI e TROVARE (file:riga), non come oracolo
2. gli edge `calls` non sono risolti: non farci conto (grafo-findings.js li evita da mesi)
3. verificare-il-grafo, non fidarsi (template: grafo-verifica.js — oracolo indipendente + fail)

Completato anche il riuso Wayfinder: endpoint Anthropic-inbound verificato → nasce
`llm/claude-local.sh` (Claude Code come harness sul locale); `connect claude` non automatizzato
in questa build, ricetta manuale documentata in `router/README.md`. Route nominate: SPERIMENTALI
(instradano ma rispondono vuoto nel test). Privacy posture documentata come leva per i dati BC.

### 2026-08-21, sera — l'esperimento DFlash2: il video prometteva 3x, i fatti dicono altro

Occasione: un video mostrava Qwen3.8-27B a 10 tok/s via llama.cpp e 2,7-3,4x col draft model
DFlash2 (z-lab). Abbiamo misurato tutto sul nostro Mac (metodo: stessa identica richiesta).

**Risultati (stessa richiesta, 400 token):**

| Configurazione | Velocità | Condizione |
|---|---|---|
| Ollama, Q4_K_M MTP (il nostro) | 3,7 tok/s | funzionante |
| llama.cpp mainline, stesso GGUF | 3,7 tok/s | **nessun guadagno** |
| llama.cpp + DFlash2 (build PR #27342) | **0,14 tok/s** | thrashing: 10,2 GB di swap |

**Le tre lezioni (tutte con la prova):**
1. **llama.cpp diretto NON è più veloce di Ollama** su questa macchina — il 2x del video non
   si riproduce nelle nostre condizioni. Il collo è la banda memoria, non il runtime.
2. **DFlash2 su 24 GB unificati è una regressione, non un'accelerazione**: target (16,8) +
   drafter (1,1) + contesti sforano il working set Metal e ogni token paga il disco. Serve RAM
   maggiore. Il GGUF del drafter resta in `~/models-dflash2-q4.gguf` per il giorno in cui
   l'hardware crescerà.
3. ⛔ **LA SCOPERATA DELLA SESSIONE: il working set Metal è ~75% della RAM** (~18 GB sui
   nostri 24) e l'OS lo STRINGE sotto pressione. Questa È la causa dei nostri «errori Metal»
   ricorrenti: configurazioni che stanno dentro il limite oggi falliscono domani quando il
   sistema si riprende margine. Regola: mai forzare `-ngl 99`, sempre fit automatico; il
   Q5_XL (21 GB) non è mai stato vicino a funzionare — ora sappiamo perché con precisione.

Il turno notturno resta su Ollama + Q4_K_M MTP: 3,7-5,9 tok/s, il massimo dimostrato su
questa macchina. Il file `llama-bench.log` conserva le prove.

### 2026-08-21, sera — loop engineering: il nome arriva dopo la pratica

Il sistema pratica loop engineering dalla prima notte (trigger→harness→verifica→memoria→ciclo)
senza conoscerne il nome; il vocabolario pubblico (Cherny, Steinberger, Karpathy-AutoResearch)
arriva ora e lo formalizza in `docs/system.md`. Si adottano tre cose: la **tassonomia dei cinque
livelli di verifica** — che svela che il "riscontro" BC è verità terrena ritardata (livello 3)
praticata da giugno, e che il nostro banco è un livello 4 potenziato (smentisce, non si
autovaluta) — il **comando /goal** per i loop diurni (verifica dichiarata, tetto di tentativi,
log in `loops/`, avversario prima della vittoria), e la **tensione dichiarata**: notte senza
limite di tempo vs /goal sempre col tetto — commessa lunga unica vs ottimizzazione iterativa,
entrambe giuste nel loro contesto.

### 2026-08-21, pomeriggio tardi — ponytail e superpowers: il delta, non il catechismo

Due framework entrano nel sistema lo stesso giorno, con lo stesso criterio: si adotta ciò che
il metodo NON ha già.

**Ponytail** (107k ⭐, MIT; ~54% meno codice nei benchmark — ricalibrati dopo la contestazione
della community, onestà metodologica che ci è piaciuta): la scala a sette pioli entra in §2
come PROCEDURA del "zero waste" (*serve? → riusa → stdlib → nativo → dipendenza esistente →
una riga → il minimo*), dopo la lettura mai prima. Plugin installato su **OpenCode** (la notte
scrive minimale: a 4 tok/s meno output = notte più veloce — l'ottimizzazione più economica
misurata finora, batte DFlash che era una regressione) e su **Claude Code**. Nasce
**DEBITI.md** (da /ponytail-debt: le scorciatoie rimandate si scrivono). Il gate passa a
**tre controlli**: verifiche dichiarate + banco avversariale ESECUTORE (velocizzato: via
thinking dalla generazione — il test lo teneva 25 minuti) + verifica di MINIMITÀ consultiva
(livello 4, delete-list in stile /ponytail-review; bloccante solo quando le metriche lo
giustificheranno).

**Superpowers** (275k ⭐, MIT, 476k installazioni, Jesse Vincent): mappatura onesta prima di
adottare — TDD rigoroso = il nostro banco-scritto-prima; debugging 4 fasi ≈ §5; review agent
= il gate. Il delta vero che entra: il **guardrail tre-strike in §5** (dopo tre fix falliti si
ferma TUTTO e si rivede l'architettura: il difetto non è dove si crede) e **/brainstorming per
ZCode** (disciplina socratica, una domanda per ciclo, convergenza su formulazione verificabile
→ /goal o commessa). Plugin installato su Claude Code dal marketplace ufficiale.

**Cosa NON adottiamo** (economia del metodo, ragioni scritte): subagent-dev-review (c'è il
gate), skill-writing TDD (c'è skill-creator), execute-plan a blocchi (le sessioni lo fanno
nativamente), ponytail-ultra e ponytail-mcp (non misurati sul modello locale).

Il flusso giorno-perfetto che ne esce, documentato: **/brainstorming → /goal → (notte) → gate**.

### 2026-08-21, sera — la review di Opus applicata: ogni punto verificato sul codice, poi corretto

Review esterna del hub (sessione Claude Code, branch di analisi) con mandato esplicito di
riverificare ogni punto prima di toccare nulla — fatto, e il report era accurato al 100% su
quanto verificabile. Cosa è stato corretto, con la prova:

**Bug §2.1 (confermato: header a 7 colonne, righe a 6):** il CSV ora scrive la settima colonna
(vuota al gate) e nasce `gate-esito.sh` per registrare l'esito umano (merge/chiusura/commessa)
sull'ultima riga corrispondente. Le righe storiche col vocabolario vecchio NON sono state
riscritte: il drift si annota qui (righe con banco `proposto`/`vuoto` precedono l'esecutore).

**Bug §2.2 (confermato: main hardcoded in 6 punti + silenziatore alla r.85):** `night-shift/lib.sh`
con `default_branch()` (symbolic-ref → gh repo view → main con AVVISO). Refactor completo;
checkout fallito → log duro + riclone, mai continuare in silenzio.

**Sicurezza §3 (buco reale: find -delete e git reset --hard passavano la blacklist):** difesa in
profondità approvata da Luca — allowlist per segmento (split su && || ; |, git readonly) come
prima linea + **sandbox seatbelt** (`sandbox.sb`: rete negata, scritture solo nella copia
disposabile) come seconda + watchdog 120s esteso anche alle .night-verify (l'asimmetria).
**Testato dal vivo: curl in sandbox = exit 7 (connessione negata), scrittura fuori workdir
vietata, dentro concessa.**

**Processo §4:** percorso cloud/ibrido documentato in onboard-repo.sh e system.md (MCP può
commit-tare file; label e repos.conf restano manuali sul Mac); drift-check del CLAUDE.md nel
gate (informativo); **credenziali BC in CDG_Costi_Diretti: VERIFICATO peggio del report — oltre al
file rtf, lo stesso segreto Azure era sparso in 21 commit (Config.gs, script, SAL.md). Storia
ripulita con filter-repo (file rtf rimosso + 2 valori segreti sostituiti con --replace-text),
gitleaks post-scan: ZERO leak. ⛔ L'AZIONE CHE RESTA È DI LUCA: ruotare le credenziali su
Azure — le vecchie hanno viaggiato nella storia git. gitleaks ora gira in bootstrap (bloccante
pre-push) e come pre-scan in onboard.**

**Minors §5:** il hub ora ha il suo `.night-verify` (shellcheck + bash -n — il sistema che
pretende verifiche dichiarate finalmente le dichiara per sé); warning quando si tocca il limite
50; DEBITI.md compilato con i rinvi deliberati (rotazione log, portabilità, test bc_*).

Nota operativa per Luca: i cloni locali di CDG_Costi_Diretti vanno RICLONATI (la storia è stata
riscritta, gli hash sono cambiati).

### 2026-08-21, notte — dev-critic: il critico costruttivo diventa un comando, non un'abitudine

Occasione: la revisione manuale sopra (letti tutti gli script, poi onboarding REALE di
`CDG_Costi_Diretti` per verificarli sul campo) ha trovato bug non visibili dalla sola lettura
(`gate.csv` non scrive mai la colonna "esito"; `main` hardcoded come default branch in più
punti; banco avversariale che esegue `eval` su un comando generato da LLM con solo una
blacklist regex, nessun sandbox reale) e gap di processo (nessun percorso per onboarding da
sessione cloud senza `gh`; `credenziali BC.rtf` committata in CDG scoperta ispezionando prima
di toccare) — tutti poi confermati e corretti, come documentato sopra.

La lezione che ne esce: **il dogfooding reale trova ciò che l'ispezione statica non trova** —
tre dei gap sopra sarebbero rimasti invisibili senza aver provato l'onboarding per davvero.
Si decide di non lasciare questo metodo confinato a una sessione di chat: nasce la skill
`dev-critic`, richiamabile on-demand su qualunque target (hub o progetto onboardato), che
istituzionalizza il metodo (lettura critica + uso reale) e aggiunge un compito che il gate
notturno non fa: proporre **funzionalità non ancora considerate**, non solo trovare difetti in
ciò che esiste.

### 2026-08-21, notte — dev-critic verifica la review Opus: un fix confermato solo a metà

Primo uso reale della skill appena nata, sulle correzioni appena applicate (voce sopra). Metodo
rispettato: non fidarsi del diff, eseguirlo.

**`gate-esito.sh` era rotto dal giorno stesso della sua nascita.** `morning-gate.sh` scrive ora
7 campi con virgola finale per l'esito vuoto; `gate-esito.sh` riconosceva "esito già presente"
contando le virgole con una soglia scritta per il *vecchio* formato a 6 campi — quindi
scambiava OGNI riga nuova (esito vuoto) per "già registrata" e si rifiutava sempre di scrivere.
Riprodotto dal vivo (`bash gate-esito.sh owner/repo 99 merge` → `esito già registrato`, falso).
Il bug §2.1 della review originale (livello memoria vuoto) era quindi ancora aperto, solo
spostato: prima la colonna non veniva scritta, ora viene scritta ma non si può mai aggiornare.
**Corretto**: riconoscimento per numero di CAMPI (non virgole) con distinzione esplicita dei due
formati; tre casi testati dal vivo (formato nuovo, formato storico, doppia registrazione
respinta) — tutti corretti.

**La sicurezza §3 resta solo parzialmente chiusa — verificato, non corretto in questo giro.**
`gate_allowlist_ok()` controlla solo il primo token del segmento: `bash -c`, `python3 -c`,
`awk 'BEGIN{system()}'`, `sed .../e` restano nell'allowlist e sono state provate dal vivo a
bucarla (tutte passano). Il sandbox seatbelt non compensa: nega rete e scrittura fuori workdir,
non la lettura — un `cat ~/.ssh/id_rsa` in sandbox leggerebbe comunque il file (solo non
potrebbe spedirlo in rete). Non è un fix meccanico come gate-esito: cambia il modello di
minaccia, quindi resta in `DEBITI.md` per una decisione esplicita con Luca, non corretto a
sorpresa.

**Nuova funzionalità proposta (scope dichiarato vs implementato):** `docs/system.md` promette
che "le decisioni future le decidono i dati accumulati" in `metrics/gate.csv` — ma oggi nessuno
strumento lo legge, nemmeno dopo il fix di `gate-esito.sh`. Proposta: `gate-summary.sh`, un
riepilogo periodico (% verifiche ok, % smentite dal banco, repo con più commesse correttive
ripetute, PR senza esito da troppi giorni) — da costruire DOPO aver verificato che l'esito si
popola davvero nel tempo, altrimenti sarebbe un riepilogo di dati vuoti.

### 2026-08-21, notte (2) — il bypass dell'allowlist chiuso con l'opzione (c) di Luca

Decisione presa da Luca sulle opzioni presentate (handoff serale): **entrambe**. Fatto e
dimostrato con gli stessi comandi che avevano trovato il bypass (ora devono fallire — e
falliscono): interpreti general-purpose rimossi dall'allowlist (`bash -c`, `python3 -c`,
`awk system()`, `sed /e`, `node -e`, `npm run` → tutti BLOCCATI; il banco smentisce con
grep/cat/git readonly) e sandbox con **letture negate sui percorsi sensibili** (`.ssh`,
`.aws`, `.gnupg`, token gh in `.config/gh`, credenziali Claude, `.ollama`) — provato dal
vivo: `cat ~/.config/gh/hosts.yml` in sandbox → Operation not permitted; `/etc/hosts` e
workdir restano leggibili. Chiuso in pubblico anche il falso positivo del quoting: lo split
dei segmenti ora rispetta le virgolette (`grep -c "a;b" file` passa). I due debiti di
dev-critic sono marcati SALDATI in DEBITI.md.

### 2026-08-21, notte (3) — gate-summary: i dati promessi diventano leggibili

Il prerequisito dell'handoff verificato SENZA assumerlo: la colonna esito era vuota (#369
aspetta la review di Luca — e questo è già aging vero) e #364 era stata fusa prima che la
colonna esistesse. Backfill onesto del fatto vero (#364 → merge, con le condizioni dell'epoca)
e test di `gate-esito.sh` sul formato a 7 campi (correttamente rifiuta il doppio inserimento).
Nasce `night-shift/gate-summary.sh` (modulo `csv` di Python, zero dipendenze): per repo %
verifiche ok, % smentite del banco, aree fragili (commesse correttive ripetute ≥2) e aging
deduplicato per PR sull'attesa VERA (riga più vecchia). Prima lettura dai dati: 5/7 verifiche
ok, 0 smentite, 1 merge — e #369 in attesa. Allineato anche system.md sul percorso cloud/ibrido
(gli era sfuggito, nota dell'handoff: dichiarato ma non scritto lì).

### 2026-08-21, sera — il test che contava: sviluppare una feature NUOVA

Mandato di Luca: usare il sistema per una feature vera su Bilancio_di_Massa_PEFC, guardare
dove fallisce. Il test ha trovato il bug più importante DENTRO l'operatore: la prima proposta
era pattern-matching (bottone gemello), non progettazione — /brainstorming saltato. Il redo
ha eseguito il processo per intero: 3 agenti in parallelo leggono tutto (prodotto, motore
Python, intento/storia), gap analysis col desiderio del progetto alla mano (il suo SAL §6
aveva già la roadmap), scelta socratica → **analisi per spessore** (la granularità del banco
di Matteo, assente in dashboard). Design documentato, commessa #11 chirurgica, turno in corsa
con anche la #10 (CSV). Cinque finding d'infrastruttura in giornata, tutti corretti: pre-scan
rotto, processo-saltabile, zombie opencode, doppio proprietario del server, turni sovrapposti
(lock per repo). L'analisi completa con le proposte: docs/test-processo-2026-08-21.md —
la prima: template issue con sezione DESIGN obbligatoria, così il metodo non dipende più
dalla disciplina dell'operatore.

### 2026-08-21, sera (2) — secondo turno preparato e il processo si difende da solo

Miglioramento #1 dell'analisi implementato E testato in serata: il turno ora **salta le issue
senza \`## Design\`** (con commento esplicativo nell'issue) e il template GitHub le fa nascere
già col posto per il design — bootstrap lo crea, onboard lo porta. Finding #6 pagato subito:
committare nel workdir mentre il turno lo possiede finisce sul branch della notte — regola
scritta: **il giorno non tocca il workdir della notte, passa dall'API** (il template è stato
messo su main via gh api dopo l'errore). Nuove commesse #12 (registri nel PDF, da SAL §6.8) e
#13 (formati italiani nel PDF, da SAL §8) — entrambe nascono dal SAL del progetto, non dal
pattern matching: il processo corretto comincia prima ancora del turno.

### 2026-08-21, sera (3) — il primo A/B giorno-vs-notte, e la commessa col difetto

Luca ha mandato Claude (giorno) sulla STESSA commessa #11 che la notte stava macinando.
**Risultato netto**: Claude completa in 10m35s con qualità superiore al previsto — regex
verificata byte-per-byte, **codice eseguito in Node con 13 asserzioni su dati sintetici
(tutte passate)**, un limite onesto trovato ESECUTANDO e documentato nella PR (#14). La notte:
1h24m e ancora zero file scritti. Il sistema ha la sua prima misura A/B: il fattore ~10x
a favore del giorno su commesse con esplorazione, e la conferma che la notte è per il volume
meccanico, non per l'ignoto.

**La scoperta più utile però è un difetto MIO**: la commessa #11 assumeva che i dati
per-codice fossero nell'oggetto bilancio — Claude, eseguendo, ha scoperto che l'acquistato è
aggregato per famiglia e il dettaglio per-codice è un dataset separato on-demand. Il giorno
se ne accorge leggendo; la notte probabilmente ci annega (l'ipotesi più probabile del suo
silenzio). Lezione strutturale: **la commessa deve dichiarare la FORMA DEI DATI verificata
sul codice** — ora il template issue ha la sezione obbligatoria "## Forma dei dati".

Le tre cose che Claude non ha capito dalla documentazione → tre azioni fatte:
1. forma dei dati non documentata → sezione obbligatoria nel template (sopra)
2. grammatica dei codici articolo non documentata → TODO dominio (da chiedere a Matteo,
   candidato a docs/GRAMMATICA_CODICI.md quando qualcuno la sa scrivere)
3. CLAUDE.md §6 di PEFC citava il progetto Motore (engine, pnpm, PHP!) → corretto via API
   con il contesto reale del repo

### 2026-08-21, notte — le interazioni col giorno diventano workflow del sistema

Le sessioni Claude di oggi (review, dev-critic, A/B, audit lanciato da Luca) non restano
scambi: diventano fasi ripetibili. Nascono `/audit-commesse` (il pre-flight serale che
verifica le assunzioni delle commesse sul codice prima che la notte le incontri — la lezione
dell'A/B strutturata) e `/design-doc` (il design con opzioni che non implementa: la scelta
resta umana), entrambi per Claude E ZCode. Il gate ora giudica anche i branch claude/*: il
lavoro del giorno passa verifiche e banco come quello notturno — un giudice, due occhi.
Il ciclo completo: brainstorming → design-doc → commessa → audit-commesse → notte → gate
→ review. Ogni fase ha il suo comando, ogni comando il suo perché scritto.
