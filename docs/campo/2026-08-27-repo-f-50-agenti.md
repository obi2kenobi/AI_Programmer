# 2026-08-27 — audit REPO-F con fan-out 50 agenti + 20 correzioni

**Autore**: sessione Claude Code (Claude Sonnet 5), lavoro su REPO-F (dashboard GAS +
Business Central con `Dashboard.html`, gia' citato in SAL.md 2026-08-24 per il caso
backfill/trigger) — **codice repo non confermato dall'interno della sessione**: non ho
accesso a `night-shift/repos.key`, la corrispondenza e' dedotta dalla descrizione in
`night-shift/repos-index.md` (Dashboard.html + GAS/BC + flusso consegne). Confermare
prima di considerare questo report processato.

## Cosa ho usato

- AI_Programmer clonato in sola lettura (anonimo, `git clone` pubblico — questa sessione
  non aveva il repo onboardato) per orientarmi: `README.md`, `METHOD.md`, l'agente
  `.claude/agents/revisore-gas.md` (letto per intero, e' il mandato che ho seguito),
  `revisore-calcoli-critici.md`, la skill `gas-sviluppo` (`SKILL.md`,
  `references/metodo.md`, `references/famiglie-difetti.md`, `references/domini-gestionali.md`),
  il registro `patterns/README.md`.
- `tools/gas_qualita.py`, eseguito DAVVERO contro la working directory di REPO-F (non
  letto e basta): 15 file .gs/.js, 25 siti su 9 famiglie, 4 famiglie sopra zero. Usato
  come lead per gli agenti di ricerca, mai come verdetto — coerente con quanto il tool
  stesso dichiara in testa.
- NON ho invocato `revisore-gas`/`revisore-calcoli-critici` come sub-agenti Claude Code
  veri: questa sessione non aveva il roster di agenti di un repo esterno non onboardato.
  Ho invece distillato il loro canone (i quattro verbi, le famiglie di difetti, "esegui
  non dedurre") dentro i prompt di un `Workflow` multi-agente scritto da zero: mappa di
  raggiungibilita' → 12 lenti di ricerca indipendenti su 2 giri → verifica avversariale
  di OGNI singolo rilievo (un secondo agente prova a refutarlo rileggendo il codice) →
  critica di completezza → migliorie/funzionalita' separate. 50 agenti, 895 comandi,
  ~4,2M token.
- NON ho usato `tools/verifica_banco.py` ne' la disciplina "banco scritto PRIMA" in modo
  sistematico: le verifiche numeriche (vedi sotto) le ho fatte con script Node ad-hoc,
  non con un banco strutturato PARITA'+CORREZIONE come prescrive il canone.

## Cosa ho improvvisato

- Il metodo REPO-E prescrive un giro: censimento → **UNO** scelto da correggere per
  giro, il resto ancorato al giro dopo. L'utente ha chiesto esplicitamente di correggere
  "tutti, uno per volta, senza fermarti": ho quindi corretto 20 rilievi su 22 nella
  stessa sessione lunga, un commit per rilievo, invece di un giro-uno-fix-alla-volta su
  piu' sessioni. Non so se il canone lo vieti esplicitamente, ma e' una deviazione
  dichiarata dal "sequenziale a bassa velocita'" che il metodo descrive.
- **Pattern gia' documentato in REPO-F stesso che ho quasi violato prima di leggerlo**:
  `AccessoWeb.gs` di REPO-F dice esplicitamente "la guardia si chiama nel PONTE, mai
  nella funzione condivisa che il ponte usa: X e Y sono ponti E percorsi dei trigger
  notturni, una guardia li dentro li spegnerebbe in silenzio" — e cita un incidente
  reale gia' successo (2026-08-15, due correzioni scartate). Stavo per mettere la
  guardia di identita' direttamente dentro due funzioni condivise con i trigger,
  seguendo un pattern che avevo appena applicato con successo su 8 altre funzioni senza
  quel vincolo; solo leggendo il commento per intero (non a diagonale) ho evitato
  l'errore, creando invece un ponte guardato separato (`<funzione>Web(...)`) che
  richiama la funzione condivisa non guardata. Non e' un pattern che ho inventato: e'
  un pattern che il progetto stesso gia' dichiarava, e che ho rischiato di ignorare.
- **Safety gate opt-in per test manuali senza fixture di scratch**: 4 funzioni `test*`
  scrivevano/spedivano email su dati di produzione (nessun foglio/risorsa isolata a cui
  redirigerle esiste nel progetto). Il corpus (`famiglie-difetti.md`, "test che
  SPORCA la produzione") descrive il difetto ma non prescrive la cura quando isolare la
  risorsa non e' un'opzione a basso costo. Ho aggiunto un parametro booleano esplicito
  (es. `scriviSuProduzione=true`) che ferma l'esecuzione di default: in Apps Script il
  pulsante "Esegui" dell'editor chiama sempre a ZERO argomenti, quindi il default-safe
  blocca l'esecuzione accidentale senza impedire l'uso deliberato (si passa `true` da
  un'altra funzione o dalla console). Non l'ho trovato descritto nel corpus.
- Ho rifiutato di correggere 2 rilievi su 22 (uno critico per gravita' economica —
  formula Effetto Volume/Prezzo instabile a giacenza base piccola — uno alto —
  due nomi diversi per la stessa ubicazione assente) perche' la correzione "ovvia" per
  il secondo era gia' stata provata una volta in REPO-F e revertata sui dati BC reali
  (banco rosso dichiarato dal commit stesso), e il primo richiede una scelta di metodo
  contabile (quale soglia? quale periodo di riferimento per il prezzo?) che non e' un
  bug meccanico con un'unica correzione ovvia. Li ho lasciati bloccati con nota nel
  codice invece di indovinare — anche sotto pressione esplicita dell'utente di "non
  fermarsi".

## Cosa ha retto / ostacolato

- **Ha retto — "esegui non dedurre"**: la scoperta che due file di REPO-F
  (`WebAppDashboard.gs`, `Dashboard.html`) contengono un vero byte NUL (0x00, non la
  sequenza testuale `\x00`) dentro una stringa letterale — usato come separatore di
  chiave — e' arrivata SOLO eseguendo `python3 -c "...data.find(b'\x00')..."` a livello
  di byte, non leggendo il file con `Read`/`grep`. Confermato indipendentemente da un
  secondo lato: un agente della fase di raggiungibilita' del Workflow ha scoperto da
  solo, durante il proprio lavoro, che il tool `Grep` (ripgrep) di questa sessione
  restituiva 0 risultati per un pattern presente in quei due file (una chiamata reale
  gli risultava "assente" con `Grep`, presente con `grep -a` diretto) — lo stesso lead,
  trovato due volte, da due lati diversi, senza che i due agenti si parlassero.
- **Ha retto — la domanda discriminante, non solo la forma**: `gas_qualita.py` segnalava
  `key` come "nome globale in ombra" fra 2 file (famiglia misurata: 22 divergenti su 93
  nel parco, sintomo "totale 0/NaN senza eccezione"). La critica di completezza del
  Workflow ha verificato a livello di byte-scope che in ENTRAMBI i siti `const key` e'
  locale a una funzione (block-scoped), non un globale: nessuna ombra reale, falso
  positivo dello strumento meccanico. Senza la domanda discriminante ("stesso corpo e
  stessa firma?" — qui la domanda vera era piu' a monte: e' davvero globale?) l'avrei
  inseguito come un rilievo vero.
- **Ha ostacolato — nessun ambiente GAS eseguibile**: questa sessione non ha un progetto
  Apps Script live ne' accesso a Business Central reale. Ogni verifica "esegui non
  dedurre" su una formula/regex/parsing l'ho dovuta fare RIPRODUCENDO la logica in un
  mini-script Node isolato (trascritta riga per riga dalla funzione vera, non importata),
  mai eseguendo la funzione originale. E' un banco sintetico sulla trascrizione, non un
  banco sulla funzione vera — il rischio di trascrivere male esiste, anche tenendo la
  trascrizione minima e confrontata riga per riga col sorgente. Per il nuovo test
  `testValuationEngineCalculations` (9 casi, motore di valorizzazione) ho comunque
  eseguito la STESSA identica logica in Node prima di scriverla nel `.gs`, per lo stesso
  motivo.
- **Ha ostacolato — nessun dato BC reale**: i due rilievi lasciati aperti (vedi sopra)
  sono aperti esattamente per questo: uno richiede l'elenco vero delle ubicazioni BC,
  l'altro una decisione di metodo contabile che solo chi conosce i dati reali puo' dare.

## Proposta al canone

- Il pattern "guardia nel ponte pubblico separato, mai nella funzione condivisa con un
  trigger" meriterebbe una voce in `patterns/` dell'hub con ancora in REPO-F
  (`AccessoWeb.gs`, il commento che lo dichiara e cita l'incidente 2026-08-15): e'
  generalizzabile a qualunque progetto GAS con webapp anonima + trigger che condividono
  una funzione scrivente, ed e' un errore facile da ripetere (io stesso l'ho quasi
  ripetuto, nonostante il progetto lo dichiarasse esplicitamente altrove nello stesso
  repo — leggerlo non basta se non lo si cerca prima di scrivere).
- `famiglie-difetti.md` potrebbe guadagnare una voce "test manuale che scrive su
  produzione senza un foglio/risorsa di scratch disponibile", con la cura del parametro
  opt-in default-safe (sfrutta che l'editor Apps Script chiama sempre a zero argomenti)
  come alternativa quando isolare la risorsa non e' un'opzione a basso costo.
- Non ho una proposta sul punto "un giro, un fix scelto, il resto al giro dopo" vs
  "tutti in una sessione su richiesta esplicita dell'utente": lo segnalo come domanda
  aperta per chi processa questo report, non come proposta gia' formata.
