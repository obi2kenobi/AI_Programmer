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
| 2026-08-23 | `patterns/banco-sintetico-per-calcoli-critici.md` (riga 2, l'ancora) e `.claude/skills/dev-critic/SKILL.md` (§2ter) citano per nome un repo reale (`obi2kenobi/Bilancio_periodico`) — scritti prima che la regola "Public repo, private work" (CLAUDE.md, 2026-08-22) esistesse. Trovato per caso oggi grepando privacy sul mio stesso diff (giro 7), non è una violazione introdotta in questo ciclo | fuori scope del giro corrente (Set 1 "agenti"): una bonifica dei nomi pre-esistenti nell'intero repo è un lavoro a sé, non richiesto oggi, e toccherebbe file che nessuna commessa attuale sta modificando | quando Luca chiede esplicitamente una bonifica privacy retroattiva, o quando uno di questi due file viene toccato per un altro motivo — a quel punto anonimizzare per codice anonimo invece di limitarsi al giro richiesto |

## Dal 4° ciclo, Set 3/3 "flusso delle idee" giro 9 (2026-08-23) — non urgente, da tenere d'occhio

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-23 | La riga `.night-verify` che esegue `tests/test-*.sh` (Set 1 giro 4) misura ~31s per 50 file, ben sotto il watchdog di 120s (`run_guarded`) — ma il numero di test è cresciuto da 25 a 50 in un solo ciclo, e il trend è monotono (ogni giro ne aggiunge). Non è un problema oggi: misurato dal vivo, non presunto | non urgente: c'è ancora ~4x margine prima del ceiling; non si corregge un problema che non esiste ancora | quando la suite reale supera ~150-180 file (stimato dal trend attuale), o se una singola esecuzione della riga si avvicina ai 60-90s: a quel punto valutare se spostare il watchdog di questa riga specifica (non l'intero .night-verify) oltre i 120s, o parallelizzare l'esecuzione dei test |

## Dal 5° ciclo, Set 1/3 "agenti" giro 8 (2026-08-23) — limite d'ambiente, non un bug del hub

| Data | Scorciatoia | Perché rimandata | Quando si salda |
|---|---|---|---|
| 2026-08-23 | I tre subagent `.claude/agents/*.md` (`contabilita-analitica`, `costruttore-calcoli-gestionali`, `revisore-calcoli-critici`) non sono invocabili dal tool Agent in questa sessione Claude Code Remote/cloud (verificato dal vivo: "Agent type non trovato", anche dopo il commit). Non è una scorciatoia presa da questo ciclo — è un limite dell'ambiente, scoperto dogfoodando il proprio lavoro invece di assumerlo funzionante | fuori dal controllo di questo hub: non si può "correggere" un ambiente di sessione dall'interno della sessione stessa; il file dei tre agenti resta comunque valido come documentazione del metodo (formato Claude Code standard) | quando qualcuno verifica in un'installazione Claude Code CLI locale standard (fuori da questa sessione remota) se `.claude/agents/*.md` viene letto come previsto — se sì, aggiornare il limite #6 in `docs/system.md` da "non invocabile" a "non invocabile solo in sessioni remote/cloud"; se no, valutare se il formato dei tre file richiede una correzione |
