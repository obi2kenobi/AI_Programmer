# SAL — Business Central

Diario vivo + decisioni. Sempre aggiornato (regola "Keep living documentation").

## Stato
**88 / 108** endpoint mappati. 20 anomalie (1×403, 6×404, 13 vuoti) in `CORREZIONI.md`.
`workflowItems`: significato campi chiave compilato; riscontro count=3689 in attesa di conferma di Luca.

## Log

### 2026-06-23
- **Decisione — fonte credenziali:** OAuth2 client_credentials lette da `credenziali BC.rtf`
  (contiene tenant/client/secret/token_url/scope + base_url). Il riferimento del catalogo a
  `*/backend/Config.gs` è la copia del backend GAS; per il tooling Python si usa l'RTF.
- **Decisione — tooling:** `tools/bc_map.py` (Python stdlib, nessuna dipendenza). Legge le
  credenziali a runtime → token → GET OData → genera `endpoints/<Nome>.md`.
- **Decisione — struttura doc:** un file per endpoint + questo SAL + `CORREZIONI.md` + `README.md` indice.
- **Fatto:** `workflowItems` mappato, **208 campi** su 3 righe campione. Stato: mappato, da verificare col riscontro.
- **Fatto (A) — `workflowItems`:** compilati i ~25 campi chiave (identità, UdM, costi, giacenza/movimenti, gruppi registrazione, dimensione BU, produzione). Riscontro: `$count` = **3689** articoli.
- **Fatto (B) — mappati 12 endpoint di produzione:** `Cicli`(7), `ItemLedgerEntries`(30), `MovimentiValorizzazione`(78), `PS_PowerBI_5404_IUM`(9), `PS_PowerBI_5802_Value_Entries`(70), `PS_PowerBI_T5405_PO`(48), `PS_PowerBI_T5406_POL`(52), `PS_PowerBI_T5407_Prod_Order_Component`(65), `PS_PowerBI_T5409_PORL`(63), `PS_PowerBI_T5832_CLE`(51), `Scheda_articolo_Excel`(184), `workflowCustomers`(156).
- **Anomalia:** `PRJ_5406_Production_Order_Line` → HTTP 404 (registrata in `CORREZIONI.md`).
- **Fix tooling:** `bc_map.py` ora gestisce gli errori HTTP con messaggio pulito (niente traceback).
- **Fatto — mappatura completa catalogo:** 88/108 endpoint mappati (82 dalla tabella §3 + 6 "nuovi scoperti" §1). 20 anomalie inventariate in `CORREZIONI.md`.
- **Tooling:** `bc_map.py` esteso con modalità `--catalog` (un solo token, salta i file esistenti) + URL-encoding del nome + catch errori per-endpoint. Nuovo `bc_index.py` rigenera questo indice/`README` dai file.
- **Aperto:**
  - conferma riscontro `workflowItems` (3689 articoli + significati);
  - classificare le 20 anomalie (bug dato BC vs errore catalogo); in particolare i 3 endpoint *Query* con `/`·`.` nel nome (encoding del path da verificare) e il 403 (permessi Azure);
  - compilare *Significato* sugli endpoint oltre `workflowItems` (man mano che servono).
