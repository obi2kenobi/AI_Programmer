# Endpoint: `GeneralLedgerSetup`

- URL: `https://api.businesscentral.dynamics.com/v2.0/4d4b10ed-d04a-455b-80e1-aaf7ba4ee0d8/Production/ODataV4/Company('GRUPPO%20CAMARLINGHI%20S.P.A')/GeneralLedgerSetup`
- Righe campione lette: 1
- Campi trovati: 121
- Ultimo aggiornamento: 2026-08-26 (merge: le colonne compilate a mano sono preservate)

> Stato: **mappato** (da verificare con riscontro: interfaccia BC / gestionale / totali noti).

| Campo | Tipo | Esempio | Significato | Verificato |
|---|---|---|---|---|
| `@odata.etag` | string | W/"JzE5Ozc2MjE1ODEzMTM5MzQzMjIxODgxOz... |  | ☐ |
| `Primary_Key` | string |  |  | ☐ |
| `Allow_Posting_From` | date | 2025-01-01 |  | ☐ |
| `Allow_Posting_To` | date | 2026-12-31 |  | ☐ |
| `Allow_Posting_From_DateFormula` | string |  |  | ☐ |
| `Allow_Posting_To_DateFormula` | string |  |  | ☐ |
| `Allow_Deferral_Posting_From` | date | 2025-01-01 |  | ☐ |
| `Allow_Deferral_Posting_To` | date | 2025-12-31 |  | ☐ |
| `VAT_Reporting_Date_Usage` | string | Enabled |  | ☐ |
| `Default_VAT_Reporting_Date` | string | Posting Date |  | ☐ |
| `Register_Time` | bool | True |  | ☐ |
| `Local_Address_Format` | string | City+County+Post Code |  | ☐ |
| `Local_Cont_Addr_Format` | string | After Company Name |  | ☐ |
| `Req_Country_Reg_Code_in_Addr` | bool | True |  | ☐ |
| `Inv_Rounding_Precision_LCY` | float | 0.01 |  | ☐ |
| `Inv_Rounding_Type_LCY` | string | Nearest |  | ☐ |
| `AmountRoundingPrecision` | float | 0.01 |  | ☐ |
| `AmountDecimalPlaces` | string | 2:2 |  | ☐ |
| `UnitAmountRoundingPrecision` | float | 0.001 |  | ☐ |
| `UnitAmountDecimalPlaces` | string | 2:5 |  | ☐ |
| `Allow_G_L_Acc_Deletion_Before` | date | 2001-01-01 |  | ☐ |
| `Block_Deletion_of_G_L_Accounts` | bool | True |  | ☐ |
| `Check_G_L_Account_Usage` | bool | True |  | ☐ |
| `CashVATPrdGrp` | string |  |  | ☐ |
| `Validate_loc_VAT_Reg_No` | bool | True |  | ☐ |
| `Use_Activity_Code` | bool | False |  | ☐ |
| `Mark_Cr_Memos_as_Corrections` | bool | False |  | ☐ |
| `Pmt_Disc_Excl_VAT` | bool | False |  | ☐ |
| `Adjust_for_Payment_Disc` | bool | False |  | ☐ |
| `Unrealized_VAT` | bool | False |  | ☐ |
| `Prepayment_Unrealized_VAT` | bool | False |  | ☐ |
| `Max_VAT_Difference_Allowed` | float | 0.01 |  | ☐ |
| `Tax_Invoice_Renaming_Threshold` | float | 0 |  | ☐ |
| `VAT_Rounding_Type` | string | Nearest |  | ☐ |
| `Control_VAT_Period` | string | Block posting within closed and warn ... |  | ☐ |
| `Bank_Account_Nos` | string | BANCA |  | ☐ |
| `Company_Officials_Nos` | string |  |  | ☐ |
| `Bill_to_Sell_to_VAT_Calc` | string | Bill-to/Pay-to No. |  | ☐ |
| `Print_VAT_specification_in_LCY` | bool | False |  | ☐ |
| `Show_Amounts` | string | All Amounts |  | ☐ |
| `Hide_Payment_Method_Code` | bool | False |  | ☐ |
| `Hide_Company_Bank_Account` | bool | False |  | ☐ |
| `PostingPreviewType` | string | Standard |  | ☐ |
| `SEPANonEuroExport` | bool | False |  | ☐ |
| `SEPAExportWoBankAccData` | bool | False |  | ☐ |
| `Auto_Split_VAT_Pay_on_S_Rel` | bool | False |  | ☐ |
| `Auto_Split_VAT_Ident_Filter` | string |  |  | ☐ |
| `Auto_split_semi_incl_in_Fltr` | bool | False |  | ☐ |
| `Journal_Templ_Name_Mandatory` | bool | False |  | ☐ |
| `EnableDataCheck` | bool | False |  | ☐ |
| `CheckSourceCurrencyConsistency` | bool | False |  | ☐ |
| `Global_Dimension_1_Code` | string | BU |  | ☐ |
| `Global_Dimension_2_Code` | string | REPARTO |  | ☐ |
| `Shortcut_Dimension_1_Code` | string | BU |  | ☐ |
| `Shortcut_Dimension_2_Code` | string | REPARTO |  | ☐ |
| `Shortcut_Dimension_3_Code` | string | OPERATORE |  | ☐ |
| `Shortcut_Dimension_4_Code` | string | POST_VENDITA |  | ☐ |
| `Shortcut_Dimension_5_Code` | string | ALTRE ATTIVITA' |  | ☐ |
| `Shortcut_Dimension_6_Code` | string |  |  | ☐ |
| `Shortcut_Dimension_7_Code` | string |  |  | ☐ |
| `Shortcut_Dimension_8_Code` | string |  |  | ☐ |
| `Dimension_Code_Cust_Contr` | string | CONTRATTOCLIENTE |  | ☐ |
| `LCY_Code` | string | EUR |  | ☐ |
| `Use_Document_Date_in_Currency` | bool | True |  | ☐ |
| `Local_Currency_Symbol` | string | € |  | ☐ |
| `Local_Currency_Description` | string | Euro |  | ☐ |
| `ShowCurrencySymbol` | string | Never |  | ☐ |
| `CurrencySymbolPosition` | string | Before Amount |  | ☐ |
| `EMU_Currency` | bool | True |  | ☐ |
| `Post_with_Job_Queue` | bool | False |  | ☐ |
| `Post__x0026__Print_with_Job_Queue` | bool | False |  | ☐ |
| `Job_Queue_Category_Code` | string | JRNLPOST |  | ☐ |
| `Notify_On_Success` | bool | False |  | ☐ |
| `Report_Output_Type` | string | PDF |  | ☐ |
| `Additional_Reporting_Currency` | string |  |  | ☐ |
| `VAT_Exchange_Rate_Adjustment` | string | No Adjustment |  | ☐ |
| `Acc_Receivables_Category` | int | 0 |  | ☐ |
| `Acc_Payables_Category` | int | 0 |  | ☐ |
| `Acc_Sched_for_Balance_Sheet` | string | SALDO-M |  | ☐ |
| `Acc_Sched_for_Income_Stmt` | string | REDDITO-M |  | ☐ |
| `Acc_Sched_for_Cash_Flow_Stmt` | string | FLUSCASS-M |  | ☐ |
| `Acc_Sched_for_Retained_Earn` | string | UTILI-M |  | ☐ |
| `Fin_Rep_Bal_Sheet_Row` | string |  |  | ☐ |
| `Fin_Rep_Income_Stmt_Row` | string |  |  | ☐ |
| `Fin_Rep_Cash_Flow_Stmt_Row` | string |  |  | ☐ |
| `Fin_Rep_Retained_Earn_Row` | string |  |  | ☐ |
| `Fin_Rep_Bal_Sheet_Column` | string |  |  | ☐ |
| `Fin_Rep_Net_Change_Column` | string |  |  | ☐ |
| `Fin_Rep_Period_Type` | string | Day |  | ☐ |
| `Fin_Rep_Neg_Amount_Format` | string | Minus Sign |  | ☐ |
| `Fin_Rep_Company_Logo_Pos` | string | No Logo |  | ☐ |
| `DefaultFinancialReportStatus` | string |  |  | ☐ |
| `Appln_Rounding_Precision` | float | 0 |  | ☐ |
| `Pmt_Disc_Tolerance_Warning` | bool | False |  | ☐ |
| `Pmt_Disc_Tolerance_Posting` | string | Payment Tolerance Accounts |  | ☐ |
| `Payment_Discount_Grace_Period` | string |  |  | ☐ |
| `Payment_Tolerance_Warning` | bool | False |  | ☐ |
| `Payment_Tolerance_Posting` | string | Payment Tolerance Accounts |  | ☐ |
| `Payment_Tolerance_Percent` | float | 0 |  | ☐ |
| `Max_Payment_Tolerance_Amount` | float | 0 |  | ☐ |
| `Skip_Apply_Date_Check` | bool | True |  | ☐ |
| `App_Dimension_Posting` | string | Source Entry Dimensions |  | ☐ |
| `VAT_Rounding_Type2` | string | Nearest |  | ☐ |
| `Settlement_Round_Factor` | float | 0.01 |  | ☐ |
| `Minimum_VAT_Payable` | float | 0 |  | ☐ |
| `Last_Settlement_Date` | date | 2026-07-31 |  | ☐ |
| `Last_Gen_Jour_Printing_Date` | date | 2024-12-31 |  | ☐ |
| `Last_General_Journal_No` | int | 46464 |  | ☐ |
| `Last_Printed_G_L_Book_Page` | int | 1195 |  | ☐ |
| `Official_Debit_Amount` | float | 218065538.6 |  | ☐ |
| `Official_Credit_Amount` | float | 218065538.6 |  | ☐ |
| `VAT_Settlement_Period` | string | Month |  | ☐ |
| `Adjust_ARC_Jnl_Template_Name` | string |  |  | ☐ |
| `Adjust_ARC_Jnl_Batch_Name` | string |  |  | ☐ |
| `Apply_Jnl_Template_Name` | string |  |  | ☐ |
| `Apply_Jnl_Batch_Name` | string |  |  | ☐ |
| `Job_WIP_Jnl_Template_Name` | string |  |  | ☐ |
| `Job_WIP_Jnl_Batch_Name` | string |  |  | ☐ |
| `Bank_Acc_Recon_Template_Name` | string |  |  | ☐ |
| `Bank_Acc_Recon_Batch_Name` | string |  |  | ☐ |
| `Payroll_Trans_Import_Format` | string |  |  | ☐ |
