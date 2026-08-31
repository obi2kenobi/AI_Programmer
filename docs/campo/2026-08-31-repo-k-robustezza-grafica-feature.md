# 2026-08-31 — REPO-K, seconda sessione: 200 giri robustezza+grafica, 4 feature proposte e costruite, clasp in produzione

**Autore**: sessione Claude Code (continuazione diretta della sessione REPO-K del
2026-08-28 — stesso repo, stesso utente, git history continua)

## Cosa ho usato

- **Metodo a lenti concordato con l'utente**, non una skill di questo hub: la
  richiesta originale ("100 giri robustezza + 100 giri grafica, con tooltip
  ovunque") è stata negoziata con `AskUserQuestion` in due punti — quale repo
  (SD Web Dashboard, non l'altro repo GAS della stessa sessione) e quale
  metodo di esecuzione (passo-passo a batch progressivi, non un `Workflow`
  multi-agente). L'esecuzione reale: 5 "lenti" sequenziali sul codice esistente
  (concorrenza, validazione, errori silenziosi, logica di business
  EDIL/Pellet/Legna, duplicazione), poi 2 lenti grafiche (coerenza visiva,
  tooltip), poi 4 nuove funzionalità — proposte con `AskUserQuestion`
  (multiSelect, tutte e 4 scelte) PRIMA di scrivere una riga, come da
  istruzione esplicita dell'utente in CLAUDE.md del repo target.
- gli check temporanei di sessione (check.sh e checkjs_html.sh sotto /tmp/gascheck) (già esistenti da questa
  sessione) su ogni file `.gs`/`.html` toccato, prima di ogni commit.
- `check-duplicate-functions.js` del repo target — riusato come "lente 13"
  gratuita (nessuna funzione top-level duplicata).
- GitHub via MCP (`create_pull_request`, `subscribe_pr_activity`) per la PR
  finale: nessuna skill `lavoro-condiviso`/`allineamento-fork` di questo hub,
  perché REPO-K non è onboardata a questo hub (workflow git puro).
- Il trucco FIFO per `clasp login --no-localhost` non-interattivo, già usato
  nella prima sessione REPO-K — riusato per un token scaduto a metà lavoro
  (vedi sotto).

## Cosa ho improvvisato

- **Il sistema di tooltip non esisteva per metà — l'ho scoperto solo
  leggendo il markup, non l'ho inventato dal nulla.** Il dossier originale
  (prima sessione) aveva già lasciato `data-tooltip="..."` su 12 elementi
  (i bottoni tab), ma zero CSS o JS li rendeva visibili — erano attributi
  HTML inerti. L'ho scoperto grepando `data-tooltip` in Styles.html/Scripts.html
  e trovando zero risultati mentre dashboard.html ne aveva 12. Ho costruito
  il motore CSS (`[data-tooltip]::after`/`::before`, hover+focus-visible) UNA
  VOLTA e poi esteso la copertura, invece di presumere che "tooltip ovunque"
  volesse dire scrivere 40 tooltip a mano senza motore.
- **Decisione di NON estendere `LockService` a `bulkConfirmFromCSV`**: la
  lente concorrenza aveva appena aggiunto lock su
  `Database.updateFieldsVerified`/`updateAllRowsVerified` (Database.gs). Il
  riflesso sarebbe stato applicare lo stesso lock ovunque scriva sul foglio.
  Letto il codice di `bulkConfirmFromCSV`, ha già una strategia di
  concorrenza ottimistica scritta a mano (rilettura fresca della riga +
  rilevamento ANNULLATO-nel-frattempo, con commenti che la documentano). Un
  lock globale attorno a un'operazione che invia email e crea file Drive
  (minuti, non millisecondi) avrebbe bloccato OGNI altra scrittura sul
  foglio per tutta la durata — peggio del problema che risolveva.
  `LockService.getScriptLock()` è per-script, non per-riga: non l'avevo
  presente finché non ho dovuto guardare il sync BC (sotto).
- **Guardia anti-sovrapposizione sul sync BC senza `LockService` esteso**:
  stesso ragionamento sul sync BC (bottone manuale + trigger ogni 4h possono
  sovrapporsi, entrambi possono durare minuti). Ho usato lo script lock SOLO
  per il check-and-set atomico di un flag su `ScriptProperties` (una
  frazione di secondo), non per l'intera sincronizzazione — altrimenti
  avrebbe fatto scadere in timeout ogni `updateFieldsVerified` di ogni
  operatore per tutta la durata del sync.
- **`bulkChangeDate` per delega, non per duplicazione**: la nuova feature
  "modifica data in blocco" poteva reimplementare la logica di scrittura
  (lock, verifica, righe multiple EDIL/Legna, email). L'ho invece scritta
  come un loop che chiama `changeDate()` esistente un ordine alla volta —
  zero logica di business duplicata, un fallimento su un ordine non blocca
  gli altri, e ogni ordine riceve comunque la sua mail (comportamento
  atteso lato business, non un compromesso tecnico).
- **Login clasp scaduto A META LAVORO**, non all'inizio: `clasp push` ha
  fallito con `invalid_grant`/`invalid_rapt` (Google richiede ri-auth
  periodica, non prevedibile). Ho dovuto rifare l'intero flusso FIFO — e
  la SECONDA volta è andata storta per un motivo nuovo (sotto).

## Cosa ha retto / ostacolato

**Ha retto**: la disciplina "lente per lente, non tutto insieme" ha
prodotto rilievi VERI, non rumore — 5 bug reali in 5 lenti, zero falsi
positivi corretti poi rollbackati. Esempio concreto della lente
validazione: `Config.gs` `validation.allowedNoteValues` mancava PRENOTATO,
CONFERMATO, SPEDITO ecc. rispetto a `STATUS_BADGE_CLASSES` in Scripts.html
(stessa informazione, due fonti, disallineate) — trovato SOLO perché la
lente mi ha fatto leggere entrambe le fonti nello stesso giro invece di
fidarmi della prima trovata. Lo stesso pattern (due fonti di verità che
divergono silenziosamente) era già nel catalogo famiglie (references/famiglie-difetti.md) di questo hub,
ma qui è la CONFERMA in un secondo punto del codice, non solo nel primo giro.

**Ha ostacolato — nuovo, non nel catalogo**: il trucco FIFO per il login
OAuth non-interattivo (holder che tiene la fifo aperta in scrittura +
`clasp login < fifo` che legge) si è rotto al SECONDO utilizzo per un
motivo diverso dal primo. Avevo lanciato holder e `clasp login` con
`nohup ... & disown` dentro una singola chiamata Bash — funzionava nella
prima sessione. Questa volta, la chiamata Bash successiva (quella che
scrive l'URL nella fifo) non vedeva più né l'holder né il processo
`clasp login`: **spariti silenziosamente tra una chiamata Bash e
l'altra**, nonostante `disown`. La scrittura sulla fifo restava quindi
bloccata all'infinito (nessun lettore), e quando ho ripetuto il tentativo
con un nuovo `clasp login` (nuovo `state` OAuth), la vecchia scrittura
bloccata dal tentativo precedente si è infine sbloccata (un lettore era
finalmente comparso) e ha consegnato l'URL VECCHIO, con lo `state`
sbagliato — `Authorization rejected: state parameter mismatch`. Un
fallimento silenzioso doppio: non un errore immediato, ma una race
condition fra due tentativi di login che si mescolano. **Risolto** usando
il parametro nativo del tool Bash stesso (`run_in_background: true`) per
holder e `clasp login`, invece di `nohup`/`disown` manuali — quei processi
sono tracciati dall'harness e sopravvivono deterministicamente tra chiamate
separate, mentre i processi backgrounded a mano nella shell no.

## Proposta al canone

Un pattern nuovo, ma senza un'àncora di codice in QUESTO hub (l'evidenza
vive nella sessione REPO-K, non in un file di questo repo) — lo dichiaro
qui invece di forzare una voce in `patterns/` senza ancora reale:

> **Login OAuth non-interattivo via FIFO: usa il backgrounding nativo del
> tool, mai `nohup ... & disown` manuale.** Quando un flusso richiede un
> processo persistente che sopravviva a PIÙ chiamate separate dello
> strumento di esecuzione comandi (qui: l'holder della fifo + `clasp login`
> che aspetta l'URL in un secondo momento), il backgrounding manuale in
> shell (`nohup`, `disown`, `&`) non è affidabile attraverso chiamate
> separate — i processi possono sparire silenziosamente. Il meccanismo di
> backgrounding NATIVO dello strumento (qui: `run_in_background: true` di
> Claude Code) è tracciato e sopravvive deterministicamente. Vale per
> qualunque handshake multi-turno con un CLI che richiede input umano a
> metà (login OAuth di `clasp`, ma la forma è generale).

Se questo pattern si ripete una terza volta in un repo GAS onboardato a
questo hub, merita una voce vera in `patterns/` con l'àncora al comando
reale in quella sessione.
