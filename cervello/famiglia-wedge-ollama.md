---
tipo: famiglia
data: 2026-09-21
titolo: Wedge di Ollama: il server che risponde ma non genera
---
Sintomo: /api/tags risponde, le generazioni muoiono. 9-12 wedge in un giorno
(2026-09-21), 11 rianimati dal watchdog.

Radice (finalmente trovata): modelli da 19-21GB (Q5_K_M, Q5_K_XL) su 24GB di
RAM unificata — ogni generazione moriva soffocata insieme alla cache del
contesto e a macOS. Curata alla radice da [[decisione-modello-unico]] (12GB).

Cura dei sintomi, resta valida:
- il ping deve essere di GENERAZIONE, non /api/tags (quello mente da wedged)
- watchdog a inizio ciclo: muto = pkill serve, launchd rianima in ~15s
- la sonda deve aspettare il caricamento (240s per 12GB), altrimenti uccide
  un server sano a meta' caricamento — due volte di fila = turno morto

Un wedge diagnosticato male e' peggio di un wedge: vedi [[concetto-vaccino]].
