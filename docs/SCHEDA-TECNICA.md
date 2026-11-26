---
repo: AI_Programmer
linguaggi: [bash, python, markdown]
stato: in manutenzione
aggiornato: 2026-11-26
---

# Scheda tecnica — AI_Programmer

## Scopo
Hub di metodo per lo sviluppo assistito da AI di Gruppo Camarlinghi: regole vincolanti (`CLAUDE.md`), contesto di progetto (`PROJECT.md`), turno notturno (`night-shift/`), wrapper dei modelli (`llm/`), tool per censimento BC e rilevatori contabili. Documentazione: `docs/system.md`, `METHOD.md`, `docs/MANUALE-OPERATIVO.md`.

## Architettura
Repo documentazione/metodo con sotto-aree: root (regole e contesto), `docs/` (system, istruzioni, bc/, campo/, errori/, giri/, studi/), `llm/` (wrapper modelli), `night-shift/` (automazione notturna), `tools/` (~120 script bash/python), `tests/` (~250 test), `cervello/` (memoria concetti), `roles/`, `loops/`, `patterns/`, `profiles/`, `router/`, `metrics/`, `graphify-out/`.

## Componenti
| Componente | Ruolo | File |
|---|---|---|
| regole | CLAUDE.md 44 righe (originale in docs/REGOLE-CLAUDE-originale.md) | CLAUDE.md |
| metodo | metodo in una pagina | METHOD.md |
| contesto | strumenti, percorsi, requisiti | PROJECT.md |
| turno notturno | automazione notturna | night-shift/ |
| wrapper LLM | ask-<cervello>.sh | llm/ |
| tool | suite, censimento BC, cervello, gas | tools/ |
| test | ~250 test-*.sh | tests/ |
| docs/bc | censimento 231/258 endpoint | docs/bc/ |

## Dati e interfacce
Interfacce esterne: CLI Claude Code (skill/agenti scoped per filesystem), Ollama locale (`ask-qwen`), Cloud API (`ask-opus`, `ask-glm` con `<GLM_API_KEY>`), Business Central via API per censimento (`tools/bc_map.py`, `tools/bc_tipi_metadata.py`). Output: report/diari in `docs/campo/`, `SAL.md`. Nessun servizio in ascolto.

## Dipendenze
Python 3 (stdlib, system 3.9); bash; sed/grep BSD; `timeout` solo con ramo perl ai_timeout. Non versionate dipendenze di terze parti oltre la stdlib.

## Configurazione
Variabili nomi: `ASK_MODEL`, `ASK_TIMEOUT`, `<GLM_API_KEY>`, `night-shift/repos.conf` (da .example). Segreti mai versionati; solo `<NOME_VARIABILE>`.

## Build e test
`bash tools/suite.sh` esegue `tests/test-*.sh` e riporta riepilogo N/TOT. Suite non eseguita in questa sessione (non verificato).

## Deploy
Nessun deploy di sistema; il repo si distribuisce via `tools/sync-repo.sh <repo> --standard` (copia regole/skill/agenti/hook). Turno notturno: plist in `night-shift/plist/`.

## Rischi e debito tecnico
Comandi `/nome` citati ma assenti in `.claude/skills`/`.claude/agents` sono debiti dichiarati (vedi DEBITI.md), non bug. Elenco agenti in sessione può non aggiornarsi subito dopo la creazione. Suite non eseguita in questa sessione.
