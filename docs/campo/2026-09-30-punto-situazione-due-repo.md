# 2026-09-30 — punto della situazione su Registrazione_Fatture_Acquisto e Magazzino_Treviso
**Autore**: sessione Claude Code (claude/charming-bohr-lceeat), su richiesta di Luca

## Cosa ho usato
`tools/debiti-riapertura.sh` (hub), `add_repo` + clone shallow dei due repo, lettura di PROJECT.md, SAL.md, DEBITI.md, docs/campo, issue e PR via MCP GitHub. Nessuna modifica ai due repo. Non ho usato il grafo: graphify è ASSENTE (navigazione a grep, dichiarato dall'hook).

## Cosa ho improvvisato
Magazzino_Treviso non ha `tools/debiti-riapertura.sh`: il conteggio dei debiti (468 righe, circa 310 non marcate chiuse) l'ho fatto a grep, quindi è una stima. Le sezioni di PROJECT.md dei due repo sono state lette solo in parte (Registrazione) o per niente (Magazzino); i report dal campo di Magazzino dopo il 24/9 non sono stati letti.

## Cosa ha retto / ostacolato
Ha retto: la riapertura per debiti ha dato subito l'elenco di R1, R2 e D1. Ha ostacolato: il limite di 2 operazioni git concorrenti del proxy ha imposto i clone in serie.

## Proposta al canone
Portare `debiti-riapertura.sh` anche nei repo gemelli (oggi il settimo patto non è eseguibile lì).
