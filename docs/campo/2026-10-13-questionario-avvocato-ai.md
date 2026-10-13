# 2026-10-13 — questionario dell'avvocato (lavoro, privacy, AI Act) sul sistema di registrazione fatture
**Autore**: sessione Claude (Sonnet 5.5) per Luca — Registrazione_Fatture_Acquisto

## Cosa ho usato
Il codice come fonte (`gas/Claude.gs`, `gas/Config.gs`, `gas/Main.gs`, `gas/ControlloAccessi.gs`, `gas/GiroRegistrazione.gs`) con ogni risposta marcata V (verificato, file:riga) o P (serve una persona); la skill docx per la bozza di risposta. Non c'era: un inventario dei dati personali trattati (l'ho ricostruito leggendo lo schema di estrazione).

## Cosa ho improvvisato
La scheda del sistema data al questionario diceva «Mistral (FR)», fuori data dal 23/09 (ora Claude/Anthropic via API diretta): l'ho aperta come correzione preliminare. Il rendering visivo del docx non è stato controllabile (LibreOffice non apre nemmeno un documento di prova in questo ambiente): validazione strutturale sì, controllo a vista no, dichiarato a Luca.

## Cosa ha retto / ostacolato
Ha retto: separare ciò che il codice prova da ciò che sta nei contratti (otto domande su sedici restano a una persona). Ha ostacolato: nessun documento versionato dice quali dati personali il sistema tratta e verso chi; l'ho trovato solo perché `ControlloAccessi.gs:3` lo ammette in un commento.

## Proposta al canone
Un campo entra nello schema di estrazione solo con un consumatore dichiarato: oggi IBAN, BIC, telefono, email, incaricato e rappresentante sono estratti, conservati nel foglio e inviati al fornitore del modello senza che nessuna regola li usi. Un banco può elencare i campi dello schema mai letti dal codice.
