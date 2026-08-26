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
| `id` | guid | b5592b4e-19a1-ee11-be36-000d3ab6afd4 | GUID di sistema dell'articolo (chiave API) | ☐ |
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
| `unitPrice` | float | 0 | Prezzo unitario di vendita | ☐ |
| `priceProfitCalculation` | string | Profit=Price-Cost |  | ☐ |
| `profitPercent` | float | 0 |  | ☐ |
| `costingMethod` | string | FIFO | Metodo di costo (FIFO, Standard, Average...) | ☐ |
| `unitCost` | float | 0.23 | Costo unitario corrente | ☐ |
| `standardCost` | float | 0.19976390134529146 | Costo standard | ☐ |
| `lastDirectCost` | float | 0.23 | Ultimo costo diretto d'acquisto | ☐ |
| `indirectCostPercent` | float | 0 |  | ☐ |
| `costIsAdjusted` | bool | True |  | ☐ |
| `allowOnlineAdjustment` | bool | True |  | ☐ |
| `vendorNumber` | string |  |  | ☐ |
| `vendorItemNumber` | string |  |  | ☐ |
| `leadTimeCalculation` | string |  |  | ☐ |
| `reorderPoint` | float | 0 |  | ☐ |
| `maximumInventory` | float | 0 |  | ☐ |
| `reorderQuantity` | float | 0 |  | ☐ |
| `alternativeItemNumber` | string |  |  | ☐ |
| `unitListPrice` | float | 0 |  | ☐ |
| `dutyDuePercent` | float | 0 |  | ☐ |
| `dutyCode` | string |  |  | ☐ |
| `grossWeight` | float | 0 |  | ☐ |
| `netWeight` | float | 10 |  | ☐ |
| `unitsPerParcel` | float | 0 |  | ☐ |
| `unitVolume` | float | 0 |  | ☐ |
| `durability` | string |  |  | ☐ |
| `freightType` | string |  |  | ☐ |
| `tariffNumber` | string | 94017100 |  | ☐ |
| `dutyUnitConversion` | float | 0 |  | ☐ |
| `countryRegionPurchasedCode` | string |  |  | ☐ |
| `budgetQuantity` | float | 0 |  | ☐ |
| `budgetedAmount` | float | 0 |  | ☐ |
| `budgetProfit` | float | 0 |  | ☐ |
| `comment` | bool | False |  | ☐ |
| `blocked` | bool | False | Articolo bloccato (true = non utilizzabile) | ☐ |
| `costIsPostedToGL` | bool | False |  | ☐ |
| `blockReason` | string |  |  | ☐ |
| `lastDatetimeModified` | datetime | 2026-06-09T14:37:40.13Z |  | ☐ |
| `lastDateModified` | date | 2026-06-09 |  | ☐ |
| `lastTimeModified` | string | 16:37:40.13 |  | ☐ |
| `dateFilter` | string |  |  | ☐ |
| `globalDimension1Filter` | string |  |  | ☐ |
| `globalDimension2Filter` | string |  |  | ☐ |
| `locationFilter` | string |  |  | ☐ |
| `inventory` | float | 6537 | Giacenza attuale (qta a magazzino) | ☐ |
| `netInvoicedQty` | float | 6537 |  | ☐ |
| `netChange` | float | 6537 |  | ☐ |
| `purchasesQty` | float | 29991 | Qta totale acquistata (storico) | ☐ |
| `salesQty` | float | 48 | Qta totale venduta (storico) | ☐ |
| `positiveAdjmtQty` | float | 1905 |  | ☐ |
| `negativeAdjmtQty` | float | 2878 |  | ☐ |
| `purchasesLcy` | float | 6828.93 | Valore acquisti in valuta locale (EUR) | ☐ |
| `salesLcy` | float | 0 |  | ☐ |
| `positiveAdjmtLcy` | float | 381 |  | ☐ |
| `negativeAdjmtLcy` | float | -648.23 |  | ☐ |
| `cogsLcy` | float | 10.63 | Costo del venduto (COGS) in valuta locale | ☐ |
| `qtyOnPurchOrder` | float | 9 | Qta su ordini d'acquisto aperti | ☐ |
| `qtyOnSalesOrder` | float | 0 |  | ☐ |
| `priceIncludesVat` | bool | False |  | ☐ |
| `dropShipmentFilter` | string |  |  | ☐ |
| `vatBusPostingGrPrice` | string |  |  | ☐ |
| `genProdPostingGroup` | string | MP-ARRG-ACCESSORI | Gruppo registrazione prodotto (COGE) | ☐ |
| `transferredQty` | float | 0 |  | ☐ |
| `transferredLcy` | float | 0 |  | ☐ |
| `countryRegionOfOriginCode` | string |  |  | ☐ |
| `automaticExtTexts` | bool | False |  | ☐ |
| `numberSeries` | string |  |  | ☐ |
| `taxGroupCode` | string |  |  | ☐ |
| `vatProdPostingGroup` | string | 220 | Gruppo registrazione IVA prodotto | ☐ |
| `reserve` | string | Optional |  | ☐ |
| `reservedQtyOnInventory` | float | 0 |  | ☐ |
| `reservedQtyOnPurchOrders` | float | 0 |  | ☐ |
| `reservedQtyOnSalesOrders` | float | 0 |  | ☐ |
| `globalDimension1Code` | string | ARRG | Dimensione globale 1 = Business Unit (es. ARRG = Arredo Giardino) | ☐ |
| `globalDimension2Code` | string |  |  | ☐ |
| `resQtyOnOutboundTransfer` | float | 0 |  | ☐ |
| `resQtyOnInboundTransfer` | float | 0 |  | ☐ |
| `resQtyOnSalesReturns` | float | 0 |  | ☐ |
| `resQtyOnPurchReturns` | float | 0 |  | ☐ |
| `stockoutWarning` | string | No |  | ☐ |
| `preventNegativeInventory` | string | No |  | ☐ |
| `costOfOpenProductionOrders` | float | 0 |  | ☐ |
| `applicationWkshUserId` | string |  |  | ☐ |
| `assemblyPolicy` | string | Assemble-to-Stock |  | ☐ |
| `resQtyOnAssemblyOrder` | float | 0 |  | ☐ |
| `resQtyOnAsmComp` | float | 0 |  | ☐ |
| `qtyOnAssemblyOrder` | float | 0 |  | ☐ |
| `qtyOnAsmComponent` | float | 0 |  | ☐ |
| `qtyOnJobOrder` | float | 0 |  | ☐ |
| `resQtyOnJobOrder` | float | 0 |  | ☐ |
| `gtin` | string |  |  | ☐ |
| `defaultDeferralTemplateCode` | string |  |  | ☐ |
| `lowLevelCode` | int | 3 |  | ☐ |
| `lotSize` | float | 0 |  | ☐ |
| `serialNos` | string |  |  | ☐ |
| `lastUnitCostCalcDate` | date | 0001-01-01 |  | ☐ |
| `rolledUpMaterialCost` | float | 0 |  | ☐ |
| `rolledUpCapacityCost` | float | 0 |  | ☐ |
| `scrapPercent` | float | 0 |  | ☐ |
| `inventoryValueZero` | bool | False |  | ☐ |
| `discreteOrderQuantity` | int | 0 |  | ☐ |
| `minimumOrderQuantity` | float | 0 |  | ☐ |
| `maximumOrderQuantity` | float | 0 |  | ☐ |
| `safetyStockQuantity` | float | 0 |  | ☐ |
| `orderMultiple` | float | 0 |  | ☐ |
| `safetyLeadTime` | string |  |  | ☐ |
| `flushingMethod` | string | Backward |  | ☐ |
| `replenishmentSystem` | string | Purchase | Sistema riapprovvigionamento: Purchase / Prod. Order / Assembly | ☐ |
| `scheduledReceiptQty` | float | 0 |  | ☐ |
| `roundingPrecision` | float | 1 |  | ☐ |
| `binFilter` | string |  |  | ☐ |
| `variantFilter` | string |  |  | ☐ |
| `salesUnitOfMeasure` | string | PZ |  | ☐ |
| `purchUnitOfMeasure` | string | PZ |  | ☐ |
| `timeBucket` | string |  |  | ☐ |
| `reservedQtyOnProdOrder` | float | 0 |  | ☐ |
| `resQtyOnProdOrderComp` | float | 0 |  | ☐ |
| `resQtyOnReqLine` | float | 0 |  | ☐ |
| `reorderingPolicy` | string | Lot-for-Lot |  | ☐ |
| `includeInventory` | bool | True |  | ☐ |
| `manufacturingPolicy` | string | Make-to-Stock |  | ☐ |
| `reschedulingPeriod` | string |  |  | ☐ |
| `lotAccumulationPeriod` | string | 15D |  | ☐ |
| `dampenerPeriod` | string |  |  | ☐ |
| `dampenerQuantity` | float | 0 |  | ☐ |
| `overflowLevel` | float | 0 |  | ☐ |
| `planningTransferShipQty` | float | 0 |  | ☐ |
| `planningWorksheetQty` | float | 0 |  | ☐ |
| `stockkeepingUnitExists` | bool | False |  | ☐ |
| `manufacturerCode` | string |  |  | ☐ |
| `itemCategoryCode` | string | MP | Codice categoria articolo (es. MP = materia prima) | ☐ |
| `createdFromNonstockItem` | bool | False |  | ☐ |
| `substitutesExist` | bool | False |  | ☐ |
| `qtyInTransit` | float | 0 |  | ☐ |
| `transOrdReceiptQty` | float | 0 |  | ☐ |
| `transOrdShipmentQty` | float | 0 |  | ☐ |
| `qtyAssignedToShip` | float | 0 |  | ☐ |
| `qtyPicked` | float | 0 |  | ☐ |
| `serviceItemGroup` | string |  |  | ☐ |
| `qtyOnServiceOrder` | float | 0 |  | ☐ |
| `resQtyOnServiceOrders` | float | 0 |  | ☐ |
| `itemTrackingCode` | string | COLLO |  | ☐ |
| `lotNos` | string |  |  | ☐ |
| `expirationCalculation` | string |  |  | ☐ |
| `lotNumberFilter` | string |  |  | ☐ |
| `serialNumberFilter` | string |  |  | ☐ |
| `qtyOnPurchReturn` | float | 0 |  | ☐ |
| `qtyOnSalesReturn` | float | 0 |  | ☐ |
| `numberOfSubstitutes` | int | 0 |  | ☐ |
| `warehouseClassCode` | string |  |  | ☐ |
| `specialEquipmentCode` | string |  |  | ☐ |
| `putAwayTemplateCode` | string |  |  | ☐ |
| `putAwayUnitOfMeasureCode` | string |  |  | ☐ |
| `physInvtCountingPeriodCode` | string |  |  | ☐ |
| `lastCountingPeriodUpdate` | date | 0001-01-01 |  | ☐ |
| `lastPhysInvtDate` | date | 0001-01-01 |  | ☐ |
| `useCrossDocking` | bool | True |  | ☐ |
| `nextCountingStartDate` | date | 0001-01-01 |  | ☐ |
| `nextCountingEndDate` | date | 0001-01-01 |  | ☐ |
| `identifierCode` | string |  |  | ☐ |
| `unitOfMeasureId` | guid | b39a8244-241b-ee11-8f6e-000d3aba081a |  | ☐ |
| `taxGroupId` | guid | 00000000-0000-0000-0000-000000000000 |  | ☐ |
| `routingNumber` | string |  |  | ☐ |
| `productionBomNumber` | string |  | N. distinta base di produzione (BOM) | ☐ |
| `singleLevelMaterialCost` | float | 0 |  | ☐ |
| `singleLevelCapacityCost` | float | 0 |  | ☐ |
| `singleLevelSubcontrdCost` | float | 0 |  | ☐ |
| `singleLevelCapOvhdCost` | float | 0 |  | ☐ |
| `singleLevelMfgOvhdCost` | float | 0 |  | ☐ |
| `overheadRate` | float | 0 |  | ☐ |
| `rolledUpSubcontractedCost` | float | 0 |  | ☐ |
| `rolledUpMfgOvhdCost` | float | 0 |  | ☐ |
| `rolledUpCapOverheadCost` | float | 0 |  | ☐ |
| `planningIssuesQty` | float | 0 |  | ☐ |
| `planningReceiptQty` | float | 0 |  | ☐ |
| `plannedOrderReceiptQty` | float | 0 |  | ☐ |
| `fpOrderReceiptQty` | float | 0 |  | ☐ |
| `relOrderReceiptQty` | float | 0 |  | ☐ |
| `planningReleaseQty` | float | 0 |  | ☐ |
| `plannedOrderReleaseQty` | float | 0 |  | ☐ |
| `purchReqReceiptQty` | float | 0 |  | ☐ |
| `purchReqReleaseQty` | float | 0 |  | ☐ |
| `orderTrackingPolicy` | string | Tracking Only |  | ☐ |
| `prodForecastQuantityBase` | float | 0 |  | ☐ |
| `productionForecastName` | string |  |  | ☐ |
| `componentForecast` | string |  |  | ☐ |
| `qtyOnProdOrder` | float | 0 |  | ☐ |
| `qtyOnComponentLines` | float | 1477 | Qta impegnata su righe componente OdP | ☐ |
| `critical` | bool | False |  | ☐ |
| `commonItemNumber` | string |  |  | ☐ |
| `Unit_of_Measure_Filter` | string |  |  | ☐ |
| `Package_No_Filter` | string |  |  | ☐ |
