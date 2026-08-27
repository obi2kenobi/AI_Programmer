# DEBITI.md — il registro delle scorciatoie rimandate

Ogni scorciatoia deliberatamente rimandata (regola §2, da ponytail) si scrive qui:
cosa, perché è stata rimandate, quando va saldata. "Poi" non deve diventare "mai".

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| | | | |

## Da review Opus 2026-08-21 (rinvii deliberati)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 ✅ SALDATO (nuovo ciclo 10 giri, giro 10/10, 2026-08-22) | Rotazione log di ~/night-shift.log e ~/morning-gate.log | nessun limite raggiunto | `rotate_log_if_big()` in night-shift/lib.sh (soglia 10MB, una generazione file→file.1), richiamata da night-shift.sh e morning-gate.sh prima del primo log. Test sintetico in tests/test-lib.sh (file piccolo non ruota, file grande ruota con contenuto preservato, file assente no-op) |
| 2026-08-21 | Path /opt/homebrew hardcoded (ollama) — portabilità Intel/Linux | scelta "solo Mac Apple Silicon" dichiarata | se il sistema girerà altrove |
| 2026-08-21 ✅ SALDATO (nuovo ciclo 10 giri, giro 9/10, 2026-08-22) | Test funzionali per bc_map.py / bc_index.py | bc_map.py chiama davvero l'API BC (OAuth) — non testabile in sandbox, resta manuale; bc_index.py invece è puro | tests/test-bc-index.sh: esegue bc_index.py su una COPIA reale di docs/bc/endpoints (88 file), verifica righe/conteggio/ordinamento. bc_map.py resta debito aperto (serve un ambiente con credenziali BC vere) |

## Da dev-critic — verifica dogfooding della review Opus (2026-08-21, notte)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 ✅ SALDATO stesso giorno | `gate_allowlist_ok()` (`night-shift/lib.sh`) verificata bucabile: `bash -c`, `python3 -c`, `awk system()`, `sed .../e` passano l'allowlist perché controlla solo il primo token, non cosa fa l'interprete con gli argomenti — testato dal vivo (bypass confermati). Il sandbox seatbelt non compensa: nega solo rete e scrittura fuori workdir, non la lettura. Non corretto in questo giro: cambia il modello di minaccia, serve il sì esplicito di Luca prima di stringere ulteriormente l'allowlist o negare le letture nel sandbox | decisione di design — scelta opzione (c) di Luca: interpreti rimossi dall'allowlist E letture sensibili negate nel sandbox. Provato dal vivo: i 6 bypass storici ora bloccati, token gh illeggibile in sandbox |
| 2026-08-21 ✅ SALDATO stesso giorno | Stesso file: lo split su `;`/`\|`/`&&`/`\|\|` non rispetta le virgolette — un comando legittimo con quei caratteri dentro una stringa citata (es. `grep -c "a;b" file`) viene scartato per errore di parsing, non per una vera protezione (falso positivo) | minore, non blocca nulla oggi (il banco può sempre riprovare un comando diverso) | saldato insieme all'opzione (c): split consapevole delle virgolette, `grep -c "a;b" file` passa |
| 2026-08-21 | Indicizzare patterns/*.md nel grafo (richiede pass semantico, non --code-only) | costo token da valutare | se i pattern superano ~30 voci |
| 2026-08-21 | Mascherare segreti negli output del gate (pattern: segreto-come-impronta) | miglioramento suggerito dal raccolto REPO-A, non urgente (output locali) | al prossimo giro su morning-gate |
| 2026-08-21 (aggiornato Giro 2) | `verifica-visiva` provata su pagine sintetiche E, dal Giro 2, su un vero artefatto generato dal pilota (`night-shift-pilot` issue #10, `file://.../dist/report.html`) — screenshot confermato a occhio, nessun falso positivo su un report a dati vuoti legittimo. Resta NON provata contro un vero deploy Apps Script (dominio script.google.com, OAuth) | richiede clasp/OAuth sul Mac, non disponibile da questa sessione | al primo deploy reale toccato dopo questa PR |
| 2026-08-21 ✅ SALDATO (set 2 "capacità di progettare", giro 1/10, 2026-08-22) | `/design-doc` resta citato in prosa (SAL.md/docs/system.md) senza un file che lo implementi, come lo era `/audit-commesse` prima di oggi | fuori scope delle 4 aggiunte richieste — richiede la stessa decisione presa per audit-commessa | Implementato: `.claude/skills/design-doc/SKILL.md`. Verificato che le fonti di verità dichiarate in METHOD.md (`.zcode/commands/`, `.claude/commands/`) non esistono affatto nel repo — corretto il riferimento lì e in docs/system.md |

## Dal Giro 1 dei "3 giri autonomi" (2026-08-21, notte)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 | Una skill introdotta da una PR bozza non mersa (`audit-commessa`, PR #8) è risultata invocabile in modo inaffidabile nella stessa sessione: due `Skill()` falliti con "Unknown skill" mentre il file esisteva già sul branch corretto, riuscito al tentativo successivo senza altra azione — l'elenco skill non si aggiorna in modo sincrono al `git checkout`. Non corretto qui: non è un bug nel contenuto della skill, è un limite del meccanismo di scoperta che questa sessione non controlla | nessuna causa tecnica accertata da questa sessione (nessun accesso al meccanismo di caricamento skill) — solo il sintomo, osservato due volte | quando una PR che introduce skill nuove viene mersa presto (non lasciata a lungo in bozza), o quando qualcuno con accesso al runtime confermi la causa del ritardo |

## Dal Giro 3 dei "3 giri autonomi" (2026-08-21, notte)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 | La lente sicurezza di `dev-critic` (§2bis) non ha nessun punto della pipeline dichiarata (commessa→audit-commessa→notte→morning-gate→review) in cui sia invocata automaticamente — resta "on demand" per disegno. Verificato dal vivo su night-shift-pilot issue #12: una commessa scritta a specifica ("stampa la config a console per debug") produce codice che stampa una chiave in chiaro, e nulla nel gate lo segnala da sé. Non corretto strutturalmente qui: reso solo un promemoria nel template issue (`.github/ISSUE_TEMPLATE/night-shift.md`), non un controllo automatico | rendere obbligatoria una chiamata LLM (dev-critic) nel morning-gate è una decisione di design con costo (tempo/token per ogni commessa) — richiede il sì di Luca, non un default silenzioso | quando si decide se e come rendere automatica (non solo un promemoria in template) la lente sicurezza per le commesse che toccano logging/diagnostica |

## Dal Giro 6 dei "10 giri extra" (2026-08-21, notte)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 ✅ SALDATO (Luca ha dato il sì a "esegui le correzioni") | `morning-gate.sh:157` propone, su verifica fallita, un `gh issue create` correttivo il cui `--body` dice solo "Dettagli nel report locale del gate" — ma quel report è un file LOCALE alla macchina che ha eseguito il gate | scelta fatta: l'estratto del fallimento (`FAIL_DETAIL`, ultime righe del comando fallito o del banco smentito) entra nel body via heredoc quotato (`$(cat <<'GATE_EOF' ... GATE_EOF)`) — al riparo da backtick/`$()`/virgolette nell'output di un comando qualunque | Provato dal vivo con un `FAIL_DETAIL` avversariale (contenente `` `b` ``, `$(whoami)`, `$HOME`) passato a un `gh` finto: tutti i caratteri arrivano come testo letterale nell'argomento `--body`, nessuna espansione — `bash -n` passa; l'esecuzione END-TO-END contro un `gh` reale resta da fare al primo gate vero sul Mac (nessun `gh` autenticato in questa sessione) |

## Dal Giro 8 dei "10 giri extra" (2026-08-21, notte)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 | `morning-gate.sh` ora chiede `mergeable` a `gh pr list` e segnala `⛔ Non mergeable` nel report (fix applicato per il buco trovato al Giro 8: due PR gemelle in conflitto reale, il gate non lo diceva mai). Il campo è quello documentato nello schema `gh pr list --json` (MERGEABLE/CONFLICTING/UNKNOWN), non inventato, e `bash -n` passa — ma non eseguito dal vivo contro un `gh` autenticato, perché questa sessione non ne ha uno | nessun `gh` CLI autenticato disponibile in questa sessione cloud | primo giro reale del morning-gate sul Mac dopo questa PR — verificare che la riga compaia per una PR davvero in conflitto |

## Dal Giro 9 dei "10 giri extra" (2026-08-21, notte) — BUG REALE, non teorico

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-21 ✅ SALDATO (Luca ha dato il sì a "esegui le correzioni") | `night-shift/gate-esito.sh` registrava due volte lo stesso esito su righe diverse quando esistevano PIÙ righe pendenti per lo stesso repo+PR (riprodotto dal vivo su una copia di `metrics/gate.csv`, mai l'originale) | semantica scelta: un esito TERMINALE (`merge`/`chiusura`) chiude per sempre repo+PR, qualunque riga pendente più vecchia resti indietro; `commessa` non è terminale, quindi non blocca un `merge` legittimo su una riga successiva dopo un ciclo correttivo | Riprodotto lo stesso bug esatto sulla stessa copia del CSV reale: seconda chiamata ora respinta ("stato finale"). Provato anche il caso legittimo `commessa` → `merge` su una riga nuova (riesce) → un terzo tentativo (respinto, `merge` è terminale). Ririprovati anche i 3 casi originari (formato storico, formato nuovo, doppia registrazione) — tutti ancora corretti |

## Dal 4° ciclo, Set 1/3 "agenti" giro 7 (2026-08-23) — scoperta, non introdotta oggi

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-23 | `patterns/banco-sintetico-per-calcoli-critici.md` (riga 2, l'ancora) e `.claude/skills/dev-critic/SKILL.md` (§2ter) citano per nome un repo reale (`obi2kenobi/REPO-G`) — scritti prima che la regola "Public repo, private work" (CLAUDE.md, 2026-08-22) esistesse. Trovato per caso oggi grepando privacy sul mio stesso diff (giro 7), non è una violazione introdotta in questo ciclo | fuori scope del giro corrente (Set 1 "agenti"): una bonifica dei nomi pre-esistenti nell'intero repo è un lavoro a sé, non richiesto oggi, e toccherebbe file che nessuna commessa attuale sta modificando | quando Luca chiede esplicitamente una bonifica privacy retroattiva, o quando uno di questi due file viene toccato per un altro motivo — a quel punto anonimizzare per codice anonimo invece di limitarsi al giro richiesto — ✅ PARZIALMENTE SALDATA 2026-08-24 (report dal campo su REPO-G): bonificati 11 siti in 5 file (SAL.md, DEBITI.md, patterns/README.md, patterns/banco-sintetico, dev-critic — più di quanti la voce stessa ne dichiarasse: la voce citava 2 file, erano 5) |

## Dal 4° ciclo, Set 3/3 "flusso delle idee" giro 9 (2026-08-23) — non urgente, da tenere d'occhio

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-23 | La riga `.night-verify` che esegue `tests/test-*.sh` (Set 1 giro 4) misura ~31s per 50 file, ben sotto il watchdog di 120s (`run_guarded`) — ma il numero di test è cresciuto da 25 a 50 in un solo ciclo, e il trend è monotono (ogni giro ne aggiunge). Non è un problema oggi: misurato dal vivo, non presunto | non urgente: c'è ancora ~4x margine prima del ceiling; non si corregge un problema che non esiste ancora | quando la suite reale supera ~150-180 file (stimato dal trend attuale), o se una singola esecuzione della riga si avvicina ai 60-90s: a quel punto valutare se spostare il watchdog di questa riga specifica (non l'intero .night-verify) oltre i 120s, o parallelizzare l'esecuzione dei test |
| 2026-08-23 (5° ciclo, Set 1 giro 10 — riverifica, non un nuovo debito) | Riverificato a 54 file: due run consecutive misurano ~34s (coerente col trend sopra), ma UNA run isolata ha misurato 2m9s — quasi al ceiling di 120s. Causa trovata (non solo osservata): `tests/test-stdin-timeout.sh` lasciava orfani i `sleep 100` della process substitution (bug separato, corretto nello stesso giro) — quegli orfani accumulati da run ripetute della suite competevano per risorse del sandbox al momento dell'anomalia. Non riproducibile a comando dopo il fix | il fix del leak (stesso giro) rimuove la causa nota; resta la stessa soglia di guardia del debito sopra (150-180 file, o 60-90s su una run pulita) | nessuna azione ora — il numero anomalo non era la crescita della suite, era un leak di processi già corretto |

## Dal 5° ciclo, Set 1/3 "agenti" giro 8 (2026-08-23) — limite d'ambiente, non un bug del hub

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-23 ✅ SALDATO (riverificato dal vivo, stesso giorno) | I tre subagent `.claude/agents/*.md` erano stati rifiutati ("Agent type non trovato") in un primo tentativo di invocazione (giro 8), subito dopo il commit — sospettato un limite permanente dell'ambiente Claude Code Remote/cloud | un secondo tentativo, più tardi lo stesso giorno (dopo il push del branch e l'apertura della PR #35), ha invocato tutti e tre gli agenti con successo | Risolto: non era un limite permanente dell'ambiente, ma un roster degli agenti che non si era ancora aggiornato al momento del primo tentativo. Resta un residuo di incertezza (non isolato sperimentalmente COSA fa scattare il refresh — nuova sessione? push? un intervallo di tempo?) — annotato in `docs/system.md` §"Limiti dichiarati" #6 come nota di processo, non come limite bloccante |

## Dal feedback sul campo, REPO-F BC/GAS (2026-08-24) — buco già identificato, non richiuso

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-24 | `tools/pattern-reminder-hook.sh` (`.claude/settings.json`, `PreToolUse`) copre solo il matcher `Edit\|Write` — non `Bash`. Non è un limite teorico: nel caso reale che ha originato il hook (indagine su REPO-F, vedi `night-shift/repos-index.md`), il lavoro passava da comandi Bash (clasp deploy, probe su Business Central), non da Edit/Write di file con nome sensibile — lo stesso schema "dipende dal fatto che il tool giusto venga usato" che il hook doveva rompere | estendere il matcher a `Bash` richiede una decisione su COME riconoscere un comando sensibile (nome file negli argomenti? keyword nel comando stesso? entrambi rumorosi in modi diversi) — non una scelta tecnica neutra, va presa con Luca prima di scrivere il fix | quando si decide il meccanismo di "aggancio automatico più ampio" (priorità indicata da Luca il 2026-08-24) — questo buco specifico è probabilmente il primo caso concreto da chiudere in quella decisione, non un debito a sé |
| 2026-08-24 | Due skill (`verifica-visiva`, `dev-critic`) con `description` che descrive quasi alla lettera un caso reale (dashboard GAS modificata, funzione mai eseguita in 90+ file di un progetto) non si sono attivate da sole nella sessione che ha lavorato su quel caso — trovate per fiuto investigativo, non per matching automatico. Non corretto qui: non è un bug in una description scritta male (il testo calza), è un limite del meccanismo di attivazione automatica su cui si regge l'intero sistema di skill | richiede una decisione di design (quale meccanismo aggiuntivo, se non il solo matching per description) — stessa decisione del debito sopra, non un fix isolato | quando si decide il meccanismo di "aggancio automatico più ampio" — vedi riga sopra |

## Privacy: la storia git (2026-08-24, dal report sul campo REPO-G)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-24 | La bonifica privacy ha pulito i FILE correnti (11 siti), ma la STORIA git del repo pubblico conserva i nomi in ogni commit passato: `git log --all -S"<nome>"` li ritrova per sempre. Il privacy-check (v3) li vedrebbe e fallirebbe — per questo la chiave locale di QUESA macchina parte con lista vuota | spurgo della storia = `git filter-repo` + force push su repo pubblica con altre sessioni attive: distruttivo e coordinabile solo da Luca (annuncio ai collaboratori, fork/clone da rifare) | decisione di Luca: o si purge la storia (poi i termini entrano in repos.key e il gate li presidia davvero), o si accetta che la storia pre-2026-08-24 li contenga e si presidia solo il futuro (i termini NON entrano nella chiave: il gate resterebbe rosso per sempre) |

## Onboarding di REPO-G (2026-08-24, report sul campo F1)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-24 | REPO-G non è mai stato onboardato (nessun .claude/, nessun .night-verify; CLAUDE.md/PROJECT.md caricati a mano) — le skill/agenti del hub non erano fisicamente disponibili nella sessione che ci ha lavorato, che ha dovuto rifare a mano ciò che il metodo sistematizza | l'onboarding porta la repo nel turno notturno (repos.conf) e ~~la repo contiene credenziali BC nel repo stesso~~ AGGIORNATO 2026-08-27 sera: le credenziali sono state spostate fuori dal codice tracciato in REPO-G stesso (PR #36 batch 2, SAL D53) — l'obiezione COM'ERA SCRITTA non è più vera; restano le tre opzioni, la decisione è di Luca (SAL di REPO-G, voce D6): onboardarla è una decisione di esposizione, non una dimenticanza da correggere in silenzio | decisione di Luca: (a) onboarding completo, (b) onboarding parziale senza repos.conf (solo skill/agenti via sync-repo.sh), o (c) esclusione deliberata documentata in docs/system.md — oggi "sembra una dimenticanza, non una decisione" |

## Deploy assistito: separare i due rischi del divieto clasp (2026-08-26, report tagli)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-26 | Il report dal campo misura il costo del cancello umano (~20 cicli manuali a sessione) e osserva che il rischio VERO è maneggiare le credenziali, non eseguire il deploy: con credenziali fuori portata dall'agente, un deploy assistito ridurrebbe il costo senza perdere la protezione che conta | allentare un divieto di sicurezza su una repo pubblica con produzione vera è decisione del proprietario: il canone separa ora i due rischi (consegna.md), la regola resta intera | decisione di Luca: mantenere il cancello com'è, o definire il rituale del deploy assistito (credenziali dove, comando chi lo lancia, cosa vede l'agente, log) e scriverlo nel canone |

## Valutare Qwen 3.8 Flash come cervello notturno (2026-08-27, dal video di lancio)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-27 | Il nuovo Qwen 3.8 Flash (125B MoE, 6B attivi + 51B n-gram in RAM) dichiara proprio ciò che manca al nostro 27B locale: long-context retrieval 84,2→97% e ragionamento migliore («il modello locale capisce ma non converge sui giudizi» è il gap misurato in tre notti). MA: Q4 = 112 GB di memoria — il 27B gira sul MacBook Air proprio perché sta in ~16 GB; il Flash non entra nell'hardware attuale con NESSUNA quantizzazione dignitosa. E i benchmark hanno 3 ore di vita: la matrice llm/README si aggiorna con misure nostre, non con claim di lancio (lezione DFlash2, SAL 2026-08-21) | decisione di acquisto hardware (macchina da ~128 GB di memoria unificata: classe Bosgame M5 / Mac Studio M5 Ultra / Xiaomi AI Cube) + attesa che Ollama supporti l'architettura n-gram | quando Luca decide l'hardware E il modello è disponibile nel nostro stack: si rifà la batteria qualità 4/4 + tok/s misurati + il test di convergenza sui giudizi (issue #363 come caso) — stessa procedura che scelse il 27B.

AGGIORNATO 2026-08-27 (secondo video, analisi hardware): il quadro macchine per il
carico NOTTURNO (batch, senza limite di tempo per decisione 2026-08-21 — quindi la
critica principale del video al M5 Ultra, il prefill compute-bound per uso
interattivo, è la voce che PESA MENO per noi; conta la capacità e la qualità):
- Bosgame M5 mini 128GB (~€1,5-2k): Flash Q4 112GB ci sta STRETTO, 3-bit comodo — l'esperimento più economico
- DGX Spark 128GB (~€5k): 0,5 PFLOP, banda 250GB/s → ~50 tok/s generazione su Flash-class (misurato dal video su GLM 5.3 Flash), prefill ~1000 tok/s — per il batch notturno SUFFICIENTE
- M5 Ultra 256GB (~€12-20k configurata): ci sta comodo ma il video lo boccia come valore (€20k ≈ 4 Spark = 2 PFLOP) — per noi overkill
- ATTESA: Spark 2 (~1,5 anni), Xiaomi AI Cube (prezzo/specifiche ignoti), e Ollama deve ancora supportare l'architettura n-gram — chi compra ora paga la prima ondata
Economia attuale: il 27B gira sul MacBook Air esistente = costo marginale ZERO; qualsiasi hardware è capex puro per il gap di convergenza, che il routing giorno già compensa |

## Lavoro distribuito a due mani (Luca + Lavinia) — 2026-08-27, valutazione su evidenza

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-27 | Cosa manca al distribuito: (1) assegnazione esplicita delle commesse (le issue GitHub ce l'hanno nativo: usare assignee — è adozione, non codice); (2) regola di merge per SAL.md quando due sessioni appendono lo stesso giorno (git unisce append su code diverse: da VERIFICARE alla prima collisione vera, non presumere); (3) repos.conf/repos.key restano locali al Mac di Luca: il turno notturno resta CENTRALIZZATO per disegno — Lavinia lavora di giorno sulle stesse repo onboardate | il nucleo distribuito già c'è ed è collaudato: PR+branch convenuti (claude/*, night/*, glm/*) presidiati dal gate per chiunque, commesse=issue, SAL append-only, canone con le lezioni del multi-agente parallelo (13-17 agenti: l'estremo del lavoro distribuito), sync-repo --standard porta il metodo identico a entrambi | ✅ SALDATA 2026-08-27 (stesso giorno): (1) autore nel report di campo; (2) collisione SAL VERIFICATA con esperimento (conflitto certo senza driver) e chiusa con `.gitattributes` merge=union per i diari (merge pulito verificato: entrambe le voci, zero markers); (3) centralizzazione notturna CONFERMATA come disegno e dichiarata in AGENTS.md §0bis; assegnazione = assignee GitHub adottato. Regole scritte in AGENTS.md §0bis | — | — |

## Le 9 skill non viaggiano in OpenCode (giro 8 della coerenza, 2026-08-27)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-27 | `.opencode/skills/` contiene solo graphify: le 9 skill dell'hub (gas-sviluppo, selezione-contesto, design-doc…) non hanno equivalente notturno — il turno notturno ha gli AGENTI (specchiati) ma non le SKILL: la notte può invocare revisore-gas, non legge il canone progressivo | il formato skill OpenCode va verificato (non presumere che SKILL.md sia identico); è un porting vero, non una copia | quando la notte deve consultare il canone: portare le skill (o la sola gas-sviluppo) nel formato OpenCode, con guardia anti-drift come gli agenti |

## Privacy nei VALORI DI CAMPIONE del censimento BC (giro 14 dei 20, 2026-08-27)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-27 | I campioni d'esempio dei file endpoint portano dati di business veri (nomi fornitori trovati in 2 file: il grep dei nomi reali li ha ripresi). La census li contiene PER COSTRUZIONE (bc_map legge il vivo) — mascherarli tutti toglierebbe utilità al census | è un trade-off tra utilità del census e privacy della controparte commerciale in una repo pubblica: decisione del proprietario, non dell'agente | decisione di Luca: (a) accettare (i fornitori sono già pubblici nel catalogo prodotti), (b) mascherare la sola colonna Esempio nei file sensibili, (c) mascherarli tutti |

## Le obiezioni in DEBITI invecchiano col codice (dal campo REPO-G, 2026-08-27)

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-27 | Le voci di DEBITI motivano decisioni rimandate con FATTI («il repo contiene credenziali BC») — ma il codice CAMBIA, e un fatto che era vero quando la voce è stata scritta può non esserlo più (REPO-G: le credenziali sono state spostate via in PR #36, l'obiezione è restata com'era per giorni). Lasciarla scrivere a una cosa non più vera fa sembrare bloccata una decisione che è solo aperta | è il campo che deve accorgersene e dirlo (come è successo), non l'hub che lo vede da solo — chi processa i report dovrebbe riverificare le premesse delle voci DEBITI che il report tocca | a ogni report dal campo che tocca codice citato in DEBITI: riverificare la premessa, aggiornare la voce se il fatto è cambiato |
