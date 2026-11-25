---
repo: AI_Programmer
software:
  - Hub di metodo (root docs)
  - llm/ (wrapper modelli)
  - night-shift/ (turno notturno)
  - tools/ (suite, censimento BC, cervello, gas, varie)
  - cervello/ (memoria dei concetti)
  - docs/bc/ (censimento Business Central)
  - tests/ (suite test)
aggiornato: 2026-11-25
---

# Istruzioni d'uso — AI_Programmer

Hub di metodo per sviluppo assistito da AI di Gruppo Camarlinghi: regole (`CLAUDE.md`), contesto (`PROJECT.md`), turno notturno (`night-shift/`), wrapper LLM (`llm/`). Mappa architettura: `docs/system.md`. Metodo: `METHOD.md`. Uso quotidiano: `docs/MANUALE-OPERATIVO.md`.

## Hub di metodo (root)

### Requisiti
Repo git clonato; `bash`; Python 3 per i tool `tools/*.py`.
### Installazione
`git clone <url>`; nessun setup obbligatorio per leggere la documentazione.
### Avvio
Leggere `README.md` → `docs/system.md` → `docs/MANUALE-OPERATIVO.md`.
### Uso
Formato: `CLAUDE.md` (regole vincolanti), `PROJECT.md`, `METHOD.md`, `DEBITI.md`, `SAL.md`.
### Verifica
`bash tools/suite.sh` (ogni `tests/test-*.sh`, riepilogo N/TOT).
### Problemi noti
Alcuni comandi `/nome` citati sono debiti (vedi `DEBITI.md`), non bug.

## llm/ — wrapper modelli

### Requisiti
`llm/ask-<cervello>.sh`: bash; `ask-opus` serve `claude` CLI autenticato; `ask-qwen` serve Ollama locale; `ask-glm` serve chiave `<GLM_API_KEY>` (non versionata).
### Installazione
Nessuna: wrapper in-repo. Creare eseguibile se mancante (`chmod +x llm/*.sh`).
### Avvio
`llm/ask-<cervello>.sh "prompt"` — contesto lungo via stdin: `cat file | llm/ask-<cervello>.sh "cosa farne"`.
### Uso
Astrazione unica: risposta su stdout, diagnosi su stderr, exit 0 ok / 1 errore / 2 non configurato. Override `ASK_MODEL`, `ASK_TIMEOUT`. Cloud: prompt mascherati (secret → `«segreto <impronta> · N caratteri»`). `llm/usage-summary.sh` legge `~/.ai-programmer-usage.log`.
### Verifica
`llm/ask-qwen.sh "rispondi ok"` (locale) — non verificato in questa sessione; cloud non chiamati.
### Problemi noti
`ask-glm` sempre via 2 se non configurato; `ask-opus` via 2 se auth mancante.

## night-shift/ — turno notturno

### Requisiti
`bash`; `night-shift/repos.conf` copiato da `repos.conf.example`; plist per cron in `night-shift/plist/`.
### Installazione
`night-shift/install.sh`; config `night-shift/repos-index.md`.
### Avvio
`night-shift/night-shift.sh` (notte); `morning-digest.sh` / `morning-gate.sh` (mattina); `gate-esito.sh`, `gate-summary.sh` (check).
### Uso
Automazione pianificata; riporta esito su log/SAL, non in chat.
### Verifica
`night-shift/sandbox.sb` definisce il sandbox macOS; eseguire un singolo script in dry-run prima.
### Problemi noti
Non verificato in questa sessione (è automazione notturna).

## tools/ — script e suite

### Requisiti
`bash` + Python 3. Struttura `tools/` (~120 file, .sh/.py/.mjs).
### Installazione
Nessuna (in-repo).
### Avvio
`bash tools/suite.sh` — suite completa test. Vari gruppi: `bc_*.py` (censimento BC), `brain_*.py` (cervello), `gas_qualita.py` + `verifica_banco.py` (oracoli GAS), `dashboard.py`, `sistema`/`status-page.sh`.
### Uso
Ad es. `python3 tools/bc_index.py` (indice BC con salute), `python3 tools/gas_qualita.py`, `bash tools/giorno.sh inizio <repo>`.
### Verifica
`bash tools/suite.sh` (N/TOT in uscita).
### Problemi noti
Alcuni script richiedono chiavi/utenti locali: non verificato.

## cervello/ — memoria concetti

### Requisiti
`cervello/indice.md`; tool `tools/brain_*.py` e shell `cervello-*.sh`.
### Installazione
Nessuna.
### Avvio
`tools/brain_ingest.py` / `brain_interroga.py` (vedi `cervello/README.md`).
### Uso
Concetti/decisioni: `indice.md`, `famiglia-*`, `decisione-*`, `sospeso-*`.
### Verifica
`grep -E '^#' cervello/indice.md` (o il comando del README locale).
### Problemi noti
Non verificato in questa sessione.

## docs/bc/ — censimento Business Central

### Requisiti
Python 3; dati in `docs/bc/` (catalogo, endpoints).
### Installazione
Nessuna.
### Avvio
`python3 tools/bc_tipi_metadata.py` (tipi da schema `$metadata`); `python3 tools/bc_index.py` (indice con salute).
### Uso
`docs/bc/CATALOGO_ENDPOINT_BC.md` (231 endpoint su 258), `docs/bc/endpoints/*.md`.
### Verifica
`python3 tools/bc_index.py` (esito non verificato in questa sessione).
### Problemi noti
Dipende dai dati catalogo presenti.

## tests/ — suite test

### Requisiti
`bash`; `tests/test-*.sh`.
### Installazione
Nessuna.
### Avvio
`bash tools/suite.sh`.
### Uso
Ogni test è un `test-*.sh`; riepilogo N/TOT in uscita.
### Verifica
Lanciare `bash tools/suite.sh` — non eseguita in questa sessione (fuori perimetro).
### Problemi noti
Nessuno segnalato.

## Segreti e configurazione
- Nessun segreto in-repo. Chiavi (es. `<GLM_API_KEY>`) via env, mai versionate.
- Permessi cervello: `tools/brain_permessi.py`, `tools/privacy-check.sh`.
