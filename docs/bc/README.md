# Business Central — mappatura endpoint

Conoscenza viva sugli endpoint OData V4 di BC. Vedi `PROJECT.md` per le regole di processo.

## Come mappare un endpoint
```
python3 tools/bc_map.py <NomeServizio> [righe_campione]   # singolo
python3 tools/bc_map.py --catalog CATALOGO_ENDPOINT_BC.md  # tutti (salta i già fatti)
python3 tools/bc_index.py                                  # rigenera questo indice
```
Poi: compilare la colonna *Significato* e spuntare *Verificato* dopo il riscontro.

## Avanzamento — 187 mappati (catalogo completo: `CATALOGO_ENDPOINT_BC.md`, vive nel repo cliente)
Anomalie (403/404/vuoti): `CORREZIONI.md`.

## Salute del censimento
- Endpoint con almeno un campo verificato: 0 su 187
- File con data di aggiornamento: 99 su 187 (i senza data sono pre-2026-08-26: un refresh con bc_map li marca)
- Refresh: `python3 tools/bc_map.py <NomeServizio>` rigenera UN endpoint preservando Significato/Verificato compilati
- Su Luca's Mac: `python3 tools/bc_map.py --catalog docs/bc/CATALOGO_ENDPOINT_BC.md` mappa in blocco TUTTI i mancanti (salta i già fatti, credenziali locali)
- Catalogo servizi OData: 258 · mancanti al censimento: 71

| Endpoint | Campi | Verificato |
|---|---|---|
| `PS_PowerBI_27_Item` | 215 | ☐ |
| `PS_PowerBI_39_Purchase_Lines` | 211 | ☐ |
| `PS_EDIT_36_Testate_vendita_Excel` | 209 | ☐ |
| `workflowItems` | 208 | ☐ |
| `PS_PowerBI_T5110_PLA` | 202 | ☐ |
| `PS_PowerBI_36_Sales_Header` | 201 | ☐ |
| `purchaseDocumentLines` | 191 | ☐ |
| `workflowPurchaseDocumentLines` | 191 | ☐ |
| `PS_PowerBI_37_Sales_Lines` | 186 | ☐ |
| `PS_PowerBI_T5107_SHA` | 185 | ☐ |
| `ItemCard` | 184 | ☐ |
| `Scheda_articolo_Excel` | 184 | ☐ |
| `PS_PowerBI_38_Purchase_Header` | 182 | ☐ |
| `PS_PowerBI_T5108_SLA` | 182 | ☐ |
| `salesDocumentLines` | 178 | ☐ |
| `workflowSalesDocumentLines` | 178 | ☐ |
| `PS_PowerBI_18_Customer` | 176 | ☐ |
| `workflowGenJournalLines` | 175 | ☐ |
| `PS_PowerBI_T5109_PHA` | 175 | ☐ |
| `SalesOrder` | 170 | ☐ |
| `Ordine_vendita_Excel` | 170 | ☐ |
| `PS_PowerBI_23_Vendor` | 169 | ☐ |
| `salesDocuments` | 165 | ☐ |
| `workflowSalesDocuments` | 165 | ☐ |
| `Scheda_cliente_Excel` | 159 | ☐ |
| `workflowCustomers` | 156 | ☐ |
| `purchaseDocuments` | 150 | ☐ |
| `workflowPurchaseDocuments` | 150 | ☐ |
| `Purchase_Order_Line_Excel` | 148 | ☐ |
| `PS_PowerBI_112_Posted_Sales_Invoice` | 145 | ☐ |
| `Fatture_vendita_reg__Excel` | 135 | ☐ |
| `Scheda_fornitore_Excel` | 135 | ☐ |
| `PS_PowerBI_114_Posted_Sales_Credit_Memo` | 132 | ☐ |
| `workflowVendors` | 131 | ☐ |
| `GeneralLedgerSetup` | 121 | ☐ |
| `PS_PowerBI_122_Posted_Purchase_Invoice` | 121 | ☐ |
| `PS_PowerBI_121_Posted_Purch_Receipt_Subform` | 116 | ☐ |
| `PS_PowerBI_124_Posted_Purchase_Cr_Memo` | 116 | ☐ |
| `PS_PowerBI_123_Posted_Purchase_Inv_Subform` | 114 | ☐ |
| `PS_PowerBI_110_Posted_Sales_Shipments` | 111 | ☐ |
| `PS_PowerBI_125_Posted_Purchase_Cr_Memo_Subform` | 110 | ☐ |
| `Fattura_acquisto_reg__Excel` | 105 | ☐ |
| `PS_PowerBI_120_Posted_Purchase_Receipt` | 96 | ☐ |
| `PS_PowerBI_113_Posted_Sales_Invoice_Subform` | 96 | ☐ |
| `PS_PowerBI_115_Posted_Sales_Credit_Memo_Subform` | 96 | ☐ |
| `PS_PowerBI_21_Customer_Ledg_Entries` | 93 | ☐ |
| `PS_PowerBI_111_Posted_Sales_Ship_Subform` | 93 | ☐ |
| `PS_EDIT_254_Movimenti_IVA_Excel` | 89 | ☐ |
| `PS_PowerBI_T79_Company_Information` | 89 | ☐ |
| `Archivio_Ordini_Vendita` | 88 | ☐ |
| `PS_PowerBI_254_VAT_Entries` | 88 | ☐ |
| `Spedizioni_vendita_registrate_Excel` | 88 | ☐ |
| `PS_PowerBI_T98_General_Ledger_Setup` | 87 | ☐ |
| `Archivio_Ordini_Acquisto` | 83 | ☐ |
| `PS_PowerBI_25_Vendor_Ledger_Entries` | 82 | ☐ |
| `PS_PowerBI_T5601_FA_Ledger_Entry` | 81 | ☐ |
| `MovimentiValorizzazione` | 78 | ☐ |
| `PS_PowerBI_T270_BA` | 78 | ☐ |
| `PS_PowerBI_32_Item_Ledger_Entries` | 76 | ☐ |
| `Movimenti_contabili_clienti_Excel` | 74 | ☐ |
| `Movimenti_contabili_fornitori_Excel` | 72 | ☐ |
| `Mov_contabili_articoli_Excel` | 72 | ☐ |
| `Mov_contabili_articoli` | 72 | ☐ |
| `PS_PowerBI_5802_Value_Entries` | 70 | ☐ |
| `DDT_Acquisto` | 70 | ☐ |
| `PS_PowerBI_T5407_Prod_Order_Component` | 65 | ☐ |
| `Movimenti_C_G_Excel` | 63 | ☐ |
| `PS_PowerBI_T5409_PORL` | 63 | ☐ |
| `Items` | 62 | ☐ |
| `PS_PowerBI_15_GL_Account` | 60 | ☐ |
| `PS_PowerBI_17_General_Ledger_Entries` | 57 | ☐ |
| `Movimenti_contabili_capacità_Excel` | 53 | ☐ |
| `PS_PowerBI_T5406_POL` | 52 | ☐ |
| `Customers` | 52 | ☐ |
| `PS_PowerBI_T5832_CLE` | 51 | ☐ |
| `Componenti_ordine_produzione_Excel` | 50 | ☐ |
| `PS_PowerBI_T5405_PO` | 48 | ☐ |
| `AccountantPortalFinanceCues` | 46 | ☐ |
| `AccountantPortalActivityCues` | 43 | ☐ |
| `Setup_registrazioni_COGE_Excel` | 42 | ☐ |
| `PS_PowerBI_T271_BALE` | 40 | ☐ |
| `Registro_Cespiti` | 40 | ☐ |
| `PS_PowerBI_379_Detailed_Cust_Ledg_Entries` | 39 | ☐ |
| `PS_PowerBI_T85_Acc_Schedule_Line` | 38 | ☐ |
| `Mov_cont_cespiti` | 38 | ☐ |
| `ProvvigioniMaturate` | 37 | ☐ |
| `PS_PowerBI_380_Detailed_Vendor_Ledg_Entries` | 37 | ☐ |
| `Movimenti_contabili_C_C_bancari_Excel` | 36 | ☐ |
| `PS_PowerBI_12142_VAT_Book_Entries` | 34 | ☐ |
| `PS_EDIT_12142_Movimenti_libro_IVA_Excel` | 34 | ☐ |
| `Righe_fatt_acq_registrate_Excel` | 34 | ☐ |
| `Righe_comp_ordine_prod_Excel` | 34 | ☐ |
| `Righe_Report_Intrastat` | 34 | ☐ |
| `PostedSalesShipments` | 33 | ☐ |
| `ValueEntries` | 32 | ☐ |
| `SalesLines` | 31 | ☐ |
| `righe_spedizioni_whereh` | 31 | ☐ |
| `Spedire_a_Indirizzo` | 31 | ☐ |
| `PS_PowerBI_T287_Customer_Bank_Account` | 30 | ☐ |
| `DB_Righe` | 30 | ☐ |
| `ItemLedgerEntries` | 30 | ☐ |
| `VBACC` | 28 | ☐ |
| `Ordine_produzione_rilasciato_Excel` | 27 | ☐ |
| `PostedSalesCreditMemoLines` | 26 | ☐ |
| `PostedSalesInvoiceLines` | 26 | ☐ |
| `Righe_fattura_vendita_reg__Excel` | 26 | ☐ |
| `VendorLedgerEntries` | 26 | ☐ |
| `Ordine_produzione_pianificato_Excel` | 23 | ☐ |
| `ItemSalesAndProfit` | 23 | ☐ |
| `Metodi_Pagamento` | 23 | ☐ |
| `FALedgerEntries` | 22 | ☐ |
| `Prezzi_vendita_Excel` | 22 | ☐ |
| `DDT_Acquisto_righe` | 21 | ☐ |
| `BankAccountLedgerEntries` | 20 | ☐ |
| `PostedSalesShipmentLines` | 20 | ☐ |
| `PS_EDIT_12144_Movimenti_libro_giornale_Excel` | 19 | ☐ |
| `PS_PowerBI_12144_GL_Book_Entries` | 19 | ☐ |
| `Righe_Dich_Servizio` | 19 | ☐ |
| `OrdiniProduzionePianificati` | 19 | ☐ |
| `DimensionSets` | 18 | ☐ |
| `workflowGenJournalBatches` | 18 | ☐ |
| `PS_PowerBI_12170_PL` | 17 | ☐ |
| `Scheda_oggetto_di_costo_Excel` | 17 | ☐ |
| `Prodotti_Shopify_Excel` | 17 | ☐ |
| `SalesDashboard` | 17 | ☐ |
| `Spedire_Lista_indirizzi` | 17 | ☐ |
| `powerbifinance` | 17 | ☐ |
| `VBACC2` | 16 | ☐ |
| `Impostazioni_Estensione_Camarlinghi` | 16 | ☐ |
| `RIGHE_DOC_CONAI` | 16 | ☐ |
| `Testa_Report_Intrastat` | 16 | ☐ |
| `PS_PowerBI_T45_GL_Register` | 16 | ☐ |
| `PS_PowerBI_T172_SCSC` | 15 | ☐ |
| `Piano_Conti_Oggetti_Costo` | 14 | ☐ |
| `PS_PowerBI_349_Dimension_Value` | 14 | ☐ |
| `PS_PowerBI_T12186_VAT_Exemption` | 14 | ☐ |
| `Setup_registrazione_magazzino_Excel` | 14 | ☐ |
| `SalesOrdersBySalesPerson` | 14 | ☐ |
| `PS_PowerBI_T171_SSL` | 13 | ☐ |
| `UserTaskSetComplete` | 13 | ☐ |
| `ExcelTemplateAgedAccountsReceivable` | 12 | ☐ |
| `PS_PowerBI_12171_Posted_Payment_Lines` | 12 | ☐ |
| `Riferimenti_articolo` | 12 | ☐ |
| `Cespiti` | 12 | ☐ |
| `ExcelTemplateAgedAccountsPayable` | 12 | ☐ |
| `PS_PowerBI_T480_Dimension_Set_Entry` | 11 | ☐ |
| `TopCustomerOverview` | 11 | ☐ |
| `PS_PowerBI_352_Default_Dimension` | 11 | ☐ |
| `PS_PowerBI_T2000000006_Company` | 10 | ☐ |
| `ItemSalesByCustomer` | 10 | ☐ |
| `ExcelTemplateTrialBalance` | 10 | ☐ |
| `PS_PoswerBI_348_Dimension` | 10 | ☐ |
| `Utenti_Camarlinghi` | 10 | ☐ |
| `Gruppi_Prezzi_Cliente` | 9 | ☐ |
| `Spedizionieri` | 9 | ☐ |
| `PS_PowerBI_5777_Itmem_Reference` | 9 | ☐ |
| `DB_produzione_Excel` | 9 | ☐ |
| `Valori_dimensioni_Excel` | 9 | ☐ |
| `PS_PowerBI_5404_IUM` | 9 | ☐ |
| `Ciclo_Excel` | 9 | ☐ |
| `GestioneEstensioni_Camarlinghi` | 8 | ☐ |
| `Movimenti_C_G_TEST` | 8 | ☐ |
| `PS_PowerBI_T84_Acc_Schedule_Name` | 8 | ☐ |
| `Cliente_Esenzione_Conai` | 8 | ☐ |
| `PS_PowerBI_T5722_IC` | 8 | ☐ |
| `ExcelTemplateBalanceSheet` | 7 | ☐ |
| `Attributi_Articolo_1` | 7 | ☐ |
| `ExcelTemplateIncomeStatement` | 7 | ☐ |
| `ExcelTemplateCashFlowStatement` | 7 | ☐ |
| `ExcelTemplateRetainedEarnings` | 7 | ☐ |
| `Cicli` | 7 | ☐ |
| `Movimenti_set_di_dimensioni_Excel` | 6 | ☐ |
| `CONAI_IMB` | 6 | ☐ |
| `DimensionSetEntries` | 6 | ☐ |
| `Identificativi_articolo` | 5 | ☐ |
| `Valori_attributo_articolo_Excel` | 5 | ☐ |
| `Impiegati_warehouse_Excel` | 5 | ☐ |
| `Cal_gr_Lavoro` | 5 | ☐ |
| `Attribuzione_Articolo_Attributo` | 5 | ☐ |
| `CONAI_MATERIE_PRIME` | 4 | ☐ |
| `PianiUtente_Camarlinghi` | 4 | ☐ |
| `ExcelTemplateViewCompanyInformation` | 4 | ☐ |
| `PS_PowerBI_T170_SSC` | 4 | ☐ |
| `traduzioni_attributi` | 4 | ☐ |
| `Dichiarazioni_Servizio` | 4 | ☐ |
| `PS_PowerBI_253_GL_Entry_VAT_Entry_Link` | 3 | ☐ |
| `Collegamenti_tra_ciclo_e_distinta_base_Excel` | 3 | ☐ |
