# 2026-10-14 — riordino-legno-riapertura
**Autore**: sessione cloud claude/funny-hamilton-q6tov6 (per Luca)

## Cosa ho usato
La riapertura del settimo patto su `riordino-legno`: `bash tools/debiti-riapertura.sh` (78 aperti: 18 di dominio, 36 risolvibili, 24 in attesa) e un sotto-agente `Explore` in sola lettura per il quadro di stato (`PROJECT.md`, `DEBITI.md`, `docs/progetto-acquisti/DOMANDE.md`, report in `docs/campo/`). Ho lanciato anche `bash tests/run.sh` sul repo: dopo 600 s era ancora in corso e l'ho lasciato in background, quindi il verde dichiarato dai documenti (1189/1189 sabotaggi) NON è stato rieseguito da me. Non c'era: un comando che dica in una riga quanti minuti impiega un gate prima di lanciarlo.

## Cosa ho improvvisato
Niente di nuovo: il quadro l'ho costruito a mano mettendo insieme il conteggio del tool e la lettura dei documenti.

## Cosa ha retto / ostacolato
Ha retto: il conteggio dei debiti alla riapertura, che ha mostrato subito 36 debiti risolvibili da fare prima del lavoro nuovo. Ostacolato: la testata di `docs/progetto-acquisti/DOMANDE.md:5` dice «Aperte: 2», ma leggendo le domande ne risultano circa 29 senza risposta (2 + 12 residui + 15 con la sola scelta provvisoria della sessione), e il tool dei debiti ne conta 18 di dominio: tre conti diversi per la stessa cosa. Inoltre `PROJECT.md:44` dichiara circa 7 minuti per `run.sh`, mentre un report di campo dello stesso repo dice circa 45.

## Proposta al canone
1. Una guardia che confronti il conteggio dichiarato nella testata di un file di domande con le domande effettivamente senza risposta (e con il conto di `debiti-riapertura.sh`), in modo che una testata stantia diventi rossa.
2. Nello standard dei satelliti, il tempo misurato di ogni gate dichiarato in `.night-verify` accanto al comando, aggiornato dall'ultima esecuzione.
