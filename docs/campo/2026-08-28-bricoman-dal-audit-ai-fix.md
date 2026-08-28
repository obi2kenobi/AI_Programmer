# 2026-08-28 — Bricoman, dall'audit a 25 fix in sessione continua

**Autore**: sessione Claude Code (Claude Sonnet 5) — stessa sessione del report di
analisi REPO-J (`docs/campo/2026-08-28-bricoman-50-agenti.md`), continuata sullo
stesso repo dopo approvazione esplicita dell'utente al piano di correzione.

## Cosa ho usato

- Il metodo letto DAVVERO prima di partire (non riprodotto per fama, a differenza di
  REPO-F/REPO-K): clonato AI_Programmer in sola lettura, letti `gas-sviluppo/SKILL.md`,
  `references/metodo.md`, `references/famiglie-difetti.md`, `revisore-gas.md`,
  `revisore-calcoli-critici.md`, `dev-critic/SKILL.md` — le lenti citate sono state
  incollate per intero nei prompt dei 35 agenti di scoperta della fase di analisi
  (vedi report REPO-J fase 1). Questo report (fase 2) rilegge lo stesso clone per
  scrivere in formato.
- Nella fase di fix (questa): NESSUN nuovo workflow multi-agente. 25 correzioni
  applicate in sequenza, io stesso, un rilievo alla volta: lettura del punto esatto,
  edit minimale, verifica con uno script node scritto da zero che riproduce lo
  scenario del rilievo originale (prima E dopo la correzione, con output mostrato),
  commit separato per ciascuna con nel messaggio il rilievo di origine, lo scenario
  riprodotto e l'evidenza dell'esecuzione.
- Un tracker di task della piattaforma ospitante (non uno strumento del canone) per
  tenere visibile lo stato dei 25 punti del piano — soddisfa la stessa funzione di un
  banco a livello di sessione: uno stato aggiornato ad ogni fix, non un elenco statico.

## Cosa ho improvvisato

- **Il "banco scritto al volo NON si butta" (metodo.md) è stato violato 25/25 volte**:
  ogni script di verifica è vissuto in uno scratchpad temporaneo della sessione, mai
  salvato nel repo target come riferimento permanente. Dichiarato qui, non nascosto.
- **Rilievi interdipendenti aggregati in un solo fix quando separarli avrebbe prodotto
  uno stato intermedio peggiore**: §1.5/§1.6 del report di analisi (quota trasporto non
  attribuita + `totalTransport` mai calcolato) più un terzo rilievo NON VERIFICATO
  (divisione per zero nella stessa funzione) erano la stessa funzione
  (`_validateCubbage`, `OrderProcessor.gs`): corretti in un unico commit invece di tre,
  perché fissare solo uno dei tre avrebbe lasciato la funzione in uno stato incoerente
  (es. totale sempre calcolato ma senza guardia sulla divisione per zero). Il metodo
  (passo 5, "scegli UNO da correggere") non dice esplicitamente se "uno" significa un
  rilievo o un blocco di rilievi non separabili — ho scelto il blocco.
- **Un rilievo NON VERIFICATO conteneva un'assunzione implicita sbagliata, trovata
  solo eseguendo sulla popolazione reale**: il fallback EAN→negozio (`Config.gs`,
  "ultime 4 cifre") suggeriva implicitamente che un fallback "corretto" fosse
  ricostruibile con una formula diversa. Prima di scrivere il fix ho verificato con
  node l'intera popolazione degli EAN già mappati (39 voci, non un campione) e trovato
  che la posizione delle cifre di codifica NON è uniforme — un EAN francese usa un
  offset diverso da quelli domestici. Nessuna formula affidabile esiste. Il fix è
  passato da "ricostruire la formula giusta" (quello che il rilievo suggeriva) a
  "fallire in modo esplicito e visibile" (fail loud) — una correzione diversa da
  quella implicita nel rilievo originale, scoperta solo eseguendo.

## Cosa ha retto / ostacolato

- **Ha retto** — l'"onore del non verificato" applicato anche in fase di fix: 12 dei
  25 fix correggevano un rilievo dichiarato NON VERIFICATO nella fase di analisi
  (fuori budget della verifica avversariale). In 2 casi (`TotalConsolidator`,
  `QuantityValidator` — SMENTITI in fase di analisi) la verifica precedente aveva già
  impedito un fix inutile/sbagliato: senza quella smentita, in questa fase avrei
  probabilmente "corretto" un problema che non esiste.
- **Ha retto** — l'esecuzione reale prima di ogni commit ha trovato un dettaglio che
  la sola lettura del rilievo non conteneva (vedi il fallback EAN sopra): l'assunzione
  implicita del rilievo, non solo il sintomo, era da verificare.
- **Ha ostacolato** — nessun ambiente Google Apps Script/Business Central eseguibile
  in questa sessione: ogni verifica è passata da `node --check` sui singoli file
  (copiati in scratchpad, mai modificati nel repo per il check) e da script che
  riproducono la logica pura estratta a mano dal sorgente reale (mai riscritta a
  memoria). Mai una vera esecuzione GAS con `LockService`/`DriveApp`/`GmailApp` reali:
  il fix del lock (contro la doppia elaborazione) e quello di `moveFile` (idempotenza)
  sono verificati solo a livello di logica di controllo con un mock, non contro il
  comportamento di concorrenza reale della piattaforma.
- **Ha ostacolato** — "un giro, un fix" (metodo.md, passo 5) non è quello che è
  successo: l'utente ha approvato in blocco tutti i 25 punti del piano e chiesto
  esplicitamente di procedere "un punto alla volta senza fermarti". È la stessa
  tensione già segnalata dal report REPO-K
  (`docs/campo/2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md`, §Proposta al canone,
  che a sua volta cita REPO-F) — **terza occorrenza** della stessa richiesta esplicita
  dell'utente con lo stesso esito (l'istruzione esplicita vince sulla cautela di
  default), su tre repo e tre sessioni diverse.

## Proposta al canone

- Il buco del "banco scritto al volo NON si butta" (sopra) non è isolato: anche la
  sessione REPO-K lo segnala implicitamente (script di verifica solo in memoria di
  sessione). Propongo di rendere esplicito, nel passo 6 di `revisore-gas.md`, che
  quando una sessione applica **più fix in sequenza** (non un giro singolo), gli
  script di verifica vanno accumulati in una cartella dedicata del repo target (es.
  `tools/verifiche-YYYY-MM-DD/`) invece che nello scratchpad di sessione — il costo di
  salvarli è quasi zero quando sono già scritti ed eseguiti.
- **Terza occorrenza indipendente della "sessione continua" su richiesta esplicita
  dell'utente** (dopo REPO-F e REPO-K, tre repo/utenti/sessioni diverse, stesso
  esito): non sembra più un caso isolato da dichiarare volta per volta. Propongo di
  canonizzarlo esplicitamente in `metodo.md` come terzo regime legittimo (accanto a
  "un giro alla volta" e "consegna con cancello umano"): l'istruzione esplicita
  dell'utente di non fermarsi tra un punto e l'altro del piano approvato sospende il
  passo 5 ("scegli UNO da correggere"), non la disciplina di verifica per singolo fix
  (che resta invariata, un fix alla volta con banco proprio).
- Un fix può scoprire che l'**assunzione implicita** di un rilievo (non solo il
  sintomo che descrive) è sbagliata, verificabile solo eseguendo sulla popolazione
  reale disponibile, non su un campione (vedi fallback EAN sopra). Propongo una riga
  in `metodo.md`, verbo CORREGGE: "prima di implementare il fix suggerito da un
  rilievo, verifica anche le assunzioni implicite del rilievo stesso sulla
  popolazione reale disponibile — un rilievo corretto sul sintomo può comunque
  suggerire una cura sbagliata."

## Riepilogo dei 25 fix (per severità)

Bug confermati con verifica avversariale (13): escape apici filtri OData (5 punti),
paginazione `@odata.nextLink`, escaping CSV verso `BC_Import`, `testEmailCubbageReport`
isolato dalla produzione, ripartizione trasporto EDIL (3 rilievi in un fix, vedi sopra),
release character EDIFACT, guardia CSV parser, `moveFile` idempotente, celle malformate
nel foglio regole quantità segnalate, prezzi BC negativi scartati, date di calendario
impossibili rifiutate.

Rilievi NON VERIFICATI ma corretti (6): `LockService` contro doppia elaborazione,
allerta email su errore critico, fallback EAN rimosso (vedi sopra), test prezzo con
asserzioni reali, test tautologico riscritto, retry differenziato su errori permanenti.

Igiene test (1): verdetti di 3 funzioni di test lanciati come eccezione invece di solo
loggati, con isolamento della suite (un fallimento in un sotto-test non abortisce gli
altri — principio già in `metodo.md`, applicato qui).

Coerenza documentale (2) e pulizia codice morto (1, con verifica grep di zero chiamanti
per ognuna delle 9+5+1+1+1 rimozioni prima di toccarle) più changelog/versione finale.

Non implementate, segnalate esplicitamente all'utente perché richiedono una decisione
di design non ricostruibile dal solo codice: persistenza token OAuth in `CacheService`
(rischio di loop di 401 se l'invalidazione è fatta male), un secondo canale di allerta
email (nessun canale alternativo disponibile in questo ambiente), overhaul del Logger
strutturato (decisione architetturale, non urgente).

Report di analisi: `docs/campo/2026-08-28-bricoman-50-agenti.md`.
PR con tutti i 24 commit: repo `Gestione-ordini-Bricoman`, branch
`claude/project-analysis-review-ryly0b`.
