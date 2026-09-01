# 2026-09-01 — Golilla: due campagne di audit (6 giri), "decidi tu su tutto", un incidente in produzione e il suo post-mortem

**Autore**: sessione Claude Code (remota, claude-sonnet-5) — proprietario del repo: Luca

## Cosa ho usato

- Skill `gas-sviluppo` (`references/famiglie-difetti.md` come lente) — letta però via `Read`
  diretta dai sub-agenti, non con lo strumento Skill: l'agente `revisore-gas` non ha il tool
  `Skill` in dotazione (solo `Read`/`Grep`/`Glob`/`Bash`).
- Agente `revisore-gas` per il censimento read-only per dominio: 6 istanze in parallelo nella
  seconda campagna (Golilla core, MdI, DTE+Arco, logistica interna, infrastruttura BC,
  frontend/webapp), dopo una prima campagna (3 giri) fatta con agenti `general-purpose` +
  verifiche avversariali dedicate.
- Skill `post-mortem` (installata nello standard di questo repo, mai usata prima in Golilla
  con l'infrastruttura completa): applicata in forma RIDOTTA, direttamente dentro `SAL.md`,
  perché `docs/errori/REGISTRO.md` non esiste ancora in Golilla — non l'ho creato di mia
  iniziativa, l'ho dichiarato come limite (stesso trattamento già usato per un post-mortem
  precedente nella stessa sessione, SAL §83).
- Nessun oracolo `tools/*.py` esiste per le formule di riconciliazione fattura di Golilla
  (DTE/Arco/MdI/Golilla): dove il mandato ("decidi tu su tutto") avrebbe richiesto di
  inventare una soglia finanziaria (accessori DTE mai verificati), ho rifiutato esplicitamente
  di indovinarla — vedi sotto.

## Cosa ho improvvisato

- **Partizione manuale in 6 gruppi di file per dominio** per la seconda campagna (Golilla/MdI/
  DTE+Arco/logistica-interna/infrastruttura-BC/frontend): nessuno strumento di questo hub
  partiziona automaticamente un progetto GAS di ~90 file per audit parallelo a questa scala.
- **"Decidi tu su tutto"**: l'utente, dopo il riepilogo di 6+3 domande di dominio aperte a fine
  seconda campagna, ha delegato esplicitamente la decisione invece di rispondere lui. Nessuna
  skill di questo hub copre "l'utente delega la decisione invece di scioglierla lui" — ho
  trattato ogni domanda caso per caso: quelle risolvibili con difesa-in-profondità (aggiungere
  un gate di autenticazione senza cambiare comportamento per l'utente legittimo) le ho decise e
  implementate; quella che richiedeva un dato reale che non avevo (un codice cliente BC per
  estendere una feature a nuovi negozi) l'ho decisa a livello di policy ma dichiarata bloccata
  sui dati, non sul giudizio; quella che avrebbe richiesto inventare una soglia finanziaria
  l'ho rifiutata esplicitamente, citando il vincolo di metodo ("oracolo prima della formula")
  come ragione — non timidezza.
- **Nuovo codice condiviso per azioni sensibili non-camion**: il progetto aveva già un pattern
  (`CODICE_SBLOCCO` per i viaggi camion) ma nessun equivalente per gli endpoint finanziari
  scoperti dall'audit (extra-costi, impostazioni suggeritore, commit fatture corriere). Ho
  esteso lo STESSO pattern (un PIN condiviso in config, verificato server-side) invece di
  inventare un meccanismo nuovo — riuso deliberato di una convenzione già presente nel repo,
  non un nuovo standard.
- **Verifica di copertura post-hoc**: `diff` fra la lista di file assegnata ai 6 agenti e
  l'elenco reale di `apps_script/*.gs *.html` — ha trovato un file mai assegnato
  (`AnalisiCorrieri2026.gs`), che si è rivelato NON morto (raggiunto in produzione via
  `CartelliniCorriere.gs`) e con un bug reale (gate di candidabilità stale rispetto al
  suggeritore live). Nessuna skill richiede questo controllo esplicitamente.

## Cosa ha retto / ostacolato

**Ha retto**:
- La verifica avversariale ripetuta a ogni giro (agente fresco che rilegge senza fidarsi del
  commit message) ha trovato problemi reali in OGNI giro in cui è stata applicata: nella prima
  campagna un fix che riproduceva il bug uno scalino più in là (isolamento notifiche MdI); nella
  seconda, 3 problemi di severità bassa su 10 correzioni (uno accettato come rischio residuo
  dopo analisi esplicita — un lock condiviso che tiene una chiamata di rete, difetto reale ma
  la correzione completa avrebbe richiesto un mutex che `LockService` di Apps Script non offre).
- La risposta a una domanda di dominio era in un punto che nessuno aveva ancora letto: il
  commento a `Config.gs:PROVINCE_DIRETTA` dichiarava esplicitamente "usata SOLO per
  raggruppamento retrospettivo, il suggeritore non limita più camion/SCUDO a queste province" —
  eseguire `grep`/lettura vera invece di dedurre ha trasformato una "domanda di dominio aperta"
  in un fatto verificabile, senza bisogno di chiedere all'utente.
- 6 agenti paralleli indipendenti, senza coordinarsi, hanno trovato la STESSA classe di difetto
  (endpoint webapp che si fida del payload client) su ~9 endpoint diversi in 6 domini diversi —
  segnale forte che la lente famiglie-difetti.md generalizza bene anche senza cross-talk fra
  agenti.

**Ha ostacolato / ha fatto danno reale — l'incidente**:
- Nel giro "decidi tu su tutto" ho scritto una nota HTML lunga, in italiano discorsivo, dentro
  un literal JS a apici singoli (`Dashboard.html`), con un apostrofo NON escaped
  (`nell'esito`). Il parser ha chiuso la stringa a metà frase e ha trovato `esito` come
  identificatore isolato: `SyntaxError` che ha invalidato l'INTERO script inline della pagina,
  non solo quella riga — la Dashboard in produzione ha smesso di caricare qualunque dato, subito
  dopo il deploy. **Nessuna delle verifiche fatte in quel giro l'ha preso** (la verifica
  avversariale dedicata ha letto il diff riga per riga per la LOGICA, non ha eseguito il
  JavaScript risultante). L'ho scoperto solo perché l'utente ha incollato l'errore di console
  dopo aver già deployato in produzione (clasp push già fatto). Fix a un carattere, ma il
  tempo-a-scoperta è stato "dopo il deploy in produzione", non prima del merge — il caso
  peggiore per questa classe di errore. Post-mortem completo (7 campi) in
  `SAL.md` §91 del repo Golilla, guardia verificata per davvero (riproduce il crash sul
  commit rotto, pulita su quello corretto): `node --check` sull'intero script inline estratto
  da `Dashboard.html`, PRIMA di ogni consegna che tocchi quel file — non bastava leggere il
  diff.

## Proposta al canone

1. **Gap di lente misurato**: `famiglie-difetti.md` copre difetti di LOGICA (scope globale,
   paginazione, lock, ecc.) ma nessuna famiglia copre "sintassi rotta dentro una stringa
   letterale lunga in un file HTML/JS con script inline" — un difetto banale da correggere ma
   capace di rompere il 100% di una webapp, invisibile alla sola lettura del diff (un umano
   legge il SENSO della frase italiana, non conta gli apici). Proposta concreta: per QUALUNQUE
   consegna che tocca un file `.html` con `<script>` inline (pattern comune nei progetti GAS di
   questo hub — dashboard web), la fase di verifica deve includere un controllo sintattico
   eseguito (`node --check` sullo script estratto, o equivalente), non solo la lettura del diff.
   Questo vale sia per l'agente che corregge sia per l'agente di verifica avversariale — in
   questo incidente NESSUNO dei due l'ha fatto.
2. **L'agente `revisore-gas`** (`.claude/agents/revisore-gas.md`) ha in dotazione solo
   `Read`/`Grep`/`Glob`/`Bash`, ma la sua descrizione promette di "consegnare diff con prova di
   parità" — con questo toolset non può scrivere un diff, solo riportarlo in prosa/snippet.
   Non bloccante (il fix lo applica comunque chi orchestra), ma descrizione e toolset sono
   disallineati — o si aggiunge Edit in sola-lettura-poi-diff-file, o la descrizione smette di
   promettere "diff" e dice "riporta il fix in prosa, il diff lo applica chi orchestra".
3. **"Decidi tu su tutto"** come pattern non coperto da nessuna skill: quando l'utente delega
   esplicitamente una decisione di dominio invece di risponderla, il criterio che ho usato
   (implementare se difesa-in-profondità/reversibile/non richiede dati inventati; dichiarare
   bloccato-sui-dati se serve un valore reale che non ho; rifiutare esplicitamente se
   richiederebbe indovinare una formula di business) non è scritto da nessuna parte — è la
   stessa tensione di `/design-doc` ("la scelta resta sempre di chi possiede il progetto") ma
   per il caso in cui chi possiede il progetto dice esplicitamente "no, scegli tu". Proposta:
   una nota in `brainstorming`/`design-doc` che tratti esplicitamente questo caso, con lo stesso
   criterio triage sopra, invece di lasciarlo improvvisato ogni volta.
