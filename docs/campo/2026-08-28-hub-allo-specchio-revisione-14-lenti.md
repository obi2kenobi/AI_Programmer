# 2026-08-28 — l'hub allo specchio: 14 lenti indipendenti, 9 batch di fix, PR #63

**Autore**: sessione Claude Code su mandato Luca · richiesta esplicita: "50 giri di revisione" sull'hub AI_Programmer stesso (non un progetto cliente) + "sistema tutto".

## Cosa è stato chiesto

Non un audit di un repo servito dall'hub, ma un audit dell'hub su se stesso: errori di logica, errori silenziosi, errori di programmazione, più una ricerca separata di migliorie. Poi, in un secondo turno: "fai un piano e procedi uno per volta con tutti i punti trovati non ti fermare e sistema tutto".

## Metodo

"50 giri" preso alla lettera avrebbe prodotto duplicazione pura senza portare a nulla in più — la consolidazione delle lenti è zero-waste (`docs/ngiri-paralleli.md`). Consolidati in **14 lenti indipendenti** senza sovrapposizione (script operativi, tool di calcolo di dominio, pipeline night-shift, llm/, governance dei documenti, propagazione .opencode/skills, sicurezza dei pattern regex, test-degli-stessi-test, ecc.), lanciate in parallelo. Ogni rilievo verificato con `esegui non leggere`: bug riprodotto dal vivo prima del fix, fix riprodotto dal vivo dopo, banco di regressione nuovo o esteso per ognuno — mai un "dovrebbe funzionare" senza prova.

## Risultato

**9 batch di fix**, un commit per batch, PR #63 (`fix/revisione-14-lenti` → `main`). 25 file di test nuovi/estesi, suite completa **99/99 verde**. Alcuni rilievi:

- **night-shift.sh**: lock a directory non atomico (`mkdir -p` non fallisce mai se la dir esiste — due turni potevano correre insieme); `git checkout main` hardcoded lasciava il checkout sbagliato su repo con default branch diverso.
- **gas_qualita.py**: il pattern anti-segreto per `securityCode` era una stringa NORMALE con `r"` letterale in testa invece di una raw-string — il rilevatore non ha mai riconosciuto un segreto vero dalla sua introduzione.
- **bilancio_bu.py**: aggiunta una quadratura davvero indipendente (prova matematica: contributo per riga = `-amount` sempre) al posto di un controllo che si limitava a risommare gli stessi numeri.
- **bc_index.py**: il regex del censimento-mancanti catturava il gruppo backtick sbagliato in una riga di tabella a 2 valori — bug più profondo di quello segnalato dalla lente che lo aveva trovato (la sua ipotesi aritmetica era sbagliata, ma sotto c'era un bug reale).
- **test-project-md-percorsi-citati.sh**: un `sed 's/://;...'` toglieva proprio i due punti che `grep -n` doveva produrre — il test non aveva mai verificato nulla dalla sua creazione (2026-08-24).
- **test-flusso-artefatti.sh**: asseriva sulla vecchia forma sbagliata `/audit-commesse` — certificava il typo invece di scovarlo.

Tre casi lasciati aperti deliberatamente, per non inventare: il denominatore di `indici_crisi.py` (serve una mappatura REPO-E esterna), l'attivazione automatica di verifica-visiva/dev-critic (decisione di design, non tecnica), "password nei test" (nessun fix è mai esistito da recuperare — solo annotato come debito).

## Scoperta non pianificata: collisione con un lavoro indipendente concorrente

Alla verifica finale, PR #63 risulta `mergeable_state: dirty`. `main` è avanzato di **~25 commit** dal punto in cui questo branch si era diramato (`84ac73c` → `59ec4a8`), da un **altro filone di lavoro indipendente e concorrente** che ha fatto, in parallelo e senza coordinamento, un audit molto simile su questo stesso hub — al punto da usare lo stesso nome, "hub allo specchio" (`4fafb42 SAL: hub allo specchio — revisione indipendente processata`), per lo stesso concetto.

Sovrapposizione reale (verificata riga per riga, non per titolo di commit):
- **`night-shift/night-shift.sh`**: stesso bug del lock trovato e corretto da entrambi i filoni, sulle stesse righe. La loro correzione (`mkdir "$LOCK" 2>/dev/null || exit 0`) è più semplice; la mia aggiunge anche il recupero di un lock scaduto (>12h). Conflitto testuale sicuro al merge, nessun conflitto di logica: la mia versione è un superset compatibile.
- **`tools/sync-repo.sh`**: loro hanno aggiunto solo `patterns` alla lista `--standard`; io ho aggiunto sia `patterns` sia `.opencode/skills` (mancava anche quello) più un fix separato non toccato da loro (`$HUB_CLAUDE.md` → `$HUB_CLAUDE`, bug del punto-md doppio). Nessuna perdita di comportamento nell'unione.
- **`tools/gas_qualita.py`**: **stesso bug esatto** (raw-string mancante sul pattern securityCode), corretto **in modo diverso** da entrambi i filoni — la loro versione richiede la virgoletta di chiusura e ammette `_` nel valore; la mia mantiene la semantica "s finale opzionale" dell'originale ma è più permissiva. Qui scegliere l'una o l'altra cambia davvero cosa il rilevatore intercetta: non risolvo da solo, lo segnalo a Luca.

Il worktree-dal-primo-commit (lezione già scritta in `docs/campo/2026-08-27-test-repo-e-ciclo2.md` per correttori paralleli sullo STESSO repo) non è stato applicato qui — lavorato nel clone condiviso. Con due filoni indipendenti sullo stesso hub in corso nello stesso periodo, la stessa lezione si applica anche a "sessioni diverse che non sanno l'una dell'altra", non solo ad agenti coordinati nella stessa sessione.

## Proposta al canone

Conferma della lezione già scritta, estesa: il rischio di collisione non richiede coordinamento esplicito per materializzarsi — due filoni indipendenti sullo stesso hub, nello stesso arco di tempo, sono bastati. La differenza in `gas_qualita.py` (stesso bug, due fix diversi e non equivalenti) è un caso concreto in più per "correggere è audit" (§3, stesso report del 27): il merge di due correzioni indipendenti allo stesso bug va sempre riletto come una lente in più, non solo unito meccanicamente.

## Da verificare dal vivo

- Decisione su `tools/gas_qualita.py`: quale delle due regex (o una terza, unione dei due) resta.
- Merge di `main` in `fix/revisione-14-lenti`, risoluzione dei 2 conflitti testuali non ambigui (night-shift.sh, sync-repo.sh), ri-verifica suite 99/99 dopo merge.
