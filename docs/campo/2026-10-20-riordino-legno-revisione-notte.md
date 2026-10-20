# 2026-10-20 — riordino-legno, revisione della notte (PR Riordino-legno#121)
**Autore**: sessione Claude Code (cloud) per Luca

## Cosa ho usato
Cinque sottoagenti in sola lettura (codice A, B, C; grafica nel browser F; test T) con riproduzioni eseguite; il banco di sabotaggio del progetto (`tests/banco-acq-mutazioni.js`, `MUT_SOLO`, `MUT_GATE`); Playwright/Chromium per i banchi del browser. Non c'era un modo di far girare per intero il banco dei sabotaggi (~1700 voci) in una sessione: ho giudicato solo le voci toccate.

## Cosa ho improvvisato
- Uno script per riallineare 44 ancore morte dei sabotaggi (voci `da` che non compaiono più): il giudice le classificava «non applicabile» ma nessun controllo veloce le segnalava prima del giro lungo. Ora c'è `provaLeAncore` nel banco dei sabotaggi.
- Il conteggio onesto dei «giri»: l'utente ne chiedeva 50-70; ho dichiarato 5 letture indipendenti e circa 15 cicli di correzione, non il numero chiesto.

## Cosa ha retto / ostacolato
- Ha retto: banco prima della correzione (rosso → verde → sabotaggio rosso): ha scoperto tre volte che il mio test non provava niente (GRA-7, REV-19, P3/OFM-1 sopravvissuti).
- Ha ostacolato: i numeri di riga citati nella guida (`tests/banco-acq-struttura.js:511`) scivolano a ogni modifica di un file citato; costano un giro ogni volta. Due comandi separati per scrivere e committare (patto 5) li ho violati una volta per abitudine (`git add && status && commit`).

## Proposta al canone
Un controllo veloce delle ancore dei sabotaggi in ogni banco di test (fatto in Riordino-legno, `provaLeAncore`): da ricopiare dove esiste un elenco di mutazioni.
