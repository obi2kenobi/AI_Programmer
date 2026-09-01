# 2026-09-01 — REPO-Q: audit di sola lettura su tutto il repo, 53 voci, 2 PR

Autore: sessione Claude Code (remota, PR review umana di Luca)

## Cosa ho usato
Repo NON onboardato allo standard. Letto il hub (METHOD.md, CLAUDE.md, system.md) in sola
lettura a inizio sessione, poi principi applicati A MANO: 6 agenti paralleli di sola lettura
per l'audit (uno per area, 8 sotto-progetti), citando sempre file:riga. Io stesso da
verificatore ad ogni giro (node --check, test in Node, confronto byte-a-byte). Nessun oracolo
per le formule di REPO-Q: il progetto GEMELLO già corretto usato come surrogato quando
disponibile, e «non verificabile senza OAuth BC» dichiarato quando non lo era.

## Cosa ho improvvisato
- «200 giri» su territorio enorme: chiarito con l'utente, poi audit reale → 53 rilievi VERI
  (numero non gonfiato — «Never invent requirements»).
- Struttura Tier1-4 (BUG/RISCHIO/DEBITO/IDEA) per il backlog: improvvisata.
- Rimando motivato invece di esecuzione a rischio: 8 Tier3 + 5 Tier4 rimandati CON la ragione
  scritta (refactor meccanici su funzioni centrali, decisioni di dominio non deducibili).
- A metà sessione l'utente chiese «le 5 per gas-contabilità»: solo 3 toccavano quel progetto
  — chiarito con AskUserQuestion, e per la voce eseguita l'ambito scelto esplicitamente.

## Cosa ha retto / ostacolato
- HA RETTO: «esegui non dedurre» applicato all'AUDIT — la scoperta più grave (lo scrub di un
  secret leakato aveva corrotto un NOME DI FUNZIONE in produzione, sintassi non valida, file
  mai girato) NON era nell'audit dei 6 agenti: emersa leggendo un file per intero invece di
  fidarsi del grep. E «il guardiano si prova quando deve fallire»: CSV deliberatamente
  troncato per confermare che il test di regressione fallisse davvero.
- HA OSTACOLATO: nessun hook attivo (il report esiste solo perché l'utente l'ha chiesto a
  fine sessione — nessun promemoria strutturale); nessun oracolo eseguibile (il gemello ha
  funzionato quando c'era, ma non è generalizzabile).

## Proposta al canone
1. Un repo NON onboardato va dichiarato ALL'INIZIO della sessione (come REPO-H dichiara
   «NON RAGGIUNGIBILE»), non a fine sessione via report quando è troppo tardi per correggere.
2. «Territorio grande dichiarato esplicitamente dall'utente» merita una variante dichiarata
   del metodo: audit paralleli di sola lettura per area → esecuzione a livelli di priorità
   con motivazione scritta per ciò che si rimanda. Distinta da commessa/notte (qui: repo
   singolo, sessione interattiva, niente turno notturno multi-repo).
