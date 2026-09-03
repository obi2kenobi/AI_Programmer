# 2026-09-03 — Fase 2 fatture estere: la registrazione via API si chiude

Autore: Luca + sessione Claude Code (remota). Repo: REPO-W (GAS+BC, fatture estere).
Esito: la registrazione di una fattura fornitore estera via API Business Central si
chiude con 204. 41/41 test, node check verdi, 15 cicli log→analisi→commit in 2 ore.

## Cosa ha usato
Skill gas-agent (BC Specialist + quality-standards) prima di scrivere le funzioni GAS.
Documentazione vivente §25.30→§25.41, una voce per scoperta. node tools/test_regole.mjs
(41/41) prima di ogni commit.

## NON RAGGIUNGIBILE: installazione parziale
.claude/skills/ (fra cui post-mortem) e docs/errori/REGISTRO.md non esistono in questo
repo: l'installazione AI_Programmer era rimasta PARZIALE. Due errori della sessione
sarebbero finiti nel registro con la sua guardia; sono finiti nella documentazione di
progetto, che non ha lente automatica.

## Le due proposte al canone

### 1. Verifica l'identità PRIMA di configurarla
Costo di non farla: UN'ORA di permessi concessi alla scheda sbagliata. Ho proposto
l'applicazione BC come «candidato quasi certo» sulla base del NOME, conferma non arrivata,
ho proseguito. Il dato stava nel token, a 10 righe di distanza.
Regola: prima di concedere permessi, quote o accessi a un'utenza/applicazione, far dire
al SISTEMA STESSO quale identità sta usando (token, whoami, log di audit). Il nome di una
risorsa NON è un dato sull'identità.

### 2. Una sonda che può restituire zero deve distinguere zero da domanda sbagliata
elencaServiziOData() interrogava Company('NOME') — 200, ma è la scheda della SOCIETÀ,
non il documento di servizio — e usciva in silenzio. Costò un'esecuzione; dentro una
misura avrebbe prodotto un numero falso dall'aria vera.
Regola: ogni funzione diagnostica che può legittimamente non trovare nulla deve dichiarare
COSA ha trovato (codice, forma della risposta, chiavi presenti) prima di uscire.
