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
- Exit 0 ok · 1 errore · 2 via non configurata (ask-glm sempre; ask-opus quando
  l'errore di `claude -p` indica auth assente — armonizzato, set 1 2026-08-22)
- Override per chiamata: `ASK_MODEL`, `ASK_TIMEOUT` — **davvero** universali su tutti e
  tre i wrapper (set 1 2026-08-22: prima solo parzialmente implementati, verificato e
  corretto); specifiche: `QWEN_MODEL`, `QWEN_CTX`, `QWEN_THINK`, `GLM_MODEL`
- **Traccia locale** (`~/.ai-programmer-usage.log`, mai versionata, best-effort):
  ogni chiamata registra cervello/esito/durata/lunghezza prompt — mai il contenuto.
  Simmetria con la memoria del turno notturno (SAL.md + metrics/gate.csv). Percorso
  configurabile con `ASK_USAGE_LOG` (utile nei test, per non scrivere nel vero $HOME).
  **Riepilogo**: `llm/usage-summary.sh` — la stessa simmetria completata (4° ciclo, set 3,
  2026-08-23): il log si scriveva ma nessuno lo leggeva, la traccia entrava e non
  usciva mai come insight. Per cervello: chiamate, successi, % successo, durata media.

## La matrice decisionale — quale cervello per quale compito (fatti misurati, 2026-08)

| Compito | Cervello | Perché |
|---|---|---|
| Digest/bozze/triage one-shot, alta volume, privacy | **ask-qwen** (locale) | costo marginale zero, dati che non lasciano il Mac; 3,7-5,9 tok/s a Mac scarico |
| Commesse meccaniche ripetitive | **ask-qwen** via turno notturno | tutta la notte che serve (nessun limite di tempo, decisione 2026-08-21) |
| Indagine, giudizio, architettura, correzione | **sessione diretta** (ZCode/GLM o Claude Code/Opus) — skill `dev-critic` per il giro di scoperta gap/nuove idee | tre notti di test: il modello locale capisce ma non converge dove serve giudizio — la lezione dell'issue #363 |
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
