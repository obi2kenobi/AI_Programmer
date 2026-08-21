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
