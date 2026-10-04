# roles/ — la faretra dei ruoli, in un formato che parla a QUALSIASI LLM

<!--
Nata il 2026-10-03 (decisione di Luca): «AI_Programmer non è un sistema solo
Claude — tutto deve essere disponibile a tutti gli LLM, anche i cinesi
open-weight». Prima di oggi i ruoli vivevano in due copie con formati
proprietari (.claude/agents/ per Claude, .opencode/agent/ per OpenCode) e la
notte non li usava affatto: risolvi-issue risolveva SENZA canone di dominio.
Questa directory è la fonte unica: i due specchietti si GENERANO
(tools/genera-agenti.sh), la notte legge qui, ogni harness che legge markdown
(Qwen via Ollama, DeepSeek, GLM, una sessione cloud, un umano) legge qui.
Banco: tests/test-roles-sync.sh (gli specchietti non derivano → rosso).
-->

## Il formato (neutrale per costruzione)

Ogni file è un ruolo:

```markdown
---
nome: sviluppatore-gas
descrizione: <a cosa serve, quando invocarlo — una riga, anche lunga>
quando: <condizione operativa sintetica>
domini: <lista separata da virgole>
edita: si | no
---

# Il corpo: missione, metodo, regole, confini
```

- `nome` — il kebab-case, stabile: è la chiave che notte e harness citano.
- `descrizione` — il testo che un harness usa per DECIDERE se invocare il ruolo
  (la `description` di Claude e OpenCode nasce da qui, verbatim).
- `quando` — la stessa cosa in forma breve, per indici e prompt notturni.
- `domini` — per il routing: la notte trova i ruoli di un repo per dominio.
- `edita` — l'UNICO permesso che distingue chi costruisce da chi giudica:
  `no` = il ruolo legge ed esegue banchi, MAI scrive il repo.

## Chi consuma e come

| Consumatore | Come |
|---|---|
| **La notte** (risolvi-issue, caccia) | `roles/<nome>.md` iniettato nel prompt per i ruoli attivi del repo (`.git/ruoli-attivi`, vedi tools/rileva-ruoli.sh) |
| **Claude Code** | `.claude/agents/<nome>.md` GENERATO (frontmatter name/description/tools) |
| **OpenCode** | `.opencode/agent/<nome>.md` GENERATO (frontmatter mode/permission) |
| **Qualsiasi LLM open-weight** | il file stesso: body markdown puro, nessun protocollo. Lo si incolla nel prompt o lo si mette in RAG — non serve nient'altro |
| **Un umano** | uguale, è un documento leggibile |

## Le regole della casa

1. **Il corpo non cita MAI un percorso di harness** (`.claude/`, `.opencode/`):
   si cita la skill per NOME («skill `gas-sviluppo`»), ciascuno la trova dove
   il suo harness la tiene. Le eccezioni storiche migrate sono state neutralizzate.
2. **Si modifica roles/, mai gli specchietti**: chi scrive in .claude/agents/
   vede il suo lavoro cancellato al prossimo giro del generatore (è voluto:
   la deriva muore così).
3. **Ogni ruolo nuovo nasce con**: missione, metodo, confini, e almeno un
   aggancio a qualcosa di misurato (un pattern, un errore del registro, un
   canone di repo veri). Niente ruoli da manuale astratto.
4. **Il numero si conta, non si scrive** (canone del catalogo pattern).

## L'inventario (si conta, non si scrive)

Sviluppo GAS · revisione GAS · censimento forma dati · contabilità analitica ·
costruzione calcoli · revisione calcoli · analisi trading · pipeline dati ·
logistica · revisione Python · cura della conoscenza.
