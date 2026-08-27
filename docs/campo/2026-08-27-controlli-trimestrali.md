# Report per AI_Programmer
### Riscontri dall'applicazione del metodo su un progetto reale (Controlli-trimestrali-Bilancio)

**Da:** sessione Claude Code, per conto di Luca (GRUPPO CAMARLINGHI S.P.A.)
**Oggetto:** proposte di miglioramento per il metodo/tooling AI_Programmer, basate su un ciclo completo — analisi, correzione, sviluppo del catalogo di idee fino a esaurimento — condotto su un progetto GAS reale già in produzione (97 file sorgente, ~850 asserzioni di test preesistenti, nessun bug noto in sospeso all'inizio).

**Aggiornamento:** questa versione copre l'intero ciclo, comprese le due pull request. La prima stesura (§1-5 originali) si fermava a "7 idee su 44 implementate"; da lì si è proseguito senza interrompersi fino a portare **tutte** le idee residue a uno stato terminale — implementata, verificata come già coperta da un meccanismo esistente, esclusa o rinviata — in una seconda PR (#98). Le sezioni nuove sono marcate esplicitamente "Fase 2".

---

## 1. Contesto

Il progetto `Controlli-trimestrali-Bilancio` (controlli trimestrali di bilancio, GAS + Business Central, per GRUPPO CAMARLINGHI S.P.A.) aveva già adottato manualmente parte della disciplina di AI_Programmer — `CLAUDE.md`/`PROJECT.md`/`SAL.md`, la regola "verifica-contro-i-propri-totali", `npm test` come parità fuori-GAS — ma **non** aveva `.claude/skills`, `.claude/agents`, `patterns/` né `DEBITI.md`: l'infrastruttura di AI_Programmer non era installata come tooling riusabile, solo recepita come prosa nei documenti di progetto.

Su questa base si è condotto un ciclo in tre fasi, esplicitamente ispirato al metodo AI_Programmer:

1. **Analisi ("30 giri")** — 30 agenti paralleli, 15 aree del codice × 2 letture ciascuna (una a caccia di errori silenziosi/incongruenze logiche, l'altra a caccia di possibilità non sviluppate), con le stesse quattro lenti dichiarate nel metodo: *scarto-mai-silenzioso*, *banco-sintetico-per-calcoli-critici*, *oracolo-indipendente*, *copertura-dal-glob* — più lo standard *dev-critic* ("chi porta solo difetti ha fatto un terzo del lavoro").
2. **Correzione** — tutti i 19 findings di gravità ALTA emersi, corretti uno alla volta con l'approvazione esplicita del proprietario del progetto ad ogni passo.
3. **Sviluppo** — 7 delle 44 idee/possibilità catalogate, implementate una alla volta con lo stesso criterio.

La Fase 1 (analisi + correzione + prime 7 idee) è confluita nella pull request #97, con CI aggiunta durante il percorso. La Fase 2 (le restanti idee del catalogo, sviluppate senza fermarsi) è confluita nella pull request #98.

---

## 2. Risultato in cifre

| Metrica | Fase 1 (#97) | Fase 2 (#98) |
|---|---|---|
| Findings ALTA corretti | 19 / 19 (100%) | — |
| Idee/possibilità dal catalogo | 7 implementate | tutte le restanti portate a uno stato terminale (implementata / già coperta e verificata / esclusa / rinviata) |
| Test automatici | 845/852 → 915/915 | 915/915 → **1057/1057** (0 falliti) |
| Nuove asserzioni aggiunte | +70 | +142 |
| Commit | 18 | 22 |
| File toccati | 26 (incl. 2 nuovi) | 36 (incl. 3 nuovi) |
| Righe | +1.303 / −112 | +2.258 / −65 |
| Regressioni introdotte | 0 | 0 (ogni commit validato dalla suite intera prima del push) |

Il dato più rilevante resta lo stesso di Fase 1: **tutti** i findings ALTA e **tutte** le idee sviluppate erano riproducibili/verificabili con un test prima/dopo, e **zero** correzioni o feature sono state respinte in revisione o hanno richiesto un rollback. In più, in Fase 2 il catalogo delle 44 idee è stato interamente esaurito — non è rimasto nulla "in sospeso senza una ragione dichiarata": ogni idea non implementata porta con sé il motivo (decisione di dominio necessaria, rischio/beneficio sfavorevole, o vincolo architetturale documentato altrove nel progetto).

---

## 3. Cosa ha funzionato bene

### 3.1 Le quattro lenti trovano bug reali, non nitpick di stile
Tutti e 19 i findings ALTA erano istanze concrete delle stesse quattro famiglie di bug (soprattutto *scarto-mai-silenzioso*): un `Number(x) || 0` che confonde "zero vero" con "valore non leggibile" (Cespiti, CE), un `catch` o un `return` silenzioso che fa sparire un'esecuzione dal registro invece di dichiarare il fallimento (Audit trail, riconciliazione mastrini), un lock preso solo da metà dei percorsi che toccano la stessa risorsa condivisa (Banche, Audit trail). Nessuno di questi produce un crash: producono un **verde plausibile e sbagliato**, la categoria di bug più pericolosa in un sistema di controllo. Le lenti del metodo sono tarate esattamente su questa categoria, ed è quello che hanno trovato.

### 3.2 La convergenza indipendente è un segnale di qualità reale
Gli 8 "temi trasversali" sono emersi da agenti diversi su aree diverse, **senza coordinarsi fra loro** — è stata la sintesi finale a raggrupparli dopo, non un'istruzione condivisa in partenza. Che lo stesso pattern (es. "verifica di unicità del candidato: rigorosa in alcune funzioni, assente nelle gemelle") sia stato notato indipendentemente su Mastrini fornitori e su Fondo TFR è una prova di robustezza che un singolo giro di revisione non dà.

### 3.3 Lo standard dev-critic ha prodotto valore misurabile, non solo un elenco di idee
Le 44 idee non sono rimaste su carta: 7 sono già in produzione (CI, tre alert/digest via email, un trigger di diagnostica, materialità storicizzata, follow-up automatico sui mastrini). Obbligare ogni agente a portare anche possibilità, non solo difetti, ha spostato il lavoro da "riparare quello che c'è" a "usare meglio quello che c'è già" — es. il digest di stato e l'alert sui moduli fermi hanno riusato per intero le funzioni di lettura registro già scritte per il Cruscotto, zero duplicazione.

### 3.4 Il pattern "verifica-contro-i-propri-totali" ha reso i findings quasi tutti riproducibili in `npm test`
La maggior parte della logica di dominio (parser, calcoli di scostamento, matching per nome/cognome, semafori) era già estratta in funzioni pure testabili fuori da GAS. Questo ha reso possibile dimostrare ogni fix con un test PRIMA/DOPO invece che a parole — coerente con "Done means proven", ma è stato possibile solo perché l'estrazione era già una disciplina del progetto.

### 3.5 (Fase 2) Verificare prima di costruire ha evitato due implementazioni inutili
Due idee del catalogo (Fase 2, "storico degli scostamenti" per i Cespiti e per gli Indici di crisi) chiedevano un trend nel tempo che, una volta guardato da vicino, risultava **già prodotto gratis** da un'infrastruttura generica costruita poco prima per un'altra area (il cruscotto storicizza *qualsiasi* coppia modulo/controllo dal registro audit, usando il campo numerico "totale" come serie). In entrambi i casi il lavoro corretto non era scrivere nuovo codice, ma **verificare con un test** che il meccanismo esistente si applicasse davvero al caso nuovo — nome di controllo stabile fra esecuzioni, totale sempre numerico anche a scostamento zero. Il rischio, senza questo passo, era costruire due volte la stessa cosa perché l'idea era stata scritta pensando "serve un nuovo pezzo" invece di chiedersi prima "un pezzo che già fa questo esiste?".

### 3.6 (Fase 2) Un terzo modo di trattare una soglia, fra "hardcoded" e "decisione di Luca"
Le 5 soglie di legge usate per gli indici di crisi d'impresa erano hardcoded nel codice, validate col revisore — l'unico controllo del progetto le cui soglie non passavano dal foglio CONFIG come tutte le altre. Spostarle di netto nel foglio le avrebbe rese modificabili da chiunque senza revisione, per numeri che determinano un giudizio di legge; lasciarle hardcoded le avrebbe tenute fuori dal pattern già in uso ovunque nel progetto. La soluzione già in uso altrove nel codice si è rivelata applicabile pari pari: il foglio CONFIG **può** sovrascriverle, ma il default hardcoded resta quello validato e viene usato ogni volta che il foglio non lo fa, con un avviso esplicito scritto nella descrizione di ogni riga a non toccarle senza conferma del revisore. Né "tutto fisso nel codice" né "tutto nelle mani di chi apre il foglio": un default guardato, con l'override esplicito e la ragione scritta accanto al numero.

### 3.7 (Fase 2) Un'idea "rischiosa" non è per forza un'idea da scartare: a volte è un'idea da verificare fuori dal repo
Una delle idee di Fase 2 chiedeva di rendere permanente (nel repository) un test visivo con Playwright per il cruscotto, oggi solo uno script usa-e-getta. Il repository dichiara però esplicitamente, nel commento del proprio workflow CI, "zero dipendenze npm, zero segreti" — un vincolo architetturale reale, non uno stile di scrittura. Anziché scegliere fra "ignoro il vincolo e installo Playwright comunque" e "scarto l'idea perché rischiosa", si è installato Playwright in una directory di lavoro **esterna al repository** (mai toccato `package.json`, mai committato), costruito un finto `google.script.run` con una risposta per funzione (non una risposta unica per tutte, l'errore che lo stesso SAL.md del progetto segnala essere già capitato), e fatta girare la funzionalità nuova in un vero Chromium headless con 16 asserzioni — poi tutto lo scaffolding è stato scartato, restando solo il codice sorgente modificato. Ha dato la stessa prova ("visto girare davvero", non solo "letto il codice") che un test committato avrebbe dato, senza toccare l'invariante del progetto.

---

## 4. Attriti e lacune osservate (feedback per il metodo/tooling)

### 4.1 L'infrastruttura di AI_Programmer non è "installabile", va ricostruita a mano
Il report "Trenta giri" lo segnala esplicitamente nella sua stessa area Infrastruttura: questo progetto ha CLAUDE.md/PROJECT.md/SAL.md portati a mano, ma non `.claude/skills`, `.claude/agents`, `patterns/`, `DEBITI.md`, né il meccanismo di *night-verify*. Il risultato pratico: le quattro lenti e lo standard dev-critic sono stati **riapplicati da zero come istruzioni in linguaggio naturale** ad ogni giro, invece di essere invocati come skill/agenti pacchettizzati. Ha funzionato, ma non c'è garanzia di applicarli allo stesso modo la prossima volta, su un altro progetto, con un'altra persona al comando.

**Proposta:** un pacchetto installabile (plugin/skill Claude Code, o equivalente) che porti le quattro lenti, lo standard dev-critic e il pattern "N giri paralleli" come oggetti riusabili — non solo come prosa in un repo di riferimento da leggere e imitare.

### 4.2 Il pattern "N giri paralleli" non è ancora un workflow riproducibile
Il giro da 30 agenti (15 aree × 2 letture) è stato orchestrato a mano: prompt per ogni area scritti singolarmente, lancio in batch da 10 per i limiti di concorrenza, sintesi finale fatta leggendo tutti i risultati e raggruppando a mano gli 8 temi trasversali. È un procedimento che si presta bene a una definizione dichiarativa (N aree × M lenti → fan-out → sintesi con individuazione di pattern ricorrenti), ma oggi va ridisegnato ogni volta.

**Proposta:** un template di orchestrazione documentato — non necessariamente legato a uno strumento specifico — che fissi la struttura (fan-out per area × lente, soglia di ricorrenza per "tema trasversale", formato di sintesi) lasciando solo il contenuto delle aree da compilare per il progetto specifico.

### 4.3 Manca un pattern nominato per "estrazione guidata dalla testabilità"
Insieme alle quattro lenti dichiarate, in questo ciclo è ricorso costantemente un quinto movimento, non nominato nel metodo per quanto emerso qui: **isolare la logica pura da un involucro che tocca servizi reali (Sheets, Drive, Gmail, BC) apposta per poterla testare**, lasciando l'involucro stesso onestamente dichiarato "non testabile fuori da Apps Script" invece di forzare un mock che finge di verificare qualcosa che non verifica. È successo su quasi ogni fix di questo ciclo (`_numeroCespiti`, `_moduliFermiDaModuli`, `_mastriniInRitardo`, `_corpoDigestStato`, `_righeSaldiRealiDaValori`...) — con la stessa frequenza delle quattro lenti già nominate.

**Proposta:** nominare esplicitamente questo quinto pattern (es. *estrazione-per-testabilità*) accanto agli altri quattro, con la stessa dignità — è comparso troppo spesso per essere un dettaglio implementativo.

### 4.4 Le regole di processo "one problem at a time" / "ask, don't guess" non distinguono lavoro nuovo da lavoro già diagnosticato
Le regole di processo (ripeti la richiesta, un problema alla volta, chiedi invece di indovinare) sono state preziose in fase di *analisi* — dove ogni finding era una scoperta da verificare. In fase di *correzione* di 19 findings già diagnosticati con precisione (file, righe, causa), applicarle letteralmente a ogni singolo fix avrebbe introdotto un attrito che il proprietario del progetto ha risolto da solo, dando un'autorizzazione unica per "finire tutto il resto" invece di riconfermare ogni volta. Il metodo, così com'è scritto, non distingue esplicitamente questi due regimi.

**Proposta:** articolare nel metodo quando le regole di conferma-passo-per-passo si applicano per intero (decisioni di dominio, logica nuova, ambiguità reale) e quando si comprimono legittimamente (batch di fix già interamente specificati da un'analisi precedente, con l'autorizzazione esplicita del proprietario a procedere in sequenza).

### 4.5 Manca uno stato esplicito a tre valori per "confermato"
"Done means proven and confirmed" richiede sia l'evidenza tecnica sia la conferma del proprietario. In questo ciclo, per una parte consistente delle correzioni (tutto ciò che tocca GmailApp/DriveApp/SpreadsheetApp reali o Business Central) l'evidenza tecnica disponibile **dentro la sessione** si ferma al test unitario della logica estratta — la conferma "gira davvero in produzione" resta fuori portata di una sessione cloud. Questo stato intermedio (testato in isolamento, non ancora verificato dal vivo, non ancora confermato dal proprietario) è stato tracciato a mano in una checklist nel corpo della PR, ma non è un concetto che il metodo nomina.

**Proposta:** un terzo stato esplicito accanto a "difetto"/"idea" — qualcosa come *da verificare dal vivo* — con una convenzione per tracciarlo (sul modello di `DEBITI.md`) invece di reinventarla ogni volta nella descrizione della PR.

### 4.6 (Fase 2) "Escluso perché serve una decisione di Luca" non è una categoria sola
Il catalogo di 44 idee, arrivato a esaurimento, ha mostrato che le idee non implementate cadono in **almeno due famiglie diverse**, oggi non distinte nel metodo:
- idee che richiedono un **parametro o una scelta di business concreta** (una soglia, un accantonamento, un canale d'invio) — qui la domanda a Luca è puntuale e la risposta chiude la questione;
- idee **architetturalmente speculative**, che generalizzano un pattern esistente "e se lo applicassimo anche altrove" senza un caso reale che lo richieda oggi (è successo con "estendere gli stati multipli del fondo TFR anche a Ferie e Fornitori"). Qui il problema non è la mancanza di un dato da chiedere: è che implementarla comunque rischierebbe di inventare una classificazione che nessuno ha ancora chiesto, il tipo di over-engineering che le regole di processo del progetto vietano esplicitamente altrove ("solo quello che è stato chiesto").

Il metodo tratta oggi entrambe come "chiedi, non indovinare" — ma la prima si chiude con una domanda, la seconda si chiude lasciandola aperta finché non esiste un caso concreto.

**Proposta:** distinguere nel metodo *idea in attesa di un parametro* da *idea in attesa di un caso d'uso reale* — la seconda va segnata come "non ancora matura", non genericamente "esclusa".

### 4.7 (Fase 2) I vincoli architetturali del progetto possono vivere in un commento di configurazione, non solo in SAL.md/CLAUDE.md
Il vincolo che ha fatto rinviare l'idea del test Playwright permanente non era scritto in un documento di metodo: era un commento di due righe dentro `.github/workflows/test.yml` ("npm test carica tutto in un contesto vm... zero dipendenze npm, zero segreti"). Le lenti e le regole del metodo guardano bene ai file di documentazione dichiarati (SAL.md, PROJECT.md); un vincolo altrettanto vincolante scritto dentro un file di configurazione tecnico rischia di non essere mai controllato prima di proporre un'idea che lo violerebbe.

**Proposta:** includere esplicitamente, fra le cose da controllare prima di implementare un'idea, i commenti nei file di configurazione/CI del progetto (workflow, lockfile, `.tool-versions` e simili) — non solo i documenti di metodo dichiarati.

---

## 5. Proposte concrete, in sintesi

1. Impacchettare le quattro lenti + dev-critic come skill/agenti installabili, non solo come prosa da imitare.
2. Documentare il pattern "N giri paralleli" come workflow a struttura fissa (fan-out per area×lente, sintesi con soglia di ricorrenza per i temi trasversali).
3. Nominare un quinto pattern, *estrazione-per-testabilità*, comparso quanto le altre quattro in questo ciclo.
4. Distinguere nel metodo il regime di conferma "passo-per-passo" (analisi, decisioni di dominio) da quello "batch autorizzato" (correzione di findings già diagnosticati).
5. Aggiungere un terzo stato tracciabile — *da verificare dal vivo* — fra "difetto" e "confermato", per il lavoro che una sessione cloud non può validare fino in fondo.
6. **(Fase 2)** Prima di implementare un'idea del catalogo, controllare esplicitamente se un meccanismo generico già costruito la copre già — verificarlo con un test invece di costruire una seconda volta.
7. **(Fase 2)** Distinguere *idea in attesa di un parametro di Luca* da *idea architetturalmente speculativa senza un caso reale* — solo la prima si chiude con una domanda; la seconda resta "non ancora matura".
8. **(Fase 2)** Nominare il pattern *soglia con default guardato* (override facoltativo da configurazione, default validato invariato, avviso esplicito accanto al valore) come via di mezzo fra "hardcoded" e "decisione di Luca" per un parametro tecnico-normativo.
9. **(Fase 2)** Includere fra i controlli pre-implementazione anche i vincoli scritti nei file di configurazione/CI (non solo SAL.md/CLAUDE.md), e — quando un'idea li violerebbe — considerare una verifica fuori dal repository (strumenti installati in una directory di lavoro esterna, mai committati) come prova equivalente a un test committato.

---

## Appendice — riferimenti

- Pull request Fase 1: `obi2kenobi/Controlli-trimestrali-Bilancio#97` (19 findings ALTA + prime 7 idee)
- Pull request Fase 2: `obi2kenobi/Controlli-trimestrali-Bilancio#98` (catalogo di idee esaurito, 1057/1057 test)
- Report di analisi "Trenta giri" (30 agenti, temi trasversali, elenco completo di errori e idee per area): artifact pubblicato durante la sessione
- Repository di riferimento del metodo: `obi2kenobi/AI_Programmer`
