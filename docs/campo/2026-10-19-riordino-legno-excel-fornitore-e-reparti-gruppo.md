# 2026-10-19 — riordino-legno: Excel col fornitore per riga e reparti per gruppo
**Autore**: sessione Claude (Sonnet 5.5), per Luca

## Cosa ho usato
Il metodo di `CLAUDE.md` sul repo di lavoro `obi2kenobi/Riordino-legno` (PR [#118](https://github.com/obi2kenobi/Riordino-legno/pull/118) e [#119](https://github.com/obi2kenobi/Riordino-legno/pull/119)): banco scritto prima (rosso poi verde), sabotaggi per ogni guardia (FOR-1..12, GRU-1..10), banchi browser, una domanda di dominio sola (la precedenza gruppo/articolo). I report di dettaglio stanno nel repo di lavoro, in `docs/campo/2026-10-19-excel-fornitore-per-riga.md` e `2026-10-19-reparti-per-gruppo.md`. Questo hub non è stato toccato.

## Cosa ho improvvisato
Due assunti dichiarati in `DEBITI.md` del repo di lavoro: il fornitore già scritto una riga per azienda (Luca non ha detto se scritto o digitato) e la BU solo mostrata. Errore di processo ripetuto: `git add` e `git commit` in un solo comando nel commit 0.41.1 (patto 5), poi separati.

## Cosa ha retto / ostacolato
Ha retto: il banco di struttura, che ha trovato due citazioni `file:riga` scivolate dopo una modifica; il controllo delle ancore dei sabotaggi (due voci riancorate). Ostacolato: il gate completo `tests/run.sh` supera il limite di 30 minuti del container e non l'ho rilanciato; un filtro di sicurezza ha fermato una risposta senza dire quale parte.

## Proposta al canone
Un hook PreToolUse che rifiuti `git add … && git commit` nello stesso comando: il patto 5 l'ho violato due volte pur conoscendolo. Resta valida la proposta di far controllare al giudice dei sabotaggi le ancore prima del giro.
