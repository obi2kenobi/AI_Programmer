# SAL — il diario vivo del sistema

> Diario del sistema di sviluppo (hub + cervelli + turno notturno + giudizio).
> Ogni decisione porta la data e i fatti che l'hanno imposta. Aggiornato dal morning-gate
> e a ogni decisione strutturale.

<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->
## Indice del diario

- [2026-08-21 — assemblaggio del sistema](#2026-08-21-assemblaggio-del-sistema)
- [2026-08-21, ore 12 — prima lezione operativa del gate (e chi la firma)](#2026-08-21-ore-12-prima-lezione-operativa-del-gate-e-chi-la-firma)
- [2026-08-21, pomeriggio — graphify entra nel sistema come strato di navigazione](#2026-08-21-pomeriggio-graphify-entra-nel-sistema-come-strato-di-navigazione)
- [2026-08-21, sera — l'esperimento DFlash2: il video prometteva 3x, i fatti dicono altro](#2026-08-21-sera-l-esperimento-dflash2-il-video-prometteva-3x-i-fatti-dicono-altro)
- [2026-08-21, sera — loop engineering: il nome arriva dopo la pratica](#2026-08-21-sera-loop-engineering-il-nome-arriva-dopo-la-pratica)
- [2026-08-21, pomeriggio tardi — ponytail e superpowers: il delta, non il catechismo](#2026-08-21-pomeriggio-tardi-ponytail-e-superpowers-il-delta-non-il-catechismo)
- [2026-08-21, notte — dev-critic verifica la review Opus: un fix confermato solo a metà](#2026-08-21-notte-dev-critic-verifica-la-review-opus-un-fix-confermato-solo-a-met)
- [2026-08-21, notte (2) — il bypass dell'allowlist chiuso con l'opzione (c) di Luca](#2026-08-21-notte-2-il-bypass-dell-allowlist-chiuso-con-l-opzione-c-di-luca)
- [2026-08-21, notte (3) — gate-summary: i dati promessi diventano leggibili](#2026-08-21-notte-3-gate-summary-i-dati-promessi-diventano-leggibili)
- [2026-08-21, sera — il test che contava: sviluppare una feature NUOVA](#2026-08-21-sera-il-test-che-contava-sviluppare-una-feature-nuova)
- [2026-08-21, sera (2) — secondo turno preparato e il processo si difende da solo](#2026-08-21-sera-2-secondo-turno-preparato-e-il-processo-si-difende-da-solo)
- [2026-08-21, sera (3) — il primo A/B giorno-vs-notte, e la commessa col difetto](#2026-08-21-sera-3-il-primo-a-b-giorno-vs-notte-e-la-commessa-col-difetto)
- [2026-08-21, notte — le interazioni col giorno diventano workflow del sistema](#2026-08-21-notte-le-interazioni-col-giorno-diventano-workflow-del-sistema)
- [2026-08-21, notte (2) — il primo giro di /audit-commesse: 3 commesse su 4 difettose](#2026-08-21-notte-2-il-primo-giro-di-audit-commesse-3-commesse-su-4-difettose)
- [2026-08-21, notte (3) — il raccolto di REPO-A entra: 18 pattern vivi](#2026-08-21-notte-3-il-raccolto-di-repo-a-entra-18-pattern-vivi)
- [2026-08-21, notte (4) — quattro ambiti mancanti nel roster, chiesti da Luca dopo l'analisi](#2026-08-21-notte-4-quattro-ambiti-mancanti-nel-roster-chiesti-da-luca-dopo-l-analisi)
- [2026-08-21, notte (6) — Giro 1 dei "3 giri con test autonomi": audit-commessa alla prova](#2026-08-21-notte-6-giro-1-dei-3-giri-con-test-autonomi-audit-commessa-alla-prova)
- [2026-08-21, notte (7) — Giro 2 dei "3 giri autonomi": verifica-visiva su un artefatto vero](#2026-08-21-notte-7-giro-2-dei-3-giri-autonomi-verifica-visiva-su-un-artefatto-vero)
- [2026-08-21, notte (9) — Luca chiede altri 10 giri: Giro 4, Design assente](#2026-08-21-notte-9-luca-chiede-altri-10-giri-giro-4-design-assente)
- [2026-08-21, notte (10) — Giro 5: una convenzione di dominio inventata, non confermata](#2026-08-21-notte-10-giro-5-una-convenzione-di-dominio-inventata-non-confermata)
- [2026-08-21, notte (11) — Giro 6: una regressione vera, e cosa fa davvero il gate](#2026-08-21-notte-11-giro-6-una-regressione-vera-e-cosa-fa-davvero-il-gate)
- [2026-08-21, notte (12) — Giro 7: verifica-visiva non vedeva "undefined"](#2026-08-21-notte-12-giro-7-verifica-visiva-non-vedeva-undefined)
- [2026-08-21, notte (14) — Giro 9: gate-esito.sh su dati VERI, non su un test giocattolo](#2026-08-21-notte-14-giro-9-gate-esito-sh-su-dati-veri-non-su-un-test-giocattolo)
- [2026-08-21, notte (15) — Giro 10: Closes multiplo e prima commessa chore, entrambi puliti](#2026-08-21-notte-15-giro-10-closes-multiplo-e-prima-commessa-chore-entrambi-puliti)
- [2026-08-21, notte (17) — le due correzioni in sospeso, eseguite col sì di Luca](#2026-08-21-notte-17-le-due-correzioni-in-sospeso-eseguite-col-s-di-luca)
- [2026-08-21 — nuova regola: qui solo metodo, mai il nome dei progetti onboardati](#2026-08-21-nuova-regola-qui-solo-metodo-mai-il-nome-dei-progetti-onboardati)
- [2026-08-21 — Giro 3 sullo stesso progetto onboardato: un addendum, non un pattern nuovo](#2026-08-21-giro-3-sullo-stesso-progetto-onboardato-un-addendum-non-un-pattern-nuovo)
- [2026-08-22, mattina — la notte ha parlato: 11h39m su #12, zero file](#2026-08-22-mattina-la-notte-ha-parlato-11h39m-su-12-zero-file)
- [2026-08-22, sera — ciclo dei 5 giri completato: il processo osservato in loop](#2026-08-22-sera-ciclo-dei-5-giri-completato-il-processo-osservato-in-loop)
- [2026-08-22, notte — ciclo 2 su REPO-D: la progettazione protagonista](#2026-08-22-notte-ciclo-2-su-repo-d-la-progettazione-protagonista)
- [2026-08-22, notte (2) — 10 giri di auto-miglioramento: il sistema giudica se stesso](#2026-08-22-notte-2-10-giri-di-auto-miglioramento-il-sistema-giudica-se-stesso)
- [2026-08-22, notte (3) — 10 giri di FEATURE: cosa mancava davvero](#2026-08-22-notte-3-10-giri-di-feature-cosa-mancava-davvero)
- [2026-08-22, notte (4) — le decisioni di dominio prese (mandato di Luca: "decidi da solo")](#2026-08-22-notte-4-le-decisioni-di-dominio-prese-mandato-di-luca-decidi-da-solo)
- [2026-08-22, notte (5) — terzo ciclo di 10 giri: bug reali trovati eseguendo, non leggendo](#2026-08-22-notte-5-terzo-ciclo-di-10-giri-bug-reali-trovati-eseguendo-non-leggendo)


## Stato

`PRIMA INSTALLAZIONE` (2026-08-21) — sistema completo assemblato: base (regole + conoscenza),
cervelli richiamabili (`llm/`), turno notturno multi-repo, giudizio mattutino col banco
avversariale, memoria (questo file + `metrics/gate.csv`).

## Decisioni

- **2026-08-21 · Il repo chiama i vari LLM** (deciso da Luca). Wrapper uniformi `llm/ask-*`
  con contratto unico: chiunque può delegare a qualsiasi cervello. WayfinderRouter come tessuto
  per OpenCode; Opus resta diretto perché il router non implementa l'outbound Anthropic
  (verificato sui sorgenti, non presunto).
- **2026-08-21 · Nessun limite di tempo per issue notturna** (deciso da Luca, mutuata da REPO-A):
  fino a che non ha finito, il tempo non esiste. Guardie: prompt anti-loop + review del mattino.
- **2026-08-21 · Config reale fuori dal repo pubblico**: `night-shift/repos.conf` è gitignored —
  i nomi delle repo private non entrano in un repo pubblico. Nel repo solo `repos.conf.example`.
- **2026-08-21 · Il giudizio è avversariale**: il morning-gate non colleziona report, prova a
  smentire le PR (metodo del Supervisore in REPO-A, applicato al sistema). I fallimenti
  diventano proposte di commesse correttive — nulla si rifà senza il sì di Luca.
- **2026-08-21 · La scoperta di gap/nuove idee diventa una skill, non un'abitudine** (deciso da
  Luca): il ruolo "cervello di giorno per giudizio/architettura" della matrice `llm/README.md`
  esisteva solo come istruzione implicita ("fallo tu quando serve"). Diventa la skill
  `dev-critic` (`.claude/skills/dev-critic/`), richiamabile on-demand da qualunque sessione
  (questo hub o un progetto onboardato), non legata al turno notturno.

## Log cronologico

### 2026-08-21 — assemblaggio del sistema

Costruito su tutto ciò che le tre notti su REPO-A hanno insegnato (cinque difetti
d'infrastruttura trovati e corretti; il modello locale capisce ma non converge sulle indagini;
le issue devono essere commesse). Primo carico notturno per il hub: compilazione della colonna
_Significato_ BC — lavoro documentale, zero credenziali, il riscontro resta umano.

### 2026-08-21, ore 12 — prima lezione operativa del gate (e chi la firma)

Assemblando il sistema, chi scrive ha spinto `.night-verify` su REPO-A dal branch della PR
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

**Versione pinata: 0.9.48** (trovata installata la 0.8.50 — vecchia). Lezione di REPO-A
importata: lo schema cambia fra minor (0.8→0.9.36 ha rotto tre tool contemporaneamente) —
aggiornare solo a versioni verificate e stampare la versione sugli artefatti.

**Le tre regole del grafo** (tutte pagate da REPO-A, le adottiamo):
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
gate (informativo); **credenziali BC in REPO-C: VERIFICATO peggio del report — oltre al
file rtf, lo stesso segreto Azure era sparso in 21 commit (Config.gs, script, SAL.md). Storia
ripulita con filter-repo (file rtf rimosso + 2 valori segreti sostituiti con --replace-text),
gitleaks post-scan: ZERO leak. ⛔ L'AZIONE CHE RESTA È DI LUCA: ruotare le credenziali su
Azure — le vecchie hanno viaggiato nella storia git. gitleaks ora gira in bootstrap (bloccante
pre-push) e come pre-scan in onboard.**

**Minors §5:** il hub ora ha il suo `.night-verify` (shellcheck + bash -n — il sistema che
pretende verifiche dichiarate finalmente le dichiara per sé); warning quando si tocca il limite
50; DEBITI.md compilato con i rinvi deliberati (rotazione log, portabilità, test bc_*).

Nota operativa per Luca: i cloni locali di REPO-C vanno RICLONATI (la storia è stata
riscritta, gli hash sono cambiati).

### 2026-08-21, notte — dev-critic: il critico costruttivo diventa un comando, non un'abitudine

Occasione: la revisione manuale sopra (letti tutti gli script, poi onboarding REALE di
`REPO-C` per verificarli sul campo) ha trovato bug non visibili dalla sola lettura
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

Mandato di Luca: usare il sistema per una feature vera su REPO-B, guardare
dove fallisce. Il test ha trovato il bug più importante DENTRO l'operatore: la prima proposta
era pattern-matching (bottone gemello), non progettazione — /brainstorming saltato. Il redo
ha eseguito il processo per intero: 3 agenti in parallelo leggono tutto (prodotto, motore
Python, intento/storia), gap analysis col desiderio del progetto alla mano (il suo SAL §6
aveva già la roadmap), scelta socratica → **analisi per spessore** (la granularità del banco
di il referente di dominio, assente in dashboard). Design documentato, commessa #11 chirurgica, turno in corsa
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
2. grammatica dei codici articolo non documentata → TODO dominio (da chiedere a il referente di dominio,
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

### 2026-08-21, notte (3) — il raccolto di REPO-A entra: 18 pattern vivi

La PR #7 di Claude (8 pattern setacciati dai 93 strumenti di REPO-A, tutti ancorati e
provati per esecuzione dove possibile) è MERGED — e con essa la #14 (spessori): Luca ha
fuso entrambe in giornata. La libreria patterns/ conta ora 18 voci vive. Note di_onestà:
il pattern trovare-non-e-fallire dichiara che riallinea-mirror.sh intero non ha mai girato
nell'ambiente del raccolto (scritto, non finto); tre candidati scartati CON motivo. Il
pattern segreto-come-impronta indica un buco nostro (il gate non maschera gli output) —
in DEBITI. Rettificata pure una mia pretesa: il README diceva che il grafo indicizza i
pattern — falso con --code-only, voce in DEBITI. Backfill CSV: #14 fusa-prima-del-gate.

### 2026-08-21, notte (4) — quattro ambiti mancanti nel roster, chiesti da Luca dopo l'analisi

Luca ha chiesto un giudizio sul roster di cervelli/ruoli del sistema, "in base ai GAS fatti
e analizzati" (CDG, REPO-B, il parco di REPO-A). Risposta: il PROCESSO è
maturo e misurato (A/B, audit-commesse), ma i ruoli restano due soli (notte meccanica,
giorno generico) contro un roster molto più specializzato osservato in REPO-A
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
  PEFC ("grammatica dei codici articolo non documentata... da chiedere a il referente di dominio"): nessun
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
riassuntiva ≠ dettaglio completo" già pagato su REPO-B #11 e scritto nella
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
nuove a 7 campi vuote, tutte per lo STESSO repo+PR (`REPO-A #369`), impilate da
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

### 2026-08-21, notte (16) — Giri 11/12: la propria citazione non verificata, trovata verificandola

Rettifica onesta: la chiusura sopra contava 7 giri (4-10), non i 10 annunciati a
Luca — mancavano "citazione di un pattern invece di reinventare" e "lente BC,
endpoint con limite noto citato a memoria vs verificato". Anziché costruire una
finta issue per forzarli (avrebbero richiesto un livello OData che
night-shift-pilot non ha e non deve avere, essendo dati mock), li ho verificati
sulla fonte vera dove esistono già: il claim della lente BC nella mia stessa
`audit-commessa/SKILL.md` ("niente OR annidati... torna HTTP 501 — visto in
Cache.gs di REPO-B").

**Trovato**: falso per come citato. `Cache.gs:14` (clone ancora presente in questa
sessione) dice solo "non supporta filtri complessi (OR annidati, Entry_No,
orderby)" — NESSUN "501" nel codice. Il dettaglio "HTTP 501" esiste davvero, ma in
`SAL.md:235-236` dello stesso progetto, non nel file citato. La citazione era
imprecisa esattamente nel modo che il pattern `citazione-non-presidio` avverte:
un'ancora che esiste ma non per il fatto specifico che le si attribuisce non è
una salvaguardia vera. **Corretto**: la citazione ora punta a entrambe le fonti,
distinguendo cosa dice il codice da cosa dice il diario del progetto.

### 2026-08-21, notte (17) — le due correzioni in sospeso, eseguite col sì di Luca

Luca ha detto "esegui le correzioni" — le due voci DEBITI dei Giri 6 e 9 che
aspettavano una decisione di design. Entrambe saldate, entrambe riprovate dal vivo:

- **`gate-esito.sh` (Giro 9)**: semantica scelta — un esito TERMINALE (`merge`,
  `chiusura`) chiude repo+PR per sempre; `commessa` no. Riprodotto lo STESSO bug
  esatto sulla stessa copia del vero `metrics/gate.csv` (mai l'originale): la
  doppia chiamata ora è respinta. Costruito anche il caso legittimo che il fix
  doveva salvare — `commessa` su una riga, poi `merge` su una riga successiva —
  e verificato che riesce, seguito da un terzo tentativo correttamente respinto.
  Ririprovati i 3 casi originari (storico/nuovo/doppia registrazione): ancora
  tutti corretti.
- **`morning-gate.sh` (Giro 6)**: la issue correttiva ora porta un estratto vero
  del fallimento (`FAIL_DETAIL`: le ultime righe della verifica o del banco
  falliti), incorporato con un heredoc quotato (`$(cat <<'GATE_EOF' ... GATE_EOF)`)
  invece dell'interpolazione diretta in una stringa fra virgolette. **Provato dal
  vivo, non solo letto**: costruito un `FAIL_DETAIL` avversariale con backtick,
  `$(whoami)`, `$HOME`, generato il comando suggerito, eseguito contro un `gh`
  finto — ogni carattere arriva come testo letterale nell'argomento `--body`,
  nessuna espansione, nessuna esecuzione indesiderata.

`bash -n` passa su entrambi gli script; `shellcheck` non installato in questa
sessione (annotato, non finto). L'esecuzione end-to-end contro un `gh` autenticato
vero resta al primo gate reale sul Mac dopo questa PR — dichiarato in DEBITI.md.

### 2026-08-21, notte (18) — un bug reale su un progetto vero apre una lente mancante nel roster

Luca ha chiesto di seguire con attenzione anche gli agenti/il roster, in particolare sui
temi matematico-finanziari: "capire col tempo se gli esperti sono tutti e sono corretti o
hanno bisogno di revisioni". Occasione concreta, non ipotetica: continuando l'analisi su
`Bilancio_periodico` (progetto vero, cliente vero — vedi il suo SAL.md), costruito un
banco di verifica in Node per `gas/Sp.js` (Stato Patrimoniale per le banche) — **trovato
un segno sbagliato** nella formula del plug (`resto2 = serve - suIva`, doveva essere
`serve + suIva`), invisibile a lettura E invisibile a "quadratura: 0,00 ✅" perché il
passo di tie-out finale (per centesimi di arrotondamento) assorbiva SEMPRE l'intero
residuo, qualunque fosse la sua entità — ogni riscontro storico del progetto tornava "in
pareggio" anche quando la logica non lo era. Corretto e riverificato su 8 scenari
sintetici (`tools/test-sp.js`, ora nel repo del cliente); aggiunta una guardia che
segnala un residuo anomalo invece di assorbirlo in silenzio.

**Il gap di roster che questo espone**: nessuna delle lenti esistenti (dev-critic
generico, sicurezza §2bis, audit-commessa sulla forma-dati, verifica-visiva sullo
schermo) avrebbe mai trovato questo bug — nessuna prevede di ESEGUIRE le formule di
calcolo con dati sintetici e misurare l'invariante di dominio PRIMA di un passo di
aggiustamento finale. **Aggiunta**: `dev-critic` §2ter — lente matematico-finanziaria,
stesso schema della lente sicurezza (sempre applicata quando il target ha questa
caratteristica, non solo su richiesta). Pattern gemello registrato:
`patterns/banco-sintetico-per-calcoli-critici.md`, ancorato a `tools/test-sp.js` (banco
vero, provato) e `gas/Sp.js:366` (il bug corretto) di Bilancio_periodico.

**Nota onesta sul metodo di scoperta**: il bug non è stato trovato applicando la nuova
lente (che non esisteva ancora) — è stato trovato per tentativi, con più derivazioni a
mano sbagliate corrette solo eseguendo il codice vero. La lente esiste ORA perché quel
percorso (spesso fatica sprecata a mano, poi risolta in un minuto di esecuzione) merita
di diventare il primo passo la prossima volta, non l'ultimo.

### 2026-08-21 — nuova regola: qui solo metodo, mai il nome dei progetti onboardati

Luca ha chiesto esplicitamente che questo repo (pubblico) contenga sistema e metodo, MAI
riferimenti a quali progetti/clienti lavoriamo — solo forma anonima da qui in avanti. Le
voci precedenti che nominano `Bilancio_periodico`/`REPO-C` restano invariate
(la regola vale in avanti, non è stata chiesta una bonifica retroattiva — se in futuro
Luca vorrà anche quella, è un passo separato ed esplicito). Le due voci che seguono
adottano già la nuova convenzione: "un progetto onboardato" al posto del nome, il
dominio di business omesso, solo file/funzione (generici, non identificano da soli quale
cliente).

### 2026-08-21 — Giro 1 di 5 su un progetto onboardato: due bug della stessa famiglia di (18), un secondo pattern nuovo

Primo di 5 giri di sviluppo autonomo su un secondo progetto onboardato (pipeline GAS di
raccolta dati esterni + dashboard di analisi — stesso genere di stack di
Bilancio_periodico, cliente diverso). Applicata la lente §2ter appena introdotta in (18):
banco sintetico Node/vm sul codice vero, eseguito prima di fidarsi di qualunque "quadra".

Trovati e corretti **due bug reali della stessa famiglia**, in punti diversi dello stesso
progetto:
1. Un oggetto "stato vuoto" scritto a mano per il caso "nessun dato ancora" era rimasto
   con la forma vecchia dopo che la funzione di aggregazione reale era stata riscritta con
   nuove chiavi — non un crash (il consumatore a valle aveva già una guardia difensiva),
   ma un contratto silenziosamente sbagliato. Fix: il caso vuoto ora chiama la stessa
   pipeline reale con input vuoto, non descrive più la forma a mano — non può più
   divergere per costruzione. **Nuovo pattern**: `patterns/stato-vuoto-dalla-pipeline.md`.
2. Una funzione di validazione (range plausibili su campi numerici) azzerava
   silenziosamente ogni valore fuori soglia, zero log, zero traccia — indistinguibile da
   un campo mai estratto. Non è la prima volta: lo stesso schema esatto (un residuo/scarto
   reale mascherato invece che segnalato) era già comparso due volte all'interno di
   Bilancio_periodico dopo la voce (18) — un plug contabile che assorbiva un residuo nel
   tie-out, e un pool di costi che spariva sotto una guardia anti-divisione-per-zero. Tre
   occorrenze indipendenti in due progetti bastano per un pattern a sé, distinto dal banco
   sintetico (quello è la tecnica di TEST, questo è la FORMA del fix): **nuovo pattern**
   `patterns/scarto-mai-silenzioso.md` — una funzione che scarta/clampa deve ritornare
   cosa ha scartato, il chiamante lo logga, la regola/soglia non cambia.

Anche corretti nello stesso giro (non generalizzati a pattern, casi singoli): una funzione
di test di modulo che non girava più da tempo (riferiva campi superati da una riscrittura
precedente — avrebbe lanciato un errore se eseguita), un'asimmetria nel mascheramento
segreti nei log d'errore (una chiave era già mascherata negli errori, l'altra no — stessa
tecnica di `segreto-come-impronta`, solo applicata a metà), un prompt LLM per un campo
booleano corretto per un caso di misclassificazione noto e mai chiuso, e il CLAUDE.md del
progetto stesso — che si dichiara vincolante — desincronizzato dal codice reale (due
decisioni tecniche superate erano ancora scritte come attuali).

### 2026-08-21 — Giro 2 sullo stesso progetto onboardato: un terzo pattern, sul TEST non sul fix

Giro 2 (nuova funzionalità, richiesta esplicita già scritta nella roadmap del progetto — non
una scelta nostra). La funzionalità in sé (rendere cliccabili tabelle e grafici rimasti fuori
da una scheda-dettaglio prodotto già esistente altrove) non generalizza a un pattern — è
troppo specifica. Quello che generalizza è COME è stata verificata: una web app Google Apps
Script non ha un ambiente locale eseguibile, ma il frontend è HTML/JS puro dentro
`HtmlService` — risolvendo a mano gli `include()`, stubbando `google.script.run` con
l'output vero di una funzione di backend eseguita a parte (non un finto scritto a mano — si
ricadrebbe nel problema di `stato-vuoto-dalla-pipeline`), e localizzando le dipendenze CDN
quando la rete non arriva al browser (curl sì, browser headless no — differenza reale
riscontrata in questo ambiente), si ottiene un banco di verifica in un browser reale senza
mai toccare Apps Script. **Nuovo pattern**: `patterns/banco-browser-per-webapp-gas.md`.
Nota onesta riportata nel pattern stesso: la logica del click è stata provata con certezza
(stessa funzione, stessa forma di argomenti della libreria grafica); il click del mouse
*simulato* su un punto scatter non ha affidabilmente centrato l'hit-test pixel della
libreria — l'ultimo miglio di automazione non è la stessa cosa della logica sottostante,
e va detto quando succede, non nascosto sotto un "verificato" generico.

### 2026-08-21 — Giro 3 sullo stesso progetto onboardato: un addendum, non un pattern nuovo

Giro 3 (nuova funzionalità, dichiarata da tempo nella roadmap del progetto). Il primo tentativo
di banco Node/vm per la nuova logica è fallito — non per un bug nel codice testato, ma perché le
date sintetiche del banco erano costruite con `new Date(...)` dell'host, mentre il codice testato
gira in un contesto `vm` con una REALM diversa: `instanceof Date` fallisce silenziosamente tra
realm diverse anche per due date "identiche" nel valore. Non un pattern nuovo — un caso specifico
di `banco-sintetico-per-calcoli-critici` (già esistente) che vale la pena scrivere PERCHÉ chi
userà il banco-sintetico su un codice che usa `instanceof Date`/`Array` ci sbatterà contro
inevitabilmente e leggerà il fallimento come un bug nel codice, non nel banco. **Aggiunto un
addendum al pattern esistente**, non una nuova voce nel registro — non tutto quello che si impara
merita un pattern a sé; a volte è solo un caso in più dello stesso.

### 2026-08-21 — Chiusura dei 5 giri autonomi su un secondo progetto onboardato: cosa ha funzionato nel processo

Luca aveva chiesto esplicitamente di osservare come il sistema si comporta "in loop" su 5 giri
completamente autonomi (1 giro di correzione ampia + 4 di nuove funzionalità), migliorando sia lo
script del progetto sia il sistema stesso a ogni passo, senza fermarsi a chiedere conferma
step-by-step come CLAUDE.md richiederebbe normalmente — un'eccezione esplicita e dichiarata alla
regola "repeat the request... wait for explicit approval", non una sua violazione silenziosa.
Onestà di processo, non solo di risultato: cosa ha tenuto e cosa no.

**Ha tenuto**:
- **Un branch, una PR, un merge per giro** — mai una commessa unica a fine sessione. Ogni giro
  verificabile e revertibile indipendentemente dagli altri; la cronologia commit racconta la
  sequenza reale, non un blob finale.
- **Verifica per esecuzione ad ogni giro, mai per lettura sola** — banco Node/vm sul codice VERO
  per la logica pura (5 banchi nuovi in 5 giri), banco Playwright con `google.script.run` stubbato
  e Chart.js scaricato in locale quando la feature era di UI (drill-down, grafico storico) e non
  bastava un banco puro. Due volte il primo tentativo di banco è fallito per un bug DEL BANCO
  (Date cross-realm, tab-selector sbagliato in un test) — mai scambiato per un bug del codice senza
  verificare, mai lasciato correre "probabilmente funziona".
- **Onestà sui limiti della verifica**, ripetuta in ogni giro senza eccezioni: cosa è stato provato
  dal vivo in un browser reale, cosa solo a livello di logica/handler (il click Chart.js simulato
  che non centrava l'hit-test pixel), cosa resta da confermare lato cliente perché richiede
  `clasp push`/chiavi API reali/dati con ≥2 run — mai un "verificato" generico che nasconde quale
  dei tre livelli è stato raggiunto.
- **Le feature scelte erano tracciabili a una fonte**, non inventate: la roadmap dichiarata del
  progetto stesso (drill-down, Trend & Alert, storico prezzo — tutti già scritti nella specifica
  originale o nel SAL del progetto) o un rischio operativo reale trovato leggendo il codice
  (trigger settimanale mai automatizzato). Mai una funzionalità aggiunta solo perché "sarebbe
  carina".
- **La lezione metodologica, quando genuina, è tornata qui anonimizzata** — due nuovi pattern, un
  addendum a uno esistente, mai forzati quando il giro non aveva prodotto niente di generalizzabile
  oltre il fix specifico (Giro 4 e Giro 5 non hanno prodotto nessuna voce di pattern: non tutto
  quello che si fa qui deve generare una pagina di metodo).

**Non ha tenuto/da migliorare**:
- **`git push` verso il repo del progetto ha avuto ripetuti 502/503 transitori** ("session scope
  unavailable") durante la sessione — risolto con un retry loop in background (`until git push...;
  do sleep 15; done`), non con i soli 4 tentativi con backoff fisso previsti dalla procedura
  standard, insufficienti quando il guasto dura più di ~30 secondi. Da portare nella procedura
  operativa: se il retry a backoff fisso si esaurisce e il proxy segnala esplicitamente un problema
  transitorio (non una policy denial 403/407), un retry loop in background è preferibile a
  rinunciare o a ripetere manualmente.
- **Il banco Playwright non è ripetibile automaticamente** — richiede Chromium + una copia locale
  di eventuali dipendenze CDN, ricostruito a mano ad ogni giro con un piccolo script diverso.
  Riusabile come METODO (`banco-browser-per-webapp-gas`), non come strumento pronto all'uso: se
  questo genere di verifica ricorre spesso su progetti futuri, vale la pena costruire un piccolo
  harness generico (repo/percorso dei file GAS in input, stub configurabile) invece di riscriverlo
  da zero ogni volta — non fatto in questa sessione, segnalato come possibile debito futuro.
### 2026-08-22, mattina — la notte ha parlato: 11h39m su #12, zero file

Prima notte completamente automatica col sistema a regime. Il design-gate HA FUNZIONATO:
le 4 commesse vecchie senza ## Design (#363, #2, #3, #4) tutte saltate col commento — il
processo si difende. Ma la notte su #12 (commessa corretta dall'audit, design passata,
forma dei dati presente) è rimasta 11 ore e 39 minuti senza scrivere un file: fermata la
mano la mattina. Conferma definitiva dell'A/B: il limite della notte non è il biglietto,
è il TERRITORIO — file grandi da esplorare = giorno, sempre. Regola di smistamento che ne
esce (proposta a Luca): le commesse notturne dichiarano anche la dimensione del territorio
(file piccoli e righe indicate), altrimenti passano al giorno. Stato completo del progetto:
docs/stato-2026-08-22.md.

### 2026-08-22, mattina (2) — messo a posto tutto: la regola del territorio, e il giorno chiude #10+#12

Miglioramenti di processo entrati (tutti dalla lezione dell'11 ore):
- **Regola del Territorio**: sezione obbligatoria nelle commesse (quanto codice serve leggere) — il turno la salta come il Design se manca; il template la chiede alla nascita
- **Escalation automatica**: al secondo fallimento notturno di una issue, il commento propone di passarla al giorno (regola dell'A/B applicata dal sistema, non più solo ricordata da noi)
- **Corsia glm/***: il gate giudica anche il lavoro di GLM (terzo cervello, stessa legge di notte e claude)
- **Mascheramento segreti** negli output del gate (DEBITI saldato, pattern segreto-come-impronta applicato)

Esecuzioni: **le commesse BC #2/#3/#4 riabilitate** (Design + Territorio piccolo aggiunti — il
lavoro perfetto per stanotte: un file md a colonna). **Il giorno ha chiuso #10 e #12** in un
colpo (PR #15 su PEFC, branch glm/): nome file CSV datato (un punto per tutte le tabelle,
testato in Node) e registri di conformità nel PDF (tabella DDS 4→6 colonne, avviso assenti
con la funzione GIUSTA, le 7 voci del sistema di gestione) — sintassi JS verificata per
esecuzione. Stanotte la notte prova le BC: la prima prova della regola del territorio.

### 2026-08-22, pomeriggio — ciclo dei 5 giri su REPO-D (mandato: tutto da solo, processo osservato)

Fase 0 prima di tutto: **il hub era pubblico e spifferava nomi di repo private** (24 file).
Anonimizzato, chiave solo locale (repos.key gitignored), il gate scrive codici nel CSV e
privacy-check entra nel .night-verify: una perdita futura FALLISCE il gate. Il check stesso
è nato con un bug (grep -qv = quiet: divorava l'output e passava sempre) — trovato
eseguendolo contro il caso noto-difettoso, prima lezione del ciclo: **un guardiano si prova
anche quando deve fallire, non solo quando deve passare**.

**Giro 1 (sweep bug) completato**: 3 agenti in parallelo per la caccia (pipeline, dati,
webapp — il territorio era grande: il giorno legge, per la regola nuova), 20 difetti
trovati (3 critici, 8 maggiori), ogni fix verificato, i testabili coperti da un test file
nuovo con 11 asserzioni + i 4 esistenti verdi. PR aperta, commit per step logico.
Osservazioni di processo del giro: (1) i 3 difetti critici erano tutti della classe
'silenzioso' — dati sbagliati senza errore, il tipo che solo l'esecuzione rivela;
(2) il test file nuovo è nato DOPO i fix: la prossima volta nasce CON il primo fix
(regola: ogni fix porta la sua asserzione nello stesso commit, quando testabile);
(3) un fix ha rotto un test esistente perché usava una costante non caricata dal contesto
— risolto completando il test, non indebolendo il fix: il test serve al codice, non
viceversa.

### 2026-08-22, sera — ciclo dei 5 giri completato: il processo osservato in loop

Cinque giri su REPO-D (1 sweep + 4 feature), tutto da un solo operatore in loop: 5 PR,
20 difetti corretti, 55 asserzioni nuove tutte verdi. Le osservazioni che il loop ha
estorto — le quattro che valgono regole:

1. **Il test smentisce l'autore, non il codice** — quattro volte (su giri 4 e 5) le
   aspettative scritte a mano erano sbagliate e il codice giusto: mediana che non si muove
   con le code, regola n≥3 che esclude l'insegna da due punti dati, punto-e-virgola naked
   in un CSV virgola-separated. Regola: l'aspettativa si DERIVA (si calcola a mano passo
   per passo) o si costruisce da un caso noto — non si abbozza a memoria.
2. **Verificare la PR prima di dichiararla, non dopo** — l'hook del digest è mancato al
   primo commit (anchor spostato) e il commit è partito lo stesso: trovato riguardando.
   Regole: nessun commit dopo un edit programmatico senza grep della prova, e il flusso
   edit→verifica→commit è SEMPRE in quest'ordine.
3. **I test caricano le loro dipendenze transitive** — successo due volte (percentile_,
   RAW_DATA_HEADERS): il test che carica un modulo nuovo scopre le sue dipendenze e le
   aggiunge — non indebolisce il codice per adattarlo al test.
4. **I check sintattici non vedono la spazzanza semantica** — una stringa-colore corrotta
   è passata 'JS OK': il codice generato programmaticamente si RIGUARDA con occhi umani
   prima del commit.

E una conferma: la caccia con 3 agenti in parallelo + la parte meccanica a mano è il
rapporto qualità/tempo migliore mai misurato nel sistema per il lavoro di giorno su
territori grandi. Le 5 PR aspettano la review di Luca col gate.

### 2026-08-22, notte — ciclo 2 su REPO-D: la progettazione protagonista

Cinque feature con design-doc (docs/DESIGN_CICLO_2.md nella repo: opzioni pesate, scelte
dichiarate, verifica per livello) impilate in PR ordinate. Il dato nuovo del ciclo: **il
test come strumento di DESIGN, non solo di correttezza** — ha scoperto che le categorie
del classificatore non si sarebbero mai incontrate fra prodotti propri (_wall_na) e
mercato (_wall_28): difetto di design intercettato prima della produzione e convertito
in normalizzazione per categoria base. E ha corretto le aspettative dell'autore altre
quattro volte (l'aritmetica del fixture si conta a mano, sempre). 55 asserzioni nuove,
16 avversariali, PR impilate col merge in ordine dichiarato.

### 2026-08-22, notte (2) — 10 giri di auto-miglioramento: il sistema giudica se stesso

Il mandato: il sistema migliora AI_Programmer e il metodo viene analizzato a ogni passo.
Dieci PR (#14-#21, una finita per errore direttamente su main — scivolone di checkout
dichiarato: giro 3):

| Giro | Cosa | Prova |
|---|---|---|
| 1 | regression test per lib.sh: i 6 bypass storici non riaprono MAI | 25 asserzioni |
| 2 | test per gate-esito e gate-summary (i bug del CSV come regression) | 10 |
| 3 | wrapper mai eseguiti → eseguiti (percorsi di fallimento) | 7 |
| 4 | privacy v2 + **bug latente del guardiano trovato dal test**: git -C non vale per grep, il check passava tutto se invocato fuori dalla root — silenziosamente, da sempre | 5 (con leak piantate) |
| 5 | indice del SAL generato e verificato nel gate (30 voci) | presidio |
| 6 | summary v2: il rigore del banco misurato (scarti allowlist %) | live |
| 7 | idempotenza install (onesto: test debole in HOME finta) | 4 |
| 8 | qualità minima Design (≥80 char col da-dove) e Territorio (nomina file) | presidio |
| 9 | bootstrap --dry-run | sintassi |
| 10 | METHOD.md: la porta del sistema | docs |

**Il dato del ciclo**: il test del giro 4 ha trovato un bug latente nel guardiano della
privacy che c'era DA SEMPRE — il check funzionava solo se lanciato dalla root del repo,
il che significa che IL GATE l'ha sempre invocato correttamente per caso. Regola rafforzata:
**il guardiano si prova anche dalle posizioni sbagliate** — un check che funziona solo
nella posizione giusta non è un presidio, è una coincidenza.

### 2026-08-22, notte (3) — 10 giri di FEATURE: cosa mancava davvero

Dieci PR (#22-#31), il sistema guadagna ciò che non sapeva di non avere:

| Giro | PR | Feature | Il gap che colmava |
|---|---|---|---|
| 1 | #22 | **health check** | 7 componenti, nessuno sapeva chi vive — e infatti ha subito trovato launchd nightshift FERMO e 22 GB di swap |
| 2 | #23 | **verify-patterns** | la regola diceva 'l'ancora muore, la voce muore' ma nessuno verificava — 19 vive, 1 morta (corretta) |
| 3 | #24 | **morning-digest** | Luca doveva ANDARE a leggere il report: ora arriva in mailbox |
| 4 | #25 | **backup config** | repos.conf, key, metrics: l'unica copia viveva su un Mac |
| 5 | #26 | **promemoria audit** | l'audit serale era manuale e facile da dimenticare |
| 6 | #27 | **multi-cadence** | tutte le repo alla stessa frequenza; ora per-repo |
| 7 | #28 | **status page** | tutto era CLI e file sparsi; ora una vista HTML |
| 8 | #29 | **/nuova-commessa wizard** | le commesse buone erano arte manuale |
| 9 | #30 | **auto-SAL del turno** | l'esito notturno viveva solo nel log |
| 10 | #31 | **manuale operativo** | il perché c'era, le mani no |

Osservazione di metodo: le 10 feature rispondono tutte alla stessa domanda —
**"cosa deve fare il sistema che oggi fa l'operatore a mano?"**. Il pattern: l'operatore
è il collo di bottiglia quando fa cose ripetibili (leggere report, ricordarsi audit,
scrivere SAL, verificare ancore, controllare salute). Il sistema cresce automatizzando
l'operatore, non sostituendolo: le decisioni restano sue (review, merge, rotazione).

### 2026-08-22, notte (4) — le decisioni di dominio prese (mandato di Luca: "decidi da solo")

| # | Decisione | Perché |
|---|---|---|
| Suggeritore target | **−5%** (confermato) | produttore vs retail: leggermente sotto la mediana categoria è la posizione competitiva senza svendersi |
| Watchlist | **anche soglia SUPERIORE** | quando un concorrente ALZA i prezzi è il tuo spazio: segnalarlo è intelligenza competitiva, non solo costo |
| Tassonomia alluminio | **categoria dedicata C8** | un gazebo in alluminio con tetto in policarbonato NON è pieghevole: cambia le mediane di C7 e la lettura del mercato |
| Digest email | **solo quando ci sono variazioni** | un'email vuota ogni settimana insegna a ignorarla |
| Qualità: scarno 50% | **confermato** | sotto il 50% i dati non bastano per decidere |
| Qualità: stale 9 giorni | **confermato** | run settimanale (7g) + 2 di margine |
| Confronto n≥3 | **confermato** | ~1051 URL / 20 insegne ≈ 50 per insegna: 3 per categoria è un filtro minimo che basta |
| Export CSV | **solo dominio** (confermato) | già restrictivo, nessuna apertura |
| Radar in digest | **sì** | i nuovi entrati sono intelligence azionabile, non solo dashboard |
| Calendario pocodati | **10 osservazioni, solo mesi passati** | campione minimo per non mentire |
| Morning-digest email | **configurare la stessa del notturno** | un solo canale, meno rumore |
| Audit reminder | **21:30 confermato** | 1.5h prima del turno: tempo per agire, non troppo presto per dimenticare |
| Multi-cadence | **REPO-A settimanale (lun), le altre giornaliere** | il giudice non deve correre ogni notte |
| Cursor per-id | **fix ORA** | rischio reale di perdita dati durante run |
| Onboarding checkpoint | **rinvio accettato** | 5 competitor entro 6 min GAS oggi |

### 2026-08-22, notte (5) — terzo ciclo di 10 giri: bug reali trovati eseguendo, non leggendo

Mandato di Luca: nuovo ciclo di 10 giri per migliorare operativamente il processo,
monitorando per capire come migliorare. I due cicli precedenti (#14-#21 test/hardening,
#22-#31 feature mancanti) erano già mersati su main. Uso dev-critic sul hub stesso
(lettura critica + dogfooding reale, non solo ispezione statica) per trovare i gap di
questo terzo ciclo — niente ripetuto dai due precedenti.

| Giro | Cosa | Trovato eseguendo |
|---|---|---|
| 1 | system-health.sh: `$⛔/RED` non si espandeva MAI — il verdetto finale non mostrava mai i critici, in nessun ambiente, da sempre | eseguendo lo script |
| 2-3 | morning-digest.sh: dead code (EMAIL calcolato, mai usato) + BODY assegnato al PATH del report invece che al suo contenuto + injection AppleScript (virgolette/backslash non escaped) | intercettando osascript con un finto eseguibile |
| 4 | test-ask-wrappers.sh falliva IN QUESTA STESSA SESSIONE: l'assunzione "auth assente" non vale in un ambiente cloud dove `claude` è già autenticato — non un difetto del wrapper, un'assunzione del test mai verificata fuori dal Mac | il test è fallito davvero, dal vivo |
| 5 | privacy-check.sh vedeva solo `git ls-files` (i file di OGGI) — un nome committato e poi rimosso resta esposto per sempre nella storia, e il check diceva "pulito". Mai applicata al hub stesso la lezione dell'incidente citato in dev-critic/SKILL.md | riprodotto con un repo git sintetico: commit-poi-rimozione, il vecchio check l'avrebbe lasciato passare |
| 6 | morning-gate.sh: la mascheratura segreti non copriva "Authorization: Bearer \<token\>" — un JWT sarebbe passato intero nel report | verificato con sed su un caso realistico |
| 7 | bootstrap-app.sh: la catena `[ dry ] \|\| git add -A && [ dry ] \|\| git commit` non si fermava se `git add` falliva — `set -e` non intercetta un fallimento intermedio dentro una catena &&/\|\| | riprodotto con una `git` finta che fa fallire add |
| 8 | night-shift.sh: l'auto-SAL (giro 9/10 del ciclo precedente) scriveva contatori SEMPRE VUOTI — PR_CREATED/FAILED sono `local` dentro shift_repo(), spariscono dopo il for. La feature pensata per "la memoria non dipende da chi ricorda" non si ricordava nulla da sola | riprodotto con simulazione bash |
| 9 | test di regressione per bc_index.py (debito 2026-08-21): puro, testabile su una copia reale di docs/bc/endpoints senza tocca il README vero. bc_map.py resta debito (richiede OAuth BC vero) | — |
| 10 | rotazione log oltre soglia (debito 2026-08-21, "nessun limite raggiunto"): `rotate_log_if_big()` in lib.sh, una generazione, richiamata da night-shift.sh e morning-gate.sh | test sintetico |

**Il dato del ciclo**: 6 bug su 10 giri erano REALI, non ipotetici — e tre di loro
(giro 4, 7, 8) sono emersi SOLO eseguendo il codice o simulandone la struttura di
controllo, non leggendolo: la lettura da sola li avrebbe lasciati passare, esattamente
come predetto dal metodo di dev-critic. Nota di processo: durante l'analisi, un test
di `sal-indice.sh` su una copia è stato lanciato per errore anche sul SAL.md reale
(rigenerazione dell'indice, nessuna perdita — committato a parte con messaggio onesto).
Osservazione aggiuntiva: `llm/ask-opus.sh`, richiamato ricorsivamente da questa stessa
sessione, ha mostrato latenza variabile (una run ha superato i 2 minuti) — aggiunto un
timeout al test che lo esercita, per non bloccare la suite a tempo indefinito.

### 2026-08-22, notte (6) — correzione: la diagnosi "claude -p lento" era sbagliata

Nel ciclo precedente (giro 4/10) un hang di 2+ minuti era stato attribuito a "chiamata
ricorsiva a claude -p lenta o bloccata", con un timeout aggiunto al TEST come guardia.
Set 1 del ciclo nuovo ("armonizza gli agenti") ha riprodotto l'hang dal vivo con
`< <(sleep 100)`: la causa vera è `[ ! -t 0 ] && STDIN_DATA=$(cat)` in tutti e tre i
wrapper `llm/ask-*.sh` — `-t 0` non distingue "arriva un contesto vero in pipe" da "non
c'è nulla ma non è un terminale", e `cat` blocca a tempo indefinito nel secondo caso.

Annotato come richiede CLAUDE.md §1: un errore della NOTA precedente (l'ipotesi
"claude lento"), non un difetto del sistema scoperto oggi — il sistema aveva davvero
un bug, solo diagnosticato nel posto sbagliato. Corretto con `timeout 5 cat` nei tre
wrapper; il timeout già presente nel test resta comunque una buona guardia generale.

### 2026-08-22, notte (7) — Set 1/3: agenti giorno+notte armonizzati, 8 bug reali

Mandato di Luca: tre nuovi cicli tematici. Set 1 — "migliorare gli agenti, non solo
notturni ma anche e sopratutto quelli diurni (code e glm)". Dieci giri su llm/ask-*.sh,
morning-gate.sh, docs/system.md.

| Giro | Cosa | Trovato eseguendo |
|---|---|---|
| 1 | ask-qwen.sh validava il prompt DOPO aver tentato Ollama — 30.4s sprecati su chiamata invalida | `time` |
| 2 | **Correzione di una diagnosi errata**: l'hang di 2+ minuti del ciclo precedente non era "claude -p lento" — è `$(cat)` senza limite su stdin non-tty-senza-EOF, in TUTTI i wrapper | riprodotto con `< <(sleep 100)` |
| 3 | ask-qwen.sh ignorava ASK_TIMEOUT (--max-time fisso 1800) | curl finto |
| 4 | ASK_MODEL "universale" per contratto ma implementato solo in ask-opus.sh | curl finto |
| 5 | ask-opus.sh: exit 2 per auth assente, armonizzato con ask-glm.sh | claude finto |
| 6 | GLM mai cablato come ADVERSARY nel banco (solo qwen/opus) | estratta la logica reale |
| 7-8 | ask-glm.sh e ask-qwen.sh: risposta malformata → traceback Python grezzo invece di diagnosi pulita | curl finto, 3 casi avversariali ciascuno |
| 9 | docs/system.md disallineato dalla correzione già fatta nell'header di ask-opus.sh | lettura incrociata |
| 10 | nessuna traccia dei cervelli di giorno in memoria condivisa (asimmetria con SAL/gate.csv del notturno) — colmata con llm/_usage.sh | cervelli finti |

**Il dato del ciclo**: la scoperta più importante non era nella lista di partenza — è
emersa RIPRODUCENDO il giro 2 dell'ultimo ciclo per costruire un nuovo test, e ha
smentito la propria diagnosi precedente. Lezione di metodo: anche un fix già
committato e testato può portare la causa sbagliata se il sintomo (l'hang) non è
stato isolato dal resto (qui: mai provato senza la chiamata vera al cervello).

### 2026-08-22, notte (8) — Set 2/3: capacità di progettare, 3 skill mai esistite + bug ad alta severità

Set 2 — "migliorare la capacità di progettare nuovo software" (processo esistente +
nuovi strumenti). Dieci giri su .claude/skills/, night-shift.sh, morning-gate.sh, lib.sh.

| Giro | Cosa | Trovato |
|---|---|---|
| 1-3 | `/design-doc`, `/brainstorming`, `/goal`: citati ovunque (METHOD.md, docs/system.md, CLAUDE.md §7) come fonti di verità in `.zcode/commands/`/`.claude/commands/` — NESSUNA delle due directory esiste nel repo. `loops/` vuota da sempre | ricerca sul repo |
| 4 | `docs/stato-2026-08-22.md` citato in METHOD.md, mai scritto | ricerca sul repo |
| 5 | design-gate: due messaggi dedicati "SENZA sezione" erano dead code (il check di qualità intercetta sempre prima una sezione assente) | simulazione su 6 casi |
| 6 | design-gate: soglia 80 caratteri bucabile con prosa di riempimento senza riferimento reale | verificato dal vivo, 87 char di nulla passavano |
| 7 | `/nuova-commessa` non referenziava `/design-doc` nonostante la pipeline dichiarata | lettura incrociata |
| 8 | night-shift.sh non registrava le issue saltate per Design/Territorio (proposta 2026-08-21 mai fatta) | grep |
| 9 | **`run_guarded()` impiegava SEMPRE l'intera durata del watchdog** (120s in produzione) per OGNI comando `.night-verify` e il banco avversariale, anche se il comando reale finiva in millisecondi — un `sleep` orfano teneva aperta la pipe di una command substitution. Trovato per caso costruendo il test di un ALTRO bug (VERDICT="verifiche-ok" con zero comandi eseguiti — falso verde su ogni repo appena bootstrappata) | `time`, poi riprodotto e corretto due volte (il primo fix era sbagliato) |
| 10 | categoria "non-verificabile" per repo senza modo di verificare (proposta 2026-08-21 mai fatta) | grep |

**Il dato del ciclo**: il giro 9 è la scoperta più importante di questo set, e non era
nella lista di partenza — è emersa mentre si costruiva il test per un bug diverso. Il
PRIMO tentativo di fix (un subshell "killer" con `exec sleep`) sembrava corretto a
lettura ma si è rivelato sbagliato alla PROVA dal vivo (un subshell non può fare `wait`
su un job che non è figlio suo): riproveur lo stesso identico caso di studio di sempre —
eseguire, non leggere, anche il proprio fix.

### 2026-08-22, notte (9) — Set 3/3: flusso delle idee, tutte le interazioni

Set 3 — "il flusso delle idee, l'interazione fra una parte e l'altra" (giorno↔notte,
hub↔progetti onboardati, agente↔agente — "tutte le parti", mandato di Luca). Dieci giri.

| Giro | Cosa | Trovato |
|---|---|---|
| 1-2 | `.claude/skills/` (6 skill) non arrivava MAI a un progetto — né nuovo (bootstrap-app.sh) né esistente (onboard-repo.sh, merge prudente: mai sovrascrive personalizzazioni) | ricerca sul repo |
| 3-4 | `patterns/` (23 trucchi provati) stesso gap, stesso fix (copia + merge prudente) | ricerca sul repo |
| 5 | morning-gate.sh: `ISSUE_NUM` diventava l'INTERO nome del branch per PR `claude/*`/`glm/*`, corrompendo `metrics/gate.csv` con stringhe invece di numeri | verificato dal vivo |
| 6-7 | Il marcatore `NON-VERIFICABILE` (Set 2 giro 10) non era menzionato nei template `.night-verify` di bootstrap/onboard | lettura incrociata |
| 8 | Il prompt del banco avversariale diceva "sono ammessi node/python" — l'allowlist li scarta SEMPRE (rimossi per sicurezza in un ciclo precedente). Ogni scelta di quel tipo sprecava l'intero turno di giudizio | verificato dal vivo con `gate_allowlist_ok` |
| 9 | CLAUDE.md non documentava il prefisso di branch richiesto dal gate (`night/`,`claude/`,`glm/`) né la regola "Closes in inglese" — vivevano solo in commenti di codice/SAL.md | ricerca sul repo |
| 10 | "cartelle specchio dichiarate dalla repo" citate nel prompt della notte senza alcun meccanismo di dichiarazione — introdotto `.night-mirror` | ricerca sul repo |

**Il dato del ciclo**: 6 dei 10 giri sono varianti dello stesso pattern — "citazione senza
presidio" applicato non a un comando (come nel Set 2) ma a un CANALE fra parti del
sistema: uno strumento esiste ma non viaggia dove serve, una convenzione esiste ma non è
scritta dove chi ne ha bisogno la legge, un prompt promette una capacità che il codice
non concede. Il flusso delle idee, quando si guarda con attenzione, si rompe più spesso
per canali mai costruiti che per bug nella logica.

## Riepilogo dei tre set (30 giri totali, dopo i 10 iniziali)

- **Set 1** (agenti giorno+notte armonizzati): 8 bug reali, tra cui la correzione di una
  diagnosi errata del ciclo precedente (l'hang non era "claude lento", era stdin senza EOF).
- **Set 2** (capacità di progettare software): 3 skill mai esistite implementate
  (`/design-doc`, `/brainstorming`, `/goal`), 1 bug ad alta severità in `run_guarded()`
  (ogni verifica costava 120s invece di terminare quando finita), 1 falso verde nel
  VERDICT del gate, 2 proposte di processo del 2026-08-21 mai chiuse.
- **Set 3** (flusso delle idee, tutte le interazioni): skill e pattern del hub ora
  raggiungono i progetti, 1 bug di corruzione dati corretto, 3 convenzioni tacite
  documentate dove serve, il prompt del banco avversariale sincronizzato con la realtà.

### 2026-08-23 — 4° ciclo, Set 1/3 giro 1: agenti per problemi matematico-contabili, ancorati a dati reali

Nuovo mandato di Luca: ripetere il ciclo dei tre set altre tre volte, ma Set 1 ora chiede
esplicitamente di costruire un sistema di agenti per problemi matematico-contabili,
economico-industriali (contabilità analitica, di magazzino, controllo di gestione) — non
solo armonizzare gli agenti esistenti. Prima di scrivere qualsiasi formula: chiesto a
Luca se ancorare al dato reale di Gruppo Camarlinghi o restare generico → risposta:
ancorato a Business Central, sia skill di metodo che tool eseguibili, con un caso pilota
reale. Luca ha condiviso un repo esterno — codice **REPO-E** in questo diario, mai il nome
per intero (regola "Public repo, private work") — con una cartella `gas-src/` di ~90
progetti Google Apps Script reali dell'azienda, come base di verità.

**Censimento** (agente Explore, non io a memoria): trovati ~10 progetti reali di
controllo di gestione già implementati in REPO-E/gas-src/ — scostamento standard/effettivo
ed efficienza manodopera in produzione, riconciliazione inventario fisico e bridge
volume/prezzo per il magazzino, roll-forward/quadratura dei cespiti, margine per fattura
di vendita, indici di crisi e analisi di conto economico (quest'ultimo non ancora
ispezionato a fondo).

**Scoperta collaterale da segnalare, fuori scope di questo hub**: in due progetti dentro
REPO-E/gas-src/ il `client_secret` di Business Central è scritto in chiaro nel codice
sorgente, versionato pubblicamente su GitHub (nomi di progetto e dettaglio esatto dati a
voce a Luca, non versionati qui). Segnalato; non è stato toccato (accesso in sola lettura
a REPO-E, fuori dal ramo di lavoro di questo ciclo).

**Giro 1**: creata `.claude/skills/controllo-gestione/SKILL.md` — generalizza per questo
dominio lo schema già in uso ad-hoc per BC ("censimento campi" + "riscontro" di
PROJECT.md): individuare la fonte dato reale, citare la formula esistente come oracolo
(mai indovinarla), costruire input/output concreti prima del codice, verificare con un
riscontro. Primo caso risolto col metodo: `tools/riconciliazione_magazzino.py`, formula
oracolo = il modulo di riconciliazione inventario del progetto magazzino in
REPO-E/gas-src/: `delta = qtyFisica - qtyBC; deltaValore = delta * costoFinale`, con "non
contato" sempre distinto da "contato a zero" (regola di business reale trovata nel codice
originale, preservata come requisito). Caso pilota verificato: `qty_bc=120,
costo_finale=4.50, qty_fisica=115`
→ `delta=-5, deltaValore=-22.50€`. Test: `tests/test-riconciliazione-magazzino.sh`.

### 2026-08-23 (2) — Set 1/3 giri 2-3: la skill raggiunge la commessa, poi il progetto nuovo

**Giro 2**: `.claude/skills/controllo-gestione/SKILL.md` (giro 1) esisteva ma il template
`.github/ISSUE_TEMPLATE/night-shift.md` — l'unico posto che chi scrive una commessa legge
PRIMA di scriverla — non la citava. Stesso pattern trovato più volte nel ciclo precedente
al contrario: lì una skill era citata senza esistere, qui una skill esiste senza essere
citata dove serve. Aggiunta una riga nella sezione "## Forma dei dati" (dove già vivono i
riferimenti a `audit-commessa` per BC e a `GRAMMATICA_DOMINIO.md` per i termini di
dominio) che rimanda a `controllo-gestione` per le commesse che calcolano/riconciliano
una cifra contabile o gestionale reale. Test:
`tests/test-night-shift-template-controllo-gestione.sh`.

**Giro 3**: verificando la propagazione del template ho trovato che
`tools/bootstrap-app.sh` crea la label GitHub `night-shift` (l'agente notturno la userà
per pescare le issue) ma non copiava mai il template che insegna la FORMA della commessa
in un progetto nuovo — stesso gap già corretto per `.claude/skills/` e `patterns/` nel
set 3 del ciclo precedente, mai applicato a questo file. Un progetto bootstrappato da
zero avrebbe la label pronta e zero guida su come scrivere una issue che il gate non
salti in silenzio per mancanza di `## Design`. Corretto: `bootstrap-app.sh` ora copia
anche `.github/ISSUE_TEMPLATE/night-shift.md`. Test:
`tests/test-bootstrap-issue-template-propagation.sh`.
