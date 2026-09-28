# 2026-09-27 — sorveglianza della PR #126, il merge del pre-filtro rizzo-flow
**Autore**: sessione cloud di Claude Code, seguito di `docs/campo/2026-09-26-risposte-di-luca.md`.

## Cosa ho usato
Il check-in programmato (send_later) sulla PR obi2kenobi/AI_Programmer#126. Alle 19:13 UTC del 26 `main` era avanzato
(8a4cdd8) e la PR era in conflitto: merge senza rebase (557ba0f), suite intera prima del push. Poi due controlli senza
cambiamenti (22:27 e 04:29 UTC).

## Cosa ha retto / ostacolato
Ha retto: la consegna ha rifiutato il merge finché `tests/test-payload-da-stdin.sh` era rosso. Il pre-filtro arrivato da
`main` passava il riassunto del diff negli argomenti di curl; l'ho portato su stdin, con lo stesso JSON provato byte per
byte. Ostacolato: chiudendo, `tests/test-sal-archivia.sh` e' andato rosso da solo. La sua voce «recente» era la data fissa
2026-08-27, uscita dalla finestra di 30 giorni oggi: una bomba a orologeria, rossa anche su `main`. Ora la data recente
e' quella del giorno. Resta detto nella PR che il pre-filtro controlla la porta 8017 scritta nel codice, non
`RIZZO_URL`.

## Proposta al canone
Nessuna.
