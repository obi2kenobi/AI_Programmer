# La mappa del sistema — AI_Programmer come base di sviluppo globale

> Assemblato il 2026-08-21. Ogni vincolo porta la sua provenienza: cosa è misurato,
> cosa è deciso, cosa è un limite dichiarato di strumenti di terzi. Niente promesse vuote.

```
┌───────────────────── AI_Programmer (hub, PUBBLICO) ─────────────────────┐
│ L0 BASE      CLAUDE.md (regole Karpathy §1-6 + §7 delega) · PROJECT.md  │
│              multi-progetto · conoscenza docs/bc · SAL.md · fabbrica    │
│ L1 CERVELLI  llm/ask-qwen (locale) · ask-opus (claude -p) · ask-glm    │
│              (API opzionale) — contratto unico, matrice in llm/README  │
│              router/ WayfinderRouter: tessuto per OpenCode, route       │
│              nominate @route/night @route/digest                       │
│ L2 LAVORO    giorno: sessioni dirette + deleghe llm/ask-*              │
│              notte: night-shift 23:00 multi-repo (repos.conf LOCALE)   │
│ L3 GIUDIZIO  morning-gate: verifiche dichiarate + banco avversariale   │
│              + proposte correttive (sì umano obbligatorio)             │
│ L4 MEMORIA   SAL.md + metrics/gate.csv → le decisioni future le        │
│              decidono i dati accumulati, non le opinioni               │
└─────────────────────────────────────────────────────────────────────────┘
```

## Chi fa cosa, e perché

| Ruolo | Chi | Provenienza della scelta |
|---|---|---|
| Cervello giorno primario | ZCode / GLM 5.3 | sessione diretta |
| Cervello giorno profondo | Claude Code / Opus 5 | **Limite verificato**: Wayfinder non implementa l'outbound Anthropic (letto nei sorgenti, non presunto) — Opus resta diretto, `ask-opus` via `claude -p` (auth nel Keychain SUL MAC: funziona da terminale utente e launchd, non da shell sandbox locale; **una sessione cloud ha auth propria e risponde davvero** — verificato 2026-08-22, vedi `llm/ask-opus.sh`) |
| Braccia notturne | Qwen3.8-27B Q4_K_M via Ollama | batteria qualità 4/4 pari alla Q5, 3,7-5,9 tok/s, margine RAM (misure 2026-08-18) |
| Tessuto di routing | WayfinderRouter 2026.8.0 | solo-locale per scelta (Luca 2026-08-21); il turno notturno NON dipende dal router — garanzia «nessun punto di failure singolo» |
| Giudice/censore/correttore | REPO-A + morning-gate | il metodo del Supervisore (banco che smentisce) applicato alle PR del sistema |
| Memoria | SAL.md + metrics/gate.csv | regola del repo: ciò che un giro insegna si scrive prima del giro successivo |

## Limiti dichiarati (cosa il sistema NON fa, oggi)

1. **Opus non passa dal router** — outbound Anthropic assente in Wayfinder (2026-08)
2. **ask-glm** richiede `ZHIPUAI_API_KEY`; endpoint non testato né da Wayfinder né da noi.
   Via naturale: sessione ZCode
3. **Apple Foundation Models**: rimandato — superficie sperimentale (2026-08)
4. **Il modello locale non converge sui giudizi**: tre notti di prove (#363 su REPO-A).
   Le indagini restano ai cervelli di giorno
5. **Le repo private non si nominano nel repo pubblico**: `repos.conf` è locale e gitignored
6. **`.claude/agents/` — invocabilità dipende da un refresh del roster, non solo dai
   file (verificato dal vivo due volte, con esiti diversi)**: un primo tentativo REALE
   di invocare `contabilita-analitica` (set 1 giro 8, stesso giorno) è stato rifiutato
   con "Agent type non trovato" subito dopo il commit dei tre file — il roster degli
   agenti disponibili in quella sessione era rimasto quello di apertura sessione. Un
   secondo tentativo, più tardi lo stesso giorno (dopo il push e l'apertura della PR
   #35), ha invocato con successo tutti e tre gli agenti — il roster si era
   aggiornato nel frattempo. Non è chiaro DA COSA dipenda il refresh (nuova sessione?
   push al branch remoto? un intervallo di tempo?) — non riverificato con un
   esperimento isolato, quindi non presumerlo. Conseguenza pratica: `.claude/agents/`
   funziona, ma non è garantito che sia invocabile nella stessa sessione/turno in cui
   i file vengono creati — se un'invocazione fallisce con "Agent type non trovato"
   subito dopo aver scritto un nuovo agente, non è necessariamente un bug del file,
   riprova più tardi o in una sessione nuova prima di concludere che non funzioni.
   Anche OpenCode (ZCode, turno notturno) restava fuori scope — **AGGIORNATO 6°
   ciclo, set 3 (2026-08-24): chiuso per la parte agenti**: `.opencode/agent/`
   ora specchia i 5 agenti di `.claude/agents/` con corpo identico per contratto
   (guardia: `tests/test-opencode-agent-sync.sh`) e bootstrap/onboard propagano
   anche quella cartella. La parte Claude Code del limite (refresh del roster)
   resta valida.

## La fabbrica

- `tools/bootstrap-app.sh <nome>` — repo nuova col sistema pre-cablato
  (regole ereditate, PROJECT.md stub, label night-shift, `.night-verify` dichiarato)
- `tools/onboard-repo.sh <owner/repo>` — repo esistente dentro il sistema
  (label, repos.conf, `.night-verify` da riempire)

## Il ciclo completo (come si chiude)

```
commessa (issue night-shift) → notte (PR bozza) → gate (verifiche + smentita)
   → esito: merge (tuo sì) | chiusura | commessa correttiva (da approvare)
   → lezione scritta in SAL.md + riga in metrics/gate.csv → il ciclo migliora
```

---

## Il ciclo come loop engineering (2026-08-21)

Il sistema pratica **loop engineering** da prima di conoscere il nome: trigger che avviano un
harness, verifica, memoria su file, ciclo che riparte. Il vocabolario pubblico (Boris Cherny —
"non scrivo più prompt, disegno loop"; Peter Steinberger; Karpathy col suo AutoResearch — le sue
quattro regole sono in CLAUDE.md dal principio) arriva dopo e formalizza.

| Loop engineering | Qui |
|---|---|
| Trigger (evento o orario) | issue `night-shift` + launchd 23:00 |
| Harness (subtask, stato su file, contesto fresco per step) | CLAUDE.md + SAL + grafo + commesse precaricate |
| Verifica | `.night-verify` + morning-gate col banco |
| Memoria persistente (file system come estensione del contesto) | SAL.md + metrics/gate.csv + lezioni |
| Loop sul loop | commessa → notte → gate → correttore → notte |

**I cinque livelli di verifica** (tassonomia assorbita, i nostri nomi):

| Livello | Qui |
|---|---|
| 1 · deterministico (booleano) | `.night-verify`: exit code, test-motore |
| 2 · regole e vincoli numerici | soglie, conteggi asserzioni, metriche del gate |
| 3 · verità terrena ritardata | **il "riscontro" BC**: Verificato ☐ che matura quando i dati veri arrivano; esiti deploy |
| 4 · LLM giudice | banco avversariale — variante POTENZIATA: un modello che prova a smentire batte un modello che si autovaluta |
| 5 · checkpoint umano | la review di Luca — mai saltato, chiude ogni ciclo |

Comando per i loop diurni iterativi: **`/goal`** (obiettivo verificabile + tetto di tentativi,
log di ogni tentativo in `loops/`). Tensione dichiarata e voluta: la notte non ha limite di
tempo (decisione del 2026-08-21, guardia = review del mattino); i loop `/goal` diurni hanno
sempre un tetto — commessa unica e lunga vs ottimizzazione iterativa: contesti diversi,
regole diverse, entrambe giuste.

## Plugin adottati nel tessuto (2026-08-21)

| Plugin | Dove | Cosa porta | Cosa NON abbiamo preso |
|---|---|---|---|
| **ponytail** (107k ⭐) | OpenCode (notte) + Claude Code | scala minimale in §2, notte minimalista, DEBITI.md, minimità nel gate | ultra, mcp |
| **superpowers** (275k ⭐) | Claude Code | guardrail tre-strike §5, /brainstorming ZCode | subagent-review, execute-plan, skill-writing |

Flusso giorno: **/brainstorming → /goal → (notte minimalista) → gate a tre controlli**.

## Percorso cloud/ibrido (da review 2026-08-21 §4.1)

Una sessione cloud/remota (es. Claude Code nel container) NON ha `gh` CLI né accesso a
`night-shift/repos.conf` (locale del Mac per design). Cosa può fare da sola: commit di file
(es. `.night-verify`) via tool MCP GitHub. Cosa resta manuale sul Mac del proprietario: creare
la label `night-shift` (i tool MCP disponibili non la creano) e aggiungere la repo a
`repos.conf`. Un agente cloud che esegue l'onboarding O il bootstrap di un progetto nuovo
deve dirlo all'utente, non tacere i passi rimasti (dettaglio operativo in testa sia a
`tools/onboard-repo.sh` che a `tools/bootstrap-app.sh` — stesso limite, due script
gemelli, entrambi chiamano `gh` direttamente; 4° ciclo, set 3, giro 8, 2026-08-23: prima
citava solo "l'onboarding", non il bootstrap).

## Il ciclo guadagna la fase di audit (2026-08-21, sera)

```
/brainstorming ⇄ design-doc (torna a brainstorming se NESSUNA opzione è buona — 5°
                  ciclo, set 2 giro 7, 2026-08-23: non forzare una scelta scadente)
                  │
                  ├─ territorio piccolo/giorno → /goal | max N tentativi
                  └─ territorio grande/notte   → commessa → /audit-commesse (il giorno
                     verifica le assunzioni sul codice PRIMA della notte) → notte →
                     gate (night/* E claude/*: due occhi) → review di Luca
```

- **`/audit-commesse <repo>`** (Claude e ZCode): audita le commesse in coda contro il codice
  reale, corregge i body, compila la "Forma dei dati (verificata)". Nato dall'A/B: la commessa
  con l'assunzione sbagliata costa alla notte ore, al giorno una lettura
- **`/design-doc <feature>`** (Claude e ZCode): 2-3 opzioni confrontate su criteri
  espliciti (costo/rischio/reversibilità + criteri specifici alla decisione, dichiarati
  PRIMA delle opzioni, in una tabella opzioni×criteri — 4° ciclo, set 2, 2026-08-23: non
  più un trade-off narrativo libero), senza implementare — la scelta resta di Luca. È il
  passo /brainstorming che diventa documento. Implementato come skill Claude in
  `.claude/skills/design-doc/SKILL.md` (set 2 2026-08-22: prima citato qui senza esistere
  — stesso debito già chiuso per `/audit-commesse`)
- **Il gate guarda anche i branch `claude/*`**: il lavoro del giorno passa le stesse verifiche
  dichiarate e lo stesso banco avversariale di quello notturno

## Il ciclo guadagna il controllo di gestione (4° ciclo, set 1 "agenti", 2026-08-23)

- **`/controllo-gestione`** (Claude e ZCode): ancora un calcolo contabile/gestionale
  reale (contabilità analitica, di magazzino, controllo di gestione, margini, cespiti) a
  una formula esistente citata come oracolo (mai indovinata) — generalizza per questo
  dominio lo schema censimento+riscontro già in uso ad-hoc per Business Central
  (`PROJECT.md`). Implementato come skill Claude in
  `.claude/skills/controllo-gestione/SKILL.md`. Nato da un censimento di un repo esterno
  (codice anonimo **REPO-E**, regola "Public repo, private work": questo hub è pubblico,
  mai nomi reali) che ha trovato ~10 calcoli di controllo di gestione reali già
  implementati ma nessun metodo condiviso per affrontarne uno nuovo senza indovinare la
  formula. Primo caso risolto: `tools/riconciliazione_magazzino.py`.
- Citata anche nel template `.github/ISSUE_TEMPLATE/night-shift.md` (sezione
  "## Forma dei dati") e propagata ai progetti nuovi/esistenti come le altre skill
  (`tools/bootstrap-app.sh`, `tools/onboard-repo.sh` — copia wholesale di
  `.claude/skills/`, nessuna riga dedicata necessaria).
- **`.claude/agents/`** (5° ciclo, set 1 "agenti", 2026-08-23): il metodo sopra diventa
  anche un piccolo sistema di subagent Claude Code (frontmatter `name`/`description`/
  `tools`, non solo skill invocate a comando) — tre ruoli distinti, non varianti dello
  stesso testo: `contabilita-analitica` (applica/verifica un calcolo esistente, sola
  lettura), `costruttore-calcoli-gestionali` (ne scrive uno nuovo, Edit/Write
  autorizzati), `revisore-calcoli-critici` (dubita di un calcolo già scritto con la
  lente dev-critic §2ter, sola lettura). Cinque casi reali risolti finora (magazzino,
  produzione, cespiti, crisi d'impresa, scadenzario aging), tutti minati da REPO-E.
  Propagati ai progetti nuovi/esistenti con lo stesso schema di `.claude/skills/`
  (stesso gap trovato e corretto per la terza cartella, set 1 giro 5).

## Il ciclo guadagna la mappa del dominio e il quarto e quinto agente (6° ciclo, set 1 "agenti", 2026-08-24)

- **`docs/mappa-dominio-gas-src.md`**: censimento verificato dei 91 progetti REPO-E
  (998 file) in 12 categorie, incrociato con gli oracoli esistenti — la legge
  emersa: i due domini più popolati (ciclo attivo ~20 progetti, ciclo passivo ~10)
  erano gli unici grandi SENZA oracolo. Il test `tests/test-mappa-dominio-gas-src.sh`
  presidia forma e privacy della mappa.
- Tre oracoli nuovi, tutti minati dal codice REPO-E con aritmetica derivata a mano:
  `tools/valorizzazione_magazzino.py` (costo medio + override
  gruppo>categoria>articolo; "senza costo" anomalia non-zero; location escluse
  riportate; **costi generali % NON applicati: caricati in config REPO-E ma senza
  consumer, formula non provata — l'oracolo dichiara e rifiuta**),
  `tools/margine_documento.py` (accoppiamento per riferimento normalizzato, % sui
  ricavi, nota di credito annulla, unmatched=errore non margine zero),
  `tools/accuratezza_fatture_acquisto.py` (solo over-invoicing è discrepanza —
  fattura sotto ordine = fatturazione parziale, falso positivo corretto in REPO-E;
  whitelist fornitori; accuratezza (T−E)/T).
- **`.claude/agents/` cresce a 5**: `censitore-forma-dati` (sola lettura, produce
  la "Forma dei dati (verificata)" con provenienze file:riga per commesse e
  design NUOVI — prima era manuale) e `sviluppatore-gas` (costruisce progetti
  Apps Script interi col canone dei sei pattern misurati su REPO-E: client BC
  dedicato, CacheService>PropertiesService, override a livelli, WebApp+dashboard,
  LockService, assente≠zero). Il trio calcoli esistente resta: applica/costruisci/
  revisiona. Stessa nota di invocabilità del §"Limiti dichiarati" #6.

## Il design guadagna squalifiche, secondo ordine, spike e selezione del contesto (6° ciclo, set 2 "progettare", 2026-08-24)

- **`/selezione-contesto`** (skill nuova): prima di progettare si sceglie un pacchetto
  LIMITATO di fonti (SAL del dominio → pattern → mappa dei domini → oracoli →
  graphify/grep), con budget dichiarato (max ~5 fonti) e ESCLUSIONI scritte —
  "un'esclusione silenziosa è un buco travestito da scelta". Se il contesto trovato
  chiude il compito (oracolo/lezione già esistenti), il compito è riportare il
  riferimento, non progettare.
- **`/brainstorming`** guadagna la divergenza (2-3 RIFORMULAZIONI del problema prima di
  convergere — il problema, non soluzioni travestite) e il giro di contesto preventivo:
  non chiedere all'utente ciò che il sistema sa già.
- **`/design-doc`** guadagna tre pezzi: §1bis VINCOLI DI SQUALIFICA prima dei criteri
  (un'opzione che li viola non corre — la gara fra opzioni morte è teatro), gli
  effetti di secondo ordine per ogni opzione (cosa tocca altrove: notte, gate, skill,
  progetti che ereditano) e §3bis lo SPIKE (criterio critico ignoto → esperimento a
  tempo/scopo vincolati via /goal max 1, output da buttare — misurare, non iniziare
  a implementare).
- **`dev-critic`** aggancia la mappa dei domini come backlog prioritizzato per densità
  d'uso: le categorie VUOTO/PARZIALE dicono da dove partire; un'idea che contraddice
  la mappa va giustificata contro la mappa.

## Il flusso guadagna AGENTS.md, il gate la memoria, la notte gli agenti (6° ciclo, set 3 "flusso/interazione", 2026-08-24)

- **`AGENTS.md` diventa il contratto d'ingresso per agenti LLM** (prima: solo regole
  graphify): pipeline+artefatti, cervelli con contratto unico, oracoli/agenti per il
  dominio contabile, come si esce (night-verify, privacy). Un agente che atterra
  legge una pagina, non deduce.
- **L'hook pattern-reminder copre anche `Bash`** (matcher `Edit|Write|Bash`): il
  varco documentato nella voce SAL del 5° ciclo ("non copre clasp deploy, probe su
  BC") è parzialmente chiuso — i comandi che toccano materiale sensibile
  (printenv, .env, chiavi, Bearer) ricevono lo stesso reminder. Resta un reminder,
  non un cancello; l'estensione a UserPromptSubmit (compito↔skill) resta decisione
  di Luca, come dichiarato allora.
- **Il gate richiama la memoria**: morning-gate appende al report, quando c'è qualcosa
  da giudicare o la notte era a coda vuota, il richiamo che la lezione va scritta in
  SAL.md — l'anello L4 ("SAL.md + metrics/gate.csv") esisteva nei documenti, non nel
  meccanismo. La prosa resta umana (livello 4-5).
- **La catena degli artefatti ha una guardia** (`tests/test-flusso-artefatti.sh`):
  ogni anello (selezione-contesto → brainstorming → design-doc → commessa → notte →
  gate → SAL) dichiara la consegna al successivo, e la catena è circolare (il SAL è
  la fonte #1 di selezione-contesto).
- **La notte ha gli stessi 5 agenti del giorno**: `.opencode/agent/` specchiato,
  propagato a bootstrap/onboard, con guardia anti-drift sul corpo identico.

## La rotta corretta: il parco come corpus, non come cava (2026-08-24, 6° ciclo, addendum)

Feedback di Luca a caldo sul Set 1: il censimento era per classificazione dei
nomi + una decina di file letti, e gli oracoli scavati da 3 progetti — «pettini
adatti a un solo progetto». Il parco REPO-E andava letto come IL CORPUS
dell'esperienza (procedure, trucchi, errori già pagati, difficoltà), sul
modello della skill `gas-agent` di REPO-E (95 file: 17 specialisti, mandato,
famiglie misurate con popolazioni). Fatto:

- **Skill `gas-sviluppo`** (`.claude/skills/gas-sviluppo/`): il corpus
  distillato con PROVENIENZA dichiarata (l'autorità resta gas-agent di
  REPO-E). SKILL.md (consulenza vs consegna, loading progressivo) +
  `.claude/skills/gas-sviluppo/references/metodo.md` (i quattro verbi, le 7 regole del banco, i
  sabotaggi, l'ordine, i vincoli multi-agente pagati) +
  `.claude/skills/gas-sviluppo/references/famiglie-difetti.md` (le famiglie MISURATE: nomi in ombra 22
  divergenti su 9 progetti, nextLink ignorato 26/52, Number('')=0, «non letto»
  vs «vuoto» 57 siti/14 progetti, lock sulla risorsa, atHour fascia, sentinella
  0001-01-01 truthy, webapp anonime 20/80 con ogni funzione globale = endpoint,
  test finti 55/80, guardia cieca sull'estremo... ogni famiglia con popolazione
  e domanda discriminante) + `.claude/skills/gas-sviluppo/references/consegna.md` (worktree, baseline,
  parità a 3 livelli col Livello 3 dichiarato NON dimostrato, protocollo PR,
  clasp mai) + `.claude/skills/gas-sviluppo/references/domini-gestionali.md` (le domande di contabilità,
  CDG, produzione, sviluppo business).
- **Agenti generali**: `sviluppatore-gas` riscritto come agente GENERALE che
  carica il canone progressivamente (non più i soli 6 pattern), e il nuovo
  `revisore-gas` (i quattro verbi su progetti esistenti: censimento con
  raggiungibilità prima, banco prima, sabotaggio, tre prodotti). Ora 7 agenti,
  specchiati OpenCode con anti-drift.
- Guardia: `tests/test-gas-sviluppo-sistema.sh` (16 controlli: provenienza,
  regole non negoziabili, popolazioni numeriche ≥15, privacy).

La lezione di metodo, scritta nel SAL: quando il mandato dice «gli agenti
devono essere adatti a sviluppare QUESTO genere di script», la domanda non è
«quali formule estraggo» ma «quale esperienza il parco ha già pagato che gli
agenti devono incarnare». Il censimento per categorie era il passo 1, non il
lavoro.

## Il 7° ciclo: da prosa a strumenti, e il flusso dogfooddato (2026-08-24)

- **Tre oracoli** per i residui della mappa: `tools/leasing_amministrativo.py`
  (Euribor trimestrale ARRETRATO, stime del codice REPO-E dichiarate nell'output),
  `tools/rating_dso_clienti.py` (DSO con factoring; il confine DSO-0≠«paga subito»
  dichiarato: 'n.d.' per i non misurabili), `tools/bilancio_bu.py` (convenzione segni
  G/L in testa, NOBU visibile, quadratura meccanica; REPARTO dichiarato APERTO).
  Ora 11 oracoli.
- **`tools/gas_qualita.py`**: le famiglie misurate del corpus diventano
  RILEVATORE meccanico (censimento aid con domanda discriminante, mai verdetto;
  .js E .gs; mai valori di segreti). Dogfood su progetti veri: conteggi coerenti
  col corpus, falsi positivi attesi non accusati.
- **`tools/verifica_banco.py`**: il hub impara a GIUDICARE le uscite dei banchi
  (riga-verdetto canonica, M dichiarato, attese saltate = rosso, più righe =
  ambiguo): l'exit code non è un verdetto — ora è meccanico.
- **Il flusso di progettazione dogfooddato**: design-doc REALE (DTE vs intrastat)
  nel SAL con squalifiche/criteri/secondo ordine, scelta lasciata a Luca. Le
  correzioni nate dal dogfood: la RICETTA DELLA DENSITÀ in selezione-contesto
  (quanto pesa la formula in un dominio: decide oracolo vs progetto — la
  famiglia dei pettini chiusa per criterio, non per divieto) e la DOMANDA DI
  DOMINIO in brainstorming (prima del criterio di successo, silenzio vietato).

## Feedback dal campo su REPO-G processato (2026-08-24, sessione esterna)

Un report di dogfooding (sessione su REPO-G, repo mai onboardata) ha verificato
eseguendo quanto del metodo fosse disponibile su un progetto reale: quasi niente
(nessuna skill/agente fisicamente presente) — e ha trovato tre buchi veri
dell'hub, tutti chiusi o dichiarati:

- **F3 privacy**: `tools/privacy-check.sh` senza `repos.key` usciva 0 («niente da
  controllare» che si legge «pulito») — esattamente nelle sessioni cloud, dove
  la chiave non esiste per disegno. Ora: GATE DEGRADATO + exit 1. E il danno era
  reale: 11 occorrenze del nome vero in 5 file (la voce di DEBITI che dichiarava
  il problema ne citava 2) — bonificate in codice REPO-G. La STORIA git conserva
  i nomi nei commit passati: spurgo (filter-repo + force push) o accettazione
  del passato = decisione di Luca (DEBITI).
- **F2 sync**: onboard/bootstrap sono a un colpo solo, ogni repo diverge
  silenziosamente. Nuovo `tools/sync-repo.sh` (diff + PR di solo CLAUDE.md,
  minimale come chiesto dal report).
- **F5 memoria diurna**: il promemorio SAL esisteva solo nel morning-gate;
  l'hook PreToolUse ora conta gli edit di una sessione e al 5° senza SAL.md
  (se il progetto ne ha uno) mette il promemorio nel contesto — mai un blocco.
- **F4 citazioni**: PROJECT.md citava un catalogo inesistente nell'hub — ora
  dichiara dove vive; nuovo test presidia ogni percorso citato.
- **F6 soglia**: METHOD.md guadagna la terza corsia «task da una sessione»
  (chiarito in 1-2 domande, un file, verificabile ora: si fa e basta, col
  metodo ma senza pipeline — la cerimonia senza rigore in più è spreco).
- **F1**: l'onboarding di REPO-G resta decisione di Luca (credenziali BC nel
  repo: vedi DEBITI).

## Hook di sistema (2026-08-24 — primo hook di questo repo)

`.claude/settings.json` esiste da questo giro: prima non c'era alcun hook, la
consultazione di `patterns/` prima di certe modifiche dipendeva dalla memoria
dell'agente in quel turno (feedback di un utente esterno che ha usato il sistema).
`PreToolUse` su `Edit|Write` esegue `tools/pattern-reminder-hook.sh`: se il
`file_path` toccato matcha una categoria sensibile (auth/secret/credential/token/
login/password, incluse le varianti italiane), stampa un `additionalContext` con le
righe pertinenti di `patterns/README.md` — non blocca mai l'operazione
(`permissionDecision` sempre `"allow"`), è un reminder, non un cancello. Verificato
dal vivo (non solo pipe-test sintetico): un vero Edit su un path sensibile in questa
stessa sessione ha prodotto il reminder nello stesso turno.
