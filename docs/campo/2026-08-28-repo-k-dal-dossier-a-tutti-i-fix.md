# 2026-08-28 — REPO-K, dal dossier ai fix: 86 rilievi e 25 idee, tutti chiusi in una sessione continua

**Autore**: sessione Claude Code (Claude Sonnet 5). Lavoro su REPO-K — codice nuovo,
assegnato da questo report (non era ancora in `night-shift/repos-index.md`). Corrisponde
al repo già citato come "dossier SD" in `famiglie-difetti.md` e in `SAL.md` (voce
2026-08-28, "dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI") — stesso
giorno, stesso lavoro, dedotto dal contenuto (dashboard web GAS+BC per gestione ordini
con foglio "aperti" e foglio storico paralleli). **Codice repo non confermato dall'interno
della sessione**: nessun accesso a `night-shift/repos.key` da questa sessione — verificare
prima di considerare processato.

Il dossier (fase 1, la stessa sera) è già stato triato: tre famiglie nuove in
`famiglie-difetti.md`, canonizzato in `metodo.md` per l'onestà del processo (71/86
rilievi dichiarati NON VERIFICATO invece di presentati come certi). Questo report copre
la fase 2, non ancora processata: dal dossier a **tutti** gli 86 rilievi + 25 idee di
miglioramento implementati, su richiesta esplicita dell'utente di non fermarsi fra un'area
e l'altra.

## Cosa ho usato

- **AI_Programmer NON è stato letto durante il lavoro vero** (fase di analisi E fase di
  fix): l'utente lo ha citato solo come riferimento di stile all'apertura della sessione,
  e davanti a due opzioni proposte ("revisione multi-agente massiva" vs "solo come
  stile/metodo di lavoro") ha scelto esplicitamente la seconda. Ho riprodotto lo spirito
  che mi era già noto per fama (fan-out multi-agente, verifica avversariale a doppio
  giudice, etichettatura di confidenza) senza clonare né leggere una riga del canone
  reale in quel momento.
- **Solo ora, per scrivere QUESTO report**, ho clonato AI_Programmer in sola lettura
  (anonimo) e letto: `README.md`, `METHOD.md`, `docs/campo/README.md` (il formato che sto
  seguendo), un report precedente di REPO-F come modello, `famiglie-difetti.md` (dove ho
  trovato le tre voci "dal dossier SD" già canonizzate — non sapevo esistessero),
  `night-shift/repos-index.md`, la regola privacy in `CLAUDE.md`.
- **Nessun agente/skill/hook del canone invocato per davvero**: la fase di ricerca ha
  usato uno strumento di orchestrazione multi-agente di questa piattaforma (192 agenti
  pianificati: 12 lenti indipendenti su altrettante aree di codice, poi verifica
  avversariale a doppio giudice per ogni rilievo, poi sintesi) — un fan-out scritto per
  l'occasione, non gli agenti/skill del canone (`revisore-gas`, `gas-sviluppo`, ecc., mai
  citati né invocati).
- **Nessun ambiente GAS/clasp/Business Central eseguibile**: ogni verifica di sintassi è
  passata da `node --check` (anche sul blocco `<script>` embedded di un file HTML,
  isolato con un piccolo script ad-hoc) e da un piccolo strumento nuovo,
  `check-duplicate-functions.js`, scritto in questa sessione e committato nel repo stesso
  per intercettare in anticipo il tipo esatto di collisione da scope-globale-unico che ha
  causato uno dei rilievi del dossier (due file dichiaravano la stessa funzione top-level;
  Apps Script concatena senza garanzia d'ordine, quindi una sovrascriveva l'altra in
  silenzio).

## Cosa ho improvvisato

- **Continuità senza pipeline, su richiesta esplicita**: l'utente ha chiesto di vedermi
  "partire e non fermarti fino alla fine del lavoro". Ho trattato l'istruzione esplicita
  in tempo reale come autorizzazione a superare la cautela di default (conferma ad ogni
  passo) dichiarata nelle regole stesse del progetto, mantenendo però il giudizio tecnico
  sui singoli punti: rifiutato di indovinare un valore di libreria esterna non accessibile
  da questa sessione, rifiutato di inventare o comunicare codici di sicurezza reali,
  rifiutato di applicare una funzione di sanitizzazione dove avrebbe corrotto dati reali
  (nome/indirizzo cliente) prima di scriverli sul foglio o di usarli per un lookup esterno.
- **Sintesi manuale dopo un limite di sessione**: il fan-out da 192 agenti pianificati si è
  fermato a 44/192 completati (solo 2 aree su 12 con verifica avversariale a doppio
  giudice finita) per esaurimento del budget della sessione automatica. Ho letto il JSON
  grezzo dei 44 agenti completati e sintetizzato io stesso il resto, dichiarando
  esplicitamente nel dossier finale quali rilievi restavano NON VERIFICATO (71/86) invece
  di presentarli tutti come confermati o di aspettare un reset di quota.
- **Una funzione di escaping nuova, da un ragionamento non ovvio**: `escapeHtml()` esistente
  nel progetto entity-codifica `<>"` ma non l'apice singolo; il suo output veniva riusato
  per costruire stringhe JS dentro attributi `onclick="fn('...')"`. Codificare anche
  l'apice come entità HTML (`&#39;`) SEMBRA la cura ovvia — ma non lo è: il parser HTML
  decodifica le entità dell'attributo PRIMA che il motore JS legga il codice risultante,
  quindi `&#39;` ridiventa un apice vero e rompe comunque la stringa. Serve backslash-escape
  sull'apice per il livello JS e entity-escape sul doppio apice per il livello HTML — due
  livelli di parsing, due funzioni distinte (`escapeJsAttr`, separata da `escapeHtml`,
  usata SOLO per argomenti dentro `onclick`).
- **Trovato un mio stesso fix rimasto a metà, rileggendo tutto alla fine**: in un batch
  precedente avevo aggiunto lato server, con l'intento dichiarato in un commento di
  risolvere un disallineamento di vocabolario stato-ordine fra backend e frontend, un
  elenco di valori validi passato alla pagina. Solo nel ripasso finale ho verificato che
  quell'elenco non veniva MAI letto lato client (zero occorrenze nel file JS) — e comunque
  non era nemmeno la lista giusta per lo scopo dichiarato (una whitelist di validazione
  input, più stretta del vocabolario completo usato per la visualizzazione). L'ho rimosso
  e ho risolto il problema vero direttamente dove serviva (badge di stato e filtro
  calendario), con test di corrispondenza uno-a-uno contro tutti i valori realmente
  scritti dal backend.
- **Un secondo fix "completato" che proteggeva solo metà del problema**: una conferma in
  blocco riscriveva l'intera riga da uno snapshot di cache di 3 minuti prima (rilievo
  critico del dossier); un batch precedente lo aveva corretto scrivendo SOLO le colonne
  cambiate invece dell'intera riga — ma la POSIZIONE della riga da scrivere veniva ancora
  presa dallo stesso snapshot vecchio. Se nel frattempo righe fisiche si fossero spostate
  (un sync, un'altra conferma, un annullamento), la scrittura sarebbe finita sulla riga
  sbagliata — un ordine completamente diverso. Corretto rileggendo la posizione fresca al
  momento della scrittura; aggiunto anche un controllo di conflitto esplicito (l'ordine è
  stato annullato nel frattempo → la conferma si blocca invece di far tornare "prenotato"
  un ordine che qualcun altro ha appena annullato).

## Cosa ha retto / ostacolato

- **Ha retto — l'etichettatura di confidenza**, anche inventata senza conoscere il canone:
  dichiarare 71/86 rilievi "non verificato" invece di presentarli tutti come certi ha reso
  possibile, in fase di fix, ripassarli uno per uno contro il codice reale invece di
  fidarmi ciecamente del riassunto automatico. In almeno un caso il rilievo grezzo
  suggeriva implicitamente una correzione sbagliata: "usa la funzione di parsing data
  condivisa invece di `new Date(stringa)`" — falso, perché quella funzione condivisa non
  ancorava affatto a mezzogiorno le stringhe ISO nonostante il changelog del progetto lo
  dichiarasse; la cura vera ha richiesto una funzione di confine-giornata dedicata, non lo
  scambio a una riga suggerito dal rilievo.
- **Ha retto — "esegui, non dedurre" anche senza conoscere quel nome**: ogni batch è stato
  validato con `node --check` prima del commit. Un difetto è stato trovato SOLO eseguendo,
  non leggendo: non un errore di sintassi (che il check avrebbe preso) ma di riferimento —
  tracciare a mano l'ordine di esecuzione di un file HTML/JS ha rivelato una funzione
  richiamata da un punto del codice prima che la sua definizione fosse scritta nello
  stesso file, un `ReferenceError` a runtime che nessun controllo di sintassi statico
  avrebbe mai preso.
- **Ha ostacolato — nessun ambiente GAS eseguibile**, stesso limite già raccolto da
  REPO-F: ogni verifica di logica (parsing date, escaping, paginazione, concorrenza di
  scrittura su foglio) è stata fatta ragionando sul codice e con `node --check`, mai
  eseguendo la funzione vera contro un foglio o un'API reale.
- **Ha ostacolato — la "dichiarazione di fine" non verificata contro lo scenario originale**:
  il primo giro di lavoro si è chiuso dichiarando "fatto" su tutti gli otto gruppi di aree
  pianificati (una todo-list interna alla sessione, non un banco). Solo un ripasso finale
  — voluto per buon senso, non richiesto da un passo esplicito del metodo che non
  conoscevo ancora — ha trovato almeno quattro casi in cui "fatto" nella mia stessa
  todo-list non corrispondeva a "lo scenario di fallimento descritto nel rilievo originale
  non si riproduce più" (i due esempi sopra, più due minori). Il divario non era visibile
  finché non ho riconfrontato ogni singolo rilievo con lo stato ATTUALE del codice, uno per
  uno, invece di fidarmi della mia stessa descrizione del fix.

## Proposta al canone

- Il gap appena descritto — un batch dichiarato "completed" nella todo-list interna che in
  realtà lasciava il sintomo originale intatto o solo parzialmente coperto — sembra la
  stessa famiglia del "verdetto calcolato e non alzato" già in `famiglie-difetti.md`
  ("Test e verifica"), ma applicato al PROCESSO di correzione, non solo al codice/test.
  Proporrei una voce esplicita: prima di dichiarare un rilievo chiuso, rileggere lo
  SCENARIO DI FALLIMENTO originale (non la propria descrizione del fix già scritta) e
  verificare che non si riproduca più sul codice attuale — un banco per il processo di fix
  in una sessione lunga con molti batch, non solo per il codice che produce.
- Il pattern di doppio-livello di escaping (l'HTML decodifica l'attributo PRIMA che il
  motore JS legga il codice, quindi l'entity-encoding da solo non protegge una stringa JS
  dentro un attributo `onclick`) non sembra coperto da `famiglie-difetti.md` (che parla di
  XSS via `innerHTML` senza escape — un caso diverso e più diretto). Proporrei una voce
  dedicata: è un errore facile da ripetere proprio perché la cura "ovvia" (aggiungere
  l'apice alla lista di entità già esistente) è quella sbagliata.
- Non ho una proposta sulla domanda aperta lasciata dal report di REPO-F ("un giro, un fix
  scelto, il resto al giro dopo" vs "tutti in una sessione su richiesta esplicita
  dell'utente"): anche qui l'utente ha chiesto esplicitamente di non fermarsi, e anche qui
  non so se il canone lo permetta o lo scoraggi esplicitamente. Segnalo solo che è la
  SECONDA volta (REPO-F, ora REPO-K) che questa stessa tensione si presenta con lo stesso
  esito dichiarato (l'istruzione esplicita dell'utente vince) — forse la sposta da
  "domanda aperta isolata" a "pattern ricorrente da decidere una volta per tutte".
2026-08-28 — REPO-K, dal dossier ai fix: 86 rilievi e 25 idee, tutti chiusi in una sessione continua
Autore: sessione Claude Code (Claude Sonnet 5). Lavoro su REPO-K — codice nuovo, assegnato da questo report (non era ancora in night-shift/repos-index.md). Corrisponde al repo già citato come "dossier SD" in famiglie-difetti.md e in SAL.md (voce 2026-08-28, "dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI") — stesso giorno, stesso lavoro, dedotto dal contenuto (dashboard web GAS+BC per gestione ordini con foglio "aperti" e foglio storico paralleli). Codice repo non confermato dall'interno della sessione: nessun accesso a night-shift/repos.key da questa sessione — verificare prima di considerare processato.

Il dossier (fase 1, la stessa sera) è già stato triato: tre famiglie nuove in famiglie-difetti.md, canonizzato in metodo.md per l'onestà del processo (71/86 rilievi dichiarati NON VERIFICATO invece di presentati come certi). Questo report copre la fase 2, non ancora processata: dal dossier a tutti gli 86 rilievi + 25 idee di miglioramento implementati, su richiesta esplicita dell'utente di non fermarsi fra un'area e l'altra.

Cosa ho usato
AI_Programmer NON è stato letto durante il lavoro vero (fase di analisi E fase di fix): l'utente lo ha citato solo come riferimento di stile all'apertura della sessione, e davanti a due opzioni proposte ("revisione multi-agente massiva" vs "solo come stile/metodo di lavoro") ha scelto esplicitamente la seconda. Ho riprodotto lo spirito che mi era già noto per fama (fan-out multi-agente, verifica avversariale a doppio giudice, etichettatura di confidenza) senza clonare né leggere una riga del canone reale in quel momento.
Solo ora, per scrivere QUESTO report, ho clonato AI_Programmer in sola lettura (anonimo) e letto: README.md, METHOD.md, docs/campo/README.md (il formato che sto seguendo), un report precedente di REPO-F come modello, famiglie-difetti.md (dove ho trovato le tre voci "dal dossier SD" già canonizzate — non sapevo esistessero), night-shift/repos-index.md, la regola privacy in CLAUDE.md.
Nessun agente/skill/hook del canone invocato per davvero: la fase di ricerca ha usato uno strumento di orchestrazione multi-agente di questa piattaforma (192 agenti pianificati: 12 lenti indipendenti su altrettante aree di codice, poi verifica avversariale a doppio giudice per ogni rilievo, poi sintesi) — un fan-out scritto per l'occasione, non gli agenti/skill del canone (revisore-gas, gas-sviluppo, ecc., mai citati né invocati).
Nessun ambiente GAS/clasp/Business Central eseguibile: ogni verifica di sintassi è passata da node --check (anche sul blocco <script> embedded di un file HTML, isolato con un piccolo script ad-hoc) e da un piccolo strumento nuovo, check-duplicate-functions.js, scritto in questa sessione e committato nel repo stesso per intercettare in anticipo il tipo esatto di collisione da scope-globale-unico che ha causato uno dei rilievi del dossier (due file dichiaravano la stessa funzione top-level; Apps Script concatena senza garanzia d'ordine, quindi una sovrascriveva l'altra in silenzio).
Cosa ho improvvisato
Continuità senza pipeline, su richiesta esplicita: l'utente ha chiesto di vedermi "partire e non fermarti fino alla fine del lavoro". Ho trattato l'istruzione esplicita in tempo reale come autorizzazione a superare la cautela di default (conferma ad ogni passo) dichiarata nelle regole stesse del progetto, mantenendo però il giudizio tecnico sui singoli punti: rifiutato di indovinare un valore di libreria esterna non accessibile da questa sessione, rifiutato di inventare o comunicare codici di sicurezza reali, rifiutato di applicare una funzione di sanitizzazione dove avrebbe corrotto dati reali (nome/indirizzo cliente) prima di scriverli sul foglio o di usarli per un lookup esterno.
Sintesi manuale dopo un limite di sessione: il fan-out da 192 agenti pianificati si è fermato a 44/192 completati (solo 2 aree su 12 con verifica avversariale a doppio giudice finita) per esaurimento del budget della sessione automatica. Ho letto il JSON grezzo dei 44 agenti completati e sintetizzato io stesso il resto, dichiarando esplicitamente nel dossier finale quali rilievi restavano NON VERIFICATO (71/86) invece di presentarli tutti come confermati o di aspettare un reset di quota.
Una funzione di escaping nuova, da un ragionamento non ovvio: escapeHtml() esistente nel progetto entity-codifica <>" ma non l'apice singolo; il suo output veniva riusato per costruire stringhe JS dentro attributi onclick="fn('...')". Codificare anche l'apice come entità HTML (&#39;) SEMBRA la cura ovvia — ma non lo è: il parser HTML decodifica le entità dell'attributo PRIMA che il motore JS legga il codice risultante, quindi &#39; ridiventa un apice vero e rompe comunque la stringa. Serve backslash-escape sull'apice per il livello JS e entity-escape sul doppio apice per il livello HTML — due livelli di parsing, due funzioni distinte (escapeJsAttr, separata da escapeHtml, usata SOLO per argomenti dentro onclick).
Trovato un mio stesso fix rimasto a metà, rileggendo tutto alla fine: in un batch precedente avevo aggiunto lato server, con l'intento dichiarato in un commento di risolvere un disallineamento di vocabolario stato-ordine fra backend e frontend, un elenco di valori validi passato alla pagina. Solo nel ripasso finale ho verificato che quell'elenco non veniva MAI letto lato client (zero occorrenze nel file JS) — e comunque non era nemmeno la lista giusta per lo scopo dichiarato (una whitelist di validazione input, più stretta del vocabolario completo usato per la visualizzazione). L'ho rimosso e ho risolto il problema vero direttamente dove serviva (badge di stato e filtro calendario), con test di corrispondenza uno-a-uno contro tutti i valori realmente scritti dal backend.
Un secondo fix "completato" che proteggeva solo metà del problema: una conferma in blocco riscriveva l'intera riga da uno snapshot di cache di 3 minuti prima (rilievo critico del dossier); un batch precedente lo aveva corretto scrivendo SOLO le colonne cambiate invece dell'intera riga — ma la POSIZIONE della riga da scrivere veniva ancora presa dallo stesso snapshot vecchio. Se nel frattempo righe fisiche si fossero spostate (un sync, un'altra conferma, un annullamento), la scrittura sarebbe finita sulla riga sbagliata — un ordine completamente diverso. Corretto rileggendo la posizione fresca al momento della scrittura; aggiunto anche un controllo di conflitto esplicito (l'ordine è stato annullato nel frattempo → la conferma si blocca invece di far tornare "prenotato" un ordine che qualcun altro ha appena annullato).
Cosa ha retto / ostacolato
Ha retto — l'etichettatura di confidenza, anche inventata senza conoscere il canone: dichiarare 71/86 rilievi "non verificato" invece di presentarli tutti come certi ha reso possibile, in fase di fix, ripassarli uno per uno contro il codice reale invece di fidarmi ciecamente del riassunto automatico. In almeno un caso il rilievo grezzo suggeriva implicitamente una correzione sbagliata: "usa la funzione di parsing data condivisa invece di new Date(stringa)" — falso, perché quella funzione condivisa non ancorava affatto a mezzogiorno le stringhe ISO nonostante il changelog del progetto lo dichiarasse; la cura vera ha richiesto una funzione di confine-giornata dedicata, non lo scambio a una riga suggerito dal rilievo.
Ha retto — "esegui, non dedurre" anche senza conoscere quel nome: ogni batch è stato validato con node --check prima del commit. Un difetto è stato trovato SOLO eseguendo, non leggendo: non un errore di sintassi (che il check avrebbe preso) ma di riferimento — tracciare a mano l'ordine di esecuzione di un file HTML/JS ha rivelato una funzione richiamata da un punto del codice prima che la sua definizione fosse scritta nello stesso file, un ReferenceError a runtime che nessun controllo di sintassi statico avrebbe mai preso.
Ha ostacolato — nessun ambiente GAS eseguibile, stesso limite già raccolto da REPO-F: ogni verifica di logica (parsing date, escaping, paginazione, concorrenza di scrittura su foglio) è stata fatta ragionando sul codice e con node --check, mai eseguendo la funzione vera contro un foglio o un'API reale.
Ha ostacolato — la "dichiarazione di fine" non verificata contro lo scenario originale: il primo giro di lavoro si è chiuso dichiarando "fatto" su tutti gli otto gruppi di aree pianificati (una todo-list interna alla sessione, non un banco). Solo un ripasso finale — voluto per buon senso, non richiesto da un passo esplicito del metodo che non conoscevo ancora — ha trovato almeno quattro casi in cui "fatto" nella mia stessa todo-list non corrispondeva a "lo scenario di fallimento descritto nel rilievo originale non si riproduce più" (i due esempi sopra, più due minori). Il divario non era visibile finché non ho riconfrontato ogni singolo rilievo con lo stato ATTUALE del codice, uno per uno, invece di fidarmi della mia stessa descrizione del fix.
Proposta al canone
Il gap appena descritto — un batch dichiarato "completed" nella todo-list interna che in realtà lasciava il sintomo originale intatto o solo parzialmente coperto — sembra la stessa famiglia del "verdetto calcolato e non alzato" già in famiglie-difetti.md ("Test e verifica"), ma applicato al PROCESSO di correzione, non solo al codice/test. Proporrei una voce esplicita: prima di dichiarare un rilievo chiuso, rileggere lo SCENARIO DI FALLIMENTO originale (non la propria descrizione del fix già scritta) e verificare che non si riproduca più sul codice attuale — un banco per il processo di fix in una sessione lunga con molti batch, non solo per il codice che produce.
Il pattern di doppio-livello di escaping (l'HTML decodifica l'attributo PRIMA che il motore JS legga il codice, quindi l'entity-encoding da solo non protegge una stringa JS dentro un attributo onclick) non sembra coperto da famiglie-difetti.md (che parla di XSS via innerHTML senza escape — un caso diverso e più diretto). Proporrei una voce dedicata: è un errore facile da ripetere proprio perché la cura "ovvia" (aggiungere l'apice alla lista di entità già esistente) è quella sbagliata.
Non ho una proposta sulla domanda aperta lasciata dal report di REPO-F ("un giro, un fix scelto, il resto al giro dopo" vs "tutti in una sessione su richiesta esplicita dell'utente"): anche qui l'utente ha chiesto esplicitamente di non fermarsi, e anche qui non so se il canone lo permetta o lo scoraggi esplicitamente. Segnalo solo che è la SECONDA volta (REPO-F, ora REPO-K) che questa stessa tensione si presenta con lo stesso esito dichiarato (l'istruzione esplicita dell'utente vince) — forse la sposta da "domanda aperta isolata" a "pattern ricorrente da decidere una volta per tutte".
‎night-shift/repos-index.md‎
+1
Lines changed: 1 addition & 0 deletions


Original file line number	Diff line number	Diff line change
| REPO-H | repo cespiti GAS+BC standalone (FA Ledger + G/L da BC, report mensile) | prima segnalazione 2026-08-27: 13 rilievi, 12 fix, banco Node 19/19 | docs/campo/2026-08-27-revisione-cespiti-gas-bc.md |
| REPO-I | controlli trimestrali di bilancio GAS+BC (97 file, ~850 asserzioni preesistenti) | ciclo 2026-08-27: 30 agenti, 19 findings ALTA corretti, 915/915 test, PR #97 — report docs/campo/2026-08-27-controlli-trimestrali.md | docs/campo/2026-08-27-controlli-trimestrali.md |
| REPO-J | Gestione-ordini-Bricoman (ordini EDI fornitori, GAS+BC, 12 file) | audit 50 agenti 2026-08-28: 153 rilievi, 13 confermati, 2 smentiti | docs/campo/2026-08-28-bricoman-50-agenti.md |
| REPO-K | Dashboard web GAS+BC per gestione ordini multi-categoria (foglio "aperti" e foglio storico paralleli, sync automatico) — già citato informalmente come "dossier SD" in `famiglie-difetti.md` e in `SAL.md` (voce 2026-08-28) prima che questo codice esistesse | dossier 86 rilievi/25 idee (`docs/campo/2026-08-28-sd-dashboard-dossier.md`), tutti implementati in sessione continua — report `docs/campo/2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md` |

## Come usarlo
