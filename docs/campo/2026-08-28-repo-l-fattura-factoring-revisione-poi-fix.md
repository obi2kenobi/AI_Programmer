# 2026-08-28 — REPO-L, revisione a 30 agenti poi 14 fix in sessione continua

**Autore**: sessione Claude Code (Claude Sonnet 5)

## Cosa ho usato

- Il metodo letto DAVVERO prima di partire: clonato AI_Programmer in sola lettura,
  letti `gas-sviluppo/SKILL.md`, `references/metodo.md`, `references/famiglie-difetti.md`,
  `revisore-gas.md` — le lenti citate sono state incollate per intero nei prompt dei 21
  agenti di scoperta.
- **Adozione dello standard** nel repo target (piccolo progetto GAS + Business Central,
  9 file `.gs`, nessuno standard AI_Programmer presente prima): riprodotto a mano il
  comportamento di `tools/sync-repo.sh <repo> --standard` (CLAUDE.md, `.claude/skills`,
  `.claude/agents`, `.claude/settings.json` + hook, `patterns/`, `.night-verify`), aperto
  come PR separata. Escluso deliberatamente `docs/campo/` (report di sessione di ALTRI
  repo, non pertinenti al target) su richiesta esplicita dell'utente.
- **Workflow a 30 agenti** (21 scoperta + 9 verifica avversariale) invece del singolo
  agente `revisore-gas` — scala scelta esplicitamente dall'utente ("lanciassi 30 giri di
  revisione"), non dedotta da me. Ripartizione 70/30 (scoperta/verifica), simile al
  35/15 di REPO-J ma su una superficie molto più piccola (9 file `.gs`, ~500 righe,
  contro i ~12 file di REPO-J).
- Poi, **sessione continua sui fix**: l'utente ha approvato in blocco tutto il report e
  chiesto esplicitamente di procedere "senza fermarti" — terza occorrenza dello stesso
  regime già segnalato da REPO-F/REPO-K/REPO-J (istruzione esplicita che sospende il
  passo 5 "scegli UNO da correggere", non la disciplina di verifica per singolo fix).
  14 commit, uno per rilievo o cluster di rilievi non separabili nello stesso file,
  banco (`node --test`, gia' presente nel repo target) rilanciato dopo ogni fix.

## Cosa ho improvvisato

- **`gh` non disponibile in questa sessione**: `sync-repo.sh --standard` lo richiede
  (`gh api`, `gh repo clone`, `gh pr create`). Riprodotto lo stesso comportamento
  dichiarato dello script a mano con `git` + i tool MCP GitHub di questa piattaforma
  (clone in una cartella scratch, copia dei gruppi di file dichiarati, branch, commit,
  push, apertura PR). Nessuna divergenza nota rispetto a cosa avrebbe fatto lo
  strumento canonico, ma non e' lo strumento che ha girato davvero.
- **Verifica manuale PRIMA del workflow**: ho eseguito con `node` i costruttori di
  record del progetto target contro le righe reali "verificate con il committente"
  gia' presenti nella specifica del repo, prima di lanciare i 21 agenti — coerente con
  "esegui non dedurre", ma non e' un passo esplicito del canone farlo IO STESSO come
  operatore umano-in-loop prima di delegare. **Ha prodotto un falso positivo tutto
  mio**: avevo letto male il conteggio-documenti/l'importo dalla riga di esempio
  (offset di colonna sbagliati contati a occhio), concludendo erroneamente una
  discrepanza che non c'era. Corretto risliceando gli offset con precisione. Nota per
  il canone: *"un banco rosso che conferma il sospetto con cui l'hai scritto si crede"*
  vale anche quando il banco lo scrive l'operatore umano prima di delegare, non solo
  un sub-agente.
- **Un secondo segreto reale** (stesso `client_secret` di un primo file già rimosso,
  non un secondo segreto diverso) e' emerso DURANTE il workflow di scoperta, in un
  file mai notato dalla mia ispezione manuale preliminare del repo, presente in 7
  commit della history di `main` prima di essere rimosso in un commit successivo.
  Dichiarato all'utente con file:commit precisi, MAI il valore, nessuna rotazione
  proposta da me — la decisione (ruotare il segreto, ripulire la history) resta
  dell'utente, coerentemente con "segreti: mai il valore, mai proporre rotazione, si
  prosegue e si dichiara".
- **Un fix scartato di mia iniziativa in fase di correzione** (non un rilievo del
  workflow, ma la mia stessa lettura durante l'implementazione): il rilievo suggeriva
  di far fallire il caricamento dello script se un segreto risultava assente/vuoto in
  Script Properties. Implementarlo alla lettera avrebbe reso impossibile il primo
  avvio della funzione di setup dei segreti (che DEVE poter girare prima che i segreti
  esistano) — un caso concreto, scoperto solo verificando l'assunzione implicita
  prima di scrivere il fix, non leggendo il rilievo.

## Cosa ha retto / ostacolato

- **Ha retto** — l'"onore del non verificato": 54 rilievi grezzi, 9 verificati
  avversarialmente per budget (0 smentiti), 45 dichiarati non verificati senza essere
  promossi. In fase di fix ho comunque corretto molti dei 45 quando l'evidenza nel
  rilievo era già un comando+output eseguibile e il fix era minimale/senza decisioni
  di dominio: nessuno si e' rivelato falso durante l'implementazione (verificato coi
  test aggiunti, banco verde prima E dopo per ognuno).
- **Ha retto** — verificare l'esempio "reale" del committente PRIMA di lanciare il
  workflow ha dato ai 21 agenti di scoperta un fatto assodato da NON ri-verificare
  (dichiarato esplicitamente in ogni prompt), risparmiando budget che altrimenti
  sarebbe finito a ri-controllare la stessa cosa 21 volte.
- **Ha ostacolato** — nessun accesso a `gh` in questa sessione (vedi sopra): stesso
  tipo di muro già segnalato da REPO-J per `clasp`/OAuth Google, stavolta per GitHub
  CLI. Qualunque sessione onboardata su un repo target sconterà lo stesso limite finché
  lo strumento non distingue esplicitamente "repo privata senza accesso" da "`gh`
  assente" nel proprio messaggio d'errore (oggi sono lo stesso messaggio: bisogna
  leggere lo script per saperlo).
- **Ha ostacolato (lieve)** — l'adozione dello standard e la richiesta di revisione
  sono arrivate nello stesso turno utente, in un ordine che non rispecchia la sequenza
  naturale del canone ("Lo standard non è un'opzione" prima, poi ANALIZZA). Ho dovuto
  fermarmi per due domande esplicite (grado di adozione dello standard, interpretazione
  letterale di "30 giri") prima di poter procedere — non zero domande, anche se la
  richiesta nominava già esplicitamente sia l'hub sia il numero di giri.

## Proposta al canone

- **Conferma indipendente di una regola già in metodo.md** (sezione REPO-J,
  "verifica le assunzioni implicite di un rilievo prima di implementare il fix
  suggerito"): qui la regola ha impedito un fix dannoso in un contesto dove il
  "rilievo" non era nemmeno un rilievo del workflow, ma la mia stessa osservazione
  durante la fase di correzione. Propongo di generalizzare la riga in metodo.md
  togliendo il riferimento implicito a "un rilievo altrui": vale anche per le proprie
  osservazioni fatte mentre si corregge.
- Propongo che `sync-repo.sh` (o il suo messaggio d'errore) distingua esplicitamente
  "`gh` assente in questa sessione" da "repo privata senza accesso" — oggi e' lo stesso
  messaggio (`impossibile leggere CLAUDE.md da REPO (repo privata senza accesso, o gh
  assente)`), e la sessione ha dovuto leggere lo script per scoprire quale dei due
  fosse il caso reale prima di poter improvvisare l'equivalente a mano.
- Nessuna proposta sulla proporzione 21/9 (scoperta/verifica) del workflow: si e'
  comportata bene su una superficie piccola, ma un solo campione non basta a proporre
  una formula generale (stessa cautela già espressa da REPO-G sulla convergenza).
