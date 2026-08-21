# llm/ — i cervelli richiamabili

Il repo **chiama i vari LLM**: ogni wrapper ha lo stesso contratto, così qualsiasi progetto,
script, agente o turno notturno delega a qualsiasi cervello con lo stesso gesto.

## Il contratto unico

```bash
llm/ask-<cervello>.sh "prompt"                # risposta su stdout
cat file.lungo | llm/ask-<cervello>.sh "cosa farne del contenuto"   # contesto via stdin
```

- Prompt come argomento, contesto lungo via stdin (mai incollato nel prompt)
- Risposta pulita su **stdout**; statistiche/diagnosi su **stderr**
- Exit 0 ok · 1 errore · 2 via non configurata (solo ask-glm)
- Override per chiamata: `ASK_MODEL`, `ASK_TIMEOUT`; specifiche: `QWEN_MODEL`, `QWEN_CTX`, `QWEN_THINK`

## La matrice decisionale — quale cervello per quale compito (fatti misurati, 2026-08)

| Compito | Cervello | Perché |
|---|---|---|
| Digest/bozze/triage one-shot, alta volume, privacy | **ask-qwen** (locale) | costo marginale zero, dati che non lasciano il Mac; 3,7-5,9 tok/s a Mac scarico |
| Commesse meccaniche ripetitive | **ask-qwen** via turno notturno | tutta la notte che serve (nessun limite di tempo, decisione 2026-08-21) |
| Indagine, giudizio, architettura, correzione | **sessione diretta** (ZCode/GLM o Claude Code/Opus) | tre notti di test: il modello locale capisce ma non converge dove serve giudizio — la lezione dell'issue #363 |
| Compito cloud programmatico (pipeline, script) | **ask-opus** | `claude -p` headless; auth nel Keychain (funziona da terminale utente/launchd) |
| Compito GLM programmatico | **ask-glm** | richiede `ZHIPUAI_API_KEY`; via naturale resta la sessione ZCode |

## Cosa NON delegare mai (a nessun cervello, ma sopratutto al locale)

- Catene agentiche multi-step con decisioni architetturali
- Qualsiasi cosa con segreti nei valori (mai nei riferimenti — regola _"Never expose secrets"_)
- Compiti la cui verifica non è dichiarata prima di iniziare (regola _"Done means proven"_)

## Limiti dichiarati (non promesse vuote)

- **Opus non passa da WayfinderRouter**: il router non implementa l'outbound Anthropic —
  ask-opus va diretto. Documentato in `docs/system.md`.
- **ask-glm**: endpoint OpenAI-compat non testato dal fornitore del router né da noi —
  configura e verifica prima di farci conto.
- **Apple Foundation Models**: rimandato a maturazione (superficie sperimentale, Aug 2026).
