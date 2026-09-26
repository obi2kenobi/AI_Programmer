# 2026-09-26 — le 15 risposte di Luca, applicate
**Autore**: sessione cloud di Claude Code, seguito di `docs/campo/2026-09-26-sorveglianza-pr-126.md`.

## Cosa ho usato
Le domande poste una alla volta con le opzioni (AskUserQuestion), poi una cura per commit: banco rosso, cura, sabotaggio
con `git stash`, consegna con la suite intera. Il Mac simulato (bash 3.2) per i due banchi nuovi.

## Cosa ho improvvisato
Il perimetro della domanda 12: la domanda nominava quattro oracoli, la risposta dice «tutti». Ho cercato con
`grep -l "^import csv" tools/*.py` quelli che leggono numeri da un CSV (otto) e li ho collegati tutti.

## Cosa ha retto / ostacolato
Ha retto: `tests/test-portabilita.sh` (V4 R1) ha preso due `$NOME»` senza graffe prima del push. Ha ostacolato: un
banco che copia un oracolo da solo in `/tmp` (`tests/test-bilancio-bu.sh`) ha perso l'import del modulo comune; e la
batteria avversaria prova HEAD, non l'albero (in DEBITI).

## Proposta al canone
Nessuna.
