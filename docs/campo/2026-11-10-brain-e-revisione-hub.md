# 2026-11-10 — il Brain e la revisione dell'hub
**Autore**: sessione cloud di Luca (ramo claude/admiring-allen-na6rxr)

## Cosa ho usato
`tools/suite.sh --tutti`, `banco-passaggio.sh --solo-copertura`, `pre-commit.sh`, `debiti-riapertura.sh`, un worktree
di origin/main come banco di confronto, un agente revisore in sola lettura; skill post-mortem (E-062). Non c'erano in
cloud: graphify, Vale, clasp, Ollama, shellcheck (il revisore l'ha installato in un venv temporaneo).

## Cosa ho improvvisato
Il confronto col worktree pulito di main per sapere quali rossi erano miei: la suite non lo offre. Vale e clasp
FINTI nei banchi dove mancano.

## Cosa ha retto / ostacolato
Hanno pagato: la suite che pretende «N OK, 0 FAIL» (ha preso un mio banco muto), test-chiarezza (docstring),
test-e002-banchi-curati (ha preso un mio `grep | grep -q`), la copertura per file toccato. Ha ostacolato: la suite
fail-fast su `main` già rossa al 27° banco — chi arriva non vede il quadro finché non lancia `--tutti`.

## Proposta al canone
Un banco rosso su main va saldato prima del lavoro nuovo, come i debiti alla riapertura: un `.night-verify-profonda`
che nessuno guarda in verde lascia marcire 194 banchi dietro il primo rosso.
