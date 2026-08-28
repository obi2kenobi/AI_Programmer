# Relazione di sessione — Sistema Gestione Magazzino

**Data**: 27/08/2026
**Branch**: `claude/magazzino-review-errors-vt5kvy`
**PR**: [#46](https://github.com/obi2kenobi/Sistema-Gestione-Magazzino/pull/46) — aperta, `mergeable_state: clean`, nessuna review/commento in sospeso, nessuna CI configurata sul repo
**Commit in questa sessione**: 72
**File toccati**: 14 (`+2986 / -598` righe)

---

## 1. Contesto e metodo

Il lavoro nasce da due giri di revisione automatica separati, entrambi fatti girare su questo branch prima di iniziare a scrivere codice:

1. **Audit di difetti** (primo giro) — bug, race condition, guardie di sicurezza mancanti, calcoli scorretti, test senza asserzioni. Ha prodotto 20 rilievi.
2. **Revisione di prodotto/UX** (secondo giro, `prod_confermate.json`, 57 proposte) — non bug ma cose mancanti: cosa aggiungere, come rendere il sistema più leggibile, più configurabile, più utilizzabile su mobile. Ogni proposta è stata verificata da un secondo agente che ha riletto il codice citato riga per riga prima di confermarla (0 scartate su 57 valutate, 0 "già esistenti").

Ogni singolo rilievo/proposta è diventato un task nella todo-list e un commit dedicato, in ordine di priorità (le 3 con miglior rapporto valore/costo per l'uso quotidiano prima, poi tutte le altre). Ogni commit è stato sintassi-verificato con `node --check` (i file `.gs` sono Apps Script, non eseguibile localmente; gli `<script>` di `Dashboard.html` sono stati estratti e verificati allo stesso modo) prima di essere pushato.

---

## 2. Cosa è stato corretto — audit di difetti (20/20)

**Critici**
- XSS persistente e non autenticato: `saveGroupOverride`/`saveCategoryOverride` senza guardia di identità + `innerHTML` senza escape in 3 funzioni di render.
- Motore di valorizzazione senza asserzioni: nuovo banco sintetico con 9 casi verificati.

**Alta gravità**
- Lock mancante su `appendCicloToStoricoConte` (scritture concorrenti su Storico_Conte).
- `fetchBCPaged` non validava che `response.value` fosse un array (200 malformato → 0 righe silenziose).
- `ANOMALIE_BYPASS_ESCLUSIONE` inefficace per `GIACENZA_NEGATIVA` (il filtro qty>0 escludeva quegli articoli prima che il bypass potesse scattare).
- Guardia di identità mancante su 6 ponti scrittura/email + su `generateAIAnalysis`/`forceRegenerateAIAnalysis` (chiamava Claude API a pagamento senza controllo).
- 4 test manuali che scrivevano/spedivano email su dati di produzione — ora richiedono un parametro esplicito.
- `_buildInventoryByCode` sovrascriveva invece di sommare le righe multi-ubicazione dello stesso articolo.
- `getOverrideConfig` ingoiava qualsiasi errore, ritornando liste vuote indistinguibili da "nessun override".
- Filtro magazzini secondari (NC, Sospesi) applicato solo alla tabella principale, non a Trend/Timeline/Confronto/Bridge.
- Analisi AI poteva salvarsi sullo snapshot sbagliato in caso di race con un export.

**Media gravità**
- Token OAuth Business Central: TTL costante indovinata invece di `expires_in` reale.
- `exportInventorySnapshot` senza lock; tie-break deterministico mancante su dateKey uguale.
- Size-check pre-cache usava `string.length` (UTF-16) invece dei byte UTF-8 reali.
- `setupValuationConfigSheet` non idempotente su fallimento a metà.
- `_indexSnapshotRowsByGroup` usava uno spazio come separatore di chiave invece di NUL.
- 2 test con catch che ingoiava l'errore invece di rilanciarlo.

**Bassa gravità**
- `testClaudeConnection` può saltare la chiamata reale a pagamento.
- Calcolo della mediana scorretto su un numero pari di elementi.

---

## 3. Cosa è stato aggiunto — revisione di prodotto (55/57 implementate)

Raggruppate per area:

**Ciclo di vita magazzino**: copertura reale della Mappa Magazzino (banner % valore senza ubicazione nota), riepilogo Carichi/Scarichi nel drill-down Movimenti, verifica mirata post-ricezione (non più esclusa come "in lavorazione"), giorni di copertura residua al posto della sola Scorta Minima.

**Leggibilità dashboard**: soglie anomalia lette da Config_Anomalie invece di testo fisso, tab Override Articoli visibile, destinatario email analisi AI mostrato, ripartizione anomalie nel tempo, sottotitoli sulle 5 KPI principali, legenda icona "Fuori giacenza".

**Automazione lavoro manuale**: menu self-service per indagini BC (niente più `clasp push` per ogni analisi), chiusura tracciata del ciclo rettifiche (Storico_Conte non più congelato a T+1), bottone conta straordinaria in dashboard, avviso disallineamento TRIGGER_ORA.

**Fiducia/osservabilità**: badge freschezza snapshot mensile, data del foglio Inventario Fisico selezionato, invalidazione cache Trend/Bridge dopo export on-demand, pannello "salute sistema" (letto da LogLib).

**Ricerca e produttività**: filtri che non si azzerano più dopo un Override, indicatore rettifica aperta in tabella, vista aggregata conte recenti, ricerca/filtri collegati fra Tabella/Anomalie/Mappa, link condivisibile per una vista filtrata.

**Resilienza operativa**: avviso prima di lasciare la pagina a metà scrittura, avviso proattivo prima che la sessione scada, promemoria "Disponibile offline" nell'email di conta, segnale a logistica se il trigger del mattino fallisce, idempotenza sull'invio rettifiche a Operations.

**KPI di settore**: aging dello stock come colonna, tasso di conferma per motivo di selezione, accuratezza inventariale per Area/Zona/Gruppo cumulativa nel tempo.

**Configurabilità self-service**: cap pool candidati (50) e location BC escluse/secondarie portati da codice a Config_Inventario/tab dedicato, NOTIFICATION_EMAIL self-service.

**Messaggi ed errori parlanti**: errore "chiave AI mancante" non tecnico, messaggio "nessuno snapshot" cita il bottone Genera Nuovo, `window.onerror` per errori JS non gestiti, pannello di aiuto/onboarding.

**Integrazione con altri processi**: riepilogo mensile rettifiche per la chiusura contabile, lista sotto-scorta per fornitore (recuperato `Vendor_No`, già letto da BC e mai riusato), valore di magazzino per Business Unit nell'email mensile.

**Mobile/touch**: griglie card responsive, bottoni azione riga sopra la soglia minima di tocco (44px), footer modali sticky.

**Pulizia**: rimosse ~135 righe di migrazione one-shot ormai storiche, funzione `downloadCSV` condivisa per i 6 export CSV (corretto anche un bug di escaping virgolette in uno di essi), rimosse 2 funzioni di override gruppo/categoria mai richiamate da UI.

**Coerenza terminologica**: allineata la definizione di "rettifiche aperte" fra digest email settimanale e dashboard (prima divergevano), etichetta unica "Effetto Prezzo" nel Bridge (era anche "Impatto"/"Eff. Prezzo" a seconda della vista), colonna "Stato" rinominata in "Variazione" nel modale Confronto (era ambigua con lo stato di ciclo-vita conta), titolo modale "Movimenti Articolo" corretto (era "Movimenti Magazzino").

---

## 4. Deliberatamente non implementato — richiede una decisione umana

Due rilievi dell'audit bug-fix restano aperti perché la correzione dipende da un dato o una scelta che il codice non può fornire da solo:

- **`(VUOTO)` vs `PRINCIPALE`** (ubicazione assente): un tentativo precedente di unificarli (commit `6b8cb52`) si è rivelato sbagliato sui dati reali BC ed è stato revertato in produzione — serve l'elenco reale delle ubicazioni BC per una convenzione corretta, non una scelta di codice.
- **Formula Effetto Volume/Prezzo instabile a giacenza base piccola**: è un metodo di scomposizione contabile legittimo ma matematicamente instabile per costruzione quando la quantità del periodo base è vicina a zero; la correzione richiede una decisione di metodo contabile (quale soglia? quale periodo di riferimento?), non è un bug meccanico.

## 5. Proposte confermate ma mai implementate (gap scoperto in questa sessione)

Verificando `prod_confermate.json` a posteriori sono emerse 2 proposte su 57, entrambe confermate valide (`fondata: true`) dal secondo agente di verifica, che però non erano finite nella todo-list operativa e quindi non sono mai state implementate. Non richiedono una decisione di dominio come i due punti sopra — sono solo lavoro non ancora fatto:

- **Filtri Gruppo/Categoria/Magazzino/Area/Zona come `<select multiple>` nativi**: pattern touch-fragile su mobile (box alto 80px, nessun indizio visivo di multi-selezione). Costo stimato: medio.
- **Tabella Inventario a 15 colonne, nessuna vista "a schede" per mobile**: solo scroll orizzontale continuo attraverso colonne intermedie. Costo stimato: grande (l'unico "grande" di tutto l'elenco).

## 6. Segnalazione a parte già in coda

Task suggerito (non ancora avviato): `openOverrideModal` (Dashboard.html) legge `item.overrideValue`, campo che non esiste sugli oggetti articolo (esistono solo `overrideType` e `overrideDetails`) — bug pre-esistente scoperto durante il lavoro su un'altra funzionalità, isolato in una segnalazione separata per non mescolare due correzioni indipendenti nello stesso commit.

---

## 7. File toccati

`Dashboard.html`, `PhysicalInventory.gs`, `WebAppDashboard.gs`, `SnapshotExporter.gs`, `InventoryDataService.gs`, `InventoryModels.gs`, `LocationPolicy.gs`, `AIReportAnalysis.gs`, `BCRevaluationAnalysis.gs` (+ nuovo `BCInvestigationDialog.html`), `ValuationConfig.gs`, `SheetsSetup.gs`, `setup.gs`, `README.md`.

## 8. Prossimo passo consigliato

1. Deploy in produzione (`clasp push` dal clone locale di Luca — non è qualcosa che questa sessione può fare).
2. Eseguire una tantum, dopo il deploy, le funzioni di migrazione idempotenti aggiunte in questa sessione (elencate nel blocco "One-shot di attivazione" di README.md): `ensurePoolCandidatiGiornalieroConfigParam()`, `ensureLocationPolicyTab()`, `ensureNotificationEmailConfigParam()`.
3. Decisione umana sui due punti bloccati (sezione 4).
4. Eventuale via libera per i due gap scoperti (sezione 5) o per la segnalazione in coda (sezione 6).
