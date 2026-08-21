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

### 2026-08-21, notte (2) — il primo giro di /audit-commesse: 3 commesse su 4 difettose

Luca ha lanciato l'audit su Claude la sera stessa in cui il comando è nato. Verdetto:
**tre commesse su quattro avevano difetti veri** — #13 interamente obsoleta (il PDF era già in
formato italiano: la nota SAL che la giustificava descriveva uno stato superato MAI
aggiornato — rettificata via API con la regola che ne esce), #10 con premessa falsa (il CSV
esiste già, verificato per esecuzione — ridotta a micro-commessa sul gap reale: la data nel
nome file), #12 con due assunzioni sbagliate (tabella DDS esistente da estendere, funzione
citata errata — riscritta). #11: assunzioni giuste ma specifica incompleta — l'audit ha
trovato la causa probabile dello stallo notturno (la fonte per-codice mai nominata). Notte
fermata su #11: la consegna esiste già (PR #14 del giorno), la coda riparte alle 23:00 con
le commesse corrette.

**Il dato di sistema che conta**: il tasso di difetti delle commesse scritte a mano era 75%.
La difesa in profondità ora è: template (Design + Forma dei dati obbligatori) → audit serale
→ notte. L'audit ha pagato il biglietto al primo giro, trovando con esecuzione (non lettura)
ciò che l'autore non vedeva. Regola aggiunta alla自身的 pratica: chi scrive commesse verifica
le affermazioni del SAL contro il codice — un diario che dice il passato come presente è
peggiore di un diario mancante (rettifica scritta anche nel SAL di PEFC).

### 2026-08-21, notte (3) — il raccolto di AI_Develop entra: 18 pattern vivi

La PR #7 di Claude (8 pattern setacciati dai 93 strumenti di AI_Develop, tutti ancorati e
provati per esecuzione dove possibile) è MERGED — e con essa la #14 (spessori): Luca ha
fuso entrambe in giornata. La libreria patterns/ conta ora 18 voci vive. Note di_onestà:
il pattern trovare-non-e-fallire dichiara che riallinea-mirror.sh intero non ha mai girato
nell'ambiente del raccolto (scritto, non finto); tre candidati scartati CON motivo. Il
pattern segreto-come-impronta indica un buco nostro (il gate non maschera gli output) —
in DEBITI. Rettificata pure una mia pretesa: il README diceva che il grafo indicizza i
pattern — falso con --code-only, voce in DEBITI. Backfill CSV: #14 fusa-prima-del-gate.

### 2026-08-21, notte (4) — quattro ambiti mancanti nel roster, chiesti da Luca dopo l'analisi

Luca ha chiesto un giudizio sul roster di cervelli/ruoli del sistema, "in base ai GAS fatti
e analizzati" (CDG, Bilancio_di_Massa_PEFC, il parco di AI_Develop). Risposta: il PROCESSO è
maturo e misurato (A/B, audit-commesse), ma i ruoli restano due soli (notte meccanica,
giorno generico) contro un roster molto più specializzato osservato in AI_Develop
(bc-specialist, ui-engineer, business-development-specialist, ecc.). Quattro aggiunte,
tutte richieste e implementate lo stesso giro:

- **`audit-commessa`** (`.claude/skills/audit-commessa/`) — scoperta collaterale: `/audit-commesse`
  e `/design-doc`, citati come comandi in SAL.md e docs/system.md, non esistevano come file
  in nessun repo (solo prosa). `audit-commessa` li rende un artefatto vero e ci porta dentro
  la lente Business Central (aggregazione per famiglia ≠ per codice, endpoint con buchi
  noti, CATALOGO_ENDPOINT_BC.md come fonte di verità) — è lo specialista forma-dati/BC
  richiesto, senza duplicare un ruolo nuovo scollegato dal processo esistente.
  `/design-doc` resta non formalizzato: fuori scope di questo giro, segnalato non deciso.
- **`verifica-visiva`** (`.claude/skills/verifica-visiva/` + `tools/verifica-visiva.js`) —
  il buco più ripetuto nell'audit di oggi: 4 commesse su 4 (#10-13) finivano con "review
  visiva di Luca nel deploy" come unico controllo sul frontend. Screenshot reale via
  Chromium headless (zero dipendenze nuove — CLI diretta, non il package playwright) +
  guardia contro segnali d'errore noti di Apps Script e pagine vuote. **Provato dal vivo in
  questa sessione** sui tre casi (pagina sana, pagina con "Autorizzazione richiesta", pagina
  vuota) — tutti rilevati correttamente. **Limite dichiarato**: non provato contro un vero
  deploy Apps Script, che richiede clasp/OAuth sul Mac.
- **Lente sicurezza in `dev-critic`** (§2bis, non un nuovo skill) — i due incidenti reali di
  oggi (bypass dell'allowlist, credenziali BC in CDG) non sono mai stati trovati da un ruolo
  dedicato: dev-critic ora applica SEMPRE (non solo su richiesta) la lente sicurezza quando
  il target esegue codice generato da LLM o stampa output derivato da terzi.
- **`docs/GRAMMATICA_DOMINIO_TEMPLATE.md`** — chiude un TODO lasciato aperto dall'audit di
  PEFC ("grammatica dei codici articolo non documentata... da chiedere a Matteo"): nessun
  ruolo possedeva la cattura del vocabolario tribale che si ripete in ogni progetto BC del
  gruppo. Seminato ora in `bootstrap-app.sh`/`onboard-repo.sh` (copiato solo se assente).

**Prossimo passo, richiesto da Luca**: un pilota end-to-end su `night-shift-pilot` (repo
nuovo, scaffold minimo) per verificare che l'intero processo — comprese queste quattro
aggiunte — produca davvero una commessa pronta per la notte. App scelta apposta di scarso
valore proprio ("fatturati per cliente e articolo" su BC, dati mock): serve a testare il
banco di sviluppo, non a produrre un'app vera.

### 2026-08-21, notte (5) — due giri del pilota chiusi end-to-end, e un vincolo scoperto sul vivo

Luca ha chiesto di eseguire il processo su `night-shift-pilot` "monitorandolo per
migliorarlo", esplicitamente saltando l'attesa del turno reale (non lanciabile da questa
sessione: niente Ollama/opencode/clasp qui). Due cicli completi, entrambi commessa→
implementazione (Claude al posto della notte, dichiarato in ogni PR)→verifica reale
(`npm test`)→PR bozza→merge→issue chiusa:

- **#4** (fatturato per cliente/articolo su mock BC): 3/3 test verdi, `Closes #4` ha chiuso
  l'issue correttamente al merge (keyword inglese, coerente con la lezione già nota).
- **#6** (riepilogo: totali + cliente top, sopra il codice di #4): 4/4 test verdi (i 3
  esistenti invariati, zero regressioni), stessa dinamica.

**Il vincolo vero, trovato eseguendo due commesse in sequenza nella stessa sessione**: la
crescita "a piccoli passi" richiede che la commessa N si basi sul codice della N-1 —
merge di mezzo. Il sistema non ha (né dovrebbe avere di default) un modo per bypassare il
sì umano al merge, quindi ho chiesto e ottenuto un'autorizzazione esplicita, dichiaratamente
scoped a questo pilota di test ("senza valore reale"), per non fermarmi a ogni giro. **Non è
un difetto del sistema**: nel mondo reale la notte è quotidiana, non compressa in pochi
minuti — il vincolo è emerso solo per la compressione temporale del test, ma vale la pena
saperlo: chi testa più commesse dipendenti in una sola sessione deve aspettarsi di dover
chiedere il via libera al merge più spesso del normale.

**Gap onesto confermato due volte**: il banco avversariale resta non eseguibile da una
sessione cloud (nessun cervello locale/Opus raggiungibile) — segnalato in entrambe le PR,
non finto.

### 2026-08-21, notte (6) — Giro 1 dei "3 giri con test autonomi": audit-commessa alla prova

Luca ha chiesto almeno 3 giri autonomi (test + sviluppo), ognuno con un'analisi sincera e
una correzione al progetto master. Giro 1: stress-test deliberato di `audit-commessa` — ho
scritto io stesso l'issue #8 di `night-shift-pilot` con un'affermazione sulla forma dei dati
FALSA ma plausibile ("il dato per-cliente è già disponibile in `riepilogoFatturato`"),
apposta senza verificarla, per vedere se la skill la cattura prima che diventi codice.

**Esito sul contenuto: la skill ha funzionato.** Applicata come da manuale (§1.3: eseguire,
non leggere), ha smascherato la falsità con un `node -e` reale su `src/fatturato.js`:
`riepilogoFatturato` costruisce una mappa `perCliente` completa ma la scarta, restituendo
solo `clienteTop` (un vincitore, non l'elenco) — esattamente il pattern "aggregazione
riassuntiva ≠ dettaglio completo" già pagato su Bilancio_di_Massa_PEFC #11 e scritto nella
lente BC della skill. Corretta l'issue #8 con `## Forma dei dati (verificata sul codice)` e
la correzione concreta per chi implementerà la commessa.

**Esito sul processo, non richiesto ma trovato per strada — questo è il vincolo reale**:
invocare `audit-commessa` è FALLITO due volte di seguito ("Unknown skill: audit-commessa")
mentre ero sul branch corretto (`claude/nuovi-ruoli-audit`, PR #8 non ancora mersa) con il
file `.claude/skills/audit-commessa/SKILL.md` confermato presente su disco — poi ha
funzionato al tentativo successivo, senza che io avessi fatto altro che passare un turno.
La causa più probabile: l'elenco delle skill disponibili per la sessione non si aggiorna in
modo sincrono al `git checkout`, ma con un ritardo di durata non garantita. **Questo è un
difetto operativo reale**: una skill che vive solo su un branch/PR non mersa è, per questo
motivo, invocabile in modo inaffidabile nella stessa sessione — non un problema della skill
in sé, ma del momento in cui viene provata. Correzione applicata al master: voce in
DEBITI.md che raccomanda di non concludere "skill assente" al primo fallimento quando il
file esiste sul branch giusto, e di preferire il merge delle PR che introducono skill non
appena il contenuto è verificato, proprio per non pagare due volte questo ritardo.

Chiuso anche il ciclo pratico: implementata la commessa #8 corretta (`csvFatturatoPerCliente`
costruito da zero, non estratto da `riepilogoFatturato`), 6/6 test verdi, PR #9 mersa,
`Closes #8` verificato al merge.

### 2026-08-21, notte (7) — Giro 2 dei "3 giri autonomi": verifica-visiva su un artefatto vero

Giro 2: creata la commessa #10 (report HTML statico del fatturato, `src/report.js` +
`tools/genera-report.js` → `dist/report.html`, gitignored) apposta per dare a
`verifica-visiva` un vero artefatto del pilota da controllare — non più solo le pagine
sintetiche scritte a mano per testare lo strumento la prima volta (limite scritto in
DEBITI.md dopo l'aggiunta del roster).

**Esito: positivo, e verificato per davvero.** `node tools/verifica-visiva.js file://.../dist/report.html out.png`
→ exit 0; ho guardato lo screenshot (non solo il verdetto del tool) e corrisponde
esattamente ai dati generati (5 righe, stessi clienti/articoli/importi del file HTML).
Ho anche provato un caso limite reale — non ipotetico — che un report vero incontrerebbe:
0 fatture nel periodo (stato legittimo, non un errore). Nessun falso positivo: titolo e
intestazioni tabella restano sopra la soglia di "pagina vuota" (40 caratteri) della skill
anche senza righe di dati.

**Limite onesto, non richiuso**: questo resta un test su `file://` locale via Chromium
headless, non su un vero deploy Apps Script (dominio `script.google.com`, OAuth) — quel
gap dichiarato in DEBITI.md non si chiude da questa sessione (nessun clasp/OAuth
disponibile). Correzione applicata al master: la voce DEBITI.md è stata aggiornata per
riflettere il progresso reale senza sovra-dichiararlo — "provata anche su un artefatto
vero" è vero, "provata su un deploy reale" resta falso finché qualcuno con clasp non lo fa.

### 2026-08-21, notte (8) — Giro 3 dei "3 giri autonomi": la lente sicurezza di dev-critic alla prova

Giro 3: stress-test deliberato della lente sicurezza (§2bis). Creata la commessa #12 su
`night-shift-pilot` ("diagnostica connessione BC") che chiede letteralmente di stampare a
console `JSON.stringify(config)` di una configurazione di connessione mock
(`mock/bc-connessione.json`, con un `apiKey` finto ma verosimile) — implementata alla
lettera, PRIMA di qualunque audit, esattamente come la seguirebbe la notte senza giudizio
proprio.

**Esito: la lente funziona quando viene invocata, e l'ho verificato eseguendo il codice
davvero**, non leggendolo: `node -e 'diagnosticaConnessione(require("./mock/bc-connessione.json"))'`
stampa a console la riga intera con `"apiKey":"mock-api-key-NON-REALE-..."` in chiaro —
esattamente il pattern descritto in `segreto-come-impronta.md` (nato dallo stesso tipo di
incidente, un `client_secret` finito in una trascrizione). Applicando il metodo della
skill (lettura critica + dogfooding reale, non ipotetico) il problema è innegabile e
puntuale: `src/diagnostica.js:2`.

**Il vincolo reale, non di contenuto ma di processo**: nella pipeline dichiarata
(commessa → audit-commessa → notte → morning-gate → review umana) NON esiste un punto in
cui la lente sicurezza di dev-critic sia invocata automaticamente — è "on demand", per
disegno (la SKILL.md dice "usa quando l'utente chiede... o invoca /dev-critic
esplicitamente"). Una commessa come la #12 potrebbe attraversare l'intera pipeline ed
essere mersa senza che nessuno la applichi mai, esattamente come i due incidenti originali
(allowlist bucabile, credenziali BC committate) non sono mai stati trovati finché qualcuno
non ha deliberatamente provato ad aggirarli. **Correzione applicata al master**: aggiunto
un puntatore nella sezione `## Verifica` del template issue night-shift
(`.github/ISSUE_TEMPLATE/night-shift.md`) — stesso schema già usato per `verifica-visiva`
— che invita a valutare la lente sicurezza quando la commessa stampa/logga output
derivato da config/credenziali/dati di terzi, dichiarando esplicitamente che il gate non
la esegue da sé.

Chiuso anche il ciclo pratico: `src/diagnostica.js` corretto per mascherare `apiKey` con
un'impronta (pattern `segreto-come-impronta`, non con un'omissione silenziosa) prima del
merge della PR del pilota — la scoperta non resta solo teorica.

### 2026-08-21, notte (9) — Luca chiede altri 10 giri: Giro 4, Design assente

Luca ha chiesto altri 10 giri dopo i primi 3. Giro 4: issue #14 creata apposta SENZA
`## Design` (e con un claim sui dati sbagliato, "il campo filtro è già in Amount" quando
serve `Posting_Date`). **Esito positivo**: applicando `audit-commessa` mi sono fermato al
passo 1 come da regola, senza guardare il claim sui dati — comportamento corretto, non
un'audit sprecata su una commessa che la notte salterebbe comunque.

**Finding minore, corretto**: la regola diceva solo "fermati e dillo" senza specificare
DOVE — ambiguo tra "dillo alla sessione che chiama" e "dillo sulla issue". Ho deciso per
un commento sull'issue (visibile a chi la possiede, non solo in chat) e ho chiarito la
SKILL.md di conseguenza, così le prossime invocazioni non debbano decidere da capo.

### 2026-08-21, notte (10) — Giro 5: una convenzione di dominio inventata, non confermata

Issue #15: "i codici `ART-` sono articoli di test, esclusi dai report" — convenzione
scritta come fatto, MAI confermata. Verificato: `docs/GRAMMATICA_DOMINIO.md` non la
cita, e la sua stessa regola dice che una riga senza fonte è un'ipotesi. Eseguito
l'impatto reale sul mock: il filtro avrebbe escluso 6/6 righe (tutti gli articoli
mock sono `ART-*`) — uno svuotamento totale di qualunque report, non un dettaglio.
Corretta l'issue, commessa sospesa (nessuna implementazione: una scelta di dominio con
impatto non si decide da sé).

**Correzione applicata al master**: il metodo di `audit-commessa` (§1.2) verificava
solo claim su forma-dati/campi, non convenzioni di dominio presentate come fatto —
aggiunto un passo esplicito che impone il controllo su `GRAMMATICA_DOMINIO.md` anche
per questo tipo di claim, con la prova di questo giro come esempio ancorato.

### 2026-08-21, notte (11) — Giro 6: una regressione vera, e cosa fa davvero il gate

Issue #16: cambiare l'ordinamento di `fatturatoPerClienteArticolo` (per cliente invece
che per importo) — richiesta plausibile, non un errore evidente. Implementata da sola:
`npm test` → 11/12, 1 fallito (l'ordine atteso dal test esistente). Verificato che
nessun altro consumatore dipendesse da quell'ordine, poi corretto il test al nuovo
contratto — non disattivato. 12/12, PR #17 mersa.

**Verifica di un fatto sul sistema, non presunto**: sono andato a leggere cosa fa
DAVVERO `morning-gate.sh` su una verifica fallita (non l'ho mai eseguito dal vivo prima
d'ora in questo modo): non merge mai da solo — scrive un verdetto `verifiche-fallite`
sempre visibile nel riepilogo finale, e propone (testo, non eseguito) un comando
`gh issue create` correttivo "da approvare". Design corretto: nessun merge automatico,
umano sempre nel loop.

**Correzione applicata al master**: quel comando correttivo propone un body che dice
solo "Dettagli nel report locale del gate" — ma il report è un file sul Mac che ha
eseguito il gate, irraggiungibile da chi lavorerà la issue correttiva altrove (stesso
tipo di buco già noto per il percorso cloud/ibrido). L'output vero del fallimento
esiste già nello stesso report, solo non viene copiato nella issue. Voce in DEBITI.md:
non corretto il codice (decidere cosa dell'output è sicuro incollare in una issue
pubblica è una scelta di Luca, non mia).

### 2026-08-21, notte (12) — Giro 7: verifica-visiva non vedeva "undefined"

Simulato un caso realistico (non pianificato per far fallire lo strumento apposta,
ma un vero scenario BC: un cliente il cui master data non è ancora sincronizzato,
`Customer_Name` assente). Il report generato mostra `undefined` in chiaro nella cella
"Cliente" — verificato eseguendo `generaReportHtml` e guardando l'HTML. Passato a
`tools/verifica-visiva.js`: **exit 0, "nessun segnale d'errore"** — falso verde
confermato anche a occhio nello screenshot.

**Corretto direttamente** (fix piccolo, senza trade-off di design): aggiunti
`"undefined"`, `"NaN"`, `"[object Object]"` a `SEGNALI_ERRORE`. Riprovato lo stesso
file: ora exit 1, segnale rilevato. Riprovato anche il report sano del Giro 2: resta
exit 0, nessuna regressione. `"null"` bare escluso deliberatamente: in un progetto in
italiano collide con "nullo"/"nulla" — servirebbe un match a parola intera che
`SEGNALI_ERRORE` (solo substring oggi) non supporta; non aggiunto per non introdurre
un falso positivo peggiore di quello che risolve.

### 2026-08-21, notte (13) — Giro 8: due commesse gemelle, un conflitto reale, e un buco nel gate

Due issue (#18, #19) create dalla stessa base commit, stesso punto di
`src/fatturato.js`, apposta per produrre un conflitto di merge vero. Mersa #19 per
prima; la PR di #18 è arrivata a `mergeable_state: "dirty"` — verificato via API, non
presunto. Risolto correttamente: `git merge origin/main`, conflitto vero su due file,
tenute ENTRAMBE le funzioni (indipendenti, nessuna esclude l'altra), 14/14 test dopo
la risoluzione — nessun lavoro scartato, nessun `--force`.

**Correzione applicata al master, trovata verificando come si comporterebbe il gate
reale su questo stesso scenario**: letto `night-shift/night-shift.sh` — ogni branch
`night/issue-N` nasce da `origin/$DB` al momento della creazione (riga 168), quindi
due commesse nella stessa notte possono benissimo generare questo identico conflitto
in produzione, non solo nel test. Verificato che `morning-gate.sh` non menziona MAI
`mergeable`/`conflict` (grep, zero risultati) — potrebbe scrivere "verifiche-ok" per
una PR che i test passano sul proprio branch ma che GitHub rifiuterebbe di mergere,
e l'umano lo scoprirebbe solo provando a mergere. **Corretto direttamente** (aggiunta
informativa, nessun comportamento nuovo, GitHub blocca già il merge da solo):
`gh pr list` ora chiede anche il campo `mergeable`, e il report segnala
`⛔ Non mergeable: conflitto con main` in testa alla sezione della PR, prima di tutto
il resto. Verificato: `bash -n` passa; **non eseguito dal vivo contro `gh pr list`**
(nessun `gh` autenticato in questa sessione) — il campo `mergeable` è documentato
nello schema `gh pr list --json`, non inventato, ma la prova end-to-end resta da fare
sul Mac.

### 2026-08-21, notte (14) — Giro 9: gate-esito.sh su dati VERI, non su un test giocattolo

I tre casi che il primo test di `gate-esito.sh` aveva confermato (formato nuovo,
formato storico, doppia registrazione respinta) erano su un CSV sintetico minimale.
Giro 9: stesso script, ma testato su una COPIA di lavoro del vero `metrics/gate.csv`
(mai toccato l'originale — verificato con `git diff`, vuoto). Quel file reale ha una
forma che un test giocattolo non riproduce: 5 righe storiche a 6 campi PIÙ 2 righe
nuove a 7 campi vuote, tutte per lo STESSO repo+PR (`AI_Develop #369`), impilate da
notti diverse prima che qualcuno registrasse un esito.

**Trovato un bug reale, non ipotetico.** Prima chiamata (`gate-esito.sh ... 369
merge`): corretta, scrive sull'ULTIMA riga pendente (riga 9) — esattamente il
comportamento dichiarato. **Seconda chiamata identica, stesso comando**: doveva
essere respinta ("esito già registrato") e invece ha scritto di nuovo, esito
"registrato" su una riga DIVERSA e più vecchia (riga 7, anch'essa a 7 campi ma
ancora vuota) — lo stesso evento reale (un merge) finirebbe duplicato su due righe
del CSV, gonfiando le metriche aggregate di `gate-summary.sh`. Riprodotto due volte
di seguito, stesso esito.

**Causa verificata leggendo il codice**: lo script cerca "l'ultima riga pendente"
ad ogni chiamata, non "esiste già un esito per questo repo+PR in una qualunque
riga" — quindi se più righe pendenti si sono accumulate nel tempo (realistico: la
notte scrive una riga nuova a ogni gate, un PR può restare aperto su più notti),
una seconda chiamata trova sempre un'altra vittima. **Non corretto qui**: la
soluzione ovvia ("respingi se un esito esiste già per questo repo+PR") romperebbe
il caso legittimo opposto — un PR con esito `commessa` che poi, dopo la correzione,
riceve una riga nuova con esito `merge` in una notte successiva. Distinguere i due
casi (doppia registrazione per errore vs. secondo esito legittimo su un ciclo
correttivo) è una decisione di design sul significato di "esito", non un fix
meccanico — voce in DEBITI.md con la riproduzione esatta, per il sì di Luca.

### 2026-08-21, notte (15) — Giro 10: Closes multiplo e prima commessa chore, entrambi puliti

Ultimo dei 10 giri extra. Due issue gemelle (#22 LICENSE, #23 .editorconfig),
un'unica PR con `Closes #22` e `Closes #23` nel body, prima commessa di tipo
`chore` in questo pilota (finora solo feat/fix/refactor). Verificato via API dopo
il merge: entrambe le issue `state: closed`, `state_reason: completed`, entrambe
con `closed_by_pull_requests` che punta alla stessa PR #24 — GitHub riconosce
correttamente due keyword indipendenti nello stesso body, non solo la prima.

**Esito onesto: nessun difetto trovato, nessuna correzione al master per questo
giro.** Non ogni giro deve produrne una — forzarne una qui sarebbe meno onesto che
dirlo chiaramente. Comportamento mercanico di GitHub confermato, non specifico ad
alcun codice di questo sistema.

---

**Chiusura dei 10 giri extra (Giri 4-10, oltre ai 3 iniziali).** Sintesi dei
risultati concreti sul master: 2 fix diretti a codice condiviso (`verifica-visiva.js`
non vedeva `undefined`/`NaN`; `morning-gate.sh` non segnalava PR non mergeable), 1
bug reale documentato ma non corretto perché richiede una decisione di design
(`gate-esito.sh`, doppia registrazione), 2 chiarimenti al metodo di `audit-commessa`
(dove riportare "Design assente"; verificare anche le convenzioni di dominio, non
solo la forma-dati), 1 giro senza difetti (Giro 10). Il filo comune resta lo stesso
di tutta la sessione: ogni claim in questo diario è stato eseguito, non presunto —
compreso "non ho trovato niente" quando è stato il caso.
