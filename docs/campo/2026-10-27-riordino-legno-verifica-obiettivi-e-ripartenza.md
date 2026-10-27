# 2026-10-27 — riordino-legno: verifica degli obiettivi, lavori in parallelo, ripartenza dopo il limite di spesa
**Autore**: sessione Claude Code (utente: Luca) — un coordinatore e agenti `revisore-gas` / `verificatore-frontend` (sola lettura) e `sviluppatore-gas` (consegne), PR #165–#171 del repo del progetto.

## Cosa ho usato
- Cinque letture indipendenti in sola lettura (obiettivi e decisioni, ciclo di un ordine, contratti, robustezza, interfaccia) su una copia pulita di `main`, riunite in `docs/progetto-acquisti/VERIFICA-OBIETTIVI-2026-10-22.md` (PR #170); poi quattro consegne in parallelo (backup e allarmi, correzioni dell'interfaccia, import dei contratti, guardie di produzione) con versione ed etichetta di guida assegnate in anticipo.
- Domande di dominio a Luca una alla volta finché ha detto «vai avanti senza domande»; da lì ogni scelta è un ASSUNTO scritto nella PR.

## Cosa ho improvvisato
- Per non tirare a indovinare «vero gestionale» ho scritto io una definizione in sei criteri e l'ho fatta confermare da Luca prima di lanciare gli agenti.
- Quando i quattro agenti si sono fermati per il limite di spesa (HTTP 429) ho aspettato il reset e li ho ripresi con `SendMessage`: il lavoro fatto era salvo nei worktree.

## Cosa ha retto / ostacolato
- **Ha retto**: le letture indipendenti hanno trovato cose che nessun banco vedeva: un elenco degli approvatori con «;» azzera i ruoli in silenzio; il confine dei 90 giorni dei contratti non era coperto da nessun test; il file con le credenziali di BC era tracciato da git.
- **Ha ostacolato**: il limite di spesa mensile ha fermato quattro agenti insieme a metà lavoro; un file `acquisti/urgente` è comparso nel checkout condiviso durante i giri (probabile redirezione di shell di un lavoro parallelo): lo scratchpad e il checkout condivisi restano un rischio.

## Proposta al canone
1. Prima di lanciare molti agenti in parallelo, controllare il margine del limite di spesa e dare a ciascuno un worktree proprio anche per le letture.
2. Un file con credenziali tracciato da git si scopre a ogni verifica ma nessuna regola lo ferma: aggiungere al cancello dei segreti il controllo `git ls-files | grep -i credenz`.
