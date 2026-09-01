# 2026-09-01 — REPO-Q: audit di sola lettura su tutto il repo, 53 voci, 2 PR

**Autore**: sessione Claude Code (remota, PR review umana di Luca)

## Cosa ho usato

Il repo di lavoro (REPO-Q) **non è mai stato onboardato allo standard** (nessun
`sync-repo.sh --standard`, nessun hook, nessuna skill di questo hub sincronizzata
al suo interno). Ho letto il hub via clone di sola lettura all'inizio della
sessione (`METHOD.md`, `CLAUDE.md`, `docs/system.md`) per orientarmi, poi ho
applicato i principi **a mano**, senza gli hook/skill veri:

- 6 agenti paralleli di sola lettura per l'audit iniziale (uno per area del
  repo: 8 sotto-progetti Apps Script indipendenti), citando sempre file:riga —
  principio "esegui/verifica, non dedurre" applicato all'AUDIT, non solo alla
  correzione.
- Nessun agente "revisore"/verifica avversariale dedicato: ho fatto io stesso
  da verificatore ad ogni giro (`node --check` su ogni file toccato, riesecuzione
  di test reali in Node quando possibile senza le credenziali BC, confronto
  output byte-a-byte prima/dopo su una pipeline Python).
- Nessun oracolo tipo `tools/*.py` esisteva per le formule contabili di REPO-Q:
  ho usato **un secondo progetto gemello già corretto** (stessa logica, bug
  già risolto in un punto ma non nell'altro) come surrogato di oracolo quando
  disponibile, e ho dichiarato esplicitamente "non verificabile senza OAuth
  Business Central" quando non lo era (niente affermato "a memoria").

## Cosa ho improvvisato

- Il mandato era "200 giri di miglioramento su tutto il repo" — in tensione
  diretta con la regola CLAUDE.md del repo di lavoro "no additions, no
  spontaneous initiatives" e con "territorio dichiarato = piccolo" di questo
  metodo. Non c'è una skill che copra "l'utente chiede un numero enorme di
  cicli su un territorio enorme, dichiarato esplicitamente grande". Ho
  chiarito con l'utente prima di partire (repo di riferimento AI_Programmer
  citato da lui stesso), poi ho eseguito l'audit e dichiarato onestamente
  che i problemi REALI trovati erano 53, non 200 — rifiutando di gonfiare
  il numero con voci inventate (regola "Never invent requirements").
- Struttura Tier1-4 (BUG/RISCHIO/DEBITO/IDEA) per il backlog: non prevista
  da nessuna skill, improvvisata per dare un ordine di esecuzione sensato
  (bug prima, idee dopo) a 53 voci eterogenee.
- Decisione di **rimandare** 8 voci Tier3 e 5 voci Tier4 con motivazione
  scritta invece di eseguirle comunque: dedotta da "misura due volte, taglia
  una" applicato a un contesto senza possibilità di eseguire contro dati BC
  veri (refactor meccanici su funzioni centrali, o decisioni di dominio/
  prodotto non deducibili dal codice). Non è una regola scritta da nessuna
  parte in questo hub — l'ho trattata come applicazione diretta di "misura
  due volte" più "never invent business logic".
- A metà sessione la PR è stata mergiata e l'utente ha chiesto di proseguire
  con un sottoinsieme delle idee rimandate ("le 5 per gas-contabilita"): il
  numero non coincideva con l'elenco reale (solo 3 delle 5 rimandate
  toccavano quel progetto). Ho chiarito con AskUserQuestion invece di
  indovinare quali — e per la voce eseguita, ho fatto scegliere esplicitamente
  l'ambito (4 BU invece di 1) invece di assumerlo.

## Cosa ha retto / ostacolato

**Ha retto**:
- "Esegui, non dedurre" applicato all'audit stesso, non solo alla correzione:
  la scoperta più grave della sessione (uno scrub automatico di un secret
  leakato aveva corrotto anche un NOME DI FUNZIONE reale, sintassi non valida,
  file di produzione che non sarebbe girato) non era nell'audit iniziale dei
  6 agenti — è emersa solo perché durante l'esecuzione ho letto per intero un
  file invece di fidarmi del grep, e ho verificato con `git log -S` che la
  history stessa era stata riscritta dallo scrub (non recuperabile
  direttamente, ricostruita dal contesto del commit originale).
- Verifica reale anche senza esecuzione BC: rieseguire i test puri del banner
  in Node (2 riparati, verificato che passano davvero — non "dovrebbero
  passare"), ricalcolare l'intera pipeline Python di classificazione sul CSV
  reale (output byte-identico prima/dopo il fix), e — seguendo alla lettera
  "il guardiano si prova quando deve fallire" — troncare deliberatamente un
  CSV per confermare che il nuovo test di regressione fallisce davvero prima
  di fidarmi che passi sul dato vero.

**Ha ostacolato**:
- Nessun hook di questo hub era attivo nel repo di lavoro: ho dovuto portare
  "a mano" ogni principio, col rischio classico che l'hook Stop di questo hub
  esiste apposta per correggere ("invocato all'inizio e poi dimenticato").
  Prova diretta: questo stesso report esiste solo perché l'utente me l'ha
  chiesto esplicitamente a fine sessione — nessun promemoria strutturale me
  lo ha ricordato.
- Nessun banco/oracolo eseguibile per le formule contabili di REPO-Q: la
  verifica "confronta con un progetto gemello già corretto" ha funzionato
  quando un gemello esisteva (è successo più volte — la stessa classe di bug,
  già trovata e corretta in un progetto, non ancora riportata nell'altro), ma
  non è un oracolo generalizzabile: dipende dal caso, non da uno strumento.

## Proposta al canone

1. Un repo di lavoro **mai onboardato** (come REPO-Q) non riceve nessuno dei
   meccanismi strutturali di questo hub — l'intero metodo dipende dalla
   sessione che se lo ricorda da sola leggendo il hub una volta, a inizio
   sessione. Proposta: una sessione che scopre di lavorare su un repo non
   onboardato dovrebbe poterlo dichiarare esplicitamente **prima** di
   iniziare (come fa REPO-H con "NON RAGGIUNGIBILE"), non solo a fine
   sessione via report — il report arriva quando è già troppo tardi per
   correggere la sessione stessa.
2. "Territorio dichiarato" (regola 3, pensato per territorio PICCOLO) non ha
   una guida per quando l'utente chiede esplicitamente "tutto il repo" su un
   repo multi-progetto grande. Il pattern che ho trovato da solo — audit
   paralleli di sola lettura per area, poi esecuzione a livelli di priorità
   con motivazione scritta esplicita per ciò che si rimanda invece di
   eseguirlo a rischio — potrebbe valere come variante dichiarata del metodo
   per "territorio grande dichiarato esplicitamente dall'utente", distinta
   dalla commessa/notte già prevista (qui non c'era la possibilità di usare
   il turno notturno multi-repo: repo singolo, sessione interattiva).
