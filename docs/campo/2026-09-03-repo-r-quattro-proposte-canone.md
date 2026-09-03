# Report per AI_Programmer — quattro proposte al canone, con le prove

Da: sessione reale su progetto onboardato GAS+Sheets, 2026-09-02/03. Codice: REPO-R.
Il giro: da "le banche chiedono un file" a ingestione mergiata, via /design-doc →
3 decisioni → /goal (3 tentativi) → banco 27 attese → verifica avversariale → PR.

## 1. Il banco che confronta STRUTTURE non può usare vm.createContext
assert.deepStrictEqual confronta i prototipi: ciò che nasce in un contesto vm appartiene
a un altro realm (Array là ≠ Array qui). 4 attese su 23 fallivano con valori identici.
Fix: new Function (stesso realm) invece di vm.createContext — senza toccare una riga
del codice in prova. La prova che il difetto era nel BANCO, non nel codice.

## 2. La verifica avversariale ha ripagato al primo uso reale
Banco 27/27 verde. L'avversariale (rieseguire contro TUTTI i record veri) ha trovato
una discrepanza che esiste solo in AGGREGATO (due totalizzazioni dello stesso file
danno numeri diversi) — il banco valida riga per riga e non poteva vederla.
Un banco verde prova che i casi che hai immaginato passano, non che il codice è corretto.

## 3. Quando l'oracolo esiste ma NON è esatto: tolleranza derivata, mai scelta
Il file gestionale dichiarava i propri totali: 3 righe su 14 divergevano di poche unità.
Uguaglianza secca → 3 falsi allarmi. Soglia a occhio → nasconde residui veri.
La via giusta: derivare la tolleranza dal meccanismo (arrotondamento → max n×0,5 per
riga), e flaggare (Coerenza: OK / DA VERIFICARE diff N) finché il dominio non conferma.

## 4. "Quale sistema lo produce?" prima di qualsiasi ricerca
"Il file che il sistema mi produce" — l'articolo determinativo nascondeva che il file
nasceva in un applicativo DIVERSO. Il dato cercato non esisteva nel sistema che
guardavamo, in nessuna forma. Una domanda ha riorientato tutto.

## Corollario
Chi verifica va verificato. Il banco ha trovato un difetto nel banco; l'avversariale
ha trovato ciò che il banco non vedeva. Senza un livello esterno che controlla il
verificatore, il sistema non è verificato: è creduto.
