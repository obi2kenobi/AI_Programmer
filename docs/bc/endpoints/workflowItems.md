# Endpoint: `workflowItems`

- URL: `https://api.businesscentral.dynamics.com/v2.0/4d4b10ed-d04a-455b-80e1-aaf7ba4ee0d8/Production/ODataV4/Company('GRUPPO%20CAMARLINGHI%20S.P.A')/workflowItems`
- Righe campione lette: 3
- Campi trovati: 208
- Totale record (`$count`): **3689** articoli

> Stato: **mappato** · riscontro count = 3689 (⏳ da confermare con la lista articoli in BC) · *Significato* compilato per i campi chiave.
> `workflowItems` = anagrafica articoli BC (tabella T27 Item, pagina API 6409) + campi calcolati di giacenza/movimenti.

| Campo | Tipo | Esempio | Significato | Verificato |
|---|---|---|---|---|
| `@odata.etag` | string | W/"JzE5OzYwMDA3ODg2MDM1NjcyNjYyNDUxOz... |  | ☐ |
| `id` | string | b5592b4e-19a1-ee11-be36-000d3ab6afd4 | GUID di sistema dell'articolo (chiave API) | ☐ |
| `number` | string | A0000000000000000001 | Codice/N. articolo (chiave funzionale) | ☐ |
| `number2` | string |  |  | ☐ |
| `description` | string | ANUBE BRONZATE | Descrizione articolo | ☐ |
| `searchDescription` | string | ANUBE BRONZATE |  | ☐ |
| `description2` | string |  |  | ☐ |
| `assemblyBom` | bool | False |  | ☐ |
| `baseUnitOfMeasure` | string | PZ | Unità di misura base (es. PZ) | ☐ |
| `priceUnitConversion` | int | 0 |  | ☐ |
| `type` | string | Inventory | Tipo: Inventory / Service / Non-Inventory | ☐ |
| `inventoryPostingGroup` | string | MP-ARRG-ACCESSORI | Gruppo registrazione magazzino | ☐ |
| `shelfNumber` | string |  |  | ☐ |
| `itemDiscGroup` | string |  |  | ☐ |
| `allowInvoiceDisc` | bool | True |  | ☐ |
| `statisticsGroup` | int | 0 |  | ☐ |
| `commissionGroup` | int | 0 |  | ☐ |
| `unitPrice` | int | 0 | Prezzo unitario di vendita | ☐ |
| `priceProfitCalculation` | string | Profit=Price-Cost |  | ☐ |
| `profitPercent` | int | 0 |  | ☐ |
| `costingMethod` | string | FIFO | Metodo di costo (FIFO, Standard, Average...) | ☐ |
| `unitCost` | float | 0.23 | Costo unitario corrente | ☐ |
| `standardCost` | float | 0.19976390134529146 | Costo standard | ☐ |
| `lastDirectCost` | float | 0.23 | Ultimo costo diretto d'acquisto | ☐ |
| `indirectCostPercent` | int | 0 |  | ☐ |
| `costIsAdjusted` | bool | True |  | ☐ |
| `allowOnlineAdjustment` | bool | True |  | ☐ |
| `vendorNumber` | string |  |  | ☐ |
| `vendorItemNumber` | string |  |  | ☐ |
| `leadTimeCalculation` | string |  |  | ☐ |
| `reorderPoint` | int | 0 |  | ☐ |
| `maximumInventory` | int | 0 |  | ☐ |
| `reorderQuantity` | int | 0 |  | ☐ |
| `alternativeItemNumber` | string |  |  | ☐ |
| `unitListPrice` | int | 0 |  | ☐ |
| `dutyDuePercent` | int | 0 |  | ☐ |
| `dutyCode` | string |  |  | ☐ |
| `grossWeight` | int | 0 |  | ☐ |
| `netWeight` | int | 10 |  | ☐ |
| `unitsPerParcel` | int | 0 |  | ☐ |
| `unitVolume` | int | 0 |  | ☐ |
| `durability` | string |  |  | ☐ |
| `freightType` | string |  |  | ☐ |
| `tariffNumber` | string | 94017100 |  | ☐ |
| `dutyUnitConversion` | int | 0 |  | ☐ |
| `countryRegionPurchasedCode` | string |  |  | ☐ |
| `budgetQuantity` | int | 0 |  | ☐ |
| `budgetedAmount` | int | 0 |  | ☐ |
| `budgetProfit` | int | 0 |  | ☐ |
| `comment` | bool | False |  | ☐ |
| `blocked` | bool | False | Articolo bloccato (true = non utilizzabile) | ☐ |
| `costIsPostedToGL` | bool | False |  | ☐ |
| `blockReason` | string |  |  | ☐ |
| `lastDatetimeModified` | string | 2026-06-09T14:37:40.13Z |  | ☐ |
| `lastDateModified` | string | 2026-06-09 |  | ☐ |
| `lastTimeModified` | string | 16:37:40.13 |  | ☐ |
| `dateFilter` | string |  |  | ☐ |
| `globalDimension1Filter` | string |  |  | ☐ |
| `globalDimension2Filter` | string |  |  | ☐ |
| `locationFilter` | string |  |  | ☐ |
| `inventory` | int | 6537 | Giacenza attuale (qta a magazzino) | ☐ |
| `netInvoicedQty` | int | 6537 |  | ☐ |
| `netChange` | int | 6537 |  | ☐ |
| `purchasesQty` | int | 29991 | Qta totale acquistata (storico) | ☐ |
| `salesQty` | int | 48 | Qta totale venduta (storico) | ☐ |
| `positiveAdjmtQty` | int | 1905 |  | ☐ |
| `negativeAdjmtQty` | int | 2878 |  | ☐ |
| `purchasesLcy` | float | 6828.93 | Valore acquisti in valuta locale (EUR) | ☐ |
| `salesLcy` | int | 0 |  | ☐ |
| `positiveAdjmtLcy` | int | 381 |  | ☐ |
| `negativeAdjmtLcy` | float | -648.23 |  | ☐ |
| `cogsLcy` | float | 10.63 | Costo del venduto (COGS) in valuta locale | ☐ |
| `qtyOnPurchOrder` | int | 9 | Qta su ordini d'acquisto aperti | ☐ |
| `qtyOnSalesOrder` | int | 0 |  | ☐ |
| `priceIncludesVat` | bool | False |  | ☐ |
| `dropShipmentFilter` | string |  |  | ☐ |
| `vatBusPostingGrPrice` | string |  |  | ☐ |
| `genProdPostingGroup` | string | MP-ARRG-ACCESSORI | Gruppo registrazione prodotto (COGE) | ☐ |
| `transferredQty` | int | 0 |  | ☐ |
| `transferredLcy` | int | 0 |  | ☐ |
| `countryRegionOfOriginCode` | string |  |  | ☐ |
| `automaticExtTexts` | bool | False |  | ☐ |
| `numberSeries` | string |  |  | ☐ |
| `taxGroupCode` | string |  |  | ☐ |
| `vatProdPostingGroup` | string | 220 | Gruppo registrazione IVA prodotto | ☐ |
| `reserve` | string | Optional |  | ☐ |
| `reservedQtyOnInventory` | int | 0 |  | ☐ |
| `reservedQtyOnPurchOrders` | int | 0 |  | ☐ |
| `reservedQtyOnSalesOrders` | int | 0 |  | ☐ |
| `globalDimension1Code` | string | ARRG | Dimensione globale 1 = Business Unit (es. ARRG = Arredo Giardino) | ☐ |
| `globalDimension2Code` | string |  |  | ☐ |
| `resQtyOnOutboundTransfer` | int | 0 |  | ☐ |
| `resQtyOnInboundTransfer` | int | 0 |  | ☐ |
| `resQtyOnSalesReturns` | int | 0 |  | ☐ |
| `resQtyOnPurchReturns` | int | 0 |  | ☐ |
| `stockoutWarning` | string | No |  | ☐ |
| `preventNegativeInventory` | string | No |  | ☐ |
| `costOfOpenProductionOrders` | int | 0 |  | ☐ |
| `applicationWkshUserId` | string |  |  | ☐ |
| `assemblyPolicy` | string | Assemble-to-Stock |  | ☐ |
| `resQtyOnAssemblyOrder` | int | 0 |  | ☐ |
| `resQtyOnAsmComp` | int | 0 |  | ☐ |
| `qtyOnAssemblyOrder` | int | 0 |  | ☐ |
| `qtyOnAsmComponent` | int | 0 |  | ☐ |
| `qtyOnJobOrder` | int | 0 |  | ☐ |
| `resQtyOnJobOrder` | int | 0 |  | ☐ |
| `gtin` | string |  |  | ☐ |
| `defaultDeferralTemplateCode` | string |  |  | ☐ |
| `lowLevelCode` | int | 3 |  | ☐ |
| `lotSize` | int | 0 |  | ☐ |
| `serialNos` | string |  |  | ☐ |
| `lastUnitCostCalcDate` | string | 0001-01-01 |  | ☐ |
| `rolledUpMaterialCost` | int | 0 |  | ☐ |
| `rolledUpCapacityCost` | int | 0 |  | ☐ |
| `scrapPercent` | int | 0 |  | ☐ |
| `inventoryValueZero` | bool | False |  | ☐ |
| `discreteOrderQuantity` | int | 0 |  | ☐ |
| `minimumOrderQuantity` | int | 0 |  | ☐ |
| `maximumOrderQuantity` | int | 0 |  | ☐ |
| `safetyStockQuantity` | int | 0 |  | ☐ |
| `orderMultiple` | int | 0 |  | ☐ |
| `safetyLeadTime` | string |  |  | ☐ |
| `flushingMethod` | string | Backward |  | ☐ |
| `replenishmentSystem` | string | Purchase | Sistema riapprovvigionamento: Purchase / Prod. Order / Assembly | ☐ |
| `scheduledReceiptQty` | int | 0 |  | ☐ |
| `roundingPrecision` | int | 1 |  | ☐ |
| `binFilter` | string |  |  | ☐ |
| `variantFilter` | string |  |  | ☐ |
| `salesUnitOfMeasure` | string | PZ |  | ☐ |
| `purchUnitOfMeasure` | string | PZ |  | ☐ |
| `timeBucket` | string |  |  | ☐ |
| `reservedQtyOnProdOrder` | int | 0 |  | ☐ |
| `resQtyOnProdOrderComp` | int | 0 |  | ☐ |
| `resQtyOnReqLine` | int | 0 |  | ☐ |
| `reorderingPolicy` | string | Lot-for-Lot |  | ☐ |
| `includeInventory` | bool | True |  | ☐ |
| `manufacturingPolicy` | string | Make-to-Stock |  | ☐ |
| `reschedulingPeriod` | string |  |  | ☐ |
| `lotAccumulationPeriod` | string | 15D |  | ☐ |
| `dampenerPeriod` | string |  |  | ☐ |
| `dampenerQuantity` | int | 0 |  | ☐ |
| `overflowLevel` | int | 0 |  | ☐ |
| `planningTransferShipQty` | int | 0 |  | ☐ |
| `planningWorksheetQty` | int | 0 |  | ☐ |
| `stockkeepingUnitExists` | bool | False |  | ☐ |
| `manufacturerCode` | string |  |  | ☐ |
| `itemCategoryCode` | string | MP | Codice categoria articolo (es. MP = materia prima) | ☐ |
| `createdFromNonstockItem` | bool | False |  | ☐ |
| `substitutesExist` | bool | False |  | ☐ |
| `qtyInTransit` | int | 0 |  | ☐ |
| `transOrdReceiptQty` | int | 0 |  | ☐ |
| `transOrdShipmentQty` | int | 0 |  | ☐ |
| `qtyAssignedToShip` | int | 0 |  | ☐ |
| `qtyPicked` | int | 0 |  | ☐ |
| `serviceItemGroup` | string |  |  | ☐ |
| `qtyOnServiceOrder` | int | 0 |  | ☐ |
| `resQtyOnServiceOrders` | int | 0 |  | ☐ |
| `itemTrackingCode` | string | COLLO |  | ☐ |
| `lotNos` | string |  |  | ☐ |
| `expirationCalculation` | string |  |  | ☐ |
| `lotNumberFilter` | string |  |  | ☐ |
| `serialNumberFilter` | string |  |  | ☐ |
| `qtyOnPurchReturn` | int | 0 |  | ☐ |
| `qtyOnSalesReturn` | int | 0 |  | ☐ |
| `numberOfSubstitutes` | int | 0 |  | ☐ |
| `warehouseClassCode` | string |  |  | ☐ |
| `specialEquipmentCode` | string |  |  | ☐ |
| `putAwayTemplateCode` | string |  |  | ☐ |
| `putAwayUnitOfMeasureCode` | string |  |  | ☐ |
| `physInvtCountingPeriodCode` | string |  |  | ☐ |
| `lastCountingPeriodUpdate` | string | 0001-01-01 |  | ☐ |
| `lastPhysInvtDate` | string | 0001-01-01 |  | ☐ |
| `useCrossDocking` | bool | True |  | ☐ |
| `nextCountingStartDate` | string | 0001-01-01 |  | ☐ |
| `nextCountingEndDate` | string | 0001-01-01 |  | ☐ |
| `identifierCode` | string |  |  | ☐ |
| `unitOfMeasureId` | string | b39a8244-241b-ee11-8f6e-000d3aba081a |  | ☐ |
| `taxGroupId` | string | 00000000-0000-0000-0000-000000000000 |  | ☐ |
| `routingNumber` | string |  |  | ☐ |
| `productionBomNumber` | string |  | N. distinta base di produzione (BOM) | ☐ |
| `singleLevelMaterialCost` | int | 0 |  | ☐ |
| `singleLevelCapacityCost` | int | 0 |  | ☐ |
| `singleLevelSubcontrdCost` | int | 0 |  | ☐ |
| `singleLevelCapOvhdCost` | int | 0 |  | ☐ |
| `singleLevelMfgOvhdCost` | int | 0 |  | ☐ |
| `overheadRate` | int | 0 |  | ☐ |
| `rolledUpSubcontractedCost` | int | 0 |  | ☐ |
| `rolledUpMfgOvhdCost` | int | 0 |  | ☐ |
| `rolledUpCapOverheadCost` | int | 0 |  | ☐ |
| `planningIssuesQty` | int | 0 |  | ☐ |
| `planningReceiptQty` | int | 0 |  | ☐ |
| `plannedOrderReceiptQty` | int | 0 |  | ☐ |
| `fpOrderReceiptQty` | int | 0 |  | ☐ |
| `relOrderReceiptQty` | int | 0 |  | ☐ |
| `planningReleaseQty` | int | 0 |  | ☐ |
| `plannedOrderReleaseQty` | int | 0 |  | ☐ |
| `purchReqReceiptQty` | int | 0 |  | ☐ |
| `purchReqReleaseQty` | int | 0 |  | ☐ |
| `orderTrackingPolicy` | string | Tracking Only |  | ☐ |
| `prodForecastQuantityBase` | int | 0 |  | ☐ |
| `productionForecastName` | string |  |  | ☐ |
| `componentForecast` | string |  |  | ☐ |
| `qtyOnProdOrder` | int | 0 |  | ☐ |
| `qtyOnComponentLines` | int | 1477 | Qta impegnata su righe componente OdP | ☐ |
| `critical` | bool | False |  | ☐ |
| `commonItemNumber` | string |  |  | ☐ |
| `Unit_of_Measure_Filter` | string |  |  | ☐ |
| `Package_No_Filter` | string |  |  | ☐ |
