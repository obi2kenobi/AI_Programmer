# AI_Programmer

Hub di metodo per lo sviluppo assistito da AI di Gruppo Camarlinghi: regole vincolanti
(`CLAUDE.md`), contesto per progetto (`PROJECT.md`), turno notturno (`night-shift/`),
wrapper per i modelli (`llm/`). Mappa completa dell'architettura: `docs/system.md`.
Il metodo in una pagina: `METHOD.md`. Come si usa ogni giorno: `docs/MANUALE-OPERATIVO.md`.
Se collabori per la prima volta: `docs/benvenuto-collaboratori.md` (3 frasi, 5 regole). Il diario del perché:
`SAL.md` (le voci attive) e `SAL-ARCHIVIO.md` (la memoria ruotata).

## Come funzionano le skill e gli agenti (per chi arriva nuovo)

Non c'è un elenco da consultare a mano: Claude Code li scopre da solo leggendo il
filesystem, e li fa scattare in due modi diversi.

- **Skill** (`.claude/skills/<nome>/SKILL.md`): ogni file ha un frontmatter YAML con
  `name` e `description`. La `description` NON è documentazione per l'utente — è il
  testo che Claude Code confronta con l'intento della richiesta per decidere se
  attivare quella skill automaticamente. Scattano anche invocando il comando
  esplicito `/nome-skill`. Non serve elencarle altrove: se un file compare qui,
  è già "attivo".
- **Agenti** (`.claude/agents/<nome>.md`): stesso meccanismo (`name`/`description`/
  `tools` nel frontmatter), ma sono sub-agenti invocabili — direttamente o dal tool
  `Agent`/`Task` di Claude Code — non skill richiamate a comando. **Limite noto**:
  l'elenco degli agenti disponibili in una sessione può non aggiornarsi subito dopo
  aver scritto un nuovo file agente (serve un refresh del roster, meccanismo non
  isolato — dettagli in `docs/system.md` §"Limiti dichiarati" #6). Se un'invocazione
  fallisce con "Agent type non trovato" appena dopo aver creato l'agente, non è
  necessariamente un bug del file: riprova più tardi o in una sessione nuova.
- **Comandi citati con `/nome`** in `METHOD.md`/`docs/system.md` che NON sono né in
  `.claude/skills/` né in `.claude/agents/` sono debiti dichiarati, non bug: cercali
  in `DEBITI.md` prima di assumere che manchino per errore.

Per aggiungerne uno nuovo o capire come sono scritti: skill `skill-creator`
(builtin di Claude Code) per le skill; `.claude/agents/*.md` esistenti come modello
per gli agenti.


## Lo stato di oggi (2026-08-27, dopo i cicli 6°-8°)

- **Standard, non opzione**: SessionStart e UserPromptSubmit iniettano il metodo
  meccanicamente; `tools/sync-repo.sh <repo> --standard` porta il sistema intero
  (CLAUDE.md, skill, agenti, hook, formato report) in qualsiasi repo.
- **Censimento Business Central**: 231 endpoint su 258 del catalogo
  (`docs/bc/CATALOGO_ENDPOINT_BC.md`), tipi dallo schema `$metadata`
  (`tools/bc_tipi_metadata.py`), indice con salute visibile (`tools/bc_index.py`).
- **11 oracoli** contabili minati dal parco REPO-E (`docs/mappa-dominio-gas-src.md`)
  e due rilevatori meccanici: `tools/gas_qualita.py` (famiglie di difetti misurate)
  e `tools/verifica_banco.py` (riga-verdetto dei banchi).
- **Canone GAS**: skill `gas-sviluppo` (corpus REPO-E distillato) + 6 agenti
  (specchiati OpenCode con anti-drift).
- **Lavoro distribuito**: diari append-only con merge `union` (verificato),
  assignee GitHub per le commesse, `AGENTS.md` §0bis.
- **Ogni uso lascia il segno**: report dal campo a fine sessione
  (hook Stop + `docs/campo/`).
- Suite: 87/87 (`bash .night-verify`).
