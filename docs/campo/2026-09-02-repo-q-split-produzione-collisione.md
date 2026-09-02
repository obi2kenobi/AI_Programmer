# 2026-09-02 — REPO-Q: dal crash notturno allo split per anno (incidente da namespace globale GAS)

**Autore**: sessione Claude Code (remota, web) su mandato di Luca — REPO-Q, **mai onboardato
allo standard di questo hub**: vedi §"non raggiungibile".

Punto di partenza: una mail di alert alle 05:29. La notturna era abortita con
`Questa azione aumenterà il numero di celle nella cartella di lavoro oltre il limite di
10000000 celle` in un append. Fine giornata: causa strutturale chiusa, dati storici sanati,
architettura cambiata, 7 PR mergiate + 1 aperta. In mezzo, un incidente reale che il metodo
non copriva.

## Cosa ho usato

- **`design-doc`** (letto a mano dall'hub clonato, non installato in REPO-Q): vincoli di
  squalifica dichiarati PRIMA dei criteri, criteri PRIMA delle opzioni, tabella
  opzioni×criteri, effetti di secondo ordine, opzioni scartate motivate, e soprattutto
  "non implementare" + "la scelta resta a chi possiede il progetto". Rispettato alla
  lettera: il documento è finito nel diario vivo del progetto e Luca ha scelto dopo.
- **`selezione-contesto`**: budget dichiarato (4 fonti) ed **esclusioni scritte** nel
  documento. La riga "nessun pattern esistente sul tema, verificato" è servita subito
  dopo: mi ha detto che ero in territorio nuovo, non che non avevo cercato.
- **`brainstorming`**: avvenuto in conversazione prima del design-doc. La divergenza
  (§3, le 2-3 riformulazioni) l'ho **saltata dichiaratamente**: Luca è arrivato con
  l'opzione già in testa ("un file per anno?"), il problema aveva una lettura sola.
- **Lo spike di `design-doc` §3bis**: usato per davvero, ed è il passo che ha **cambiato
  il piano** (dettaglio in §"cosa ha retto").
- **`gas-agent`** (canone di REPO-Q, non di questo hub): consultato prima di scrivere
  l'utility condivisa; da lì la regola "batch, mai loop per cella".
- **Regola 4 "Forma dei dati verificata"**: la regola che ha pagato di più oggi.
- **Regola 6 "Il guardiano si prova quando deve fallire"**: applicata al banco della
  migrazione — un caso crea un buco artificiale nei dati per provare che il controllo di
  copertura **rifiuta** di cancellare la sorgente.
- **Regola 7 "L'aspettativa si deriva"**: aritmetica del test di slicing contata a mano
  prima di eseguirlo, non a memoria.

### Non raggiungibile (la terza casella, dal campo REPO-H)

REPO-Q non ha `.claude/skills/`, né hook, né `.night-verify`: **nessun meccanismo ha
iniettato il metodo**. È stato raggiungibile solo perché ho clonato questo hub in sola
lettura e ho letto `METHOD.md` + le tre skill a mano, su richiesta esplicita di Luca
("usa ai programmer per farti aiutare nel metodo"). Senza quella frase, la sessione
avrebbe progettato senza design-doc. Pesa: il valore più alto della giornata (§"cosa ha
retto") viene da due regole che nessuno mi ha obbligato a caricare.

Non ho potuto pushare qui (accesso anonimo in sola lettura all'hub): questo report è
consegnato come file a Luca.

## Cosa ho improvvisato

1. **Il rilevatore di collisioni nel namespace globale GAS.** Dopo l'incidente (§sotto):
   `grep` di tutti i `^function X` e `^var X` del progetto, conteggio dei nomi che appaiono
   più di una volta. Due comandi, esito binario, ora eseguito **prima di ogni push**. Non
   esisteva niente del genere né qui né in REPO-Q.
2. **Il pattern "migrazione con interruttore + copia di sicurezza"**, inventato per non
   dover scegliere fra "deploy rischioso" e "migrazione al buio":
   codice deployato **inerte** dietro una Script Property → migrazione a freddo, a chunk
   ripartibili → verifica → si accende l'interruttore → la sorgente resta come copia di
   sicurezza → il recupero spazio è un passo separato ed esplicito, dopo una notturna
   verificata. Rollback disponibile fino all'ultimo passo.
3. **Due verifiche per due domande diverse** (me l'ha imposto il banco, non l'ho pensato
   prima): uguaglianza esatta per *attivare*, copertura per chiave per *cancellare*.

## Cosa ha retto / ostacolato

### Ha retto: "Forma dei dati verificata" (regola 4) — la regola della giornata

Il piano approvato splittava per anno di `Posting_Date`. Prima di scrivere la migrazione ho
contato quel campo sui dati reali: **l'82,09% delle righe (177.076 su 215.710) lo aveva
VUOTO**. Il codice lo sapeva — c'era perfino un fallback con un commento "corruzione sync
passata" — ma per un fallback di visualizzazione l'82% è tollerabile, per uno split che deve
decidere il file di OGNI riga è un blocco totale. **Nessuna lettura di codice l'avrebbe
trovato**: solo contare sul dato vero. Se avessi implementato il piano approvato, avrei
migrato l'82% dei dati nell'anno sbagliato.

### Ha retto: lo spike (design-doc §3bis) ha cambiato il piano, non l'ha confermato

Davanti al blocco, la tentazione era progettare l'alternativa (un file "storico" per le
righe senza data). Invece: spike a scopo vincolato, 3 query piccole su inizio/metà/fine del
range → **63/63 campioni con data valida nel sistema sorgente**. La corruzione era solo
nostra, non della fonte. Il problema è passato da "serve un'altra architettura" a "si
ripara la sorgente e il piano originale resta valido". Costo dello spike: ~3 secondi di
esecuzione. Il backfill che ne è seguito ha chiuso a **0 righe senza data**, con la somma
delle parti che combacia esattamente con le 177.076 di partenza.

### Ha retto: i criteri dichiarati prima delle opzioni

Quando il blocco è emerso, la decisione era già scritta col suo perché. Non abbiamo
ri-litigato la scelta: abbiamo trattato il blocco come un prerequisito da rimuovere. Il
documento ha fatto esattamente il lavoro per cui esiste — sei ore dopo, non sei mesi dopo.

### Ha retto: il banco ha trovato un difetto di PROGETTO, non un bug

27 controlli con Apps Script mockato in Node. Ha **bocciato la prima versione dei cancelli
di verifica**: pretendevano conteggi identici anche prima di cancellare la sorgente, ma dopo
l'attivazione la notturna aggiunge legittimamente righe nuove nella destinazione — quel
cancello avrebbe bloccato **per sempre** la pulizia finale, e nessuno l'avrebbe capito
guardando il codice. Non era un errore di sintassi: era la domanda sbagliata.

### Ha ostacolato: nulla del metodo. Ma un buco vero nel metodo

**L'incidente.** Ho scritto una funzione chiamata `scaricaMappaPostingDateBc_`. Lo stesso
nome esatto esisteva già in un altro file dello stesso progetto Apps Script (indagine
precedente, scope diverso). In Apps Script tutti i file condividono **un unico namespace
globale**: il duplicato viene sovrascritto **silenziosamente** — nessun errore in deploy,
nessun errore a runtime. Luca ha lanciato la mia funzione e ha girato **quella dell'altro
file**: parametri ignorati (la loro non li accetta), filtro diverso, 921,5s invece di 130,8s,
e un aggiornamento parziale. L'unico segnale era nel log: stringhe che non avevo scritto io.

Nessun dato errato scritto (la mappa "sbagliata" conteneva comunque coppie autentiche, e il
mio controllo scriveva solo su corrispondenza reale) — ma solo per fortuna del disegno, non
per una guardia.

**La radice, però, non è la collisione: è la ricerca insufficiente del precedente.** Quel
file conteneva già una patch più ristretta sullo stesso campo, e dentro portava un vincolo
**pagato da qualcun altro**: batch da 50 con pausa 500ms, col commento "per non saturare la
quota bandwidth". La mia implementazione fresca non lo sapeva. Ho scritto codice nuovo dove
esisteva un precedente con conoscenza dentro.

## Proposta al canone

1. **Pattern `collisione-namespace-globale-gas`** (nuovo, àncora: questa sessione). In un
   progetto Apps Script tutti i file condividono un namespace: un nome duplicato vince
   silenziosamente, senza errore. Guardia meccanica, due comandi:
   `grep -rhoE "^function [A-Za-z_][A-Za-z0-9_]*" --include="*.gs" . | sed 's/^function //' | sort | uniq -c | awk '$1>1'`
   (idem per `^var`). Esito atteso: vuoto. Va nel canone `gas-sviluppo` e nella checklist
   pre-push, non solo in `patterns/`: il modo di fallire è il silenzio, quindi serve un
   controllo che parli.
2. **Pattern `il-precedente-porta-il-vincolo-pagato`** (nuovo). Prima di scrivere un tool
   nuovo su un campo/dominio, cercare nel repo chi lo ha già toccato: il codice esistente
   porta vincoli scoperti a caro prezzo (qui: una quota di banda) che una reimplementazione
   pulita non conosce. `selezione-contesto` copre le *lezioni scritte* (SAL, pattern) ma non
   il **codice già esistente sullo stesso oggetto**: è un buco dichiarato del passo di
   selezione, non della mia diligenza.
3. **Pattern `migrazione-con-interruttore`** (nuovo, generalizzabile a ogni migrazione dati
   GAS): deploy inerte dietro property → migrazione a freddo a chunk ripartibili con
   watermark salvato subito dopo ogni scrittura → verifica → interruttore → sorgente come
   copia di sicurezza → recupero spazio come passo separato. Il pregio non è la sicurezza in
   astratto: è che il deploy **non cambia comportamento**, quindi si può pushare a metà
   giornata senza aspettare una finestra.
4. **Pattern `due-verifiche-due-domande`** (nuovo, àncora: il caso 6/6b del banco). Prima
   del cutover la domanda è "sono identici?"; prima di cancellare è "tutto quello che sta
   qui esiste anche là?". Usare la prima per cancellare blocca la pulizia per sempre appena
   la destinazione cresce legittimamente. Il banco l'ha trovato perché il caso di prova
   *simulava il tempo che passa* (una notturna dopo l'attivazione): raccomandazione
   collegata — nei banchi delle migrazioni, un caso deve sempre rappresentare "il sistema
   ha continuato a vivere dopo il cutover".
5. **Onboarding di REPO-Q allo standard** (`tools/sync-repo.sh <repo> --standard`). Oggi il
   metodo è arrivato per una frase dell'utente. Le due regole che hanno prodotto il valore
   maggiore (forma dei dati verificata, spike prima di riprogettare) e il rilevatore di
   collisioni sono esattamente ciò che hook + `.night-verify` renderebbero ripetibile senza
   dipendere dalla memoria di chi apre la sessione. Nota per il triage: REPO-Q ha già un
   `CLAUDE.md` proprio, severo e sensato, e un diario vivo attivo — l'onboarding va fatto
   **additivo**, non sostitutivo.

### Un dato per il triage delle proposte

La sequenza che ha funzionato oggi è sempre la stessa, quattro volte di fila: **diagnostica
di sola lettura → conferma sui numeri veri → poi la modifica**. Quattro strumenti usa-e-getta
(dimensioni celle, distribuzione anni, spike sorgente, stato split), ognuno eseguito da Luca
e con l'esito incollato in chat prima del passo successivo. Il costo è qualche minuto per
giro; ha evitato: una migrazione sull'82% dei dati nell'anno sbagliato, una riprogettazione
inutile, e un cancello che avrebbe bloccato la pulizia finale. Se una sola cosa di questo
report entra nel canone, che sia questa cadenza.
