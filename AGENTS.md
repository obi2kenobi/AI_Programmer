# AGENTS.md — il contratto d'ingresso per agenti LLM in questo repo

> Se sei un agente LLM (Claude Code, OpenCode, sessione cloud, subagent) e sei
> atterrato qui, questo file è il primo da leggere. 6° ciclo, set 3 (2026-08-24):
> prima conteneva solo le regole graphify — un agente nuovo doveva scoprire il resto
> per deduzione. Ora dichiara le cinque cose che ogni agente deve sapere per
> lavorare qui senza rompere il metodo.

## 0. Lo standard (non serve invocarlo)

Questo repo lavora col metodo attivo PER MECCANISMO: all'apertura di una
sessione e a OGNI prompt, un hook inietta il promemoria del metodo
(`tools/metodo-reminder-hook.sh`). Se sei un agente e leggi questo file, il
metodo è già in opera intorno a te: METHOD.md §"Lo standard" dice cosa deve
esserci fisicamente in una repo che lo adotta (CLAUDE.md, skill, agenti, HOOK,
.night-verify) e `tools/sync-repo.sh <owner/repo> --standard` lo porta tutto.

## 0bis. Lavoro distribuito (a due o più mani — Luca, Lavinia, sessioni)

- **Chi sta toccando cosa ADESSO**: `bash tools/presidio.sh lista` e dichiara la tua
  zona (`claim`): presenza visibile, non lock — la contesa si risolve parlandosi.
  Skill completa: `lavoro-condiviso`.
- **Chi ha in carico cosa**: le commesse sono issue GitHub — usa l'`assignee`
  (`gh issue edit N --add-assignee @utente`): è adozione di ciò che GitHub già
  dà, non un sistema parallelo da inventare.
- **I diari append-only non confliggono**: `SAL.md` e `docs/campo/*.md` usano il
  merge driver `union` (`.gitattributes`): due append simultanee si fondono
  tenendo ENTRAMBE le voci, senza markers — VERIFICATO con esperimento reale
  (2026-08-27: senza driver è conflitto certo; con union, merge pulito). Il
  driver vale SOLO per diari: mai per codice (union non fa review, concatena).
- **Il turno notturno resta centralizzato** sul Mac del proprietario
  (`repos.conf`/`repos.key` locali, per disegno): il lavoro diurno è distribuito
  sulle stesse repo onboardate; notte e giudizio del mattino no. Cambiarlo è
  decisione di architettura, non una configurazione.
- **Prima regola di ogni PR**: le stesse verifiche dichiarate e lo stesso gate
  valgono per chiunque apra il branch (`claude/*`, `night/*`, `glm/*`).

## 1. Le regole vincolanti e la mappa

- `CLAUDE.md` — le regole (Karpathy §1-6 + §7 delega): valgono per ogni agente, non
  solo per Claude Code, qualunque sia il nome del file.
- `METHOD.md` — il metodo in una pagina: la pipeline, le fonti di verità per fase.
- `docs/system.md` — l'architettura e i LIMITI DICHIARATI (ciò che il sistema NON
  fa: leggili prima di presumere che qualcosa sia un bug).
- `SAL.md` — il diario: ciò che un giro ha imparato, con data. Grep per il tuo
  dominio prima di partire (skill `selezione-contesto` per il metodo con budget).

## 2. La pipeline e i suoi artefatti (chi produce cosa, chi lo cita)

```
/selezione-contesto → /brainstorming ⇄ /design-doc → /goal (piccolo) | commessa (grande)
                                                              → /audit-commessa → notte → censore → review di Luca
  (il censore, night-shift/revisore.sh: fonde le PR `caccia:`, lascia un parere sulle PR di issue;
  il morning-gate è in pensione dal 2026-09-23)
TASK DA UNA SESSIONE (terza corsia, 7° ciclo 2026-08-24 — dal report sul campo):
  chiarito in 1-2 domande, un file, verificabile qui e ora → si fa e basta, col metodo
  ma SENZA pipeline (dettaglio: METHOD.md) — bug reale corretto: revisione 14 lenti,
  2026-08-28, questa copia del diagramma era rimasta indietro di due giri.
```

Ogni fase consuma l'artefatto della precedente CITANDO il percorso, mai
riassumendo a memoria: design-doc cita il criterio di successo emerso dal
brainstorming; la sezione `## Design` della commessa cita il PERCORSO del
design-doc; il gate verifica che il percorso esista. Un artefatto non citato è
lavoro che il giro dopo non esiste.

## 3. I cervelli disponibili (come delegare)

`llm/ask-qwen.sh` (locale, notturno) · `llm/ask-opus.sh` (Claude headless) ·
`llm/ask-glm.sh` (API). Contratto unico: prompt come argomento, contesto via
stdin, risposta su stdout, rc 0/1/2. Matrice completa in `llm/README.md`. Per un
calcolo contabile NON delegare l'invenzione della formula: cerca l'oracolo.

## 4. I calcoli contabili: oracoli e agenti

- **Oracoli** (`tools/*.py`, formula minata dal codice reale REPO-E, mai inventata):
  scostamento, riconciliazione e valorizzazione magazzino, margine per documento,
  accuratezza fatture, leasing, rating DSO clienti, bilancio per BU, cespiti,
  indici di crisi, scadenzario aging — 11 in totale. La copertura per dominio:
  `docs/mappa-dominio-gas-src.md`.
- **Rilevatori** (7° ciclo): `tools/gas_qualita.py <cartella>` censisce le
  famiglie misurate (test finti, nomi in ombra, fusi, paginazione-indizio…)
  con la domanda discriminante — ausilio, non verdetto;
  `tools/verifica_banco.py <uscita>` giudica la riga-verdetto canonica di un
  banco GAS (`attese eseguite: N/M · fallite: K`): l'exit code non è un verdetto.
- **Agenti** (`.claude/agents/` per il giorno, specchiati in `.opencode/agent/`
  per la notte): censitore-forma-dati · contabilita-analitica (applica) ·
  costruttore-calcoli-gestionali (costruisce) · revisore-calcoli-critici (dubita) ·
  revisore-gas (censimento+banco+sabotaggio su un progetto Apps Script intero) ·
  sviluppatore-gas (progetti Apps Script interi). I corpi sono identici fra le due
  cartelle per contratto (`tests/test-opencode-agent-sync.sh`).

### Portare il metodo in una repo

`bash tools/sync-repo.sh <owner/repo> --standard` — una PR con tutto il sistema
(CLAUDE.md, skill, agenti, hook, formato report). Senza flag: verifica e riporta
il drift di CLAUDE.md.

### Il catalogo pattern

`patterns/` contiene il catalogo dei pattern (registro: `patterns/README.md`), ciascuno nato da un errore vero con ancore
a file:riga del progetto che l'ha pagato. Indice: `patterns/README.md`.
Consulta prima di reinventare; dopo averne pagato uno nuovo, scrivilo.

## 5. La verifica: come esco da qui

`bash tools/suite.sh` — la suite completa (verde = «Suite test hub: N/N file superati», `tools/suite.sh:72`); poi le altre righe di
`.night-verify` (shellcheck, py-gate, privacy-check, indice SAL), UNA ALLA VOLTA come fa il turno.
(2026-09-23, notte dei giri: qui si insegnava a eseguire il file intero con bash, che esce 0 senza far girare un
solo banco — la riga `@540 …` e' un budget che capisce solo il turno, e l'rc e' quello dell'ultima riga.) Se touchi `SAL.md`, rigenera l'indice
(`bash tools/sal-indice.sh`) e porta le modifiche in un commit/giro prima che il
gate giri. Privacy (CLAUDE.md §7, «Public repo, private work»): i nomi di repo e di persone
possono comparire, l'ACCESSO mai (segreti, credenziali, token, push in produzione). I codici REPO-x
restano nei testi storici, ma il loro registro è ritirato. I termini delle liste locali
(`repos.key`, `~/.privacy-nomi`) il privacy-check li blocca ancora: se valga per loro «nomi sì» è una
domanda aperta a Luca (DEBITI).

## Regole graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- (2026-09-24, fourth ventaglio, Q4 — measured) **Limits of the graph.** For "who uses X" run `graphify affected "X"` (file:L per caller), not `query`: with the default budget `query` prints nodes, not call sites. Calls written inside `"$(f …)"`, `<(f)` and `trap '…'` are INVISIBLE to the bash extractor (`graphify affected lente_pr` says "No affected nodes found", yet `night-shift/night-shift.sh` calls it twice): before calling anything dead, confirm with `grep -rn 'X'`. An edge carries only the FIRST call site of each caller. Query with code terms (`mask secrets`), not an Italian sentence (it matches words like "maschera", "registra"). Not in the graph: top-of-script constants, `.night-verify`, `.claude/settings.json`, plist and conf files — grep them. After editing a file, its file:L in the graph are stale until the next commit.
- (D1, 2026-09-23) `graphify-out/graph.json` is VERSIONED and kept fresh by `tools/graphify-spina.sh` (SessionStart hook, and the pre-commit stages it); the semantic pass (docs, patterns) runs at night with Ollama (`tools/grafo-semantico.sh`) and arrives as a draft PR.
