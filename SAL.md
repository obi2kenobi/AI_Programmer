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
