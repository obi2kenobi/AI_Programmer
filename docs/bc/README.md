# Business Central — mappatura endpoint

Conoscenza viva sugli endpoint OData V4 di BC. Vedi `PROJECT.md` per le regole di processo.

## Come mappare un endpoint
```
python3 tools/bc_map.py <NomeServizio> [righe_campione]   # singolo
python3 tools/bc_map.py --catalog CATALOGO_ENDPOINT_BC.md  # tutti (salta i già fatti)
python3 tools/bc_index.py                                  # rigenera questo indice
```
Poi: compilare la colonna *Significato* e spuntare *Verificato* dopo il riscontro.

## Avanzamento — 88 mappati (catalogo completo: `CATALOGO_ENDPOINT_BC.md`, vive nel repo cliente)
Anomalie (403/404/vuoti): `CORREZIONI.md`.

## Salute del censimento
- Endpoint con almeno un campo verificato: 0 su 88
- File con data di aggiornamento: 0 su 88 (i senza data sono pre-2026-08-26: un refresh con bc_map li marca)
- Refresh: `python3 tools/bc_map.py <NomeServizio>` rigenera UN endpoint preservando Significato/Verificato compilati
- Su Luca's Mac: `python3 tools/bc_map.py --catalog docs/bc/CATALOGO_ENDPOINT_BC.md` mappa in blocco TUTTI i mancanti (salta i già fatti, credenziali locali)
- Catalogo servizi OData: 258 · mancanti al censimento: 170

| Endpoint | Campi | Verificato |
|---|---|---|
| `PS_PowerBI_39_Purchase_Lines` | 211 | ☐ |
| `workflowItems` | 208 | ☐ |
| `PS_PowerBI_T5110_PLA` | 202 | ☐ |
| `PS_PowerBI_36_Sales_Header` | 201 | ☐ |
| `purchaseDocumentLines` | 191 | ☐ |
| `workflowPurchaseDocumentLines` | 191 | ☐ |
| `PS_PowerBI_37_Sales_Lines` | 186 | ☐ |
| `PS_PowerBI_T5107_SHA` | 185 | ☐ |
| `Scheda_articolo_Excel` | 184 | ☐ |
| `PS_PowerBI_38_Purchase_Header` | 182 | ☐ |
| `PS_PowerBI_T5108_SLA` | 182 | ☐ |
| `salesDocumentLines` | 178 | ☐ |
| `workflowSalesDocumentLines` | 178 | ☐ |
| `workflowGenJournalLines` | 175 | ☐ |
| `PS_PowerBI_T5109_PHA` | 175 | ☐ |
| `SalesOrder` | 170 | ☐ |
| `salesDocuments` | 165 | ☐ |
| `workflowSalesDocuments` | 165 | ☐ |
| `Scheda_cliente_Excel` | 159 | ☐ |
| `workflowCustomers` | 156 | ☐ |
| `purchaseDocuments` | 150 | ☐ |
| `workflowPurchaseDocuments` | 150 | ☐ |
| `Purchase_Order_Line_Excel` | 148 | ☐ |
| `Scheda_fornitore_Excel` | 135 | ☐ |
| `workflowVendors` | 131 | ☐ |
| `PS_PowerBI_T79_Company_Information` | 89 | ☐ |
| `Spedizioni_vendita_registrate_Excel` | 88 | ☐ |
| `PS_PowerBI_T98_General_Ledger_Setup` | 87 | ☐ |
| `PS_PowerBI_25_Vendor_Ledger_Entries` | 82 | ☐ |
| `PS_PowerBI_T5601_FA_Ledger_Entry` | 81 | ☐ |
| `MovimentiValorizzazione` | 78 | ☐ |
| `PS_PowerBI_T270_BA` | 78 | ☐ |
| `PS_PowerBI_5802_Value_Entries` | 70 | ☐ |
| `DDT_Acquisto` | 70 | ☐ |
| `PS_PowerBI_T5407_Prod_Order_Component` | 65 | ☐ |
| `PS_PowerBI_T5409_PORL` | 63 | ☐ |
| `PS_PowerBI_T5406_POL` | 52 | ☐ |
| `PS_PowerBI_T5832_CLE` | 51 | ☐ |
| `PS_PowerBI_T5405_PO` | 48 | ☐ |
| `Setup_registrazioni_COGE_Excel` | 42 | ☐ |
| `PS_PowerBI_T271_BALE` | 40 | ☐ |
| `Registro_Cespiti` | 40 | ☐ |
| `PS_PowerBI_379_Detailed_Cust_Ledg_Entries` | 39 | ☐ |
| `PS_PowerBI_T85_Acc_Schedule_Line` | 38 | ☐ |
| `PS_PowerBI_380_Detailed_Vendor_Ledg_Entries` | 37 | ☐ |
| `Righe_fatt_acq_registrate_Excel` | 34 | ☐ |
| `Righe_comp_ordine_prod_Excel` | 34 | ☐ |
| `Righe_Report_Intrastat` | 34 | ☐ |
| `SalesLines` | 31 | ☐ |
| `Spedire_a_Indirizzo` | 31 | ☐ |
| `PS_PowerBI_T287_Customer_Bank_Account` | 30 | ☐ |
| `DB_Righe` | 30 | ☐ |
| `ItemLedgerEntries` | 30 | ☐ |
| `Righe_fattura_vendita_reg__Excel` | 26 | ☐ |
| `ItemSalesAndProfit` | 23 | ☐ |
| `FALedgerEntries` | 22 | ☐ |
| `DDT_Acquisto_righe` | 21 | ☐ |
| `BankAccountLedgerEntries` | 20 | ☐ |
| `Righe_Dich_Servizio` | 19 | ☐ |
| `DimensionSets` | 18 | ☐ |
| `workflowGenJournalBatches` | 18 | ☐ |
| `Scheda_oggetto_di_costo_Excel` | 17 | ☐ |
| `Spedire_Lista_indirizzi` | 17 | ☐ |
| `Testa_Report_Intrastat` | 16 | ☐ |
| `PS_PowerBI_T45_GL_Register` | 16 | ☐ |
| `PS_PowerBI_T172_SCSC` | 15 | ☐ |
| `PS_PowerBI_349_Dimension_Value` | 14 | ☐ |
| `PS_PowerBI_T12186_VAT_Exemption` | 14 | ☐ |
| `Setup_registrazione_magazzino_Excel` | 14 | ☐ |
| `PS_PowerBI_T171_SSL` | 13 | ☐ |
| `UserTaskSetComplete` | 13 | ☐ |
| `Riferimenti_articolo` | 12 | ☐ |
| `PS_PowerBI_T480_Dimension_Set_Entry` | 11 | ☐ |
| `PS_PowerBI_T2000000006_Company` | 10 | ☐ |
| `ItemSalesByCustomer` | 10 | ☐ |
| `Utenti_Camarlinghi` | 10 | ☐ |
| `Spedizionieri` | 9 | ☐ |
| `PS_PowerBI_5777_Itmem_Reference` | 9 | ☐ |
| `DB_produzione_Excel` | 9 | ☐ |
| `Valori_dimensioni_Excel` | 9 | ☐ |
| `PS_PowerBI_5404_IUM` | 9 | ☐ |
| `PS_PowerBI_T84_Acc_Schedule_Name` | 8 | ☐ |
| `PS_PowerBI_T5722_IC` | 8 | ☐ |
| `Cicli` | 7 | ☐ |
| `DimensionSetEntries` | 6 | ☐ |
| `Valori_attributo_articolo_Excel` | 5 | ☐ |
| `PS_PowerBI_T170_SSC` | 4 | ☐ |
| `traduzioni_attributi` | 4 | ☐ |
