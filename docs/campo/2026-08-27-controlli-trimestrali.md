# Report per AI_Programmer
### Riscontri dall'applicazione del metodo su un progetto reale (Controlli-trimestrali-Bilancio)

**Da:** sessione Claude Code, per conto di Luca (GRUPPO CAMARLINGHI S.P.A.)
**Oggetto:** proposte di miglioramento per il metodo/tooling AI_Programmer, basate su un ciclo completo — analisi, correzione, sviluppo — condotto su un progetto GAS reale già in produzione (97 file sorgente, ~850 asserzioni di test preesistenti, nessun bug noto in sospeso all'inizio).

---

## 1. Contesto

Il progetto `Controlli-trimestrali-Bilancio` (controlli trimestrali di bilancio, GAS + Business Central, per GRUPPO CAMARLINGHI S.P.A.) aveva già adottato manualmente parte della disciplina di AI_Programmer — `CLAUDE.md`/`PROJECT.md`/`SAL.md`, la regola "verifica-contro-i-propri-totali", `npm test` come parità fuori-GAS — ma **non** aveva `.claude/skills`, `.claude/agents`, `patterns/` né `DEBITI.md`: l'infrastruttura di AI_Programmer non era installata come tooling riusabile, solo recepita come prosa nei documenti di progetto.

Su questa base si è condotto un ciclo in tre fasi, esplicitamente ispirato al metodo AI_Programmer:

1. **Analisi ("30 giri")** — 30 agenti paralleli, 15 aree del codice × 2 letture ciascuna (una a caccia di errori silenziosi/incongruenze logiche, l'altra a caccia di possibilità non sviluppate), con le stesse quattro lenti dichiarate nel metodo: *scarto-mai-silenzioso*, *banco-sintetico-per-calcoli-critici*, *oracolo-indipendente*, *copertura-dal-glob* — più lo standard *dev-critic* ("chi porta solo difetti ha fatto un terzo del lavoro").
2. **Correzione** — tutti i 19 findings di gravità ALTA emersi, corretti uno alla volta con l'approvazione esplicita del proprietario del progetto ad ogni passo.
3. **Sviluppo** — 7 delle 44 idee/possibilità catalogate, implementate una alla volta con lo stesso criterio.

Il lavoro è confluito in una singola pull request cumulativa (#97), con CI aggiunta durante il percorso.

---

## 2. Risultato in cifre

| Metrica | Valore |
|---|---|
| Agenti impiegati nel giro di analisi | 30 (15 aree × 2 letture) |
| Findings ALTA trovati e corretti | 19 / 19 (100%) |
| Temi trasversali (pattern ripetuti in ≥3 aree indipendenti) | 8 |
| Idee/possibilità catalogate | 44 |
| Idee implementate in questo ciclo | 7 (16%) |
| Test automatici: baseline → finale | 845/852 → **915/915** (0 falliti) |
| Nuove asserzioni aggiunte | +70 |
| Commit | 18 (11 fix + 7 feature) |
| File toccati | 26 |
| Righe | +1.303 / −112 |
| Regressioni introdotte | 0 (ogni commit validato dalla suite intera prima del push) |
| Pull request | 1 (cumulativa, rititolata/riscritta ad ogni batch) |

Il dato più rilevante per valutare il metodo non è il numero di bug — è che **tutti e 19** i findings ALTA erano riproducibili e correggibili con un test che li dimostrava prima e dopo, e **zero** correzioni hanno richiesto di tornare indietro o sono state respinte dal proprietario del progetto in revisione.

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

---

## 5. Proposte concrete, in sintesi

1. Impacchettare le quattro lenti + dev-critic come skill/agenti installabili, non solo come prosa da imitare.
2. Documentare il pattern "N giri paralleli" come workflow a struttura fissa (fan-out per area×lente, sintesi con soglia di ricorrenza per i temi trasversali).
3. Nominare un quinto pattern, *estrazione-per-testabilità*, comparso quanto le altre quattro in questo ciclo.
4. Distinguere nel metodo il regime di conferma "passo-per-passo" (analisi, decisioni di dominio) da quello "batch autorizzato" (correzione di findings già diagnosticati).
5. Aggiungere un terzo stato tracciabile — *da verificare dal vivo* — fra "difetto" e "confermato", per il lavoro che una sessione cloud non può validare fino in fondo.

---

## Appendice — riferimenti

- Pull request: `obi2kenobi/Controlli-trimestrali-Bilancio#97`
- Report di analisi "Trenta giri" (30 agenti, temi trasversali, elenco completo di errori e idee per area): artifact pubblicato durante la sessione
- Repository di riferimento del metodo: `obi2kenobi/AI_Programmer`
