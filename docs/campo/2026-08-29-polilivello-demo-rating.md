# Analisi polilivello — Analisi_Rating_Clienti (demo del protocollo)

> Prima applicazione della skill `polilivello` + fase generativa della skill
> `brainstorming` (P1-P10), su un progetto reale del parco gas-src (REPO-E).
> Scaffold meccanico: `tools/polilivello.sh`. Serve anche da record della
> validazione: i grep dello scaffold sono stati corretti SUL CAMPO da questo
> studio (gli entrypoint verbi-italiani, gli ID in const).

## Cosa ho usato

Skill polilivello (6 livelli) · skill brainstorming §4 (provocazioni) ·
oracolo hub `tools/rating_dso_clienti.py` (già minato da questo progetto).

## Cosa ho improvvisato

Nulla: prima applicazione, il protocollo regge. Due grep dello scaffold
corretti durante lo studio (entrypoint, ID) — il feedback del campo al tool.

## L1 — Identità (una riga guadagnata)

«Ogni mese mi dice chi paga veloce e chi no»: DSO medio per cliente, con le
cessioni factoring trattate come pagamenti alla data di cessione.

## L2 — Struttura (scaffold)

3 file, 149 righe js. Un entrypoint: `analizzaRatingClienti` (Codice.js:2).
Due cartelle Drive (input movimenti, output report — Codice.js:3-4). Nessuna
dipendenza esterna: tutto Fogli/Drive locali, niente BC, niente Properties.

## L3 — Cosa fa

Trigger manuale → cerca nella folder input il primo file col nome contenente
«movimenti contabili» (Codice.js:15-25) → riga per riga costruisce fatture
(colonna tipo ~«fattura»), pagamenti e cessioni (descrizione
CessioneFACTORProsoluto + codice + data ddMMaa, r.59-70) → abbinamento
pagamento→fattura: per codice documento in descrizione (regex 25(OV|FVI|CORR),
r.79) con fallback stesso cliente + data entro 7 giorni + importo entro 1 EUR
(r.85-90) → DSO medio = somma giorni / fatture pagate, arrotondato (r.118) →
crea foglio «Rating Clienti <mese>» nella folder output, ordinato per DSO
decrescente, più foglio «Pagamenti non associati» se ce ne sono (r.137-141).

## L4 — Come lo fa (formule citate)

- finestra fallback: `Math.abs(data pagamento − data fattura) < 1000·60·60·24·7` (r.87)
- giorni: `Math.floor((pagamento.data − fattura.data) / ms_al_giorno)` (r.97)
- guardia anti-falso-abbinamento: giorni scartati se <0 o >365 (r.98)
- media DSO: `Math.round(sommaGiorni / count)` (r.118)

**Fragilità / assunzioni implicite:**
1. **L'anno è CABLATO nella regex**: `(25(OV|FVI|CORR)-[0-9]+)` — i codici
   documento iniziano per anno. Dal 2026 i codici 26OV-… NON matcheranno più:
   il matching per codice si spegne in silenzio e resta solo il fallback
   euristico. Difetto a scadenza, tipologia «bomba orologio».
2. Il primo file «movimenti contabili» nella folder vince: due file (due mesi)
   → legge quello che l'iterazione gli dà per primo.
3. Colonne fisse (tipo r[3], nrDoc r[4], cliente r[6], importo r[12]) e
   `getSheets()[0]`: qualsiasi spostamento di colonna rimescola i dati in
   silenzio.
4. La cessione conta come pagamento alla data di cessione: il DSO migliora col
   factoring — misura QUANDO la banca paga, non quando paga il cliente.

## L5 — Storia

Nessun git, nessuna data nel codice, un solo commento di racconto (l'estrazione
della cessione, r.60). Progetto giovane e monolitico: nessuna cicatrice, ma
anche nessuna memoria — chi lo toccherà dopo non saprà perché le cose stanno
così (vedi assunzione 4: è una scelta di dominio vissuta come dettaglio).

## L6 — Come potrebbe farlo meglio (provocazioni applicate)

- **P9 debito visibile**: l'anno cablato (assunzione 1) è il TODO che il codice
  non ha scritto. Fix: regex `\d{2}(OV|FVI|CORR)` — l'oracolo hub la scrive
  GIÀ così: l'hub ha già pagato questa lezione, il progetto no.
- **P6 costo zero**: esiste `tools/rating_dso_clienti.py` (oracolo minato da
  questo progetto). Un banco che confronti l'output del vivo con l'oracolo
  sullo stesso CSV = parità provabile, costo zero su produzione.
- **P4 scala**: due mesi di file nella folder → doppione o file sbagliato.
  Fix minimo: il file più recente per data di nome, e gli ALTRI file denunciati
  («trovati 2 file, usato X») — scarto mai silenzioso.
- **P7 domanda di dominio** (da portare al proprietario, NON indovinare): il
  rating che serve è il DSO del CLIENTE o il DSO degli incassi (con factoring
  fuori)? La risposta decide se le cessioni contano come pagamenti o vanno
  escluse e rateizzate — due business diversi dallo stesso foglio.
- **P3 vicino**: nel parco esiste già un progetto factoring (cessionario) e un
  report hub su 30 agenti che l'hanno toccato. Confronto di matching consigliato
  prima di toccare il rating.
- **P2 next-question**: se lo rifacessimo domani: regex senza anno, file
  dichiarato invece che primo-trovato, e la domanda P7 risolta per iscritto.

## Proposta al canone

Il protocollo polilivello + le provocazioni P1-P10 funzionano: questa analisi
è nata in un passaggio, con citazioni, e la fase critica ha prodotto 6 idee
di cui 2 a costo zero e 1 domanda di dominio che nessun codice può rispondere.
Registro la demo come reference della skill.
