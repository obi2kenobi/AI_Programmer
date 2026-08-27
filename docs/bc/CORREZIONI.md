# Correzioni — Business Central

Errori di mappatura trovati e correzioni applicate (regola "Keep living documentation").
Distinguere errori nei *nostri* appunti/mappature da eventuali anomalie *del dato BC*.

### 2026-06-23 — Inventario anomalie dalla mappatura del catalogo (88/108 OK)

**403 Forbidden (1)** — permessi mancanti per l'app Azure su questo web service:
- `Cliente_Esenzione_Conai`

**404 Not Found (6)** — endpoint non raggiungibile a quel path:
- `PRJ_5406_Production_Order_Line` (catalogo §2 "verificato"; alternativa ok: `PS_PowerBI_T5406_POL`)
- `Registrazioni COGE_Excel`, `Registrazioni inventario fisico_Excel`
- `Cust.LedgerEntries`, `G/LEntries`, `G/LBudgetEntries` (tipo *Query*). Ipotesi "encoding del `/`"
  **testata e smentita** (2026-06-23): anche con `%2F` → 404. I Query endpoint non sono raggiungibili
  a questo path OData; richiedono un'esposizione/percorso diverso. Da chiarire con chi gestisce BC.

**Vuoti — nessuna riga restituita (13)** — endpoint raggiungibile ma 0 record (tabella vuota o serve un filtro;
senza dati non si possono inferire i campi):
- `PS_PowerBI_T1001_Job_Task`, `PS_PowerBI_T156_Resource`, `PS_PowerBI_T167_Job`,
  `PS_PowerBI_T169_Job_Ledger_Entry`, `PS_PowerBI_T173_SPC`, `PS_PowerBI_T174_SPL`,
  `PS_PowerBI_T175_SVPC`, `PS_PowerBI_T203_Res_Ledger_Entry`, `PS_PowerBI_T90_BC`,
  `PS_PowerBI_T96_GL_Budget_Entry`, `vvalori_attributo_articolo`, `workflowWebhookSubscriptions`,
  `JobLedgerEntries`

⏳ Tutte aperte, non ancora classificate (bug del dato BC vs errore nostro catalogo).


## Censimento di massa 2026-08-26 (due giri al vivo, output di Luca)

**231 file su 258 servizi del catalogo** (203 mappati + 28 stub VUOTO con file proprio). Le anomalie: 28 vuote (hanno stub), 27 SENZA file (403/400/404 sotto), categorizzate:

- **VUOTE (28) — legittime, non errori**: entità esistenti senza righe (moduli inutilizzati:
  Jobs, provvigioni T17x, attributi, workflow). Da dichiarare «vuoto», non «zero»:
  AccountantPortalUserTasks, Attributi_Articolo_2, Attributi_categorie_articolo, db_assemblaggi,
Job_List, Job_Planning_Lines, Job_Task_Lines, Ord_produzione_confermato_Excel, Power_BI_Job_Profitability,
Power_BI_Top_5_Opportunities, Prezzi_Acquisto, PS_PowerBI_T1001_Job_Task, PS_PowerBI_T156_Resource,
PS_PowerBI_T167_Job, PS_PowerBI_T169_Job_Ledger_Entry, PS_PowerBI_T173_SPC, PS_PowerBI_T174_SPL,
PS_PowerBI_T175_SVPC, PS_PowerBI_T203_Res_Ledger_Entry, PS_PowerBI_T90_BC, PS_PowerBI_T96_GL_Budget_Entry,
JobLedgerEntries, Power_BI_Jobs_List, SalesOpportunities, SegmentLines, valore_Filtro_attributp,
vvalori_attributo_articolo, workflowWebhookSubscriptions
- **403 Forbidden (2) — permessi**: Fattura_acquisto_Excel, Ordine_acquisto_Excel
  (pagine documento: probabilmente richiedono permessi UI, non solo API)
- **400 Bad Request (3)**: List_Prezz_Acquisto, Registrazioni_inventario_fisico_Excel, Spedizioni_Wherhouse
- **404 Not Found (22) — probabilmente non esposte**: i nomi con PUNTI o SLASH
  («G/LEntries», «Cust.LedgerEntries», «Power_BI_Aged_Acc._Payable») non sono raggiungibili
  come segmenti OData; le PRJ_* (7) non risultano esposte nonostante il catalogo dica
  pubblicato. Da rivalutare solo se un progetto le usa: oggi nessuno le cita.
