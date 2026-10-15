# 2026-10-15 — riordino-legno: gate rosso per un mio errore, primo deploy 0.9.0, misura reale di "Ordina entro"
**Autore**: sessione cloud (Claude) con Luca

## Cosa ho usato
Il gate completo `tests/run.sh` in un worktree separato (29-30 min), `tools/giorno.sh consegna` dell'hub per una consegna vera (ha spinto il ramo, la PR non e' nata: `gh` qui non sa crearla, l'ho aperta con lo strumento GitHub; la lente sicurezza ha risposto PULITA in un minuto), il banco prima della correzione e il sabotaggio della correzione (ancore VER-7/8/9), il log delle Esecuzioni di Apps Script come misura dei volumi. NON c'era: `clasp` installato e autenticato in sessione (e per regola non deve esserci: `CLAUDE.md:73`, hook).

## Cosa ho improvvisato
- Il gate su `main` era rosso per un mio errore: due mutazioni (VER-8/9) ancorate alla data di versione che avevo cambiato; `MUT_SOLO=OE` non le eseguiva. Corretto (PR 44) e il debito di fondo (ancore a testo fisso) saldato con una cura che legge la versione corrente da `Config.gs`.
- Il primo `clasp push` di Luca si e' fermato su «Conflicting files found»: nella sua cartella `acquisti/` c'era una copia `.js` accanto a ogni `.gs` (clasp 3.3.0 le scrive con `pull`); spostate fuori dal repo, push riuscito (62 file). Ho detto prima «rilancia acqInizializza»: era sbagliato, la guida (`GUIDA-STAGING.md:148`) dice che per la 0.9.0 non serve.
- La misura vera di "Ordina entro" sul 2.0: 3696 articoli, 837 candidati, 0 da ordinare, 61 con parametri mancanti (lead time vuoto), 776 senza fabbisogno. Sospettavo che la sandbox fosse ferma a agosto dal nome; Luca la dice «copia fedele» e non ho modo di verificarlo da qui.

## Cosa ha retto / ostacolato
Ha retto: il giudice del sabotaggio (`tests/banco-acq-mutazioni.js`: un'ancora che non si applica fa fallire il banco, non passa in silenzio), il debito scritto prima di correggere, la guida di staging con le righe citate (ha permesso a Luca di fare il push e il passo 10 septies da solo). Ha ostacolato: `GUIDA-STAGING.md:51` dice «33 `.gs` e 11 `.html`», il vero e' 45 e 16 (debito), e una consegna di `giorno.sh` che si ferma alla PR senza dire cosa fare in italiano.

## Proposta al canone
1. `giorno.sh consegna`: se `gh` non puo' creare la PR, dirlo con il comando per lo strumento che c'e' (qui l'ho aperta con il tool GitHub) invece del solo suggerimento di `gh api`.
2. Un passo di consegna per ogni aumento di versione: eseguire `MUT_SOLO=VER` (oggi le ancore sono lette dal file, ma il conteggio dei file in `GUIDA-STAGING.md:51` resta a mano).
