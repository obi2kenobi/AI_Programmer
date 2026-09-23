# 2026-09-23 — mappatura IA per l'AI Act (lettura di tutti i repo)
**Autore**: sessione cloud per Luca

## Cosa ho usato
Scansione a grep degli endpoint di IA nel codice (59 repo clonati in sola lettura, più la copia `gas-src` del vivo); nessuna skill del canone copriva un censimento trasversale "quale IA usa il parco". NON RAGGIUNGIBILE: i fork di altri owner (la sessione non ammette repo di owner diversi).

## Cosa ho improvvisato
Distinguere l'IA "in esercizio" (endpoint chiamati dal codice sorgente) da quella "di sviluppo" (CLAUDE.md, .claude, .opencode): il primo grep contava anche le parole italiane ("dalle") e i documenti del metodo, gonfiando i conteggi.

## Proposta al canone
Un `tools/censimento-ia.sh` che produca l'elenco fornitore·modello·file per repo.
