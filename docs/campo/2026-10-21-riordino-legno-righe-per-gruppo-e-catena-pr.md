# 2026-10-21 — riordino-legno: righe per gruppo nella mail e catena di PR senza conflitti
**Autore**: sessione Claude Code (utente: Luca) — lavoro ancora aperto: i 20 giri di revisione NON sono iniziati.

## Cosa ho usato
Banchi `tests/banco-acq-*.js` e browser, giudice delle mutazioni (`MUT_SOLO`, `MUT_GATE=browser`), controllo ancore `ancore.js`, riallineamento citazioni `fixcit.py`; worktree per ramo (/tmp/neg8–11). Non c'era: un comando unico che dica «questa catena di rami è senza conflitti» (l'ho fatto a mano, merge per merge).

## Cosa ho improvvisato
Catena cumulativa #128 → #129 → #131 → #132 (ogni ramo fonde il precedente, base PR resta `main`) per evitare i conflitti fra PR che toccano gli stessi file (Admin, Archivio, Config, struttura, mutazioni). Le voci di sabotaggio che citano righe/liste globali (S1, BU-43, BU-47) vanno riscritte a ogni fusione.

## Cosa ha retto / ostacolato
Ha retto: il banco-prima-della-correzione e le voci di sabotaggio hanno segnalato subito le liste di attivatori e i conteggi duri. Ostacolato: conteggi e citazioni `file:riga` codificati in più banchi (struttura, autotest, urgenze), che a ogni fusione si rompono in silenzio-rumoroso.

## Proposta al canone
Nessuna per ora; da valutare a fine giri: i conteggi duri nei banchi come costante unica.
