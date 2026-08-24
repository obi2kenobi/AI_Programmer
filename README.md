# AI_Programmer

Hub di metodo per lo sviluppo assistito da AI di Gruppo Camarlinghi: regole vincolanti
(`CLAUDE.md`), contesto per progetto (`PROJECT.md`), turno notturno (`night-shift/`),
wrapper per i modelli (`llm/`). Mappa completa dell'architettura: `docs/system.md`.
Il metodo in una pagina: `METHOD.md`.

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
