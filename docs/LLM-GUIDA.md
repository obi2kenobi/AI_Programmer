# Guida LLM — AI_Programmer

Repo: `AI_Programmer` — hub di metodo per sviluppo assistito da AI di Gruppo Camarlinghi.
Ra-mo di riferimento: `op/M-012-4` (catena R1→R4), base `8079dc5`.

## Struttura reale (osservata)
- Root: `README.md`, `AGENTS.md`, `CLAUDE.md`, `METHOD.md`, `PROJECT.md`, `DEBITI.md`, `SAL.md`, `SAL-ARCHIVIO.md`
- `docs/`: `system.md` (365 righe), `MANUALE-OPERATIVO.md`, `benvenuto-collaboratori.md`, `documentazione-viva.md`, `eventi.md`, `funzionalita.md`, `mappa-dominio-gas-src.md`, `regole-cancelli.md`, `test-modelli-notturni-protocollo.md`, e sottocartelle `bc/`, `campo/`, `errori/`, `giri/`, `studi/`, `archivio/` (assente: nessun file superato da archiviare)
- `llm/`, `night-shift/`, `tools/`, `tests/`, `roles/`, `loops/`, `patterns/`, `cervello/`, `graphify-out/`, `metrics/`, `profiles/`, `router/`

## Comandi eseguiti (con esito)
- `git status && git branch --show-current` → branch `op/M-012-4`, albero pulito
- `git ls-tree -r --name-only HEAD` → file `docs/_guida-lista.txt` e `docs/_revisione.tsv` presenti
- `wc -l docs/*.md` → 1370 righe totali nei `.md` top di `docs/` (esito: 365 per `system.md`)
- `head -40 README.md` → leggibile, sezione "Lo stato di oggi" presente
- `ls docs/archivio/` → assente (non verificato come esistente)

## Comandi NON eseguiti / non verificati
- Suite completa `tools/suite.sh`: non eseguita (fuori dal perimetro di R4)
- `.claude/skills/` e `.claude/agents/`: presenti nel README ma non elencati qui per non inventare nomi

## Documenti superati
- Nessun `docs/archivio/` presente sul ramo; nessun documento superato da elencare.

## Per chi arriva
Leggi `README.md` → `docs/system.md` → `docs/MANUALE-OPERATIVO.md`. Non modificare `docs/_inventario.tsv` o `docs/_revisione.tsv` senza mandato.
