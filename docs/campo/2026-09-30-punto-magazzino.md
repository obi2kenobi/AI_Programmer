# 2026-09-30 — punto-magazzino
**Autore**: sessione Claude Code (richiesta di Luca), branch `claude/quirky-newton-n1id0u`. Solo lettura: nessuna riga di codice toccata.

## Cosa ho usato
`tools/debiti-riapertura.sh` (settimo patto), gate `.night-verify` di Sistema-Gestione-Magazzino eseguito sul clone (exit 0, 95 sezioni), lettura di PROJECT.md, SAL.md, DEBITI.md, README.md, PR e rami via GitHub MCP. NON usati: la skill `gas-sviluppo` e gli agenti GAS (era una ricognizione senza consulenza né consegna); `graphify` era assente (grafo DEGRADATO, navigazione a grep).

## Cosa ho improvvisato
«Leggi tutti i repo» era ambiguo: ho letto i due nominati (hub + magazzino) e dichiarato che l'account ne ha oltre 50 fuori sessione, invece di aprirli. Il repo magazzino è stato aggiunto con `add_repo` a metà sessione (il confine non era dichiarato prima).

## Cosa ha retto / ostacolato
Ha retto: il gate del repo eseguito in 4 s diede subito un verde verificato. Ostacolato: `PROJECT.md` del magazzino dice che `DEBITI.md` non esiste, ma dal 2026-09-29 (PR #170) esiste ed è la copia dei debiti dell'hub, non i suoi; SAL.md §6 è fermo al 2026-06-26. Due documenti che smentiscono il repo, trovati eseguendo `ls`, non dal metodo.

## Proposta al canone
`sync-repo --standard` non dovrebbe copiare `DEBITI.md` dell'hub in un repo cliente: crea un registro con i debiti sbagliati e smentisce il suo PROJECT.md. Da valutare, non ancora riprodotto sull'hub.
