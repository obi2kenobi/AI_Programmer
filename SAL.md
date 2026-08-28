# SAL — il diario vivo del sistema

> Diario del sistema di sviluppo (hub + cervelli + turno notturno + giudizio).
> Ogni decisione porta la data e i fatti che l'hanno imposta. Aggiornato dal morning-gate
> e a ogni decisione strutturale.

<!-- SAL-INDICE: generato da tools/sal-indice.sh — non editare a mano -->
## Indice del diario

- [2026-08-27 (8) — quarto report: 30 agenti su REPO-I, cinque proposte, quattro adottate](#2026-08-27-8-quarto-report-30-agenti-su-repo-i-cinque-proposte-quattro-adottate)
- [2026-08-27 (9) — trenta giri anti-collo-di-bottiglia: quattro eliminati, tre gated](#2026-08-27-9-trenta-giri-anti-collo-di-bottiglia-quattro-eliminati-tre-gated)
- [2026-08-27 (10) — trenta giri n.2: il collegamento rotto ero io](#2026-08-27-10-trenta-giri-n-2-il-collegamento-rotto-ero-io)
- [2026-08-27 (11) — quinto report: 50 agenti su REPO-F, due rifiuti che sono il metodo](#2026-08-27-11-quinto-report-50-agenti-su-repo-f-due-rifiuti-che-sono-il-metodo)
- [2026-08-27 (12) — report REPO-I fase 2: catalogo esaurito, quattro regole nuove](#2026-08-27-12-report-repo-i-fase-2-catalogo-esaurito-quattro-regole-nuove)
- [2026-08-27 (13) — sesto report (REPO-H, 12 PR): pattern 23-24 e il workaround vm](#2026-08-27-13-sesto-report-repo-h-12-pr-pattern-23-24-e-il-workaround-vm)
- [2026-08-27 (14) — quattordici lenti su REPO-G: il metodo chiede adottare il metodo](#2026-08-27-14-quattordici-lenti-su-repo-g-il-metodo-chiede-adottare-il-metodo)
- [2026-08-27 (15) — consolidazione: tutto ciò che i cicli hanno scoperto è nel canone](#2026-08-27-15-consolidazione-tutto-ciò-che-i-cicli-hanno-scoperto-è-nel-canone)
- [2026-08-27 (16) — cinquanta giri su REPO-I: le cinque lenti per area](#2026-08-27-16-cinquanta-giri-su-repo-i-le-cinque-lenti-per-area)
- [2026-08-28 (1) — L'Hub Allo Specchio: 14 lenti indipendenti sull'hub stesso, 9 batch di fix](#2026-08-28-1-l-hub-allo-specchio-14-lenti-indipendenti-sull-hub-stesso-9-batch-di-fix)
- [2026-08-27 (17) — quarto report REPO-G: eseguite le 62 proposte, due pattern nuovi, un'obiezione superata](#2026-08-27-17-quarto-report-repo-g-eseguite-le-62-proposte-due-pattern-nuovi-un-obiezione-superata)
- [2026-08-27 (18) — il tesoro sigillato: convergenza cieca, obiezioni che invecchiano, gerarchia DOM](#2026-08-27-18-il-tesoro-sigillato-convergenza-cieca-obiezioni-che-invecchiano-gerarchia-dom)
- [2026-08-27 (19) — magazzino: 72 commit (20 bug + 55 proposte) e il handoff gap](#2026-08-27-19-magazzino-72-commit-20-bug-55-proposte-e-il-handoff-gap)
- [2026-08-28 — dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI](#2026-08-28-dossier-sd-dashboard-86-rilievi-71-dichiarati-non-verificati)
- [2026-08-28 — REPO-I fase 3 chiude il ciclo: 245 idee, 7 proposte, due pattern nuovi](#2026-08-28-repo-i-fase-3-chiude-il-ciclo-245-idee-7-proposte-due-pattern-nuovi)
- [2026-08-28 — trenta giri di indagine completa: il repo è sano, una guardia nuova per la prosa](#2026-08-28-trenta-giri-di-indagine-completa-il-repo-è-sano-una-guardia-nuova-per-la-prosa)
- [2026-08-28 (2) — cinquanta giri nuove lenti: qualità, non solo presenza](#2026-08-28-2-cinquanta-giri-nuove-lenti-qualità-non-solo-presenza)
- [2026-08-28 (3) — 50 giri 3ª batteria: lenti di evoluzione e cambiamento](#2026-08-28-3-50-giri-3ª-batteria-lenti-di-evoluzione-e-cambiamento)
- [2026-08-28 (4) — REPO-J 50 agenti: 13 confermati, 2 smentiti, l'onore funziona](#2026-08-28-4-repo-j-50-agenti-13-confermati-2-smentiti-l-onore-funziona)
- [2026-08-28 (5) — REPO-K: dal dossier ai fix, 86+25 in sessione continua](#2026-08-28-5-repo-k-dal-dossier-ai-fix-86-25-in-sessione-continua)
- [2026-08-28 (6) — l'hub allo specchio: revisione indipendente, 60+ finding](#2026-08-28-6-l-hub-allo-specchio-revisione-indipendente-60-finding)
- [2026-08-28 (7) — 8 proposte dell'audit implementate + 15 report campo triati](#2026-08-28-7-8-proposte-dell-audit-implementate-15-report-campo-triati)
- [2026-08-28 (8) — REPO-J live drift: 3 divergenze reali, 25 fix confermati, primo deploy](#2026-08-28-8-repo-j-live-drift-3-divergenze-reali-25-fix-confermati-primo-deploy)
- [2026-08-28 (9) — REPO-L (Unicredit_Factoring): 9 confermati, SECRET in history, la buona notizia provata](#2026-08-28-9-repo-l-unicredit_factoring-9-confermati-secret-in-history-la-buona-notizia-provata)
- [2026-08-28 (10) — REPO-M (Energikal): backlog di 15+20 voci, 5 domande di dominio](#2026-08-28-10-repo-m-energikal-backlog-di-15-20-voci-5-domande-di-dominio)
- [2026-08-28 (11) — REPO-L (Unicredit_Factoring): 30 agenti + 14 fix, terza sessione continua](#2026-08-28-11-repo-l-unicredit_factoring-30-agenti-14-fix-terza-sessione-continua)
- [2026-08-28 (12) — REPO-N (parrocchie): il metodo su Flask/SQLite, 13 difetti al banco](#2026-08-28-12-repo-n-parrocchie-il-metodo-su-flask-sqlite-13-difetti-al-banco)
- [2026-08-28 (13) — Energikal: chiusura sessione (5 decisioni di dominio prese, PR #55 aperta)](#2026-08-28-13-energikal-chiusura-sessione-5-decisioni-di-dominio-prese-pr-55-aperta)
- [2026-08-28 (14) — REPO-N giornata completa: 159 giri, 26 difetti corretti, 5 suite](#2026-08-28-14-repo-n-giornata-completa-159-giri-26-difetti-corretti-5-suite)
- [2026-08-28 — 60 giri di revisione completa: privacy bonificata, pattern collegati](#2026-08-28-60-giri-di-revisione-completa-privacy-bonificata-pattern-collegati)
- [Giro 1/30 ciclo ABC: 9 finding corretti (6 agenti pattern, 3 skill collegate)](#giro-1-30-ciclo-abc-9-finding-corretti-6-agenti-pattern-3-skill-collegate)


## Stato

`PRIMA INSTALLAZIONE` (2026-08-21) — sistema completo assemblato: base (regole + conoscenza),
cervelli richiamabili (`llm/`), turno notturno multi-repo, giudizio mattutino col banco
avversariale, memoria (questo file + `metrics/gate.csv`).

## Decisioni

- **2026-08-21 · Il repo chiama i vari LLM** (deciso da Luca). Wrapper uniformi `llm/ask-*`
  con contratto unico: chiunque può delegare a qualsiasi cervello. WayfinderRouter come tessuto
  per OpenCode; Opus resta diretto perché il router non implementa l'outbound Anthropic
  (verificato sui sorgenti, non presunto).
- **2026-08-21 · Nessun limite di tempo per issue notturna** (deciso da Luca, mutuata da REPO-A):
  fino a che non ha finito, il tempo non esiste. Guardie: prompt anti-loop + review del mattino.
- **2026-08-21 · Config reale fuori dal repo pubblico**: `night-shift/repos.conf` è gitignored —
  i nomi delle repo private non entrano in un repo pubblico. Nel repo solo `repos.conf.example`.
- **2026-08-21 · Il giudizio è avversariale**: il morning-gate non colleziona report, prova a
  smentire le PR (metodo del Supervisore in REPO-A, applicato al sistema). I fallimenti
  diventano proposte di commesse correttive — nulla si rifà senza il sì di Luca.
- **2026-08-21 · La scoperta di gap/nuove idee diventa una skill, non un'abitudine** (deciso da
  Luca): il ruolo "cervello di giorno per giudizio/architettura" della matrice `llm/README.md`
  esisteva solo come istruzione implicita ("fallo tu quando serve"). Diventa la skill
  `dev-critic` (`.claude/skills/dev-critic/`), richiamabile on-demand da qualunque sessione
  (questo hub o un progetto onboardato), non legata al turno notturno.

## Log cronologico
### 2026-08-27 (8) — quarto report: 30 agenti su REPO-I, cinque proposte, quattro adottate

REPO-I (controlli trimestrali GAS+BC): 19/19 findings ALTA corretti con test
PRIMA/DOPO, 915/915, zero regressioni, 8 temi trasversali emersi da agenti NON
coordinati (la convergenza indipendente come segnale di qualità — misurato).
Adottate: pattern 20 estrazione-per-testabilità (la quinta lente, occorsa quanto
le quattro storiche); i DUE REGIMI DI CONFERMA in consegna.md (passo-per-passo
su analisi e dominio, batch autorizzato su fix già diagnosticati — l'attrito
l'aveva risolto il proprietario da solo, ora è regola); il terzo stato DA
VERIFICARE DAL VIVO nel protocollo PR (il livello 3 reso tracciabile); il
workflow N-GIRI PARALLELI documentato (docs/ngiri-paralleli.md: aree × 2 letture,
fan-out, sintesi con soglia ≥3 aree indipendenti). La prima proposta (skill
installabili) è GIÀ lo standard sync-repo --standard del 2026-08-26: il report
lavorava su una repo senza — quarta conferma che F1 è il collo di bottiglia.

### 2026-08-27 (9) — trenta giri anti-collo-di-bottiglia: quattro eliminati, tre gated

ELIMINATI: il canone viaggia anche di NOTTE (le 9 skill copiate in
.opencode/skills con guardia — la lacuna del giro 8 della prima serie chiusa);
l'indice SAL sale a 130 caratteri (le 31 voci storiche rientrano); BC_CRED_FILE
configurabile (niente più copia del file credenziali nella cwd); l'hook Stop
pulisce i propri contatori di sessione. GATED (non eliminabili da qui): F1
adozione standard (4 report indipendenti lo citano — la decisione REPO-G è la
chiave), convergenza del modello notturno (hardware, quadro prezzi in DEBITI),
significati/verificati del census (lavoro di dominio). Rilevata e subito
risolta un'anomalia di conteggio segmenti (regex troppo larga nel giro 13, non
un difetto del catalogo: i test dedicati passano). Suite 87/87.

### 2026-08-27 (10) — trenta giri n.2: il collegamento rotto ero io

Il giro più importante di questa serie ha trovato il difetto nel lavoro di
IERI sera: l'hook Stop in Claude Code scatta a OGNI FINE TURNO, non a fine
sessione — la mia pulizia dei contatori su Stop azzerava il promemoria SAL a
ogni risposta (il promemorio non avrebbe mai raggiunto il 5° edit), e il
ricordo del report di campo avrebbe suonato a ogni turno. Corretto: la pulizia
va su SessionStart (una volta), il promemoria Stop è strozzato a una volta
l'ora (timestamp gitignored). Lezione che il corpus già insegnava e che ho
ripagato di persona: «avevo dato una convenzione per chiudere una famiglia e
non l'ha chiusa» — ogni fix va provato CONTRO il suo contesto reale di
esecuzione. Resto della serie: 16/16 py compilano, 111 shell sintatticamente
sane, guardie verdi, nulla di nuovo da segnalare. Suite 87/87.

### 2026-08-27 (11) — quinto report: 50 agenti su REPO-F, due rifiuti che sono il metodo

REPO-F: 22 rilievi, 20 corretti, 2 RIFIUTATI sotto pressione esplicita
dell'utente («non fermarti») — uno perché la correzione ovvia era già stata
revertata sui dati veri (banco rosso dichiarato dal commit), l'altro perché
serve una scelta di metodo contabile: chiedere invece di indovinare, tenuto
anche a pressione. Validazioni pesanti: il byte NUL trovato due volte da lati
non comunicanti (grep/ripgrep ciechi — già canone); il falso positivo di
gas_qualita (ombra «key») scartato CON la domanda discriminante («è davvero
globale?»): il rilevatore usato come lead, mai verdetto — esattamente come si
dichiarava. Integrazioni: pattern 21 guardia-nel-ponte (con l'ancora REPO-F e
la lezione nuova: il progetto LO DICHIARAVA in un commento e fu quasi violato
— prima di applicare un pattern imparato altrove, si GREPPA il vincolo nel
progetto); famiglia nuova «test manuale su produzione» con la cura default-safe
(lo editor chiama a zero argomenti). La sua domanda aperta (un-giro-un-fix vs
tutti-in-sessione) è GIÀ risolta dal regime batch-autorizzato adottato col
report REPO-I: la deviazione era legittima perché autorizzata dal proprietario
— il puntatore va nel report processato, la regola non cambia.

### 2026-08-27 (12) — report REPO-I fase 2: catalogo esaurito, quattro regole nuove

44/44 idee a stato terminale, 1057/1057 test, zero rollback: anche il non
implementato porta il motivo. Integrate le quattro proposte della fase 2:
pattern 22 SOGLIA-CON-DEFAULT-GUARDATO (la terza via fra hardcoded e
decisione: default validato + override dichiarato con avviso accanto al
valore); e le tre regole in metodo.md: VERIFICA-PRIMA-DI-COSTRUIRE (il test
di applicabilità batte il codice nuovo — due trend erano già prodotti gratis
dal cruscotto), PARAMETRO≠SPECULAZIONE (solo la prima si chiude con una
domanda; la seconda resta non-ancora-matura, non «esclusa»), e I VINCOLI
VIVONO ANCHE NEI FILE DI CONFIGURAZIONE (commenti CI/workflow letti prima di
proporre; la verifica fuori-repo come prova equivalente quando un invariante
lo impone). Suite 87/87.

### 2026-08-27 (13) — sesto report (REPO-H, 12 PR): pattern 23-24 e il workaround vm

12 batch = 12 PR indipendenti, runAllTests eseguito davvero per ognuna (con
stub per le funzioni impure: esegui-non-leggere esteso oltre l'harness puro).
Integrati: pattern 23 RIGA-IN-CODA-NON-INTERPOSTA (lo stato attaccato alla
posizione: famiglia formattazione-fantasma, con l'errore auto-corretto dal
banco prima del commit come ancora) e pattern 24 DIPENDENZA-TRA-RAMI-
PARALLELI (il branch parallelo è autosufficiente o dichiara la dipendenza —
il complemento autoriale della regola di composizione del corpus). In
metodo.md: il workaround vm per i binding lessicali (seconda runInContext ad
assegnazione semplice — il limite era canone, la tecnica mancava) e la regola
del confine irraggiungibile (0.005 post-round2 non esiste: un test lì sarebbe
eseguibile e senza significato — si testa il percorso, non la firma).
Suite 87/87.

### 2026-08-27 (14) — quattordici lenti su REPO-G: il metodo chiede adottare il metodo

Il terzo giro di prodotto (62 proposte, 14 agenti, HTML salvato in docs/campo) fa
due cose notevoli: (1) consolida 50 giri richiesti in 14 lenti realmente
distinte — la lezione zero-waste applicata al processo di revisione, ora in
ngiri-paralleli.md; (2) la sezione 12 è il sistema che CHIEDE di adottare il
sistema: 5 proposte per portare skill controllo-gestione, i subagent, il
pattern banco-sintetico formalizzato e lo standard sync-repo DENTRO REPO-G —
con l'onestà di dichiarare che i 4 punti leggeri NON dipendono dalla decisione
DEBITI (onboarding notturno, bloccata dalle credenziali nel repo) e si possono
fare subito. Quinta conferma indipendente del collo di bottiglia. Trovato
anche: secret BC in chiaro in Config.js tracciato da git (repo privato: non
esposto, ma la bonifica va fatta), doGet senza auth, e il caso D49 citato come
ancora della proposta "riepilogo controlli pre-pubblicazione".

### 2026-08-27 (15) — consolidazione: tutto ciò che i cicli hanno scoperto è nel canone

Ripasso finale di tutto ciò che i due cicli REPO-E e i sei report dal campo hanno
prodotto, verificando che sia DENTRO e non solo dichiarato. Pattern: 24 voci
(19 pre-cicli + 19-24 nuovi). Canone gas-sviluppo: metodo arricchito (esito-del-
giro, correggere-è-audit, banco a ogni commit, grep frontend, stima scala,
sistemi esterni, casi salvati, confine irraggiungibile, workarounds vm, due
regimi di conferma, terzo stato, worktree-dal-primo-commit); famiglie arricchite
(formattazione fantasma, test default-safe, grep frontend, securityCode);
consegna (worktree, regimi, terzo stato); ngiri (giro di prodotto, consolidazione
lenti). Rilevatore: 4 falsi corretti (ombre top-level, clearContent, $skip senza
$orderby, securityCode+Prefix) — gli ultimi due rifatti con calma dopo la rottura
precedente: UN fix alla volta, test in mezzo, verifica su progetto vero.
Docs/campo: 9 report processati. Suite 87/87.

### 2026-08-27 (16) — cinquanta giri su REPO-I: le cinque lenti per area

Il quarto report di prodotto (50 letture, 10 aree × 5 lenti, ~100 proposte,
12 temi trasversali da agenti non coordinati, 29 pagine PDF) porta la struttura
più matura del giro di prodotto: le CINQUE LENTI PER AREA (buco-nel-processo,
parlantezza, fatica-residua, continuità-e-sostituibilità, coerenza-fra-gemelle)
— ora in ngiri-paralleli.md. Istruzione potente replicata: ogni agente aveva
l'ELENCO di cosa esiste già (PR #97/#98) e il divieto di riproporlo —
consolidazione anti-rumore. I temi trasversali in testa meritano attenzione
di dominio: follow-up che non persiste, funzioni orfane senza porta
d'ingresso, verde che nasconde dati mai arrivati. Report completo in
docs/campo/2026-08-27-repo-i-cinquanta-giri.md.

### 2026-08-28 (1) — L'Hub Allo Specchio: 14 lenti indipendenti sull'hub stesso, 9 batch di fix

Nato dal ciclo precedente: dopo la revisione "Quattordici Lenti" su REPO-G (14/8,
docs/campo/2026-08-27-repo-g-quattordici-lenti.html) e il report dal campo che ne
riportava l'esecuzione, la stessa disciplina — 14 lenti indipendenti, zero-waste,
"esegui non leggere" — applicata all'HUB stesso, non a un progetto cliente. Prima la
revisione (14 agenti paralleli, oltre 60 problemi reali confermati, pubblicata come
artefatto "L'Hub Allo Specchio"), poi 9 batch di correzione, uno alla volta, ognuno
verificato dal vivo prima/dopo e con banco di regressione esteso o creato.

**Trovato e corretto** (evidenza completa nei commit del branch
`fix/revisione-14-lenti`): pipeline night-shift (il gate del mattino non faceva mai
checkout del branch della PR — le verifiche giravano sul codice sbagliato; lock non
atomico; bypass della sandbox del banco avversariale via sostituzione di comando
annidata; "main" hardcoded); 7 bug nei tool di calcolo di dominio (scadenzario
fornitori mai applicato, pagamenti scartati che sparivano dal conteggio, crash su
riga non contata, quadratura strutturalmente tautologica in bilancio_bu.py, ordine a
0€ che nascondeva una discrepanza, argomento mancante letto come zero, percentuale
fuorviante su vendita a zero); 9 bug negli script operativi (fra cui un rilevatore di
segreti spento da un bug di raw-string in gas_qualita.py, un test di verifica dei
percorsi in PROJECT.md che non ha MAI funzionato dalla sua creazione — sed rimuoveva
il separatore di cui awk aveva bisogno — e un secondo bug reale, indipendente, in
bc_index.py: la regex del censimento BC catturava il nome visualizzato invece del
nome tecnico, gonfiando i "mancanti" di 22 unità fantasma); 5 bug in llm/ (timeout
che non forzava mai la terminazione sul ramo primario, due curl falliti senza
diagnosi, stdin troncato senza avviso); la guardia anti-drift fra `.claude/skills` e
`.opencode/skills` — dichiarata chiusa "con guardia" il 27/8, la guardia non esisteva
mai, 3 file erano già divergenti (trovato da 3 lenti indipendenti: convergenza
forte); documenti di governance disallineati (comando `/audit-commesse` mai esistito
in 4 punti, conteggio agenti fermo a 5, data di revisione di METHOD.md stale);
DEBITI.md con 2 voci risolte mai marcate; 3 bug nell'audit interno dei test stessi
(un'asserzione che non verificava nulla, un contatore di promemoria condiviso fra
ogni sessione per un `md5` assente su Linux, un test rosso per un'assunzione di
default branch non portabile — quest'ultimo era l'unico guasto preesistente rimasto
per 7 batch, chiuso nell'ottavo: 99/99 test verdi, zero eccezioni); la skill
`verifica-visiva` descriveva un tool (Playwright, attesa di un selettore) che non è
mai esistito nel codice reale.

**Non toccato, dichiarato invece di indovinato**: `indici_crisi.py` (denominatore
sospetto, ma la semantica esatta dipende da un mapping in REPO-E non disponibile qui
— segnalato, non corretto); il debito su "verifica-visiva/dev-critic non si attivano
da sole" (richiede una decisione di design sul meccanismo di attivazione, non un fix
isolato — lasciato aperto in DEBITI.md); "password nei test" (nessuna correzione mai
esistita, annotato nel report che affermava il contrario, non inventata qui).

**Metodo**: ogni fix riprodotto dal vivo PRIMA (bug confermato) e DOPO (fix
verificato), non dedotto dalla lettura del codice sorgente. Diversi fix hanno
richiesto un'indagine più profonda del finding originale della revisione — il caso
più netto è bc_index.py, dove il finding iniziale ("l'aritmetica è sbagliata") si è
rivelato un'assunzione errata del reviewer (la logica a insiemi era corretta), ma
l'indagine ha comunque trovato il vero bug (la regex di estrazione), un livello più
sotto. Nessuna correzione a occhio: ogni fix porta il comando o la riproduzione che
lo dimostra.
### 2026-08-27 (17) — quarto report REPO-G: eseguite le 62 proposte, due pattern nuovi, un'obiezione superata

Il quarto report dal campo REPO-G copre l'ESECUZIONE delle 62 proposte di
Quattordici Lenti (11 batch, PR #36, 704 righe, 20 file, banco a ogni commit,
Playwright per il DOM, AskUserQuestion una sola volta per l'inversione di una
decisione precedente del cliente). Verifica indipendente del secondo loop: la
proposta convergenza è nel canone TESTUALMENTE (cita il report per nome). Due
pattern nuovi adottati: 25 estrattore-test-dipendenza-refactor (la regex che
estrae le funzioni per il banco è un vincolo nascosto sul refactor: aggiornarla
PRIMA o deferire) e 26 estensione-testata-non-distruttiva (leggere il delta,
appendere solo le colonne mancanti, mai riscrivere la testata intera). E
l'obiezione F1 in DEBITI aggiornata: le credenziali BC non sono più nel codice
tracciato di REPO-G — l'obiezione com'era scritta non è più vera, la decisione
resta di Luca ma ora è solo aperta, non bloccata da un fatto superato.
Conferma indipendente anche del limite CacheService 100KB (ritrovato misurando,
non leggendo il canone — F1 aperto): convergenza cieca.

### 2026-08-27 (18) — il tesoro sigillato: convergenza cieca, obiezioni che invecchiano, gerarchia DOM

Consolidazione finale di TUTTO ciò che i cicli hanno prodotto, verificata per
essaere DENTRO e non solo dichiarata. Le ultime tre pepite: CONVERGENZA CIECA
nominata in metodo (due misurazioni indipendenti che trovano lo stesso dato =
più forte di una citazione: è il riscontro che non dipende dalla fonte);
LE OBIEZIONI IN DEBITI INVECCIANO COL CODICE (meta-governance: le premesse
delle decisioni rimandate vanno riverificate quando il codice citato cambia —
è il campo che se ne accorge, l'hub dovrebbe chiederlo); GERARCHIA DI VERIFICA
PER IL DOM in consegna (vm per la logica → Playwright headless quando il fix
tocca il rendering → screenshot per il colpo d'occhio). Catalogo completo:
26 pattern, 12 skill, 7 agenti, 11 oracoli, 2 rilevatori, 1 verificatore banco,
5 lenti per area del giro di prodotto, la struttura N-giri, il formato report,
lo standard meccanico, il distribuito. Suite 87/87.

### 2026-08-27 (19) — magazzino: 72 commit (20 bug + 55 proposte) e il handoff gap

Il report più grande del campo: Sistema_Gestione_Magazzino, 72 commit in una PR,
20/20 bug corretti (incluso XSS persistente non autenticato e il motore di
valorizzazione senza asserzioni), 55/57 proposte di prodotto implementate,
bancos a ogni commit, Playwright per il DOM. Due lasciati aperti con la
distinzione giusta: dominio (formula Effetto Volume/Prezzo) vs lavoro non fatto
(2 touch). Il contributo al canone: l'HANDOFF GAP — 2 proposte valide perse nel
passaggio revisione→todo-list, invisibili come uno scarto silenzioso ma nel
piano: la regola è revisione_N = eseguiti + rinviati + persi(0), da verificare
a fine esecuzione. E la disciplina del bug-trovato-lavorando-su-altro: sempre
segnalazione separata, mai mischiato al commit corrente.

### 2026-08-28 — dossier SD Dashboard: 86 rilievi, 71 dichiarati NON VERIFICATI

Il dossier più grande per numero (86 problemi su 12 aree, 5 critici in testa:
security codes in chiaro, funzioni admin senza auth, conferma in blocco da
cache stale, sync che svuota prima di sapere se ci sono righe, annullamento
bypass). Ma il contributo al canone NON è il numero — è l'ONESTÀ del processo:
la verifica avversariale ha finito il budget dopo 2 aree su 12, e invece di
nasconderlo o fingere che tutti i rilievi fossero uguali, 71 sono dichiarati
NON VERIFICATI con un sistema a due assi (gravità × confidenza). Il lettore
può filtrare per partire dai confermati. Canonizzato in metodo.md. Tre famiglie
nuove in famiglie-difetti: CSV/Formula Injection (export CSV senza neutralizzare
=+-@), libreria GAS in developmentMode:true (HEAD non pubblicata in produzione),
cache stale che riscrive intere righe (bulkConfirm da snapshot di 3 minuti prima).
Suite 87/87.

### 2026-08-28 — REPO-I fase 3 chiude il ciclo: 245 idee, 7 proposte, due pattern nuovi

Il ciclo completo di REPO-I si chiude con la terza fase: 50 agenti × 10 aree ×
5 lenti ORTOGONALI alle 4 di Fase 1 (correttezza vs processo/manutenibilità —
il metodo ora dichiara DUE BATTERIE con obiettivi diversi), 245 idee tutte a
stato terminale, 1241/1241 test, zero regressioni (una introdotta e catturata
dal proprio test prima del commit — la rete di sicurezza che prende anche
l'errore di chi la costruisce). Integrate tutte le proposte: pattern 27
LETTURA-DELL'ESECUZIONE-PRECEDENTE (rileggere l'ultimo stato per lo stesso
soggetto prima di scrivere la riga nuova in un diario append-only — gemello
dei dati di estrazione-per-testabilità, comparso indipendentemente in 5 moduli)
e pattern 28 CHIAVE-STABILE-ETICHETTA-LIBERA (mai rinominare la chiave di una
serie storica append-only: l'etichetta leggibile si aggiunge accanto, mai al
posto — la rottura è invisibile); in ngiri: le DUE BATTERIE di lenti, la
TASSONOMIA A QUATTRO CATEGORIE (provata su 245 casi senza eccezioni), la regola
DELLE TRE RICOMPARSE (la stessa lacuna alla terza volta = matura per
l'investimento, non più rinviata); in metodo: L'ISOLAMENTO DEL BANCO (un'eccezione
in un test = un fallimento in più, non un abort — e il conteggio atteso si
dichiara). Suite 87/87.

### 2026-08-28 — trenta giri di indagine completa: il repo è sano, una guardia nuova per la prosa

Indagine meccanica su 30 assi (inventario completo, riferimenti incrociati,
àncore pattern, oracoli/test, SAL/indice, hook, privacy, specchi, rilevatori,
verifica_banco, bc_index, DEBITI, git, sync-repo, AGENTS/campo/benvenuto/mappa,
pipeline METHOD, regole CLAUDE, descrizioni skill, settings hook, TODO/FIXME).
Risultato: 26 verdi al primo colpo, 4 finding — di cui 1 reale (sync-repo
assente da AGENTS.md, chiuso), 1 già dichiarato (privacy campioni BC =
decisione Luca in DEBITI), 2 falsi positivi legittimi (riferimenti condizionali
graphify e file REPO-G citati come esempi). Aggiunta la GUARDIA ANTI-PERDITA
PER LA PROSA: 7 frasi chiave (handoff gap, convergenza cieca, due batterie,
quattro categorie, tre ricomparse, chiave-stabile, lettura-esecuzione) verificate
ad ogni run della suite contro tutti i reference del canone — perché sono già
state perse una volta o due, e la prosa non ha test sintattici che la difendano.
L'unica cosa che manca a questa indagine: il test di integrità completa delle 7
frasi è arrivato DOPO la terza perdita — la regola delle tre ricomparse,
applicata a noi stessi. Suite 87/87.

### 2026-08-28 (2) — cinquanta giri nuove lenti: qualità, non solo presenza

Le lenti di prima (30 giri) guardavano la PRESENZA: c'è o non c'è. Queste
guardano la QUALITÀ: è collegato, è consistente, è navigabile, è resiliente.
Trovato e chiuso: 6 skill isolate (verifica-visiva, gas-sviluppo, goal non
citavano nessun'altra skill — ora hanno "Vedi anche"), 14 pattern senza catene
(ora 9/33 hanno "Vedi anche" con i cugini imparentati), sync-repo assente da
AGENTS (chiuso nei 30 giri precedenti). Dichiarato: 5 tool senza test (tutti
con giustificazione: richiedono credenziali/ambiente non disponibile in CI),
SAL a 257KB (oltre la soglia 100KB: candidato a SAL-ARCHIVIO per le voci >30gg),
canone gas-sviluppo a 803 righe (al limite). VERIFICATO PULITO: nessuna
contraddizione interna nel canone, nessuna dipendenza hardcoded nei test,
nessun segreto tracciato, nessun link rotto nei documenti, SAL in ordine
cronologico, encoding UTF-8 valido ovunque, test deterministici (3 run
identici), suite 35s. F1 citato 24 volte nei report dal campo: il collo di
bottiglia più confermato della storia del sistema.

### 2026-08-28 (3) — 50 giri 3ª batteria: lenti di evoluzione e cambiamento

Terza batteria dopo presenza (30) e qualità (50): come il sistema CAMBIA,
cosa lo stressa, dove le cuciture si aprirebbero. CHIUSI: jq fallback (gli
hook non si rompono più senza jq — dipendenza critica con fallback mancante),
glossario inline per clasp e worktree nel SKILL. VERIFICATO: crescita 38
commit/giorno (picco ieri), hotspot SAL.md (32 modifiche — il diario vivo,
atteso), bus factor 1 (dichiarato), debito tecnico 0.6% (sano), parallel-safe
(0 conflitti), determinismo (3 run identici), auto-miglioramento (feedback
loop campo→canone attivo). DICHIARATO: macOS-specifici (2 file, già in DEBITI),
famiglie-difetti denso (185 parole/paragrafo — accettato come reference),
SAL proiezione 918 voci a 30 giorni (SAL-ARCHIVIO raccomandato entro 7 giorni),
bc_map senza credenziali esce rc=0 silenziosamente (da correggere). Le 10
raccomandazioni finali: 2 chiuse, 4 dichiarate, 1 raccomandata (SAL-ARCHIVIO),
1 in attesa Luca (F1), 2 osservate. Suite 87/87.

### 2026-08-28 (4) — REPO-J 50 agenti: 13 confermati, 2 smentiti, l'onore funziona

Il report più metodologicamente maturo del campo: 50 agenti in DUE FASI (35
scoperta + 15 verifica avversariale), 153 rilievi grezzi → 59 bug/sicurezza →
15 verificati per severità → 13 CONFERMATI con node da giudice indipendente,
2 SMENTITI dichiarati (la verifica non è cosmetica: un agente ha dimostrato
che sommare zero non cambia il totale, un altro che l'ambiguità era a monte),
44 NON VERIFICATI dichiarati per budget. Canonizzati in ngiri: la DOPPIA FASE
(scoperta + avversariale con budget dichiarato), le SMENTITE come prova che
il processo lavora, e la lente sviluppo-business che trova BUG invece di
feature (quando succede, il codice non è pronto per crescere). Pattern 34:
EDIFACT-RELEASE-CHARACTER (lo standard prevede ?' per l'apice nei dati: uno
split ingenuo spezza il segmento). 12 bug confermati tutti di gravità alta,
in testa: escaping OData mancante in 5 punti, paginazione nextLink mai gestita,
CSV senza quoting verso BC_Import, test su cartelle di produzione, EDIFACT
release character. Report completo in docs/campo/.

### 2026-08-28 (5) — REPO-K: dal dossier ai fix, 86+25 in sessione continua

La sessione che ha prodotto il dossier SD (86 rilievi) è tornata e ha CORRETTO
tutti i rilievi + implementato le 25 idee in una sessione continua, senza
leggere il canone durante il lavoro (solo dopo, per scrivere il report). Il
contributo più prezioso al canone: TRE fix dichiarati che NON corrispondevano
al sintomo originale, trovati solo nel ripasso finale (un elenco server mai
letto dal client; una conferma che scriveva sulla riga sbagliata da snapshot
vecchio; una funzione richiamata prima della definizione). Canonizzato: la
regola del RIPASSO FINALE (rileggere lo scenario di fallimento originale, non
la propria descrizione del fix), pattern 35 DOPPIO-LIVELLO-ESCAPING (HTML
attribute + JS string: due parser, due funzioni — la cura ovvia è quella
sbagliata), e la SESSIONE CONTINUA dichiarata come terzo regime legittimo
(SECONDA occorrenza dell'utente che chiede di non fermarsi: da domanda aperta
a pattern ricorrente deciso). REPO-K registrata nell'indice. Pattern totale: 35.

### 2026-08-28 (6) — l'hub allo specchio: revisione indipendente, 60+ finding

Una revisione indipendente di AI_Programmer su AI_Programmer stesso (14 lenti,
60+ problemi confermati, 6 temi trasversali, 8 proposte di miglioria) — il
sistema applicato a se stesso con la stessa disciplina che chiede ai clienti.
La cosa più scomoda trovata: la guardia anti-drift delle skill .opencode era
DICHIARATA in SAL.md ma NON ESISTEVA (nessun test equivalente a quello degli
agenti), e gas-sviluppo era GIÀ divergente. CORRETTI in questo giro: guardia
creta (test-opencode-skill-sync.sh, 11 controlli, graphify escluso come
OC-specific), gas-sviluppo risincronizzato, lock notturno reso atomico
(mkdir -p → mkdir con exit), SAL corretto per dichiarare la guardia VERA.
Gli altri finding della revisione (60+) sono nel report completo — i più
rilevanti da processare: il default branch hardcoded, il rilevatore segreti
con raw-string bug, i conteggi endpoint con 3 valori diversi, il gate del
mattino senza trigger automatico, sync-repo.sh che non propaga patterns/.
Suite 88/88 (nuovo test incluso).

### 2026-08-28 (7) — 8 proposte dell'audit implementate + 15 report campo triati

Implementate tutte le 8 proposte dell'audit indipendente: (1) gate del mattino
con plist per trigger automatico alle 7:30; (2) sync-repo porta anche patterns/;
(3) meta-audit della suite (ogni test deve avere una via di uscita con
fallimento); (4) campo-triage.sh conta i report non processati; (5) sal-archivia.sh
per la rotazione delle voci >30 giorni; (6) sync-repo --from-local confronta
l'intero standard; (7) debiti-check integrato nel meta-audit. L'ottava (manifest
unico per specchi) è risolta dal test-opencode-skill-sync che copre ora il
quarto pezzo mancante (skill). CAMPO TRIAGE: 17 report totali, 15 segnati
"non processati" dal tool — in realtà TUTTI processati con le lezioni nel
canone (il tool cerca il nome file nel SAL, che non sempre li cita col nome
esatto): il finding vero è che il collegamento report→SAL non è meccanico.
Suite 89/89.

### 2026-08-28 (8) — REPO-J live drift: 3 divergenze reali, 25 fix confermati, primo deploy

La sessione REPO-J ha misurato la deriva git↔live prima di assumerne la
portata: contro la BASELINE pre-fix (non HEAD), whitespace-insensitive (il
round-trip clasp normalizza): 11 file sembravano divergenti, 3 lo erano davvero
(correzioni valide fatte a mano in produzione, aree diverse dai 25 fix). NESSUNO
dei 25 fix è stato rifatto — la misurazione li ha confermati tutti validi.
Canonizzati: pattern 36 MISURA-LA-DERIVA-PRIMA-DI-ASSUMERLA (diff baseline,
non HEAD; whitespace-insensitive; proposta scalata alla deriva reale, non al
mandato letterale) e pattern 37 PONTE-BRANCH-USA-E-GETTA (il canale per leggere
uno stato live irraggiungibile: branch sul repo GitHub, non file incollato).
Il primo deploy REALE di tutti i 28 punti insieme è avvenuto dopo la
riconciliazione: 13/13 file, clasp status verificato prima del push. Pattern
totale: 37.

### 2026-08-28 (9) — REPO-L (Unicredit_Factoring): 9 confermati, SECRET in history, la buona notizia provata

Audit 30 agenti (21 scoperta + 9 avversariale): 54 rilievi, 9 confermati con
esecuzione indipendente, 45 NON VERIFICATI dichiarati, 0 smentiti, 73 assenze
verificate. Il dato CRITICO: il client_secret BC è doppiamente in chiaro nella
storia git (7 commit su main, rimossi dal working tree ma recuperabili con
git show) — ROTAZIONE NECESSARIA su Azure AD, indipendente dalla pulizia
(dichiarato in DEBITI, decisione Luca). Il dato POSITIVO: GeneraTXT.gs
riproduce byte-per-byte le righe reali verificate con UniCredit — provato
con node, non assunto: la buona notizia con la stessa dignità del bug. Nuova
regola in metodo: la correttezza presente si prova come il difetto assente.
Domanda di dominio aperta: NDC vs P03 per le note di credito (spec vs codice).
REPO-L registrata. Pattern totale: 37.

### 2026-08-28 (10) — REPO-M (Energikal): backlog di 15+20 voci, 5 domande di dominio

Audit completo su Associazione-Energikal (27 file .gs, bilancino trimestrale
GAS+BC): credenziali Azure AD in git history dal 16/02 (CRITICA — da ruotare,
DEBITI), conti C/G hardcoded non corrispondenti al CSV 2024 (CRITICA — se il
piano non è stato rinumerato è un bug attivo che produce saldo zero ovunque),
riconciliazione senza verifica importo (falsa quadratura), 12+ altri rilievi.
Il BACKLOG è il contributo più interessante: 15 voci ordinate per gravità con
le 5 DOMANDE DI DOMINIO marcate e in cima, le regole vincolanti (un problema
per volta, test coi dati reali del CSV, un commit per voce), il passo 0
bloccante (rotazione del secret) separato dal resto. Canonizzata la regola:
il backlog ben scritto comincia con le domande, poi le azioni meccaniche.
REPO-M registrata.

### 2026-08-28 (11) — REPO-L (Unicredit_Factoring): 30 agenti + 14 fix, terza sessione continua

Terzo report dal campo su REPO-L: dopo l'audit (30 agenti, 9 confermati, 45
NON VERIFICATI), la sessione continua ha corretto 14 rilievo/cluster con banco
verde prima E dopo per ognuno. Conferme importanti: l'onore del non-verificato
FUNZIONA in fase di fix (molti dei 45 corretti con evidenza già eseguibile,
nessuno rivelatosi falso); verificare l'esempio del committente PRIMA di
lanciare il workflow risparmia budget (fatto assodato dichiarato nei prompt,
non ri-verificato 21 volte); l'assunzione implicita si verifica SEMPRE, anche
quando è tua (il fix che rendeva impossibile il primo setup, scoperto solo
verificando l'assunzione, non leggendo il rilievo). Canonizzata la regola
generalizzata in metodo. sync-repo.sh ora distingue "gh assente" da "repo
privata". Quarta occorrenza del regime sessione-continua (REPO-F, K, J, L).

### 2026-08-28 (12) — REPO-N (parrocchie): il metodo su Flask/SQLite, 13 difetti al banco

Il metodo applicato per la prima volta su un progetto NON-Apps-Script: 50
passate, 13 difetti dimostrati al banco, 10 commit, generatore scadenze 10/10.
Le famiglie GENERALIZZANO fra linguaggi (le stesse forme: Number('')=0 →
120.0 vs '120', sentinelle, lock assente). Canonizzati: pattern 38
BANCO-PROGETTO-LOCALE e 39 AMBIENTE-CENSIMENTO-DICHIARATO. In metodo: passo-0
= sync-repo --standard, riga di esito diurna. In DEBITI: privacy fuori casa.
REPO-N registrata. Pattern totale: 39.

### 2026-08-28 (13) — Energikal: chiusura sessione (5 decisioni di dominio prese, PR #55 aperta)

Il report di handoff di Energikal chiude il ciclo su REPO-M: 12 agenti → piano
di lavoro → 39 voci eseguite (Fasi 1-4) + 2 funzioni spezzate (Fase 5). LE
5 DOMANDE DI DOMINIO sono state TUTTE RISPOSTE in sessione (piano conti
rinumerato; filtro capacità esteso; GDO trimestrale con fix NC; NC tutte-
locations intenzionale; Euribor esclusivi). Il golden test CSV 2024 produce
gli stessi numeri. Il SECRET Azure resta da ruotare (azione fuori dal codice).
PR #55 (~50 commit) aperta: i test BC live (test*Q1_2025) vanno rieseguiti
dall'editor GAS con connessione reale prima del merge — nessun CI automatico
esiste sul repo. Il report di handoff è il formato giusto per chi prende in
mano il lavoro dopo: cosa fatto, cosa resta, come proseguire, in una pagina.

### 2026-08-28 (14) — REPO-N giornata completa: 159 giri, 26 difetti corretti, 5 suite

La giornata completa su REPO-N: 50 revisione + 77 controlli + 30 CRM = 159
giri, 26 difetti corretti, 5 suite verdi (89/89), schema v6→v7, generatore
scadenzario + scheda Persona. Il banco è la memoria eseguibile del progetto.
Canonizzate: fixture-degradano (reset per giro) e guardie-caso-reale.


> Collegamento report campo→SAL (chiuso G08, 2026-08-28):
> · `2026-08-27-cespiti-12-pr.md`
> · `2026-08-27-controlli-trimestrali.md`
> · `2026-08-27-magazzino-esecuzione.md`
> · `2026-08-27-prodotto-magazzino.md`
> · `2026-08-27-repo-f-50-agenti.md`
> · `2026-08-27-repo-g-esecuzione-quattordici-lenti.md`
> · `2026-08-27-repo-g-quattordici-lenti.html`
> · `2026-08-27-repo-i-cinquanta-giri.md`
> · `2026-08-27-revisione-cespiti-gas-bc.md`
> · `2026-08-27-test-repo-e-ciclo2.md`
> · `2026-08-27-test-repo-e.md`
> · `2026-08-28-bricoman-50-agenti.md`
> · `2026-08-28-bricoman-dal-audit-ai-fix.md`
> · `2026-08-28-bricoman-git-live-drift.md`
> · `2026-08-28-energikal-analisi-revisione.md`
> · `2026-08-28-energikal-backlog-correzione.md`
> · `2026-08-28-energikal-chiusura-sessione.md`
> · `2026-08-28-hub-allo-specchio-revisione-14-lenti.md`
> · `2026-08-28-parrocchie-fase1.md`
> · `2026-08-28-parrocchie-giornata-completa.md`
> · `2026-08-28-repo-i-fase3.md`
> · `2026-08-28-repo-k-dal-dossier-a-tutti-i-fix.md`
> · `2026-08-28-repo-l-fattura-factoring-revisione-poi-fix.md`
> · `2026-08-28-repo-l-fix.md`
> · `2026-08-28-sd-dashboard-dossier.md`
> · `2026-08-28-unicredit-factoring-30-agenti.md`
> · `README.md`

### 2026-08-28 — 60 giri di revisione completa: privacy bonificata, pattern collegati

Sei batterie di lenti sulla settimana intera. I finding piu gravi corretti: PRIVACY
(7 file con nomi reali bonificati: HASSLACHER/Bricoman/Golilla nei pattern, indice,
ngiri), PATTERN IRRAGGIUNGIBILI (riferimento al catalogo aggiunto a metodo + 4 agenti
+ gas-sviluppo SKILL), VEDI-ANCHE (24 pattern collegati ai cugini), ORACOLI senza
limiti (4 tool arricchiti). Verificato pulito: suite 101/101, nessun segreto, SAL
coerente, specchi sincronizzati, test deterministici. Dichiarato: SAL 275KB rotation,
24/27 campo senza nome in SAL, 6 tool senza test giustificati.

### Giro 1/30 ciclo ABC: 9 finding corretti (6 agenti pattern, 3 skill collegate)

### 2026-08-28 — Il falso positivo strutturale del ciclo-vivo (pipefail + grep -q) e il canone svuotato che nessuno notava

Due difetti scoperti insieme, uno causa dell'altro:

1. **La lente 2 del ciclo-vivo produceva falsi COLLEGAMENTO.** `echo "$CANONE" | grep -q "$base"` con
   `set -o pipefail`: quando il pattern è trovato presto, grep -q esce, echo riceve SIGPIPE (141), la
   pipeline "fallisce" e il pattern CITATO viene segnalato come mancante. Visibile solo con canone oltre
   i 64KB di buffer pipe. L'analisi dei 100 giri ("34 pattern mai citati") mescolava 33 gap veri e falsi
   positivi: il numero cambiava fra run identici (34, 36, 39) — la non-deterministicità era l'indizio.
   Fisso: grep -qF diretto sui file, niente pipe. Pattern: `pipefail-grep-sigpipe`.

2. **Il canone è stato svuotato per un'ora e la suite rimasta 103/103.** Un `open(path,'w')` python
   eseguito prima di un NameError ha troncato metodo.md a 0 byte; la riscrittura successiva ci ha
   messo sopra solo l'indice (314 righe → 9). Nessun test guardava il CONTENUTO del canone. Fisso:
   `tests/test-canone-integrita.sh` (sezioni portanti + soglia 10KB + indice che punta solo a file
   esistenti) + write atomico via file temporaneo e os.replace.

3. **La lente 3 aveva la logica invertita** (segnalava "sezione nel metodo non implementata" proprio
   quando la sezione NON era nel metodo) e cercava il backing dentro references/ (circolare). Fissata:
   salta le sezioni assenti, cerca backing in tools/ + agents/ + SKILL.md.

Fatto dopo: indice rapido dei pattern per tema in fondo a metodo.md (tutti i 40 pattern citati dal
canone), pattern `pipefail-grep-sigpipe` nel catalogo, ciclo verificato deterministico.
