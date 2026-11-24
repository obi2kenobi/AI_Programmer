# CLAUDE.md — AI_Programmer (ridotto, max 100 righe)

> Originale (213 righe) salvato in `docs/REGOLE-CLAUDE-originale.md`. Questo file è la versione
> sintetica: legge l'originale per le provenenze e le regole complete.

## Scopo
Hub di metodo per AI-assisted dev di Gruppo Camarlinghi (pubblico: solo metodo, mai accessi).
Ra-mo di lavoro: `docs/g7-giro2-2026-11`, base `origin/main`.

## Struttura
- Root: `README.md`, `AGENTS.md`, `CLAUDE.md`, `METHOD.md`, `PROJECT.md`, `DEBITI.md`, `SAL.md`
- `docs/`: `system.md`, `MANUALE-OPERATIVO.md`, `METODO-MINI.md`, sottocartelle `bc/`, `campo/`, `errori/`, `giri/`, `studi/`, `llm/`, `night-shift/`, `tools/`, `tests/`
- `docs/LLM-GUIDA.md` (guida LLM), `docs/_inventario.tsv`, `docs/_revisione.tsv`, `docs/_guida-lista.txt`

## Comandi (esito dichiarato: non verificato se non eseguito in questa sessione)
- `git status` → albero pulito (verificato 2026-11-24)
- `bash tools/suite.sh` → non eseguito in questa sessione: non verificato
- Deploy (`tools/deploy-gas.sh`) → non eseguito: non verificato (tutti i deploy vanno per la porta del gate)

## Convenzioni
- Regole universali in questo file; contesto specifico di un progetto in `PROJECT.md`.
- Commit dopo ogni passo: `<type>: <short>` (feat/fix/refactor/docs/test/chore).
- Mai force push. Review `git diff` prima di committare.
- Problemi segnalati subito; niente silenzio. Domande prima del codice (file numerato se ambiguo).
- Il codice parla: log a ogni bivio. Report di chiusura in `docs/campo/`.
- Il debito si brucia alla riapertura (`bash tools/debiti-riapertura.sh`).
- Leggere il grafo (`graphify query "..."`) prima di paging dei file.

## Cosa non toccare
- Non toccare `docs/_inventario.tsv` o `docs/_revisione.tsv` senza mandato.
- Non toccare i segreti o i loro valori; riferirsi solo al path.
- I vivi in produzione non si toccano mai.
- Non comprimere mai la sicurezza o l'accessibilità; niente codice morto; zero waste.

## Segreti
Solo segnaposto in `.env.example`. Blocco segreto in output: mai valori grezzi; usare
«secret <fingerprint> · N chars» se una riga potrebbe portarli fuori per sbaglio.

## Delegate
- Locali (`llm/ask-qwen.sh`): digest, draft, triage.
- Night shift: issue `night-shift` → PR draft; non delegare decisioni architetturali.

## Rimando
Guida LLM completa: `docs/LLM-GUIDA.md`. Appunti repo: `~/graphify-mandati/imparato/AI_Programmer.md`.
