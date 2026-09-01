# Report per AI_Programmer
### Riscontri dall'applicazione del metodo — giro di correttezza (bug-hunt), non di prodotto (Controlli-trimestrali-Bilancio)

**Da:** sessione Claude Code, per conto di Luca (GRUPPO CAMARLINGHI S.P.A.)
**Oggetto:** un secondo tipo di giro sullo stesso progetto già coperto dal report del 27/08/2026 (`docs/campo/2026-08-27-controlli-trimestrali.md`) — quello era analisi+idee ("cosa manca"); questo è un giro di **correttezza** ("cosa è silenziosamente sbagliato"), 10 agenti paralleli, un bug alla volta, verificato con riproduzione eseguita e chiuso in pull request (`obi2kenobi/Controlli-trimestrali-Bilancio#102`, mergiata). Include anche quello che è emerso **dopo**, al primo deploy dal vivo e alla prima esecuzione reale dell'Auto-test (`#103`) — la parte che una sessione cloud non può mai chiudere da sola.

---

## 1. Contesto e mandato

La richiesta originale era "200 giri di risoluzione di problemi... con nuove idee, nuovi strumenti". Presa alla lettera avrebbe significato inventare funzionalità senza requisiti — in diretto conflitto con le regole del progetto (CLAUDE.md: "only what is asked", "ask, don't guess", "done means confirmed dal proprietario del progetto"). Prima di eseguire qualunque cosa si è:

1. Ricostruito cosa significhi "metodo AI_Programmer" per questo specifico progetto, leggendo sia la documentazione locale (SAL.md, PROJECT.md, i giri §34/§35/§37, il report del 27/08) sia l'hub (`METHOD.md`, `docs/ngiri-paralleli.md`, `patterns/`);
2. Sottoposto a Luca due domande esplicite (AskUserQuestion): che cosa intendesse per "200 giri" rispetto al metodo Supervisore già in uso, e su quale perimetro;
3. Tradotto il mandato in **un giro reale**, completo e verificabile, di correttezza — non 200 cicli letterali, non funzionalità inventate.

Il progetto era già passato per due giri precedenti dello stesso tipo di orchestrazione (30 agenti/bug + "Cinquanta Giri"/idee, entrambi documentati nell'hub). Questo giro applica lo stesso schema "N giri paralleli" una terza volta, con una variante: lenti di correttezza pure (nessuna lente di prodotto), su un progetto dove il precedente giro di prodotto aveva già esaurito il catalogo delle idee mancanti.

---

## 2. Struttura del giro

- **10 agenti indipendenti in parallelo**, uno per area (Conto Economico, Clienti, Fornitori, Mastrini Fornitori, Banche, Cespiti, Ferie, TFR, Crisi d'impresa, Cruscotto/trasversale) — non 15 aree × 2 letture come nel giro precedente: qui ogni area riceve UNA lettura, mirata, con più lenti di correttezza applicate in sequenza dallo stesso agente, non un secondo agente indipendente sulla stessa area.
- **Lenti**: `scarto-mai-silenzioso`, `oracolo-indipendente`, `confronto-non-vuoto`, `chiave-stabile-etichetta-libera`, `lock-per-risorsa`, `lettura-esecuzione-precedente`, `soglia-con-default-guardato`, `guardia-nel-ponte-non-nella-condivisa`, `riga-in-coda-non-interposta` — tutte già nel canone `patterns/`, nessuna nuova.
- **Contesto anti-duplicazione**: ogni agente riceveva il riassunto di PROJECT.md/SAL.md per la propria area, con l'istruzione esplicita di non riproporre nulla già catalogato nel giro di prodotto precedente ("Cinquanta Giri") né nelle sezioni "Escluso/Rinviato/Già coperto" già scritte.
- **Verifica obbligatoria per candidato**: file:riga, scenario concreto, ed esecuzione reale dove fattibile (script Node sullo stesso harness di `tests/run.js`, con gli stub GAS). I candidati scartati andavano riportati comunque, con il motivo — non solo quelli confermati.
- **Correzione**: un fix per commit, un test di regressione per fix, verificato **a fallire senza il fix** (via `git stash` del solo file di produzione) **e passare col fix**, prima del push.

---

## 3. Risultato in cifre

| Metrica | Valore |
|---|---|
| Agenti paralleli (discovery) | 10 |
| Bug candidati riportati (confermati + scartati) | ~60 (somma dei 10 report) |
| Bug confermati e corretti | 16 |
| Aree pulite (nessun bug trovato) | 1 (Crisi d'impresa) |
| Temi trasversali (stesso bug, ≥3 aree indipendenti) | 1 ("Open" letto come "oggi" invece che "alla data di riferimento", trovato in 4 aree) |
| Questioni non risolvibili in codice, delegate a Luca | 2 — entrambe chiuse nella stessa sessione |
| Test automatici | 1272 → 1307 (+35 asserzioni) |
| Commit | 18 (15 fix + 3 documentazione/decisioni) |
| File toccati | 21 |
| Regressioni introdotte | 0 (suite intera verde ad ogni commit) |
| Correzioni respinte in revisione | 0 |

Come nel report precedente sullo stesso progetto, il dato che conta di più non è il numero di bug: è che **tutti e 16** erano riproducibili con un test prima/dopo, non solo "letti e sembravano sbagliati" — e le **due** questioni che non erano risolvibili senza un dato/decisione esterna sono state dichiarate esplicitamente come tali invece di essere forzate, e poi effettivamente chiuse (una con una decisione di schema, una con una verifica sul sistema reale).

---

## 4. Cosa ha funzionato bene

### 4.1 Le lenti di correttezza, riapplicate a un progetto già "pulito" da un giro precedente, trovano comunque bug reali
Il progetto aveva già passato un giro di 30 agenti/bug (report del 27/08) e un giro di idee. Nessuno dei 16 bug di questo giro era stato segnalato prima — non perché il giro precedente fosse superficiale, ma perché le lenti usate stavolta (in particolare `chiave-stabile-etichetta-libera`, `lock-per-risorsa` su funzioni specifiche del cruscotto, e un caso non ancora nominato — vedi §5.1) intercettano famiglie di difetti diverse da quelle del giro di 30 agenti. Conferma indiretta di quanto già scritto nell'hub (`docs/ngiri-paralleli.md`, "Le due batterie di lenti... sono ORTOGONALI"): un progetto "pulito" rispetto a una batteria di lenti non lo è rispetto a un'altra.

### 4.2 La convergenza indipendente funziona anche per bug puri, non solo per gap di prodotto
Il tema trasversale del giro (`Open` letto come stato di oggi invece che "alla data di riferimento") è stato trovato **indipendentemente** da 4 agenti su 4 aree diverse (Circolarizzazione Clienti, Cartolarizzazione Fornitori, check08 Clienti Inattivi, check08 Fornitori Inattivi), senza che nessuno sapesse cosa avrebbero trovato gli altri. Il correttivo esisteva già, dal 28-29/07/2026, in un **quinto punto** (Mastrini Fornitori) — mai generalizzato agli altri quattro. Stesso segnale già documentato nel giro precedente (§3.2 del report del 27/08), qui riprodotto su una batteria di lenti diversa: la convergenza indipendente resta il segnale di qualità più forte del metodo, non un caso isolato di un solo tipo di giro.

### 4.3 Dichiarare "non risolvibile da qui" invece di forzare ha prodotto due chiusure pulite, non due bug nascosti
Due dei rilievi non erano bug di codice deducibili dalla sola lettura: uno richiedeva una decisione di design (schema del registro append-only), l'altro un dato esterno alla sessione (il piano dei conti reale in Business Central — questa sessione cloud non ha e non deve avere le credenziali BC, mai versionate nel repo per scelta di sicurezza). Entrambi sono stati presentati a Luca come piano ordinato per gravità, con opzioni esplicite e tradeoff — non silenziati, non forzati a una scelta arbitraria. Risultato: **entrambi chiusi** nella stessa sessione (uno con un cambio di schema — nuova colonna `Etichetta`, mai interposta — l'altro con una verifica diretta sul sistema reale che ha confermato che il codice era già corretto).

Questo è lo stesso principio del report precedente (§4.5, "manca uno stato esplicito per *da verificare dal vivo*"), ma qui si vede l'altro lato: quando lo stato viene dichiarato esplicitamente e presentato con un piano ordinato, il proprietario del progetto lo chiude rapidamente — l'attrito non era nel dichiarare l'incertezza, era nel non avere prima un posto ordinato dove metterla.

### 4.4 Un pattern esistente (`chiave-stabile-etichetta-libera`) si è generalizzato da riga a colonna
Il pattern era nato per identificatori usati come chiave in una riga di un log/registro/serie storica. Qui il caso reale era diverso di livello: non una riga da non rinominare, ma una **colonna intera** dello schema di un registro append-only, dove il testo umano (la descrizione di un controllo) era stato usato come parte della chiave fin dall'inizio. La soluzione — aggiungere una colonna separata, mai interporla (stesso principio di `riga-in-coda-non-interposta`, applicato qui a un campo di schema invece che a una riga di foglio) — mostra che i due pattern, scritti per casi diversi (righe vs colonne, dati vs schema), sono in realtà la stessa idea a due livelli di struttura.

---

## 5. Attriti e lacune osservate (feedback per il metodo/tooling)

### 5.1 Manca un terzo esito per un candidato di un giro di correttezza: non "confermato", non "falso positivo", ma "non verificabile da questa sessione"
Il giro di idee ha una tassonomia a quattro categorie già consolidata e provata su 245 casi (`docs/ngiri-paralleli.md`): Implementata / Esclusa / Rinviata / Già coperta. Il giro di bug-hunt, così come applicato qui e nel giro precedente, ha invece solo un esito binario per ogni candidato: **confermato** (si corregge) o **falso positivo** (si scarta, motivato). Il caso INTESA di questo giro non stava in nessuno dei due: non era né un bug dimostrato né uno smentito — era un candidato genuino che nessuna delle due prove disponibili alla sessione (lettura del codice, esecuzione dei test) poteva risolvere, perché la prova serviva sul sistema esterno reale (BC), fuori portata di una sessione cloud priva di credenziali per scelta di sicurezza del progetto.

**Proposta:** una terza categoria esplicita per i giri di bug-hunt — *da verificare sul sistema reale* — distinta sia da "confermato" sia da "falso positivo", con la stessa dignità di tracciamento che la tassonomia a quattro vie già dà alle idee. Non è la stessa cosa di "non eseguito per mancanza di tempo" (che gli agenti di questo giro già dichiaravano quando capitava): è "non eseguibile *da questa sessione*, per un vincolo di accesso strutturale e voluto", una distinzione che vale la pena nominare perché ricorrerà ogni volta che un progetto tiene le proprie credenziali fuori dal repository (come dovrebbe).

### 5.2 Il salto da un'istruzione numerica letterale ("200 giri") al metodo reale richiede un passo esplicito, non automatico
La richiesta originale usava una cifra ("200") che non corrisponde a nessuna unità del metodo — un "giro" non è un ciclo di i/o ripetibile N volte, è un'orchestrazione fan-out/sintesi che si esaurisce quando il catalogo (idee) o l'area (bug) è coperta. Nulla nel metodo, così come documentato, avverte esplicitamente che una richiesta numerica letterale da parte di un committente non tecnico va tradotta, non eseguita alla lettera — è stata la lettura di CLAUDE.md (regole generiche del progetto, non del metodo AI_Programmer) a bloccare l'esecuzione letterale e a portare a una domanda di chiarimento.

**Proposta:** nel `METHOD.md` o in `docs/ngiri-paralleli.md`, una riga esplicita che nomini questo caso — una cifra letterale in una richiesta ("N giri", "100 correzioni") è quasi sempre un modo per dire "esaustivo"/"a fondo", non una specifica di quante iterazioni orchestrare — così la traduzione diventa parte del metodo stesso, non qualcosa che dipende dalle regole del progetto ospite.

### 5.3 Una lente di correttezza applicata dopo un giro di prodotto trova ancora bug — ma nessuno lo garantisce esplicitamente
Il §4.1 sopra è un'osservazione positiva, ma rivela anche un rischio: chi decide "ho già fatto un giro su questo progetto" potrebbe fermarsi, assumendo che un giro (di qualunque batteria di lenti) esaurisca la correttezza del progetto. Non è così, ed è già scritto nell'hub che le due batterie sono ortogonali — ma non è scritto quante batterie esistono in tutto, né quando un progetto può dirsi "coperto" rispetto a tutte.

**Proposta:** un indice esplicito delle batterie di lenti esistenti (oggi: 4 lenti storiche di correttezza + 5 lenti di prodotto, secondo `docs/ngiri-paralleli.md`) con una nota su quali di queste sono state applicate a un dato progetto e quando — così "ho fatto un giro" diventa una domanda con risposta verificabile ("quale batteria, quando"), non un'affermazione generica.

---

## 5bis. Quello che è emerso SOLO dopo il deploy dal vivo

`npm test` (1307/1307 verde, PR #102 mergiata) non è la fine della catena di verifica per un progetto GAS+servizi esterni: il primo `npm run deploy` e la prima esecuzione reale dell'Auto-test hanno prodotto due scoperte che nessuna sessione cloud, da sola, avrebbe potuto fare.

### 5bis.1 Un test verde negli stub può essere silenziosamente sbagliato dal vivo — non solo "non coperto"
Il progetto dichiara già, come limite noto e nominato, 7 asserzioni "fuori copertura" (toccano `SpreadsheetApp`/servizi reali, saltate negli stub). Questo giro ne ha trovata una categoria diversa e non ancora nominata: **2 asserzioni che gli stub eseguono e valutano regolarmente**, ma la cui logica assume che una dipendenza reale (`DriveApp`) *lanci sempre un'eccezione* — vero solo nell'ambiente stub, dove `DriveApp` non è implementato apposta. Dal vivo, con autorizzazione completa, la stessa chiamata non lancia: **riesce**, e il test falliva perché il successo non era fra gli esiti previsti. `npm test` non poteva mai scoprirlo, perché la sua stessa infrastruttura (lo stub che lancia sempre) è la causa dell'assunzione sbagliata — un caso limite del principio già noto "un doppio va reso fedele o va fatto lanciare, mai tirato via" (§34.11 del progetto), qui applicato al ROVESCIO: il doppio era fedele all'ambiente stub, ma il test lo trattava come l'unica realtà possibile.

**Effetto collaterale reale**: quel "successo imprevisto" ha scritto una riga di prova (`modulo: "Test"`) nel registro di audit di **produzione**, prima che qualcuno se ne accorgesse — un test pensato per essere innocuo (eseguito automaticamente ad ogni Auto-test) ha inquinato un dato ISA 230 reale, per la prima volta dal vivo.

**Proposta:** una lente aggiuntiva per il codice di test che tocca servizi esterni reali — non "questo test è coperto?" ma "se la dipendenza reale si comporta diversamente dallo stub (in particolare: riesce dove lo stub fallisce), il test resta corretto, e se scrive davvero, si pulisce da solo?". Non è la stessa domanda di `oracolo-indipendente` (fidarsi di una fonte sola) né di `banco-sintetico-per-calcoli-critici` (isolare per poter provare): è una terza domanda, su cosa succede quando l'ambiente di prova e l'ambiente reale **divergono nella direzione opposta a quella temuta** (il reale è più permissivo dello stub, non più restrittivo).

### 5bis.2 Il primo deploy dal vivo di un progetto ha rivelato una trappola operativa già scritta, ma non ancora incontrata da chi esegue
`PROJECT.md` documentava già, per esperienza passata, la trappola "clasp v3 globale vs v2 locale" (`clasp login` col binario sbagliato scrive un token che il clasp locale non sa leggere). Il proprietario del progetto l'ha comunque incontrata di nuovo al primo tentativo di deploy di questa sessione — la documentazione scritta non ha impedito l'errore, solo reso più veloce diagnosticarlo (30 secondi invece di una ricerca). Nota minore ma reale: la documentazione di una trappola operativa nota, dentro `PROJECT.md`, aiuta chi legge il codice ma non necessariamente chi esegue un comando da terminale in un altro momento — sono due letture diverse dello stesso documento.

### 5bis.3 Verificare dal vivo non è opzionale quando il codice tocca servizi reali, ed è un passo che la sessione cloud non può fare da sola
Fra la PR mergiata e "fatto per davvero" ci sono stati, in sequenza: login clasp corretto, `diff:live` (parità confermata), `deploy`, scelta dell'ID di distribuzione giusto (non quello `@HEAD`), e solo allora l'Auto-test reale — che ha trovato in 2 minuti un difetto che 1307 asserzioni verdi non potevano vedere. Ognuno di questi passi richiedeva l'account e la macchina del proprietario del progetto, non la sessione. Conferma diretta, con un caso reale, della proposta già fatta al §5.1 di questo stesso report (una terza categoria "da verificare sul sistema reale"): qui non era un candidato di bug-hunt non verificabile, era un **intero passo del ciclo di vita** ("verificare dal vivo") strutturalmente fuori portata, e la sessione ha dovuto correggere un secondo giro di codice (PR #103) DOPO aver visto l'esito di quel passo — un ciclo di correzione che il metodo, così come praticato finora, non descrive esplicitamente come normale e atteso per questa classe di progetti.

**Proposta:** riconoscere esplicitamente, per i progetti che integrano servizi esterni reali (GAS+Sheets/Drive, o equivalenti), un passo del ciclo **dopo** la PR mergiata — "prima esecuzione dal vivo" — con la stessa dignità di una fase del metodo, non solo una nota a piè di pagina nella checklist della PR: è il punto in cui gli stub, per quanto ben progettati, possono ancora mentire nella direzione opposta a quella per cui erano stati pensati.

## 6. Proposte concrete, in sintesi

1. Aggiungere una terza categoria esplicita ai giri di bug-hunt — *da verificare sul sistema reale* — distinta da confermato/falso-positivo, per i candidati che una sessione senza credenziali esterne non può risolvere da sola.
2. Nominare esplicitamente, nel metodo, la traduzione di un'istruzione numerica letterale ("N giri") in "esaustivo secondo il metodo", non in N iterazioni letterali.
3. Tenere un indice delle batterie di lenti applicate a ciascun progetto (quale batteria, quando), così "già coperto" diventa verificabile invece di generico.
4. Riconoscere esplicitamente che `chiave-stabile-etichetta-libera` e `riga-in-coda-non-interposta` sono la stessa idea a due livelli di struttura (dati vs schema) — non serve un pattern nuovo, serve dirlo nella loro descrizione.
5. Nominare una lente per il codice di test che tocca servizi esterni reali: un test verde negli stub può essere sbagliato dal vivo non solo per copertura mancante, ma perché assume che una dipendenza reale si comporti in un modo (es. "lancia sempre") che è vero solo nello stub — verificare esplicitamente cosa succede quando il reale è **più permissivo** dello stub, non solo quando è più severo.
6. Dare al passo "prima esecuzione dal vivo dopo la PR mergiata" la stessa dignità di una fase del metodo per i progetti che integrano servizi esterni reali — non una nota a piè di pagina: è dove gli stub possono mentire nella direzione opposta a quella per cui erano stati progettati, ed è strutturalmente fuori portata di una sessione cloud.

---

## Appendice — riferimenti

- Pull request: `obi2kenobi/Controlli-trimestrali-Bilancio#102` (16 bug corretti, mergiata)
- Pull request di seguito, dopo il primo deploy dal vivo: `obi2kenobi/Controlli-trimestrali-Bilancio#103` (2 asserzioni valide solo negli stub, §5bis.1)
- Diario completo del giro: `SAL.md` §38 (i 16 bug), §39 (decisione presa — colonna `Etichetta`), §40 (conferma INTESA, non un bug), §41 (le 2 asserzioni dal vivo)
- Giro di prodotto precedente sullo stesso progetto: `docs/campo/2026-08-27-controlli-trimestrali.md` (questo hub)
- Repository di riferimento del metodo: `obi2kenobi/AI_Programmer`
